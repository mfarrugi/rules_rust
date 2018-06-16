#!/usr/bin/env bash
set -euo pipefail

workspace_root=$(bazel info workspace)
labels_to_generate=${@:-...}

bazel build \
    --aspects @io_bazel_rules_rust//rust/aspect:cargo_manifest.bzl%cargo_manifest_aspect \
    --output_groups=all_files \
    ${labels_to_generate}

cd ${workspace_root}

# Paths must be relative to the root.
# We only need bottom level targets in the workspace, so we can ignore the cargo vendor directory.
MANIFESTS=$(find bazel-bin/ -type f | grep '/_.*/Cargo.toml$' | grep -v vendor | xargs dirname)

echo "[workspace]" > ${workspace_root}/Cargo.toml
echo "members = [" >> ${workspace_root}/Cargo.toml
for manifest in ${MANIFESTS}; do
    echo "    \"${manifest}\"," >> ${workspace_root}/Cargo.toml
done
echo "]" >> ${workspace_root}/Cargo.toml

echo "Generated $workspace_root/Cargo.toml"

# Make sure cargo-metadata is happy before reporting success.
cargo metadata --verbose --format-version 1 --all-features > /dev/null
