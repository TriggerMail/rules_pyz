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

func zipCreateWithMethod(z *zip.Writer, name string) (io.Writer, error) {
	header := zip.FileHeader{
		Name:   name,
		Method: zipMethod,
	}
	return z.CreateHeader(&header)
}

// Returns the list of paths that need to be unzipped.
func filterUnzipPaths(paths []string) []string {
	output := []string{}
	for _, path := range paths {
		// Versioned shared libs can have names like libffi-45372312.so.6.0.4
		// Mac libs have both .so and .dylib
		file := filepath.Base(path)
		if strings.HasSuffix(file, ".so") || strings.Contains(file, ".so.") || strings.HasSuffix(file, ".dylib") {
			output = append(output, path)
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
func (c *cachedPathsZipWriter) CreateWithMethod(name string, method uint16) (io.Writer, error) {
	header := &zip.FileHeader{
		Name:   name,
		Method: method,
	}
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
	return out
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
		writer, err := zipWriter.CreateWithMethod(sourceMeta.Dst, zipMethod)
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

	writer, err := zipWriter.CreateWithMethod("__main__.py", zipMethod)
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
			copyF, err := zipWriter.CreateWithMethod(wheelF.Name, zipMethod)
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
	}

	// Add __init__.py for any directories that contain python code and do not contain it
	// This partially is to match what Bazel's native py_library rules do
	// It also makes "implicit" namespace packages work with Python2.7, without executing
	// .pth files
	dirsWithPython := map[string]bool{}
	for path, _ := range zipWriter.paths {
		if strings.HasSuffix(path, ".py") {
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
		fmt.Printf("warning: creating %s\n", initPyPath)
		_, err := zipWriter.CreateWithMethod(initPyPath, zipMethod)
		if err != nil {
			panic(err)
		}
	}

	// verify that the unzip paths are sane
	for _, forceUnzipPath := range zipManifest.ForceUnzip {
		if !zipWriter.paths[forceUnzipPath] {
			fmt.Fprintf(os.Stderr, "Error: force_unzip path %s does not exist\n", forceUnzipPath)
			os.Exit(1)
		}
	}
	unzipPaths := zipManifest.ForceUnzip
	if zipManifest.ForceAllUnzip {
		// don't list paths if we are going to unzip all
		unzipPaths = []string{}
	} else {
		nativeCodeUnzipPaths := filterUnzipPaths(zipWriter.Paths())
		unzipPaths = append(unzipPaths, nativeCodeUnzipPaths...)
	}

	// write the zip package metadata for the __main__ script to use
	zipPackageMetadata := &packageInfo{unzipPaths, zipManifest.ForceAllUnzip}
	writer, err = zipWriter.CreateWithMethod(zipInfoPath, zipMethod)
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


import json
import os.path
import sys
import zipimport


# TODO: Implement better sys.path cleaning
new_paths = []
def is_site_packages_path(path):
    return '/site-packages' in path or '/Extras/lib/python' in path
for path in sys.path:
    # Python on Mac OS X ships with wacky stuff in Extras, like an out of date version of six
    # We don't want our zips to find those files: they should bundle anything they need
    if is_site_packages_path(path):
        #print 'removing path entry:', path
        continue
    else:
        new_paths.append(path)
sys.path = new_paths

# filter these paths from any modules: in particular, these could be namespace packages
# from .pth files that the site module executed
remove_modules = set()
for name, module in sys.modules.iteritems():
    paths = getattr(module, '__path__', None)
    if paths is not None:
        module.__path__ = [p for p in paths if not is_site_packages_path(p)]
        if len(module.__path__) == 0:
            remove_modules.add(name)
    file_path = getattr(module, '__file__', '')
    if is_site_packages_path(file_path):
        remove_modules.add(name)
for name in remove_modules:
    del sys.modules[name]


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
            lines.insert(last_future_line+1, __NAMESPACE_LINE)
            f.write('\n'.join(lines))
        except IOError:
            # ziploader.get_data raises this if the file does not exist
            f.write(__NAMESPACE_LINE)

package_info = _read_package_info()
tempdir = None
need_unzip = len(package_info['unzip_paths']) > 0 or package_info['force_all_unzip']
if need_unzip and isinstance(__loader__, zipimport.zipimporter):
    # do not import these modules unless we have to
    import atexit
    import shutil
    import tempfile
    import types
    import zipfile

    # create the dir and clean it up atexit:
    # can't use a finally handler: it gets invoked BEFORE tracebacks are printed
    tempdir = tempfile.mkdtemp('_pyzip')
    atexit.register(shutil.rmtree, tempdir)

    package_zip = zipfile.ZipFile(__loader__.archive)
    files_to_unzip = package_info['unzip_paths']
    if package_info['force_all_unzip']:
        files_to_unzip = None
    package_zip.extractall(path=tempdir, members=files_to_unzip)
    sys.path.insert(0, tempdir)

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

    # make the unzipped directories namespace packages, all the way to the root
    # TODO: Should this be pre-processed at build time to avoid duplicate runtime work?
    inits = set()
    for unzipped_path in package_info['unzip_paths']:
        unzipped_dir = os.path.dirname(unzipped_path)
        while unzipped_dir != '' and unzipped_dir not in inits:
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
import runpy
runpy.run_module('{{.EntryPoint}}', run_name='__main__')
{{end}}
`
