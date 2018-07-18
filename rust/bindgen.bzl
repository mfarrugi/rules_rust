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

def _rust_bindgen(ctx):
    bindgen = ctx.executable.bindgen
    rustfmt = ctx.toolchains["@io_bazel_rules_rust//rust:toolchain"].rustfmt
    clang = ctx.executable.clang
    libclang = ctx.attr.libclang
    libstdcxx = ctx.attr.libstdcxx
    cc_toolchain = ctx.attr.cc_toolchain
    cc_fragment = ctx.fragments.cpp

    # nb. We can't grab the cc_library`s direct headers, so a header must be provided.
    cc_lib = ctx.attr.cc_lib
    if not hasattr(cc_lib, "cc"):
        fail("{} is not a cc_library".format(cc_lib))
    header = ctx.file.header
    if header not in cc_lib.cc.transitive_headers:
        fail("Header {} is not in {}'s transitive closure of headers.".format(ctx.attr.header, cc_lib))

    # rustfmt is not in the usual place, so bindgen would fail to find it
    bindgen_args = ["--no-rustfmt-bindings"]
    clang_args = []

    output = ctx.outputs.out

    clang_libs = depset(libclang.cc.libs + libstdcxx.cc.libs)
    include_directories = depset(
        cc_fragment.built_in_include_directories + [f.dirname for f in cc_lib.cc.transitive_headers]
    )

    unformatted = ctx.actions.declare_file(output.basename + ".unformatted")

    args = ctx.actions.args()
    args.add_all(bindgen_args)
    args.add(header.path)
    args.add("--output", unformatted.path)
    args.add("--")
    args.add_all(include_directories, before_each="-I")
    args.add_all(clang_args)
    ctx.actions.run(
        inputs=depset(
            [header],
            # Standard library headers aren't in the transitive_headers, so we find them in the cc_toolchain
            transitive=[cc_lib.cc.transitive_headers, clang_libs, cc_toolchain.files],
        ),
        outputs=[unformatted],
        mnemonic="RustBindgen",
        progress_message="Generating bindings for {}..".format(header.path),
        env={
            "RUST_BACKTRACE": "1",
            # Bindgen loads libclang at runtime, so we setup LD_LIBRARY_PATH
            "LD_LIBRARY_PATH": ":".join([f.dirname for f in clang_libs]),
            "CLANG_PATH": clang.path,
        },
        executable=bindgen,
        arguments=[args],
        tools=[bindgen, clang],
    )

    ctx.actions.run_shell(
        inputs=depset([rustfmt, unformatted]),
        outputs=[output],
        command="{} --write-mode=plain {} > {}".format(rustfmt.path, unformatted.path, output.path),
        tools=[rustfmt],
    )

rust_bindgen = rule(
    _rust_bindgen,
    attrs = {
        "header": attr.label(allow_single_file = True),
        "cc_lib": attr.label(),
        "bindgen": attr.label(
            executable = True,
            cfg = "host",
            default = Label("@cargo//:cargo_bin_bindgen"),
        ),
        "clang": attr.label(
            executable = True,
            cfg = "host",
        ),
        "libclang": attr.label(),
        # There is no proper `cc_toolchain`, so we use this and the cpp fragment.
        # See https://github.com/bazelbuild/bazel/issues/1624
        # An instance of cc_toolchain, used to find the standard library headers.
        # @TODO Default cc_toolchain.files is empty.. is this the right label?
        "cc_toolchain": attr.label(default = Label("@bazel_tools//tools/cpp:toolchain")),
        # Ought to be cc_toolchain.dynamic_runtime_libs, but it doesn't seem to be available.
        "libstdcxx": attr.label(),
    },
    fragments = ["cpp"],
    outputs = {"out": "%{name}.rs"},
    toolchains = ["@io_bazel_rules_rust//rust:toolchain"],
)

"""
Generates a rust file from a cc_library and one of it's headers.

It's recommended to create a macro .bzl that allows you to
enumerate all of the dependencies in a single place.

```python
def my_rust_bindgen(name, header, cc_lib):
    rust_bindgen(
        name = name,
        header = header,
        cc_lib = cc_lib,
        bindgen = "//third_party/cargo:cargo_bin_bindgen",
        clang = "//third_party/clang",
        libclang = "//third_party/clang:lib",
        cc_toolchain = "//third_party/cc:toolchain",
        libstdcxx = "//third_party/cc:lib",
    )

def rust_bindgen_library(name, header, cc_lib):
    my_rust_bindgen(
        name = name + "__bindgen",
        header = header,
        cc_lib = cc_lib,
    )
    rust_library(
        name = name,
        srcs = [name + "__bindgen.rs"],
        deps = [cc_lib]
    )
```

and then use it as follows:

```python
load("my_bindgen.bzl", "rust_bindgen_library")

rust_bindgen_library(
    name = "example_ffi",
    cc_lib = "//example:lib",
    header = "//example:api.h",
)
```
"""
