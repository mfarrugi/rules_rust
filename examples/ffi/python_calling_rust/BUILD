load("@//rust:rust.bzl", "rust_library", "rust_test", "rust_binary")

rust_library(
    name = "rusty",
    crate_type = "dylib",
    srcs = ["lib.rs"]
)

# Apparently need this extra wrapper to setup _solib_k8 (or put the .so into runfiles at all)
cc_library(
    name = "c_wrapper",
    srcs = [":rusty"],
)

# py_* rules expect a py provider, so more wrapping.
# See https://github.com/bazelbuild/bazel/issues/1475 for the latest.
py_library(
    name = "py_wrapper",
    data = ["c_wrapper"],
    imports = ['.']
)

py_test(
    name = "main",
    srcs = ["main.py"],
    deps = [":py_wrapper"],
)
