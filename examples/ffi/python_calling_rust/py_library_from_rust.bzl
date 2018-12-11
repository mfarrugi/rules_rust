# TODO: Native extensions are what we really want, cdll.LoadLibrary is not particularly great.
def py_library_from_rust(name, rust_lib):
    # 1. Put the library into _solib_ because of the ODR.
    #
    # nb. Without this, the .so doesn't make it to runfiles at all
    native.cc_library(
        name = "c_wrapper",
        srcs = [rust_lib],
    )

    # 2. Elaborate dance to figure out the path to the shared object library in _solib_...
    crate_name = rust_lib.split(":")[-1]
    out = name + ".py"
    native.genrule(
        name = "__generate" + out,
        srcs = [rust_lib],
        outs = [out],
        # TODO: Was there a template rule somewhere?
        cmd = """
        cat << EOM > $(OUTS)

from __future__ import print_function

import os
from ctypes import cdll

# TODO: This is a hack to compensate for rootpath not giving us the _solib_* path...
def _find_runfiles_solib(file_name):
    # nb. The runfiles root is already on python path, so we don't need a Runfiles object.
    python_path = os.environ["PYTHONPATH"].split(os.pathsep)

    for path in python_path:
        for dir, subdirs, files in os.walk(path):
            probably_solib_dir = "_solib_" in dir

            if probably_solib_dir and file_name in files:
                return os.path.join(dir, file_name)

    raise ValueError("Could not find " + file_name + " in runfiles.")

_lib_runfiles_path = "$(rootpath {rust_lib})"
_lib_basename = os.path.basename(_lib_runfiles_path)
_lib_path = _find_runfiles_solib(_lib_basename)
_loaded = cdll.LoadLibrary(_lib_path)

{module_name} = _loaded

EOM
""".format(
            rust_lib = rust_lib,
            module_name = crate_name,
        ),
    )

    # 3. py_* rules require a py_* provider, so more wrapping. (though we need this anyway to provide the generated .py)
    # See https://github.com/bazelbuild/bazel/issues/1475 for the latest.
    native.py_library(
        name = name,
        srcs = [out],
        data = [":c_wrapper"],
    )
