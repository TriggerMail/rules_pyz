# Bazel Python Zip Rules

This package is an alternative to Bazel's built-in Python rules. These rules work with existing Python packages from PyPI. Ideally either the built-in rules or [`rules_python`](https://github.com/bazelbuild/rules_python) should replace them, once they work with external packages.

See the [example project](https://github.com/TriggerMail/rules_pyz_example) for a tiny demonstration.


## Using the rules

Add the following lines to your `WORKSPACE`:

```python
# Load the dependencies required for the rules
git_repository(
    name = "com_bluecore_rules_pyz",
    commit = "ed9b59ab2979dc87bcd84fbc94ad520b6eaac4dd",
    remote = "https://github.com/TriggerMail/rules_pyz.git",
)

load("@com_bluecore_rules_pyz//rules_python_zip:rules_python_zip.bzl", "pyz_repositories")

pyz_repositories()
```

To each BUILD file where you want to use the rules, add:

```python
load(
    "@com_bluecore_rules_pyz//rules_python_zip:rules_python_zip.bzl",
    "pyz_binary",
    "pyz_library",
    "pyz_test",
)
```

Instead of `py_*` rules, use `pyz_*`. They should work more or less the same way. One notable difference is instead of `imports` to change the import path, you need to use the `pythonroot` attribute.


### PyPI dependencies

If you want to import packages from PyPI, write a pip `requirements.txt` file, then:

1. `mkdir -p third_party/pypi`
2. Add the following lines to `third_party/pypi/BUILD`:
    ```python
    load(":pypi_rules.bzl", "pypi_libraries")
    pypi_libraries()
    ```
3. Add the following lines to `WORKSPACE`:
    ```python
    load("@com_bluecore_rules_pyz//pypi:pip.bzl", "pip_repositories")
    pip_repositories()
    load("//third_party/pypi:pypi_rules.bzl", "pypi_repositories")
    pypi_repositories()
    ```
4. Generate the dependencies using the tool:
    ```bash
    bazel build @com_bluecore_rules_pyz//pypi:pip_generate_wrapper
    bazel-bin/external/com_bluecore_rules_pyz/pypi/pip_generate_wrapper \
        -requirements requirements.txt \
        -output third_party/pypi/pypi_rules.bzl \
        -wheelURLPrefix http://example.com/
    ```


## Motivation and problems with existing rules

Bluecore is experimenting with using Bazel because it offers two potential advantages over our existing environment:

1. *Reproducible builds and tests between machines*: Today, we use a set of virtualenvs. When someone adds or removes an external dependency, or moves code between "packages", we need to manually run some scripts to build the virtualenvs. This is error prone, and a frequent cause of developer support issues.
2. *Faster tests and CI by caching results*.
3. *One tool for all languages*: Today our code is primarily Python and JavaScript, with a small amount of Go. As we grow the team, the code base, and add more tools, it would be nice if there was a single way to build and test everything.

The existing rules have a number of issues which interfere with these goals. In particular, we need to be able to consume packages published on PyPI. The existing rules have the following problems:


* Namespace packages don't work correctly: https://github.com/bazelbuild/rules_python/issues/14
* System-installed packages can be imported, causing dependency problems: https://github.com/bazelbuild/rules_python/issues/27


The [bazel_rules_pex rules](https://github.com/benley/bazel_rules_pex) work pretty well for these cases. However, `pex` is very slow when packaging targets that have large third-party dependencies, since it unzips and rezips everything. These rules started as an exploration to understand why Pex is so slow, and eventually morphed into the rules as they are today.


## Implementation sketch

The intention is to package all `srcs` and `deps` into a single executable zip file, with a `#!` interpreter line and `__main__.py` so it is directly executable. Its gets rebuilt every time a `src` or `dep` changes, but the packaging tool does not compile the Python scripts and stores them in the zip without compression, so it is substantially faster than pex.

At build time, if any native code libraries are detected, it writes a manifest (`_zip_info_.json`) that instructs `__main__.py` to unpack the files that need to be unpacked.


## Unscientific comparison

1. Modify a Python test file:
   * `bazel_rules_pex`: 5.252s total: 2.686s to package the pex; 2.533s to run the test
   * `rules_pyz`: ~2.278s to run the test (no rebuild needed: test srcs not packaged)
2. Modify a lib file dependeded on by a Python test:
   * `bazel_rules_pex`: 5.276s total: 2.621s to package the pex; 2.624s to run the test
   * `rules_pyz`: 0.112s to pack the dependencies; 2.180s to run the test
3. Package numpy and scipy with a main that imports scipy
   * `pex`: 9.5s ; time to run: first time: 1.3s; next times: 0.4s
   * `simplepack`: 0.6s; time to run: 0.5s



## Notes

* http://python-notes.curiousefficiency.org/en/latest/python_concepts/import_traps.html
