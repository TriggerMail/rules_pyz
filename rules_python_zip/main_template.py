import errno
import os
import sys
import zipimport


MANIFEST_JSON = r'''{{MANIFEST_JSON}}'''


def main():
    # run without site-packages if this is a zip
    reexec_without_site_packages_if_needed()

    main_dir = os.path.dirname(__file__)
    if sys.path[0] != main_dir:
        # when executed as 'python .../__main__.py' sys.path[0] is the dir containing __file__,
        # but it resolves all symlinks: change it to the directory containing __main__.py without
        # resolving symlinks so this "works" in a bazel runfiles tree
        sys.path[0] = main_dir

    # when executed as python dir/__main__.py: no __loader__
    # when executed as python dir: __loader__ is pkgutil.ImpLoader
    # when executed as python zip: __loader__ is zipimport.zipimporter
    if '__loader__' in globals() and isinstance(__loader__, zipimport.zipimporter):
        # this is a zip file! unpack it to a temporary directory
        tempdir = unzip_to_tempdir()
        sys.path[0] = tempdir
        main_dir = tempdir

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
            # ENOTDIR happens with zips because we try foo_exezip/orig-prefix.txt
            if not (e.errno == errno.ENOENT or e.errno == errno.ENOTDIR):
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
    exec(ast, clean_globals)


# Environment variables that can change imports and break a pyz_binary
_STRIP_ENVVARS=set(('PYTHONHOME', 'PYTHONPATH', 'PYTHONSTARTUP'))


def reexec_without_site_packages_if_needed():
    # Attempt to isolate the Python environment as much as possible:
    # -S: Disable site module: disables .pth files that could be customized
    # -s: Don't use user site directory to sys.path
    # can't add -ESs to #! for zips: virtualenv doesn't have runpy, required to run .zip
    # TODO: Copy pex's "site cleaning" code to avoid re-executing?
    if 'site' in sys.modules:
        # re-exec without any PYTHON environment variables and without site packages
        clean_env = {k: v for k, v in os.environ.items() if k not in _STRIP_ENVVARS}
        # ensure runpy is available: virtualenv python -S does not have it
        import runpy
        clean_env['PYTHONPATH'] = os.path.dirname(runpy.__file__)

        command_line = [sys.executable, '-Ss'] + sys.argv
        os.execve(command_line[0], command_line, clean_env)


tempdir_create_pid = None
def unzip_to_tempdir():
    # don't import these modules unless we need to
    import atexit
    import tempfile
    import zipfile
    global tempdir_create_pid

    # Extracts zips and preserves original permissions from Unix systems
    # https://bugs.python.org/issue15795
    # https://stackoverflow.com/questions/39296101/python-zipfile-removes-execute-permissions-from-binaries
    class PreservePermissionsZipFile(zipfile.ZipFile):
        def extract(self, member, path=None, pwd=None):
            extracted_path = super(PreservePermissionsZipFile, self).extract(member, path, pwd)
            info = self.getinfo(member)
            original_attr = info.external_attr >> 16
            if original_attr != 0:
                os.chmod(extracted_path, original_attr)
            return extracted_path

    # create the dir and clean it up atexit:
    # can't use a finally handler: it gets invoked BEFORE tracebacks are printed
    tempdir = tempfile.mkdtemp('_pyzip')
    tempdir_create_pid = os.getpid()
    atexit.register(clean_tempdir_parent_only, tempdir)
    sys.path.insert(0, tempdir)

    package_zip = PreservePermissionsZipFile(__loader__.archive)
    package_zip.extractall(path=tempdir)
    return tempdir


def clean_tempdir_parent_only(path):
    '''Only delete the tempdir in the original process even in case of fork.'''
    if os.getpid() == tempdir_create_pid:
        import shutil
        shutil.rmtree(path)


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
