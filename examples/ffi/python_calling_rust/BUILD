load("@//rust:rust.bzl", "rust_binary", "rust_library", "rust_test")
load(":py_library_from_rust.bzl", "py_library_from_rust")

rust_library(
    name = "rusty",
    srcs = ["lib.rs"],
    crate_type = "cdylib",
)

py_library_from_rust(
    name = "magic",
    rust_lib = ":rusty",
)

py_test(
    name = "main",
    srcs = ["main.py"],
    deps = [":magic"],
)
