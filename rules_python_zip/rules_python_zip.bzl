load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

PyZProvider = provider(fields = [
    "transitive_mappings",
    "transitive_force_unzip",
])

_pyz_attrs = {
    "srcs": attr.label_list(
        flags = ["DIRECT_COMPILE_TIME_INPUT"],
        allow_files = [".py"],
    ),
    "deps": attr.label_list(
        allow_files = False,
        providers = [PyZProvider],
    ),
    "wheels": attr.label_list(
        flags = ["DIRECT_COMPILE_TIME_INPUT"],
        allow_files = [".whl"],
    ),
    "pythonroot": attr.string(default = ""),

    "_empty_init_py": attr.label(
        allow_single_file=True,
        default=Label("//rules_python_zip:__init__.py")
    ),

    "data": attr.label_list(
        allow_files = True,
        cfg = "data",
    ),

    # this target's direct files must be unzipped to be executed. This is usually
    # because Python code relies on __file__ relative paths existing.
    "zip_safe": attr.bool(default = True),

    # required so the rules can be used in third_party without error:
    # third-party rule '//third_party/pypi:example' lacks a license declaration
    "licenses": attr.license(),
}

def get_pythonroot(ctx):
    if ctx.attr.pythonroot == "":
        return None

    # Find the path to the package containing this rule: BUILD file without /BUILD
    base = ctx.build_file_path[:ctx.build_file_path.rfind('/')]

    # external repositories: have a path like external/workspace_name/...
    # however the file .short_path look like "../workspace_name/..."
    # strip external: it is a reserved directory name so this should not collide
    EXTERNAL_PREFIX = "external/"
    if base.startswith(EXTERNAL_PREFIX):
      base = base[len(EXTERNAL_PREFIX):]

    if ctx.attr.pythonroot == ".":
        pythonroot = base
    elif ctx.attr.pythonroot.startswith("//"):
        maybe_root = ctx.attr.pythonroot[2:]
        if not (maybe_root.startswith(base) or base.startswith(maybe_root)):
            fail("absolute pythonroot must be on the package's path: " + maybe_root + " | " + base)
        pythonroot = maybe_root
    else:
        # relative pythonroot
        if ctx.attr.pythonroot[0] == "/":
            fail("invalid pythonroot: " + ctx.attr.pythonroot)
        if "." in ctx.attr.pythonroot:
            fail("invalid pythonroot: " + ctx.attr.pythonroot)
        pythonroot = base + "/" + ctx.attr.pythonroot

    return pythonroot

def _get_transitive_provider(ctx):
    # build the mapping from source to destinations for this rule
    pythonroot = get_pythonroot(ctx)
    prefix = "####notaprefix#####/"
    if pythonroot != None:
        prefix = pythonroot + "/"
    if not prefix.endswith("/"):
        fail("prefix must end with /: " + repr(prefix))

    direct_mappings = []
    # treat srcs and data the same: no real reason to separate them?
    for files_attr in (ctx.files.srcs, ctx.files.data):
        for f in files_attr:
            # Bazel can't handle files with spaces? "link or target filename contains space"
            if ' ' in f.short_path:
                continue

            dst = f.short_path
            # external repositories have paths like "../repository_name/"
            if dst.startswith("../"):
                dst = dst[3:]

            if dst.startswith(prefix):
                dst = dst[len(prefix):]
            direct_mappings.append(struct(src=f, dst=dst))

    force_unzips = []
    if not ctx.attr.zip_safe:
        # not zip safe: list all the files in this target as requiring unzipping
        force_unzips = [m.dst for m in direct_mappings]
        # Also list the wheel contents as needing unzipping
        # TODO: Make this a separate attribute?
        force_unzips.extend([f.path for f in ctx.files.wheels])

    # combine with transitive mappings
    transitive_mappings = []
    transitive_force_unzips = []
    for dep in ctx.attr.deps:
        transitive_mappings.append(dep[PyZProvider].transitive_mappings)
        transitive_force_unzips.append(dep[PyZProvider].transitive_force_unzip)

    # order is critical: need direct srcs to be first so we can pick the "main" script
    transitive_mappings = depset(direct=direct_mappings, transitive=transitive_mappings, order="preorder")
    return PyZProvider(
        transitive_mappings=transitive_mappings,
        transitive_force_unzip=depset(direct=force_unzips, transitive=transitive_force_unzips),
    )

def _pyz_library_impl(ctx):
    provider = _get_transitive_provider(ctx)
    return [provider]

pyz_library = rule(
    _pyz_library_impl,
    attrs = _pyz_attrs,
)

