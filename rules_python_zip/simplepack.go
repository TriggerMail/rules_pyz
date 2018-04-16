package main

import (
	"archive/zip"
	"encoding/json"
	"fmt"
	"io"
	"os"
	"path/filepath"
	"sort"
	"strings"
	"text/template"
)

// TODO: Make store/deflate toggleable? Store should be faster
const zipMethod = zip.Store
const defaultInterpreterLine = "/usr/bin/env python2.7"
const zipInfoPath = "_zip_info_.json"

type manifestSource struct {
	Src string
	Dst string
}

type manifest struct {
	Sources         []manifestSource
	Wheels          []string
	EntryPoint      string `json:"entry_point"`
	Interpreter     bool
	InterpreterPath string `json:"interpreter_path"`
	// TODO: Keep only one of these attributes?
	ForceUnzip    []string `json:"force_unzip"`
	ForceAllUnzip bool     `json:"force_all_unzip"`
}

type mainArgs struct {
	ScriptPath  string
	EntryPoint  string
	Interpreter bool
}

type packageInfo struct {
	UnzipPaths    []string `json:"unzip_paths"`
	ForceAllUnzip bool     `json:"force_all_unzip"`
}

func isPyFile(path string) bool {
	return strings.HasSuffix(path, ".py") || strings.HasSuffix(path, ".pyc") || strings.HasSuffix(path, ".pyo")
}

// Returns the list of paths that need to be unzipped.
func filterUnzipPaths(paths []string) []string {
	// find directories containing native code
	nativeLibDirs := map[string]bool{}
	for _, path := range paths {
		// Versioned shared libs can have names like libffi-45372312.so.6.0.4
		// Mac libs have both .so and .dylib
		file := filepath.Base(path)
		if strings.HasSuffix(file, ".so") || strings.Contains(file, ".so.") || strings.HasSuffix(file, ".dylib") {
			nativeLibDirs[filepath.Dir(path)] = true
		}
	}

	// unzip all non-Python things in dirs containing native code, in case the code references it.
	// E.g. gRPC needs to find certificates in a sub dir
	output := []string{}
	for _, path := range paths {
		// Leave python files in the zip
		if isPyFile(path) {
			continue
		}

		for nativeLibDir := range nativeLibDirs {
			if strings.HasPrefix(path, nativeLibDir+"/") || (nativeLibDir == "." && !strings.ContainsRune(path, '/')) {
				output = append(output, path)
				break
			}
		}
	}
	return output
}

type cachedPathsZipWriter struct {
	writer zip.Writer
	paths  map[string]bool
}

func newCachedPathsZipWriter(w io.Writer) *cachedPathsZipWriter {
	zw := zip.NewWriter(w)
	return &cachedPathsZipWriter{*zw, make(map[string]bool)}
}

// Same as zip.Writer: Does not close the underlying writer.
func (c *cachedPathsZipWriter) Close() error {
	return c.writer.Close()
}
func (c *cachedPathsZipWriter) CreateWithMethod(
	fileinfo os.FileInfo, name string, method uint16,
) (io.Writer, error) {
	var header *zip.FileHeader
	var err error
	if fileinfo != nil {
		header, err = zip.FileInfoHeader(fileinfo)
		if err != nil {
			return nil, err
		}
	} else {
		header = &zip.FileHeader{}
	}
	header.Name = name
	header.Method = method
	out, err := c.writer.CreateHeader(header)
	if err != nil {
		return nil, err
	}
	// only append the path if we got "success"
	c.paths[name] = true
	return out, nil
}

// Returns the paths written to this zip so far.
func (c *cachedPathsZipWriter) Paths() []string {
	out := []string{}
	for path, _ := range c.paths {
		out = append(out, path)
	}
	// ensure deterministic output
	sort.Strings(out)
	return out
}

func (c *cachedPathsZipWriter) Contains(path string) bool {
	return c.paths[path]
}

