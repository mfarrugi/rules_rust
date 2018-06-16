exports_files([
    "cargo_manifest.bzl",
])

# To be called from a workspace with the magical invocation:
# bazel build @io_bazel_rules_rust//rust/aspect:generate_cargo_workspace \
#     && ./bazel-bin/external/io_bazel_rules_rust/rust/aspect/generate_cargo_workspace
sh_binary(
    name = "generate_cargo_workspace",
    srcs = ["generate_cargo_workspace.sh"],
)