def _pyz_binary_impl(ctx):
    main_options_count = (int(len(ctx.files.srcs) > 0) + int(ctx.attr.entry_point != "") +
        int(ctx.attr.interpreter))
    if main_options_count != 1:
        fail("must specify exactly one of srcs OR entry_point OR interpreter; specified %d" % (
            main_options_count))

    provider = _get_transitive_provider(ctx)

    # Package all Python dependencies into a unique dir: Make it possible for a rule to depend on
    # two executables with conflicting imports (e.g. different versions)
    base_dir = ctx.workspace_name + '/' + ctx.outputs.executable.short_path + '_exedir'
    main_py_path = base_dir + '/__main__.py'

    main_script = ''
    # TODO: Only take the first src and don't call .to_list which can be slow
    mappings_list = provider.transitive_mappings.to_list()
    if len(mappings_list) > 0:
        main_script = mappings_list[0].dst
    manifest = struct(
        main_script=main_script,
        entry_point=ctx.attr.entry_point,
        interpreter=ctx.attr.interpreter,
    )

    ctx.actions.expand_template(
        template = ctx.file._main_template,
        output = ctx.outputs.main_py,
        substitutions = {
            "{{MANIFEST_JSON}}": manifest.to_json(),
        },
    )
    interpreter_path = 'python'
    if ctx.attr.interpreter_path:
        interpreter_path = ctx.attr.interpreter_path
    ctx.actions.expand_template(
        template = ctx.file._main_shell_template,
        output = ctx.outputs.executable,
        substitutions = {
            "{{MAIN_PATH}}": main_py_path,
            "{{INTEPRETER_PATH}}": interpreter_path,
        }
    )

    links = {main_py_path: ctx.outputs.main_py}
    for mapping in mappings_list:
        links[base_dir + '/' + mapping.dst] = mapping.src

    # find directories containing python source files without __init__.py
    # TODO: Require py_library rules to specify an __init__.py? This actually
    # makes things easier, and is what py_library does
    dirs_with_py = {}
    dirs_with_init = {}
    base_dir_parts = base_dir.count('/')
    for dst in links:
        if not dst.endswith('.py'):
            continue

        # mark all directories to the root as containing python files
        # (excluding the base_dir created to hold all python files)
        parts = dst.split('/')
        file_name = parts[-1]
        for dir_end_index in range(len(parts)-1, base_dir_parts+1, -1):
            py_dir = '/'.join(parts[0:dir_end_index])

            if dir_end_index == len(parts)-1 and file_name == '__init__.py':
                dirs_with_init[py_dir] = True

            dirs_with_py[py_dir] = True

    for dir_with_py in dirs_with_py:
        if dir_with_py == base_dir:
            continue
        if dir_with_py in dirs_with_init:
            continue

        init_dst = dir_with_py + '/__init__.py'
        if init_dst in links:
            fail('BUG: path should not exist: ' + init_dst)
        links[init_dst] = ctx.file._empty_init_py

    # collect_data so we get transitive runfiles from data dependencies
    # TODO: This also duplicates data dependencies; can we avoid this somehow?
    runfiles = ctx.runfiles(root_symlinks=links, collect_data=True)

    # provide an alternative target that packages everything into an executable zip
    manifest_files = []
    action_inputs = []
    base_dir_prefix = base_dir + '/'
    for dst, src in links.items():
        # strip the base_dir from dst
        if not dst.startswith(base_dir_prefix):
            fail('invalid dst path: ' + dst)
        dst = dst[len(base_dir_prefix):]

        manifest_files.append(struct(src=src.path, dst=dst))
        action_inputs.append(src)

    manifest = struct(
        output_path = ctx.outputs.exezip.path,
        interpreter_path=interpreter_path,
        files=manifest_files,
    )
    manifest_file = ctx.new_file(ctx.configuration.bin_dir, ctx.outputs.exezip, '_manifest')
    ctx.actions.write(manifest_file, manifest.to_json())
    ctx.actions.run(
        inputs=[manifest_file] + action_inputs,
        outputs=[ctx.outputs.exezip],
        arguments=[manifest_file.path],
        executable=ctx.file._linkzip,
    )

    # by default: only build the executable script and runfiles tree
    return [DefaultInfo(
        files=depset(direct=[ctx.outputs.executable]),
        runfiles=runfiles
    )]


def _dict_merge(orig_dict, additional_dict):
    new_dict = dict(orig_dict)
    new_dict.update(additional_dict)
    return new_dict