func main() {
	if len(os.Args) != 3 {
		fmt.Fprintln(os.Stderr, "Usage: simplepack (manifest.json) (output_executable)")
		os.Exit(1)
	}
	manifestPath := os.Args[1]
	outputPath := os.Args[2]

	manifestFile, err := os.Open(manifestPath)
	if err != nil {
		panic(err)
	}
	defer manifestFile.Close()
	decoder := json.NewDecoder(manifestFile)
	zipManifest := &manifest{}
	err = decoder.Decode(&zipManifest)
	if err != nil {
		panic(err)
	}
	err = manifestFile.Close()
	if err != nil {
		panic(err)
	}

	if len(zipManifest.Sources) == 0 && zipManifest.EntryPoint == "" && !zipManifest.Interpreter {
		fmt.Fprintln(os.Stderr,
			"Error: one of Sources or EntryPoint cannot be empty or Interpreter must be true")
		os.Exit(1)
	}
	if zipManifest.EntryPoint != "" && zipManifest.Interpreter {
		fmt.Fprintln(os.Stderr,
			"Error: only one of EntryPoint OR Interpreter can be set")
		os.Exit(1)
	}

	outFile, err := os.OpenFile(outputPath, os.O_CREATE|os.O_TRUNC|os.O_WRONLY, 0755)
	if err != nil {
		panic(err)
	}
	defer outFile.Close()
	if zipManifest.InterpreterPath == "" {
		zipManifest.InterpreterPath = defaultInterpreterLine
	}
	if strings.ContainsAny(zipManifest.InterpreterPath, "#!\n") {
		panic(fmt.Errorf("Invalid InterpreterPath:%#v", zipManifest.InterpreterPath))
	}
	outFile.Write([]byte("#!"))
	outFile.Write([]byte(zipManifest.InterpreterPath))
	outFile.Write([]byte("\n"))
	zipWriter := newCachedPathsZipWriter(outFile)
	defer zipWriter.Close()

	for _, sourceMeta := range zipManifest.Sources {
		if sourceMeta.Dst == "__main__.py" {
			panic("reserved destination name: __main__.py")
		}
		if sourceMeta.Dst == "" || sourceMeta.Dst[0] == '/' || strings.Contains(sourceMeta.Dst, "..") {
			panic("invalid dst: " + sourceMeta.Dst)
		}

		src, err := os.Open(sourceMeta.Src)
		if err != nil {
			panic(err)
		}
		stat, err := os.Stat(sourceMeta.Src)
		if err != nil {
			panic(err)
		}
		writer, err := zipWriter.CreateWithMethod(stat, sourceMeta.Dst, zipMethod)
		if err != nil {
			panic(err)
		}
		_, err = io.Copy(writer, src)
		if err != nil {
			panic(err)
		}
		err = src.Close()
		if err != nil {
			panic(err)
		}
	}

	writer, err := zipWriter.CreateWithMethod(nil, "__main__.py", zipMethod)
	if err != nil {
		panic(err)
	}
	args := &mainArgs{
		EntryPoint:  zipManifest.EntryPoint,
		Interpreter: zipManifest.Interpreter,
	}
	if zipManifest.EntryPoint == "" && !zipManifest.Interpreter {
		args.ScriptPath = zipManifest.Sources[0].Dst
	}
	err = mainTemplate.Execute(writer, args)
	if err != nil {
		panic(err)
	}

	// copy the wheels
	for _, wheelPath := range zipManifest.Wheels {
		reader, err := zip.OpenReader(wheelPath)
		if err != nil {
			panic(err)
		}
		for _, wheelF := range reader.File {
			wheelFReader, err := wheelF.Open()
			if err != nil {
				panic(err)
			}
			copyF, err := zipWriter.CreateWithMethod(wheelF.FileInfo(), wheelF.Name, zipMethod)
			if err != nil {
				panic(err)
			}
			_, err = io.Copy(copyF, wheelFReader)
			if err != nil {
				panic(err)
			}
			err = wheelFReader.Close()
			if err != nil {
				panic(err)
			}
		}
		err = reader.Close()
		if err != nil {
			panic(err)
		}
	}

	// Add __init__.py for any directories that contain python code and do not contain it
	// This partially is to match what Bazel's native py_library rules do
	// It also makes "implicit" namespace packages work with Python2.7, without executing
	// .pth files
	dirsWithPython := map[string]bool{}
	for path, _ := range zipWriter.paths {
		if isPyFile(path) {
			dir := filepath.Dir(path)
			for dir != "." && !dirsWithPython[dir] {
				dirsWithPython[dir] = true
				dir = filepath.Dir(dir)
			}
		}
	}
	createInitPyPaths := []string{}
	for dirWithPython, _ := range dirsWithPython {
		initPyPath := dirWithPython + "/__init__.py"
		if !zipWriter.paths[initPyPath] {
			createInitPyPaths = append(createInitPyPaths, initPyPath)
		}
	}
	// sort to make output deterministic: avoids unneeded rebuilds if output is exactly the same
	sort.Strings(createInitPyPaths)
	for _, initPyPath := range createInitPyPaths {
		// TODO: Add a verbose log flag? This could be useful for debugging problems
		// fmt.Printf("warning: creating %s\n", initPyPath)
		_, err := zipWriter.CreateWithMethod(nil, initPyPath, zipMethod)
		if err != nil {
			panic(err)
		}
	}

	// verify that the unzip paths are sane
	unzipPaths := []string{}
	for _, forceUnzipPath := range zipManifest.ForceUnzip {
		// forceUnzipPaths might be wheels
		if strings.HasSuffix(forceUnzipPath, ".whl") {
			reader, err := zip.OpenReader(forceUnzipPath)
			if err != nil {
				panic(err)
			}
			for _, wheelF := range reader.File {
				unzipPaths = append(unzipPaths, wheelF.Name)
			}
			err = reader.Close()
			if err != nil {
				panic(err)
			}
		} else if !zipWriter.Contains(forceUnzipPath) {
			fmt.Fprintf(os.Stderr, "Error: force_unzip path %s does not exist\n", forceUnzipPath)
			os.Exit(1)
		} else {
			unzipPaths = append(unzipPaths, forceUnzipPath)
		}
	}

	if zipManifest.ForceAllUnzip {
		// don't list paths if we are going to unzip all
		unzipPaths = []string{}
	} else {
		nativeCodeUnzipPaths := filterUnzipPaths(zipWriter.Paths())
		unzipPaths = append(unzipPaths, nativeCodeUnzipPaths...)
	}

	// write the zip package metadata for the __main__ script to use
	zipPackageMetadata := &packageInfo{unzipPaths, zipManifest.ForceAllUnzip}
	writer, err = zipWriter.CreateWithMethod(nil, zipInfoPath, zipMethod)
	if err != nil {
		panic(err)
	}
	err = json.NewEncoder(writer).Encode(zipPackageMetadata)
	if err != nil {
		panic(err)
	}

	err = zipWriter.Close()
	if err != nil {
		panic(err)
	}
	err = outFile.Close()
	if err != nil {
		panic(err)
	}
}

