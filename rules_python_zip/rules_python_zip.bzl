py_file_types = FileType([".py"])
wheel_file_types = FileType([".whl"])


_PyZProvider = provider(fields=[
    "transitive_src_mappings", "transitive_srcs", "transitive_wheels", "transitive_force_unzip"])

_pyz_attrs = {
    "srcs": attr.label_list(
        flags = ["DIRECT_COMPILE_TIME_INPUT"],
        allow_files = py_file_types,
    ),
    "deps": attr.label_list(
        allow_files = False,
        providers = [_PyZProvider],
    ),
    "wheels": attr.label_list(
        flags = ["DIRECT_COMPILE_TIME_INPUT"],
        allow_files = wheel_file_types,
    ),
    "pythonroot": attr.string(default=""),
    "_simplepack": attr.label(
        executable=True,
        cfg="host",
        allow_single_file=True,
        default=Label("//tools:simplepack")),
    "data": attr.label_list(allow_files = True, cfg = "data"),

    # this target's direct files must be unzipped to be executed. This is usually
    # because Python code relies on __file__ relative paths existing.
    "zip_safe": attr.bool(default=True),

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
        transitive_src_mappings += dep[_PyZProvider].transitive_src_mappings
        transitive_srcs += dep[_PyZProvider].transitive_srcs
        transitive_wheels += dep[_PyZProvider].transitive_wheels
        transitive_force_unzip += dep[_PyZProvider].transitive_force_unzip

    return _PyZProvider(
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
    attrs = _pyz_attrs
)

def _pyz_binary_impl(ctx):
    main_options_count = (int(len(ctx.files.srcs) > 0) + int(ctx.attr.entry_point != "") +
        int(ctx.attr.interpreter))
    if main_options_count != 1:
        fail("must specify exactly one of srcs OR entry_point OR interpreter; specified %d" % (
            main_options_count))

    provider = _get_transitive_provider(ctx)

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
        mnemonic="PackPython"
    )


pyz_binary = rule(
    _pyz_binary_impl,
    attrs = _pyz_attrs + {
        "entry_point": attr.string(default=""),

        # If True, act like a Python interpreter: interactive shell or execute scripts
        "interpreter": attr.bool(default=False),

        # Path to the Python interpreter to write as the #! line on the zip.
        "interpreter_path": attr.string(default=""),

        # Forces the contents of the pyz_binary to be extracted and run from a temp dir.
        "force_all_unzip": attr.bool(default=False),
    },
    executable = True,
)


def _pyz_script_test_impl(ctx):
    # run the pyz_binary with all our dependencies, with the srcs on the command line
    test_file_paths = [f.short_path for f in ctx.files.srcs]
    ctx.actions.expand_template(
        template = ctx.file._pytest_template,
        output = ctx.outputs.executable,
        substitutions = {
            "{{PYTEST_RUNNER}}": ctx.file.compiled_deps.short_path,
            # TODO: Bash escape
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
        "compiled_deps": attr.label(mandatory=True, allow_single_file=True),
        "_pytest_template": attr.label(
            default="//rules_python_zip:pytest_template.sh",
            allow_single_file=True,
        ),

        # required so the pyz_test can be used in third_party without error
        "licenses": attr.license(),
    },
    executable = True,
    test = True,
)


def pyz_test(name, srcs=[], deps=[], wheels=[], data=[], force_all_unzip=False,
    flaky=None, licenses=[], local=None, timeout=None, shard_count=None, size=None):
    '''Macro that outputs a pyz_binary with all the test code and executes it with a shell script
    to pass the correct arguments.'''

    # Label ensures this is resolved correctly if used as an external workspace
    pytest_label = Label("//rules_python_zip:pytest")
    compiled_deps_name = "%s_deps" % (name)
    pyz_binary(
        name = compiled_deps_name,
        deps = deps + [str(pytest_label)],
        wheels = wheels,
        entry_point = "pytest",
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
    native.http_file(
        name = 'pyz_pytest_whl',
        url = 'https://pypi.python.org/packages/41/e4/9de71dc666485c921f5c8d2d8078109af1f3925bf52f17ccf4c7cc19a8a0/pytest-3.4.0-py2.py3-none-any.whl',
        sha256 = '95fa025cd6deb5d937e04e368a00552332b58cae23f63b76c8c540ff1733ab6d'
    )
    native.http_file(
        name = 'pyz_six_whl',
        url = 'https://pypi.python.org/packages/67/4b/141a581104b1f6397bfa78ac9d43d8ad29a7ca43ea90a2d863fe3056e86a/six-1.11.0-py2.py3-none-any.whl',
        sha256 = '832dc0e10feb1aa2c68dcc57dbb658f1c7e65b9b61af69048abc87a2db00a0eb'
    )
    native.http_file(
        name = 'pyz_py_whl',
        url = 'https://pypi.python.org/packages/41/70/adacedf6cdc13700d40303f78b241f98c959e2745fdebbe56af74c08344d/py-1.5.2-py2.py3-none-any.whl',
        sha256 = '8cca5c229d225f8c1e3085be4fcf306090b00850fefad892f9d96c7b6e2f310f'
    )
    native.http_file(
        name = 'pyz_funcsigs_whl',
        url = 'https://pypi.python.org/packages/69/cb/f5be453359271714c01b9bd06126eaf2e368f1fddfff30818754b5ac2328/funcsigs-1.0.2-py2.py3-none-any.whl',
        sha256 = '330cc27ccbf7f1e992e69fef78261dc7c6569012cf397db8d3de0234e6c937ca'
    )
    native.http_file(
        name = 'pyz_pluggy_tgz',
        url = 'https://pypi.python.org/packages/11/bf/cbeb8cdfaffa9f2ea154a30ae31a9d04a1209312e2919138b4171a1f8199/pluggy-0.6.0.tar.gz',
        sha256 = '7f8ae7f5bdf75671a718d2daf0a64b7885f74510bcd98b1a0bb420eb9a9d0cff',
    )
    native.http_file(
        name = 'pyz_attrs_whl',
        url = 'https://pypi.python.org/packages/b5/60/4e178c1e790fd60f1229a9b3cb2f8bc2f4cc6ff2c8838054c142c70b5adc/attrs-17.4.0-py2.py3-none-any.whl',
        sha256 = 'a17a9573a6f475c99b551c0e0a812707ddda1ec9653bed04c13841404ed6f450'
    )
    native.http_file(
        name = 'pyz_setuptools_whl',
        url = 'https://pypi.python.org/packages/43/41/033a273f9a25cb63050a390ee8397acbc7eae2159195d85f06f17e7be45a/setuptools-38.5.1-py2.py3-none-any.whl',
        sha256 = '7ffe771abfae419fd104f93400b61c935b5af10bfe4dfeec7a1bd495694eea35'
    )