pyz_binary = rule(
    _pyz_binary_impl,
    attrs = _dict_merge(_pyz_attrs, {
        "entry_point": attr.string(default=""),

        # If True, act like a Python interpreter: interactive shell or execute scripts
        "interpreter": attr.bool(default=False),

        # Path to the Python interpreter to write as the #! line on the zip.
        "interpreter_path": attr.string(default=""),

        # Forces the contents of the pyz_binary to be extracted and run from a temp dir.
        "force_all_unzip": attr.bool(default=False),

        "_main_template": attr.label(
            default="//rules_python_zip:main_template.py",
            allow_single_file=True,
        ),
        "_main_shell_template": attr.label(
            default="//rules_python_zip:main_shell_template.sh",
            allow_single_file=True,
        ),
        "_linkzip": attr.label(
            default="//rules_python_zip:linkzip.py",
            allow_single_file=True,
            executable=True,
            cfg="host",
        ),
    }),
    executable = True,
    outputs = {
        "main_py": "%{name}__main.py",
        "exezip": "%{name}_exezip",
    },
)


def _pyz_script_test_impl(ctx):
    pytest_runner = ctx.workspace_name + "/" + ctx.executable.test_executable.short_path

    pyz_provider = _get_transitive_provider(ctx)

    # run the pyz_binary with all the test dependencies, with the srcs on the command line
    # find the mapped paths of the test srcs
    unmapped_test_files = {f: True for f in ctx.files.srcs}
    test_file_paths = []
    for mapping in pyz_provider.transitive_mappings.to_list():
        if mapping.src in unmapped_test_files:
            test_file_paths.append(mapping.dst)
            unmapped_test_files.pop(mapping.src)
            if len(unmapped_test_files) == 0:
                break
    if len(unmapped_test_files) > 0:
        fail('could not find files:' + repr(unmapped_test_files))

    # TODO: Bash escape?
    test_file_paths = ["${RUNFILES}/" + pytest_runner + "_exedir/" + p for p in test_file_paths]
    ctx.actions.expand_template(
        template = ctx.file._pytest_template,
        output = ctx.outputs.executable,
        substitutions = {
            "{{PYTEST_RUNNER}}": pytest_runner,
            "{{SRCS_LIST}}": " ".join(test_file_paths),
        },
    )

    runfiles = ctx.runfiles(
        files=[ctx.outputs.executable],
        collect_data = True,
    )
    return [DefaultInfo(
        runfiles=runfiles
    )]


_pyz_script_test = rule(
    _pyz_script_test_impl,
    attrs = _dict_merge(_pyz_attrs, {
        "test_executable": attr.label(
            mandatory=True,
            executable=True,
            cfg="target",
        ),
        "_pytest_template": attr.label(
            default="//rules_python_zip:pytest_template.sh",
            allow_single_file=True,
        ),

        # required so the pyz_test can be used in third_party without error
        "licenses": attr.license(),
    }),
    executable = True,
    test = True,
)

def pyz_test(name, srcs=[], data=[], deps=[], pythonroot=None,
    force_all_unzip=False, interpreter_path=None, flaky=None, licenses=[],
    local=None, timeout=None, shard_count=None, size=None, tags=[], args=[]):
    '''Macro that outputs a pyz_binary with all the test code and executes it with a shell script
    to pass the correct arguments.'''

    # Label ensures this is resolved correctly if used as an external workspace
    pytest_label = Label("//rules_python_zip/pytest")
    compiled_deps_name = "%s_deps" % (name)
    pyz_library(
        name = compiled_deps_name,
        srcs = srcs,
        data = data,
        deps = deps,
        pythonroot = pythonroot,
        testonly = True,
        licenses = licenses,
    )

    test_executable_name = "%s_exe" % (name)
    pyz_binary(
        name = test_executable_name,
        data = data,
        deps = [":" + compiled_deps_name, str(pytest_label)],
        entry_point = "pytest",
        interpreter_path = interpreter_path,
        force_all_unzip = force_all_unzip,
        testonly = True,
        licenses = licenses,
    )

    _pyz_script_test(
        name = name,
        srcs = srcs,
        data = data + [":" + test_executable_name],
        pythonroot = pythonroot,
        test_executable = test_executable_name,
        testonly = True,
        licenses = licenses,

        flaky = flaky,
        local = local,
        shard_count = shard_count,
        size = size,
        timeout = timeout,
        tags = tags,
        args = args,
    )

def wheel_build_content():
    # Label ensures this is resolved correctly when used as an external workspace
    rules_label = Label("@com_bluecore_rules_pyz//rules_python_zip:rules_python_zip.bzl")
    content = '''
load("{}", "pyz_library")

pyz_library(
    name="lib",
    srcs=glob(["**/*.py"]),
    data=glob(["**/*"], exclude=["**/*.py", "BUILD", "WORKSPACE", "*.whl.zip"]),
    pythonroot=".",
    visibility=["//visibility:public"],
)
'''.format(str(rules_label))
    return content


