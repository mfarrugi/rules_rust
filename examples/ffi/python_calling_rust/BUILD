load("@//rust:rust.bzl", "rust_binary", "rust_library", "rust_test")

# 1. Create the shared object library.
rust_library(
    name = "rust_lib",
    srcs = ["lib.rs"],
    crate_type = "cdylib",
)

# 2. Put the library into _solib_ because of the ODR.
#
# Without this, the .so doesn't make it to runfiles at all
cc_library(
    name = "c_wrapper",
    srcs = [":rust_lib"],
)

# 3. Figure out the path to the shared object library...
# TODO: This should make creating native extensions a little bit easier..
#       though the startup script should really handle putting them on the PYTHONPATH
genrule(
    name = "make_magic",
    srcs = [":rust_lib"],
    outs = ["magic.py"],
    # TODO: Was there a template rule somewhere?
    cmd = """
    cat << EOM > $(OUTS)
from __future__ import print_function

import os
from ctypes import cdll

# TODO: This is a hack to compensate for `rootpath` not giving us the _solib_* path...
def _find_runfiles_solib(file_name):
    # runfiles root is already on python path
    python_path = os.environ["PYTHONPATH"].split(os.pathsep)

    for path in python_path:
        for dir, subdirs, files in os.walk(path):
            probably_solib_dir = "_solib_" in dir

            if probably_solib_dir and file_name in files:
                return os.path.join(dir, file_name)

    raise ValueError("Could not find " + file_name + " in runfiles.")

_lib_runfiles_path = "$(rootpath {rust_cdylib})"
_lib_basename = os.path.basename(_lib_runfiles_path)
_lib_path = _find_runfiles_solib(_lib_basename)
_loaded = cdll.LoadLibrary(_lib_path)

{module_name} = _loaded

EOM""".format(
        rust_cdylib = ":rust_lib",
        module_name = "rust_lib",
    ),
)

# 4. py_* rules require a py_* provider, so more wrapping. (though we need this anyway to provide magic.py)
# See https://github.com/bazelbuild/bazel/issues/1475 for the latest.
py_library(
    name = "magic",
    srcs = [":make_magic"],
    data = [":c_wrapper"],
)

py_test(
    name = "main",
    srcs = ["main.py"],
    deps = [
        ":magic",
        # ":py_wrapper",
        "@bazel_tools//tools/python/runfiles",
    ],
)
