package main

import (
	"reflect"

	"testing"
)

func TestFilterUnzipPaths(t *testing.T) {
	paths := []string{
		"scipy/.dylibs/example.py",
		"scipy/.dylibs/libgfortran.3.dylib",
		"scipy/_lib/_ccallback.py",
		"scipy/_lib/foo.dylib.py",
		"scipy/_lib/_ccallback_c.so",
		"scipy/.so.dir/foo.py",
	}
	expected := []string{
		"scipy/.dylibs/libgfortran.3.dylib",
		"scipy/_lib/_ccallback_c.so",
	}
	out := filterUnzipPaths(paths)
	if !reflect.DeepEqual(out, expected) {
		t.Errorf("filterUnzipPaths(%#v)=%#v; expected %#v", paths, out, expected)
	}
}