def pyz_repositories():
    """Rules to be invoked from WORKSPACE to load remote dependencies."""

    excludes = native.existing_rules()

    WHEEL_BUILD_CONTENT = wheel_build_content()
    if 'pypi_atomicwrites' not in excludes:
        http_archive(
            name = 'pypi_atomicwrites',
            url = 'https://files.pythonhosted.org/packages/0a/e8/cd6375e7a59664eeea9e1c77a766eeac0fc3083bb958c2b41ec46b95f29c/atomicwrites-1.1.5-py2.py3-none-any.whl',
            sha256 = 'a24da68318b08ac9c9c45029f4a10371ab5b20e4226738e150e6e7c571630ae6',
            build_file_content=WHEEL_BUILD_CONTENT,
            type="zip",
        )
    if 'pypi_attrs' not in excludes:
        http_archive(
            name = 'pypi_attrs',
            url = 'https://files.pythonhosted.org/packages/41/59/cedf87e91ed541be7957c501a92102f9cc6363c623a7666d69d51c78ac5b/attrs-18.1.0-py2.py3-none-any.whl',
            sha256 = '4b90b09eeeb9b88c35bc642cbac057e45a5fd85367b985bd2809c62b7b939265',
            build_file_content=WHEEL_BUILD_CONTENT,
            type="zip",
        )
    if 'pypi_funcsigs' not in excludes:
        http_archive(
            name = 'pypi_funcsigs',
            url = 'https://pypi.python.org/packages/69/cb/f5be453359271714c01b9bd06126eaf2e368f1fddfff30818754b5ac2328/funcsigs-1.0.2-py2.py3-none-any.whl',
            sha256 = '330cc27ccbf7f1e992e69fef78261dc7c6569012cf397db8d3de0234e6c937ca',
            build_file_content=WHEEL_BUILD_CONTENT,
            type="zip",
        )
    if 'pypi_more_itertools' not in excludes:
        http_archive(
            name="pypi_more_itertools",
            url="https://files.pythonhosted.org/packages/9e/92/d05d8679c3bcaa263169aa47de660080df36d35697855515745657c1ba78/more_itertools-4.2.0-py2-none-any.whl",
            sha256="a18d870ef2ffca2b8463c0070ad17b5978056f403fb64e3f15fe62a52db21cc0",
            build_file_content=WHEEL_BUILD_CONTENT,
            type="zip",
        )
    if 'pypi_pluggy' not in excludes:
        http_archive(
            name = 'pypi_pluggy',
            url = 'https://files.pythonhosted.org/packages/82/05/43e3947125a2137cba4746135c75934ceed1863f27e050fc560052104a71/pluggy-0.6.0-py2-none-any.whl',
            sha256 = 'd345c8fe681115900d6da8d048ba67c25df42973bda370783cd58826442dcd7c',
            build_file_content=WHEEL_BUILD_CONTENT,
            type="zip",
        )
    if 'pypi_py' not in excludes:
        http_archive(
            name="pypi_py",
            url="https://pypi.python.org/packages/67/a5/f77982214dd4c8fd104b066f249adea2c49e25e8703d284382eb5e9ab35a/py-1.5.3-py2.py3-none-any.whl",
            sha256="983f77f3331356039fdd792e9220b7b8ee1aa6bd2b25f567a963ff1de5a64f6a",
            build_file_content=WHEEL_BUILD_CONTENT,
            type="zip",
        )
    if 'pypi_pytest' not in excludes:
        http_archive(
            name="pypi_pytest",
            url="https://files.pythonhosted.org/packages/62/59/950a805f90587d6e2f3692cf43700becb7cdf6c16b06d84e7516b199236b/pytest-3.6.0-py2.py3-none-any.whl",
            sha256="c76e93f3145a44812955e8d46cdd302d8a45fbfc7bf22be24fe231f9d8d8853a",
            build_file_content=WHEEL_BUILD_CONTENT,
            type="zip",
        )
    if 'pypi_six' not in excludes:
        http_archive(
            name = 'pypi_six',
            url = 'https://pypi.python.org/packages/67/4b/141a581104b1f6397bfa78ac9d43d8ad29a7ca43ea90a2d863fe3056e86a/six-1.11.0-py2.py3-none-any.whl',
            sha256 = '832dc0e10feb1aa2c68dcc57dbb658f1c7e65b9b61af69048abc87a2db00a0eb',
            build_file_content=WHEEL_BUILD_CONTENT,
            type="zip",
        )
    if 'pypi_setuptools' not in excludes:
        http_archive(
            name = 'pypi_setuptools',
            url = 'https://files.pythonhosted.org/packages/7f/e1/820d941153923aac1d49d7fc37e17b6e73bfbd2904959fffbad77900cf92/setuptools-39.2.0-py2.py3-none-any.whl',
            sha256 = '8fca9275c89964f13da985c3656cb00ba029d7f3916b37990927ffdf264e7926',
            build_file_content=WHEEL_BUILD_CONTENT,
            type="zip",
        )