var mainTemplate = template.Must(template.New("main").Parse(mainTemplateCode))

const mainTemplateCode = `
# copy the current state so we can exec the script in it
clean_globals = dict(globals())

import os
import runpy
import sys

# Attempt to isolate the Python environment as much as possible:
# -S: Disable site module: disables .pth files that could be customized
# -s: Don't use user site directory to sys.path
# We can't add -ESs to #! because virtualenv doesn't have runpy module required to run .zip
# TODO: Copy pex's "site cleaning" code to avoid re-executing?
if 'site' in sys.modules:
    # re-exec without site packages
    clean_env = dict(os.environ)
    clean_env.pop('PYTHONHOME', None)
    # ensure runpy is available: virtualenv python -S does not have it
    clean_env['PYTHONPATH'] = os.path.dirname(runpy.__file__)

    command_line = [sys.executable, '-Ss'] + sys.argv
    os.execve(command_line[0], command_line, clean_env)

# Remove PYTHONPATH if set: we want full control over our environment
os.environ.pop('PYTHONPATH', None)

import errno
import json
import zipimport


# copied and modified from virtualenv site.py
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


def _get_package_path(path):
    if not isinstance(__loader__, zipimport.zipimporter):
        # when executed from an unpacked directory, get_data is relative to the current dir
        # we want it to be relative to the root of our packages (relative to __main__.py)
        path = os.path.join(os.path.dirname(__file__), path)
    return path


def _get_package_data(path):
    path = _get_package_path(path)
    return __loader__.get_data(path)


def _read_package_info():
    info_bytes = _get_package_data('` + zipInfoPath + `')
    return json.loads(info_bytes)


__NAMESPACE_LINE = "__path__ = __import__('__namespace_hack__').extend_path_zip(__path__, __name__)\n"
def _copy_as_namespace(tempdir, unzipped_dir):
    '''Copies __init__.py from unzipped_dir, adding a namespace package line if needed.'''

    init_path = os.path.join(unzipped_dir, '__init__.py')
    output_path = os.path.join(tempdir, init_path)
    with open(os.path.join(tempdir, unzipped_dir, '__init__.py'), 'w') as f:
        try:
            data = __loader__.get_data(init_path)
            # from future imports must be the first statement in __init__.py: insert our line after
            # this must be after any comments and doc comments
            # TODO: maybe we should do this at "build" time?
            lines = data.splitlines()
            last_future_line = -1
            for i, line in enumerate(lines):
                if '__future__' in line:
                    last_future_line = i
            # if we don't find future, must insert after any "coding" directive, which must be
            # in the first two lines. Just insert after the first two lines of comments
            if last_future_line == -1:
                if len(lines) > 0 and lines[0].startswith('#'):
                    last_future_line = 0
                if len(lines) > 1 and lines[1].startswith('#'):
                    last_future_line = 1
            lines.insert(last_future_line+1, __NAMESPACE_LINE)
            f.write('\n'.join(lines))
        except IOError:
            # ziploader.get_data raises this if the file does not exist
            f.write(__NAMESPACE_LINE)


def clean_tempdir_parent_only(path):
    '''Only delete the tempdir in the original process even in case of fork.'''
    if os.getpid() == tempdir_create_pid:
        shutil.rmtree(path)


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
        if e.errno != errno.ENOENT and e.errno != errno.ENOTDIR:
            raise

package_info = _read_package_info()
tempdir = None
tempdir_create_pid = None
need_unzip = len(package_info['unzip_paths']) > 0 or package_info['force_all_unzip']
if need_unzip and isinstance(__loader__, zipimport.zipimporter):
    # do not import these modules unless we have to
    import atexit
    import shutil
    import tempfile
    import types
    import zipfile

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
    files_to_unzip = package_info['unzip_paths']
    if package_info['force_all_unzip']:
        files_to_unzip = None
    else:
        # pkg_resources finds our zip as an egg and can mess with sys.path:
        # make sure it doesn't do that by changing EGG_DIST precedence
        # needed to make google.cloud.datastore and gunicorn play nice
        try:
            import pkg_resources
            pkg_resources.EGG_DIST = pkg_resources.DEVELOP_DIST-1
        except ImportError:
            pass
    package_zip.extractall(path=tempdir, members=files_to_unzip)

    # pkgutil.extend_path does not add zips to __path__; hack a function that will
    # register it as a module so it can be referenced from random __init__.py
    namespace_hack_module = types.ModuleType('__namespace_hack__')
    sys.modules[namespace_hack_module.__name__] = namespace_hack_module
    _path_to_extend=[tempdir, __loader__.archive]
    def extend_path_zip(paths, name):
        name_path = name.replace('.', '/')

        do_not_add_paths = set()
        for current_path in paths:
            for extend_path in _path_to_extend:
                if current_path.startswith(extend_path):
                    do_not_add_paths.add(extend_path)
        for extend_path in _path_to_extend:
            if extend_path not in do_not_add_paths:
                paths.append(extend_path + '/' + name_path)
        return paths
    namespace_hack_module.extend_path_zip = extend_path_zip

    # generate the set of directories that contain Python packages
    py_dirs = set()
    for zip_path in package_zip.namelist():
        if zip_path.endswith('.py') or zip_path.endswith('.pyc') or zip_path.endswith('.pyo'):
            py_dirs.add(os.path.dirname(zip_path))

    # make the unzipped directories namespace packages, all the way to the root
    # TODO: Should this be pre-processed at build time to avoid duplicate runtime work?
    inits = set()
    for unzipped_path in package_info['unzip_paths']:
        unzipped_dir = os.path.dirname(unzipped_path)
        while unzipped_dir != '' and unzipped_dir not in inits:
            # only create inits if the dir contains python code
            if unzipped_dir in py_dirs:
                inits.add(unzipped_dir)
                _copy_as_namespace(tempdir, unzipped_dir)
            unzipped_dir = os.path.dirname(unzipped_dir)

{{if or .ScriptPath .Interpreter }}
{{if .Interpreter }}
if len(sys.argv) == 1:
    import code
    result = code.interact()
    sys.exit(0)
else:
    script_path = sys.argv[1]
    script_data = open(script_path).read()
    sys.argv = sys.argv[1:]
    # fall through to the script execution code below
{{else}}
script_path = '{{.ScriptPath}}'
# load the original script and evaluate it inside this zip
is_script_unzipped = script_path in package_info['unzip_paths'] or package_info['force_all_unzip']
if tempdir is not None and is_script_unzipped:
    script_path = tempdir + '/' + script_path
    script_data = open(script_path).read()
else:
    script_data = _get_package_data(script_path)

    # assumes that __main__ is in the root dir either of a zip or a real dir
    pythonroot = os.path.dirname(__file__)
    script_path = os.path.join(pythonroot, script_path)
{{end}}

clean_globals['__file__'] = script_path

ast = compile(script_data, script_path, 'exec', flags=0, dont_inherit=1)

# execute the script with a clean state (no imports or variables)
exec ast in clean_globals
{{else}}
runpy.run_module('{{.EntryPoint}}', run_name='__main__')
{{end}}
`
