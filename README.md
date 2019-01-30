# UNMAINTAINED

Unfortunately we decided not to use Bazel, so these rules are effectively unmaintained. If someone would like to take ownership, please push a copy of the code somewhere, and I will be happy to link to it from here. Thanks for the interest!


# Bazel Python Zip Rules

This package is an alternative to Bazel's built-in Python rules that work with existing Python packages from PyPI. Eventually the built-in rules or [`rules_python`](https://github.com/bazelbuild/rules_python) should replace this, once Google improves them to work with external packages. Until then, these rules work for us.

See the [example project](https://github.com/TriggerMail/rules_pyz_example) for a tiny demonstration.

We named this rules_pyz because originally it built a zip for every `pyz_binary` and `pyz_test`. We have since changed it so it only optionally builds a zip.


## Using the rules

Add the following lines to your `WORKSPACE`:

```python
# Load the dependencies required for the rules
git_repository(
    name = "com_bluecore_rules_pyz",
    commit = "eb2527d42664bc2dc4834ee54cb1bb94a1d08216",
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

Instead of `py_*` rules, use `pyz_*`. They should work the same way. One notable difference is instead of `imports` to change the import path, you need to use the `pythonroot` attribute, which only applies to the `srcs` and `data` of that rule, and not all transitive dependencies.


### PyPI dependencies

If you want to import packages from PyPI, write a pip `requirements.txt` file, then:

1. `mkdir -p third_party/pypi`
2. `mkdir wheels`
3. Add the following lines to `third_party/pypi/BUILD`:
    ```python
    load(":pypi_rules.bzl", "pypi_libraries")
    pypi_libraries()
    ```
4. Add the following lines to `WORKSPACE`:
    ```python
    load("@com_bluecore_rules_pyz//pypi:pip.bzl", "pip_repositories")
    pip_repositories()
    ```
5. Generate the dependencies using the tool:
    ```bash
    bazel build @com_bluecore_rules_pyz//pypi:pip_generate_wrapper
    bazel-bin/external/com_bluecore_rules_pyz/pypi/pip_generate_wrapper \
        -requirements requirements.txt \
        -outputDir third_party/pypi \
        -wheelURLPrefix http://example.com/ \
        -wheelDir wheels
    ```
6. If this depends on any Python packages that don't publish wheels, you will need to copy the `wheels` directory to some server where they are publicly accessible, and set the `-wheelURLPrefix` argument to that URL. We use a [Google Cloud Storage bucket](https://cloud.google.com/storage/docs/
access-public-data) and copy the wheels with: `gsutil -m rsync -a public-read wheels gs://public-bucket`
7. Add the following lines to `WORKSPACE` to load the generate requirements:
    ```python
    load("//third_party/pypi:pypi_rules.bzl", "pypi_repositories")
    pypi_repositories()
    ```

### Local Wheels

As an alternative to publishing built wheels, you can check them in to your repository. If you omit the `wheelURLPrefix` flag, `pip_generate` will generate references relative to your WORKSPACE.


## Motivation and problems with existing rules

Bluecore is experimenting with using Bazel because it offers two potential advantages over our existing environment:

1. *Reproducible builds and tests between machines*: Today, we use a set of virtualenvs. When someone adds or removes an external dependency, or moves code between "packages", we need to manually run some scripts to build the virtualenvs. This is error prone, and a frequent cause of developer support issues.
2. *Faster tests and CI by caching results*.
3. *One tool for all languages*: Today our code is primarily Python and JavaScript, with a small amount of Go. As we grow the team, the code base, and add more tools, it would be nice if there was a single way to build and test everything.

The existing rules have a number of issues which interfere with these goals. In particular, we need to be able to consume packages published on PyPI. The existing rules have the following problems:


* Namespace packages don't work correctly: https://github.com/bazelbuild/rules_python/issues/14
* System-installed packages can be imported, causing dependency problems: https://github.com/bazelbuild/rules_python/issues/27


The [bazel_rules_pex rules](https://github.com/benley/bazel_rules_pex) work pretty well for these cases. However, `pex` is very slow when packaging targets that have large third-party dependencies, since it unzips and rezips everything. These rules started as an exploration to understand why Pex is so slow, and eventually morphed into the rules as they are today.


## Implementation overview

A Python "executable" is a directory tree of Python files, with an "entry point" module that is invoked as `__main__`. We want to be able to define executables with different sets of dependencies that possibly conflict (e.g. executable `foo` may want `example_module` to be imported, but executable `bar` may need `example_module` to not exist, or be a different version). To do this, we build a directory tree containing all dependencies, and generate a `__main__.py`. This makes the directory executable by either running `python executable_exedir` or `python executable_exedir/__main__.py`. To make this more convenient, we also generate a shell script to invoke python with the correct arguments.

For example, if we have an executable named `executable`, which runs a script called `executable.py` that depends on `somepackage.module`, it will generate the following files:

```
executable          (generated shell script: runs executable_exedir)
executable_exedir
├── executable.py
├── __main__.py     (generated main script: runs executable.py)
└── somepackage
    ├── __init__.py
    └── module.py
```

The `executable_exedir` can be zipped into a zip file with a `#!` interpreter line, so it can be directly executed. This may introduce incompatibilities: many Python programs depend on reading resource files relative to their source files which fails when loaded from a zip. By default for maximum compatibility, the `__main__.py` will unzip everything into a temporary directory, execute that, then delete it at execute. You can set `zip_safe=True` on the `pyz_binary` to override this behaviour. At build time, if any native code libraries are detected, the rules write a manifest (`_zip_info_.json`) that instructs `__main__.py` to unpack these files because they cannot be loaded from a zip.


### Creating an "isolated" Python environment

We want executables generated by these rules to be "isolated": They should only rely on the system Python interpreter and the standard library. Any custom packages or environment variables should be ignored, so running the program always works. It turns out this is tricky: If the default `python` binary is part of a virtual environment for example, in behaves slightly differently than a "normal" Python interpreter. Users may have added `.pth` files to their `site-packages` directory to customize their environment. To resolve this, `__main__.py` tries very hard to establish a "clean" environment, which complicates the startup code.

To do it, we execute `__main__.py` with the Python flags `-E -S -s` which ignores `PYTHON*` environment variables, and does not load `site-packages`. Unfortunately, to execute a zip, Python needs the `runpy` module which is in `site-packages`. Additionally, people might explicitly execute `python ..._exedir` or `python ..._exedir/__main__.py`. In those cases, if we find the `site` module, we re-execute Python with the correct flags, to ensure the program sees a clean environment.

TODO: pex has code to clean the `sys.modules` which we should borrow at some point, since it avoids re-executing Python which decreases startup overhead.


### Bazel implementation: Runfiles

To make tests run quickly in Bazel, it is best to not copy files into an `_exedir`. Instead, we build the `_exedir` in the Bazel `.runfiles` directory using symlinks. This makes incremental changes much faster. As a disadvantage, it causes some slightly different paths than when things are packaged directly into a zip.


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
