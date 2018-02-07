package main

import (
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
