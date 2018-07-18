# Copyright 2015 The Bazel Authors. All rights reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

def _rust_cbindgen(ctx):
    cbindgen = ctx.executable.cbindgen
    cargo = ctx.toolchains["@io_bazel_rules_rust//rust:toolchain"].cargo

    crate = ctx.attr.crate
    # @TODO rust_library ought to generate Cargo.toml since so much tooling requires it
    crate_manifest = ctx.file.manifest
    output = ctx.outputs.out

    ctx.actions.run_shell(
        # @TODO Needs to escape sandbox to read dependencies' manifests from ~/.cargo/; won't work on build farm.
        # Need to generate Cargo.toml`s with libraries that either point to vendor dir or
        # paths.
        execution_requirements={"no-sandbox": "1"},
        inputs=depset([cbindgen, cargo, crate_manifest] + crate.rust_srcs),
        outputs=[output],
        command=" ".join(
            [
                "CARGO={}".format(cargo.path),
                "{} --output {} {}".format(
                    cbindgen.path, output.path, crate_manifest.dirname
                ),
            ]
        ),
    )

rust_cbindgen = rule(
    attrs = {
        "crate": attr.label(),
        "manifest": attr.label(
            allow_single_file = True,
            mandatory = True,
        ),
        "cbindgen": attr.label(
            executable = True,
            cfg = "host",
        ),
    },
    outputs = {"out": "%{name}.h"},
    toolchains = ["@io_bazel_rules_rust//rust:toolchain"],
    implementation = _rust_cbindgen,
)

"""
Generates a c header file from the extern functions in a rust_library.
"""
