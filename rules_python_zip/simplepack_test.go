package main

import (
	"archive/zip"
	"io/ioutil"
	"os"
	"reflect"

	"testing"
)

func TestFilterUnzipPaths(t *testing.T) {
	paths := []string{
		".libs/libffi-45372312.so.6.0.4",
		"resource.txt",
		"scipy/.dylibs/example.py",
		"scipy/.dylibs/libgfortran.3.dylib",
		"scipy/.so.dir/foo.py",
		"scipy/_lib/_ccallback.py",
		"scipy/_lib/_ccallback_c.so",
		"scipy/_lib/foo.dylib.py",
	}
	expected := []string{
		".libs/libffi-45372312.so.6.0.4",
		"scipy/.dylibs/libgfortran.3.dylib",
		"scipy/_lib/_ccallback_c.so",
	}
	out := filterUnzipPaths(paths)
	if !reflect.DeepEqual(out, expected) {
		t.Errorf("filterUnzipPaths(%#v)=%#v; expected %#v", paths, out, expected)
	}

	// non-python resources in paths that contain native code should be unzipped
	paths = []string{
		"nativelib/compiled.pyc",
		"nativelib/compiled.pyo",
		"nativelib/file.py",
		"nativelib/lib.so",
		"nativelib/resource.txt",
		"nativelib/subdir/resource.txt",
		"pythonlib/file.py",
		"pythonlib/resource.txt",
		"resource.txt",
	}
	expected = []string{
		"nativelib/lib.so",
		"nativelib/resource.txt",
		"nativelib/subdir/resource.txt",
	}
	out = filterUnzipPaths(paths)
	if !reflect.DeepEqual(out, expected) {
		t.Errorf("filterUnzipPaths(%#v)=%#v; expected %#v", paths, out, expected)
	}

	// root native libs need special handling to avoid unpacking the universe
	paths = []string{
		"lib.so",
		"resource.txt",
		"subdir/resource.txt",
	}
	expected = []string{
		"lib.so",
		"resource.txt",
	}
	out = filterUnzipPaths(paths)
	if !reflect.DeepEqual(out, expected) {
		t.Errorf("filterUnzipPaths(%#v)=%#v; expected %#v", paths, out, expected)
	}
}

func TestZipWriter(t *testing.T) {
	tempFile, err := ioutil.TempFile("", "")
	if err != nil {
		t.Fatal(err)
	}
	defer os.Remove(tempFile.Name())
	defer tempFile.Close()
	zw := newCachedPathsZipWriter(tempFile)
	createPaths := []string{"aaa.txt", "bbb.txt", "ccc.txt", "zzz.txt"}
	for _, path := range createPaths {
		if zw.Contains(path) {
			t.Error("should not contain path: ", path)
		}
		_, err = zw.CreateWithMethod(path, zip.Store)
		if err != nil {
			t.Fatal(err)
		}
	}
	err = zw.Close()
	if err != nil {
		t.Fatal(err)
	}

	// ensure Paths is deterministic
	paths := zw.Paths()
	if !reflect.DeepEqual(paths, createPaths) {
		t.Errorf("paths=%#v != createPaths=%#v", paths, createPaths)
	}

	for _, path := range createPaths {
		if !zw.Contains(path) {
			t.Error("should contain path: ", path)
		}
	}
}
