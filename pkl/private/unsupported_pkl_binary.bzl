# Copyright © 2026 Apple Inc. and the Pkl project authors. All rights reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#   https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

"""
Repository rule for platforms that a given Pkl version does not distribute binaries for.

The repository mirrors the layout of the `http_file` repositories used for real binaries
(`//file:file` and `//file:downloaded`), so that `use_repo`, toolchains and `select()`s
keep working regardless of the Pkl version.
"""

def _unsupported_pkl_binary_stub_impl(ctx):
    fail(ctx.attr.message)

unsupported_pkl_binary_stub = rule(
    _unsupported_pkl_binary_stub_impl,
    attrs = {
        "message": attr.string(mandatory = True),
    },
    executable = True,
    doc = "Fails analysis with the given message.",
)

def _unsupported_pkl_binary_impl(rctx):
    message = "Pkl {version} does not provide a {tool} binary for {platform}. Use an older Pkl version (via `pkl.install`), or a different platform.".format(
        version = rctx.attr.version,
        tool = rctx.attr.tool,
        platform = rctx.attr.platform,
    )
    rctx.file(
        "file/BUILD.bazel",
        content = """load({load_label}, "unsupported_pkl_binary_stub")

package(default_visibility = ["//visibility:public"])

unsupported_pkl_binary_stub(
    name = "file",
    message = {message},
)

alias(
    name = "downloaded",
    actual = ":file",
)
""".format(load_label = repr(str(Label(":unsupported_pkl_binary.bzl"))), message = repr(message)),
    )

unsupported_pkl_binary = repository_rule(
    _unsupported_pkl_binary_impl,
    attrs = {
        "version": attr.string(mandatory = True, doc = "The Pkl version that lacks this binary"),
        "tool": attr.string(mandatory = True, doc = "The tool this stands in for, e.g. `pkl` or `pkldoc`"),
        "platform": attr.string(mandatory = True, doc = "The platform, e.g. `macos-amd64`"),
    },
    doc = "Stands in for a Pkl binary that is not distributed for the given platform and version.",
)
