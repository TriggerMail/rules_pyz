py_file_types = FileType([".py"])

wheel_file_types = FileType([".whl"])

PyZProvider = provider(fields = [
    "transitive_src_mappings",
    "transitive_srcs",
    "transitive_wheels",
    "transitive_force_unzip",
])

_pyz_attrs = {
    "srcs": attr.label_list(
        flags = ["DIRECT_COMPILE_TIME_INPUT"],
        allow_files = py_file_types,
    ),
    "deps": attr.label_list(
        allow_files = False,
        providers = [PyZProvider],
    ),
    "wheels": attr.label_list(
        flags = ["DIRECT_COMPILE_TIME_INPUT"],
        allow_files = wheel_file_types,
    ),
    "pythonroot": attr.string(default = ""),
    "_simplepack": attr.label(
        executable = True,
        cfg = "host",
        allow_single_file = True,
        default = Label("//tools:simplepack"),
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

def _get_destination_path(prefix, file):
    destination = file.short_path
    # external repositories have paths like "../repository_name/"
    if destination.startswith("../"):
        destination = destination[3:]

    if destination.startswith(prefix):
        destination = destination[len(prefix):]
    return destination

def _get_transitive_provider(ctx):
    # build the mapping from source to destinations for this rule
    pythonroot = get_pythonroot(ctx)
    prefix = "####notaprefix#####/"
    if pythonroot != None:
        prefix = pythonroot + "/"
    if not prefix.endswith("/"):
        fail("prefix must end with /: " + repr(prefix))
    src_mapping = []
    # treat srcs and data the same: no real reason to separate them?
    for files_attr in (ctx.files.srcs, ctx.files.data):
        for f in files_attr:
            dst = f.short_path
            # external repositories have paths like "../repository_name/"
            if dst.startswith("../"):
                dst = dst[3:]

            if dst.startswith(prefix):
                dst = dst[len(prefix):]
            src_mapping.append(struct(src=f.path, dst=dst))

    # combine with transitive mappings
    transitive_src_mappings = depset(direct=src_mapping)
    transitive_srcs = depset(direct=ctx.files.srcs + ctx.files.data)
    transitive_wheels = depset(direct=ctx.files.wheels)
    force_unzips = []
    if not ctx.attr.zip_safe:
        # not zip safe: list all the files in this target as requiring unzipping
        force_unzips = [m.dst for m in src_mapping]
        # Also list the wheel contents as needing unzipping
        # TODO: Make this a separate attribute?
        force_unzips += [f.path for f in ctx.files.wheels]
    transitive_force_unzip = depset(direct=force_unzips)
    for dep in ctx.attr.deps:
        transitive_src_mappings += dep[PyZProvider].transitive_src_mappings
        transitive_srcs += dep[PyZProvider].transitive_srcs
        transitive_wheels += dep[PyZProvider].transitive_wheels
        transitive_force_unzip += dep[PyZProvider].transitive_force_unzip

    return PyZProvider(
        transitive_src_mappings=transitive_src_mappings,
        transitive_srcs=transitive_srcs,
        transitive_wheels=transitive_wheels,
        transitive_force_unzip=transitive_force_unzip,
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

    # we must include setuptools in all pyz_binary: it includes pkg_resources which is needed
    # to load resources from zip files
    if not ctx.attr.force_all_unzip:
        has_setuptools = any(['/setuptools-' in f.path for f in provider.transitive_wheels])
        if not has_setuptools:
            provider = PyZProvider(
                transitive_src_mappings=provider.transitive_src_mappings,
                transitive_srcs=provider.transitive_srcs,
                transitive_wheels=provider.transitive_wheels + [ctx.file._setuptools_whl],
                transitive_force_unzip=provider.transitive_force_unzip,
            )

    manifest = struct(
        sources=provider.transitive_src_mappings.to_list(),
        wheels=[f.path for f in provider.transitive_wheels],
        entry_point=ctx.attr.entry_point,
        interpreter=ctx.attr.interpreter,
        interpreter_path=ctx.attr.interpreter_path,
        force_unzip=provider.transitive_force_unzip.to_list(),
        force_all_unzip=ctx.attr.force_all_unzip,
    )

    manifest_file = ctx.new_file(ctx.configuration.bin_dir, ctx.outputs.executable, '_manifest')
    ctx.actions.write(manifest_file, manifest.to_json())

    # package all files into a zip
    inputs = depset(
        direct=[ctx.file._simplepack, manifest_file],
        transitive=[provider.transitive_srcs, provider.transitive_wheels]
    )
    ctx.actions.run(
        inputs=inputs,
        outputs=[ctx.outputs.executable],
        arguments=[manifest_file.path, ctx.outputs.executable.path],
        executable=ctx.executable._simplepack,
        mnemonic="PackPyZ"
    )

pyz_binary = rule(
    _pyz_binary_impl,
    attrs = _pyz_attrs + {
        "entry_point": attr.string(default = ""),

        # If True, act like a Python interpreter: interactive shell or execute scripts
        "interpreter": attr.bool(default = False),

        # Path to the Python interpreter to write as the #! line on the zip.
        "interpreter_path": attr.string(default = ""),

        # Forces the contents of the pyz_binary to be extracted and run from a temp dir.
        "force_all_unzip": attr.bool(default = False),
        "_setuptools_whl": attr.label(
            allow_single_file = True,
            default = Label("@pypi_setuptools//file"),
        ),
    },
    executable = True,
)

def _pyz_script_test_impl(ctx):
    # run the pyz_binary with all our dependencies, with the srcs on the command line
    test_file_paths = []
    for f in ctx.files.srcs:
        # TODO: what is the right workspace path?
        # TODO: Bash escape
        runfiles_path = "${RUNFILES}/__main__/" + f.short_path
        test_file_paths.append(runfiles_path)

    ctx.actions.expand_template(
        template = ctx.file._pytest_template,
        output = ctx.outputs.executable,
        substitutions = {
            "{{PYTEST_RUNNER}}": ctx.file.compiled_deps.short_path,
            "{{SRCS_LIST}}": " ".join(test_file_paths),
        },
    )

    runfiles = ctx.runfiles(
        files=[ctx.file.compiled_deps] + ctx.files.srcs,
        collect_data = True,
    )
    return [DefaultInfo(
        runfiles=runfiles
    )]

_pyz_script_test = rule(
    _pyz_script_test_impl,
    attrs = _pyz_attrs + {
        "compiled_deps": attr.label(
            mandatory = True,
            allow_single_file = True,
        ),
        "_pytest_template": attr.label(
            default = "//rules_python_zip:pytest_template.sh",
            allow_single_file = True,
        ),

        # required so the pyz_test can be used in third_party without error
        "licenses": attr.license(),
    },
    executable = True,
    test = True,
)

def pyz_test(name, srcs=[], deps=[], wheels=[], data=[], force_all_unzip=False,
    flaky=None, licenses=[], local=None, timeout=None, shard_count=None, size=None,
    interpreter_path=""):
    '''Macro that outputs a pyz_binary with all the test code and executes it with a shell script
    to pass the correct arguments.'''

    # Label ensures this is resolved correctly if used as an external workspace
    pytest_label = Label("//rules_python_zip:pytest")
    compiled_deps_name = "%s__deps" % name
    pyz_binary(
        name = compiled_deps_name,
        deps = deps + [str(pytest_label)],
        data = data,
        wheels = wheels,
        entry_point = "pytest",

        # Path to the Python interpreter to write as the #! line on the zip.
        interpreter_path=interpreter_path,
        force_all_unzip = force_all_unzip,
        testonly = True,
        licenses = licenses,
    )

    _pyz_script_test(
        name = name,
        srcs = srcs,
        data = data,
        compiled_deps = compiled_deps_name,
        testonly = True,
        licenses = licenses,

        flaky = flaky,
        local = local,
        shard_count = shard_count,
        size = size,
        timeout = timeout,
    )

def pyz_repositories():
    """Rules to be invoked from WORKSPACE to load remote dependencies."""

    excludes = native.existing_rules().keys()

    if 'pypi_attrs' not in excludes:
        native.http_file(
            name = 'pypi_attrs',
            url = 'https://pypi.python.org/packages/b5/60/4e178c1e790fd60f1229a9b3cb2f8bc2f4cc6ff2c8838054c142c70b5adc/attrs-17.4.0-py2.py3-none-any.whl',
            sha256 = 'a17a9573a6f475c99b551c0e0a812707ddda1ec9653bed04c13841404ed6f450'
        )
    if 'pypi_funcsigs' not in excludes:
        native.http_file(
            name = 'pypi_funcsigs',
            url = 'https://pypi.python.org/packages/69/cb/f5be453359271714c01b9bd06126eaf2e368f1fddfff30818754b5ac2328/funcsigs-1.0.2-py2.py3-none-any.whl',
            sha256 = '330cc27ccbf7f1e992e69fef78261dc7c6569012cf397db8d3de0234e6c937ca'
        )
    if 'pypi_more_itertools' not in excludes:
        native.http_file(
            name="pypi_more_itertools",
            url="https://pypi.python.org/packages/4a/88/c28e2a2da8f3dc3a391d9c97ad949f2ea0c05198222e7e6af176e5bf9b26/more_itertools-4.1.0-py2-none-any.whl",
            sha256="11a625025954c20145b37ff6309cd54e39ca94f72f6bb9576d1195db6fa2442e",
        )
    if 'pypi_pluggy_tgz' not in excludes:
        native.http_file(
            name = 'pypi_pluggy_tgz',
            url = 'https://pypi.python.org/packages/11/bf/cbeb8cdfaffa9f2ea154a30ae31a9d04a1209312e2919138b4171a1f8199/pluggy-0.6.0.tar.gz',
            sha256 = '7f8ae7f5bdf75671a718d2daf0a64b7885f74510bcd98b1a0bb420eb9a9d0cff',
        )
    if 'pypi_py' not in excludes:
        native.http_file(
            name="pypi_py",
            url="https://pypi.python.org/packages/67/a5/f77982214dd4c8fd104b066f249adea2c49e25e8703d284382eb5e9ab35a/py-1.5.3-py2.py3-none-any.whl",
            sha256="983f77f3331356039fdd792e9220b7b8ee1aa6bd2b25f567a963ff1de5a64f6a",
        )
    if 'pypi_pytest' not in excludes:
        native.http_file(
            name="pypi_pytest",
            url="https://pypi.python.org/packages/ed/96/271c93f75212c06e2a7ec3e2fa8a9c90acee0a4838dc05bf379ea09aae31/pytest-3.5.0-py2.py3-none-any.whl",
            sha256="6266f87ab64692112e5477eba395cfedda53b1933ccd29478e671e73b420c19c",
        )
    if 'pypi_six' not in excludes:
        native.http_file(
            name = 'pypi_six',
            url = 'https://pypi.python.org/packages/67/4b/141a581104b1f6397bfa78ac9d43d8ad29a7ca43ea90a2d863fe3056e86a/six-1.11.0-py2.py3-none-any.whl',
            sha256 = '832dc0e10feb1aa2c68dcc57dbb658f1c7e65b9b61af69048abc87a2db00a0eb'
        )
    if 'pypi_setuptools' not in excludes:
        native.http_file(
            name = 'pypi_setuptools',
            url = 'https://pypi.python.org/packages/20/d7/04a0b689d3035143e2ff288f4b9ee4bf6ed80585cc121c90bfd85a1a8c2e/setuptools-39.0.1-py2.py3-none-any.whl',
            sha256 = '8010754433e3211b9cdbbf784b50f30e80bf40fc6b05eb5f865fab83300599b8'
        )
