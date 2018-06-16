"""
Aspect that generates Cargo.toml files from BUILD files, which is useful
for interacting with vanilla rust tooling.
"""

load("@io_bazel_rules_rust//rust:utils.bzl", "relative_path")

CargoToml = provider(
    fields = {
        "version": "Version of the crate, if available.",
        "deps": "The Cargo.toml files this one depends on.",
        "directory": "The directory path the manifest is generated in.",
    }
)


def _cargo_manifest_aspect_impl(target, ctx):
    """
    Creates a separate Cargo.toml for each instance of a rust rule.
    Relies on a separate step to create the workspace Cargo.toml that makes use of them.
    """
    rule = ctx.rule
    if not rule.kind in ["rust_library", "rust_binary"]:
        return []

    # /path/to/package/$name is commonly already an output, so we prefix the path.
    output = ctx.actions.declare_file("_{}/Cargo.toml".format(rule.attr.name))
    output_dir = output.path.replace("/Cargo.toml", "")

    rust_deps = [d for d in rule.attr.deps if hasattr(d, "rust_lib")]

    manifest = "\n".join(
        [
            "# Generated by cargo_manifest_aspect from {} in {}".format(target.label, ctx.build_file_path),
            "[package]",
            'name = "{}"'.format(target.label.name),
            'version = "{}"'.format(rule.attr.version),
            "",
        ]
        + [
            "[lib]" if rule.kind == "rust_library" else "[[bin]]",
            'name = "{}"'.format(target.label.name),
            'path = "{}"'.format(relative_path(output_dir, target.crate_root.path)),
            "",
            "[dependencies]",
        ]
        + ['{} = {{ path = "{}" }}'.format(d.label.name, relative_path(output_dir, d[CargoToml].directory)) for d in rust_deps]
        + [""]
    )

    ctx.actions.write(output, manifest)

    deps = depset([output], transitive=[dep[CargoToml].deps for dep in rust_deps])

    return [
        CargoToml(deps = deps, directory = output_dir),
        OutputGroupInfo(all_files = deps)
    ]


cargo_manifest_aspect = aspect(
    implementation = _cargo_manifest_aspect_impl,
    attr_aspects = ['deps'],
)
