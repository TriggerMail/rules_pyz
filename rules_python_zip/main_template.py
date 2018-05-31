import errno
import os
import sys

MANIFEST_JSON = r'''{{MANIFEST_JSON}}'''

def main():
    main_dir = os.path.dirname(__file__)
    if sys.path[0] != main_dir:
        # when executed as 'python foo.runfiles/.../__main__.py' the first path is PWD
        sys.path[0] = main_dir

    # attempt to locate a virtualenv:
    # we don't want to import site, since that executes pth files and adds other non-standard paths
    # but virtualenv needs the "real" system paths added for modules like runpy
    for path in sys.path:
        orig_prefix_path = os.path.join(path, 'orig-prefix.txt')
        try:
            with open(orig_prefix_path) as f:
                real_prefix = f.read().strip()
            virtual_install_main_packages(real_prefix)
            break
        except IOError as e:
            # ignore not found errors
            if e.errno != errno.ENOENT:
                raise

    # import json only after modifying sys.path
    import json
    manifest = json.loads(MANIFEST_JSON)
    if manifest['entry_point']:
        import runpy
        # must use str to convert the entry point from unicode to str
        runpy.run_module(str(manifest['entry_point']), run_name='__main__')
        sys.exit(0)

    if manifest['interpreter']:
        if len(sys.argv) == 1:
            # no arguments: interactive shell
            import code
            result = code.interact()
            sys.exit(0)
        else:
            script_path = sys.argv[1]
            script_data = open(script_path).read()
            sys.argv = sys.argv[1:]
            # fall through to the script execution code below
    else:
        script_path = os.path.join(main_dir, manifest['main_script'])

        # previously we would exec the script, but Python adds the directory containing the
        # destination of the symlink to PYTHONPATH, which violates Bazel's hermetic guarantees
        # instead: read the script and evaluate it
        with open(script_path) as f:
            script_data = f.read()

    clean_globals = {
        '__file__': script_path,
        '__name__': '__main__',
        '__doc__': None,
        '__package__': None,
    }

    ast = compile(script_data, script_path, 'exec', flags=0, dont_inherit=1)
    # execute the script with a clean state (no imports or variables)
    exec ast in clean_globals

# modified from virtualenv site.py
def virtual_install_main_packages(real_prefix):
    # from module level:
    _is_pypy = hasattr(sys, 'pypy_version_info')
    _is_jython = sys.platform[:4] == 'java'

    # function from virtualenv site.py here:
    pos = 2
    hardcoded_relative_dirs = []
    if sys.path[0] == '':
        pos += 1
    if _is_jython:
        paths = [os.path.join(real_prefix, 'Lib')]
    elif _is_pypy:
        if sys.version_info > (3, 2):
            cpyver = '%d' % sys.version_info[0]
        elif sys.pypy_version_info >= (1, 5):
            cpyver = '%d.%d' % sys.version_info[:2]
        else:
            cpyver = '%d.%d.%d' % sys.version_info[:3]
        paths = [os.path.join(real_prefix, 'lib_pypy'),
                 os.path.join(real_prefix, 'lib-python', cpyver)]
        if sys.pypy_version_info < (1, 9):
            paths.insert(1, os.path.join(real_prefix,
                                         'lib-python', 'modified-%s' % cpyver))
        hardcoded_relative_dirs = paths[:] # for the special 'darwin' case below
        #
        # This is hardcoded in the Python executable, but relative to sys.prefix:
        for path in paths[:]:
            plat_path = os.path.join(path, 'plat-%s' % sys.platform)
            if os.path.exists(plat_path):
                paths.append(plat_path)
    elif sys.platform == 'win32':
        paths = [os.path.join(real_prefix, 'Lib'), os.path.join(real_prefix, 'DLLs')]
    else:
        paths = [os.path.join(real_prefix, 'lib', 'python'+sys.version[:3])]
        hardcoded_relative_dirs = paths[:] # for the special 'darwin' case below
        lib64_path = os.path.join(real_prefix, 'lib64', 'python'+sys.version[:3])
        if os.path.exists(lib64_path):
            if _is_64bit:
                paths.insert(0, lib64_path)
            else:
                paths.append(lib64_path)
        # This is hardcoded in the Python executable, but relative to
        # sys.prefix.  Debian change: we need to add the multiarch triplet
        # here, which is where the real stuff lives.  As per PEP 421, in
        # Python 3.3+, this lives in sys.implementation, while in Python 2.7
        # it lives in sys.
        try:
            arch = getattr(sys, 'implementation', sys)._multiarch
        except AttributeError:
            # This is a non-multiarch aware Python.  Fallback to the old way.
            arch = sys.platform
        plat_path = os.path.join(real_prefix, 'lib',
                                 'python'+sys.version[:3],
                                 'plat-%s' % arch)
        if os.path.exists(plat_path):
            paths.append(plat_path)
    # This is hardcoded in the Python executable, but
    # relative to sys.prefix, so we have to fix up:
    for path in list(paths):
        tk_dir = os.path.join(path, 'lib-tk')
        if os.path.exists(tk_dir):
            paths.append(tk_dir)

    # These are hardcoded in the Apple's Python executable,
    # but relative to sys.prefix, so we have to fix them up:
    if sys.platform == 'darwin':
        hardcoded_paths = [os.path.join(relative_dir, module)
                           for relative_dir in hardcoded_relative_dirs
                           for module in ('plat-darwin', 'plat-mac', 'plat-mac/lib-scriptpackages')]

        for path in hardcoded_paths:
            if os.path.exists(path):
                paths.append(path)

    sys.path.extend(paths)


if __name__ == '__main__':
    main()
