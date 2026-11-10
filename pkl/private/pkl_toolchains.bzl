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
Repository rule that defines the Pkl toolchains for the selected Pkl version.

Not every Pkl version distributes binaries for every platform (e.g. Pkl 0.33 dropped macOS/amd64).
A static `BUILD` file can't depend on the selected version, so the toolchains are generated into
their own repository, containing only the platforms that `VERSIONS` lists for the selected version.
Registering this repository means toolchain resolution fails with a regular "no matching toolchains"
error on platforms without one.
"""

load("//pkl/private:constants.bzl", "DOC_VERSIONS", "VERSIONS")

# Maps each platform to its OS and CPU constraints, and the `@bazel_tools` conditions it satisfies.
_PLATFORMS = {
    "linux-aarch64": struct(
        os = "linux",
        cpu = "aarch64",
        conditions = ["linux_aarch64"],
    ),
    "linux-amd64": struct(
        os = "linux",
        cpu = "x86_64",
        conditions = ["linux_x86_64"],
    ),
    "macos-aarch64": struct(
        os = "macos",
        cpu = "aarch64",
        conditions = ["darwin_arm64", "darwin_arm64e"],
    ),
    "macos-amd64": struct(
        os = "macos",
        cpu = "x86_64",
        conditions = ["darwin_x86_64"],
    ),
}

def _toolchains(prefix, kind, rule, toolchain_type, platforms):
    """Generates the `BUILD` content for one family of toolchains.

    Args:
        prefix: Prefix of the target names, e.g. `pkl` for `pkl_toolchain_macos_aarch64`.
        kind: Prefix of the binary repositories, e.g. `pkl-cli`.
        rule: Name of the toolchain rule, e.g. `pkl_toolchain`.
        toolchain_type: Label of the toolchain type.
        platforms: The platforms to define toolchains for.
    Returns:
        The `BUILD` content.
    """
    return "".join([
        """
{rule}(
    name = "{prefix}_{suffix}",
    cli = "@{kind}-{platform}//file",
)

toolchain(
    name = "{prefix}_toolchain_{suffix}",
    exec_compatible_with = [
        "@platforms//os:{os}",
        "@platforms//cpu:{cpu}",
    ],
    toolchain = ":{prefix}_{suffix}",
    toolchain_type = "{toolchain_type}",
)
""".format(
            rule = rule,
            prefix = prefix,
            kind = kind,
            platform = platform,
            suffix = platform.replace("-", "_"),
            os = _PLATFORMS[platform].os,
            cpu = _PLATFORMS[platform].cpu,
            toolchain_type = toolchain_type,
        )
        for platform in platforms
    ])

def _alias(name, tool, kind, platforms):
    """Generates an alias to the binary of the platform that Bazel is running on.

    Args:
        name: Name of the alias.
        tool: Name of the tool, for error messages.
        kind: Prefix of the binary repositories, e.g. `pkl-cli`.
        platforms: The platforms that have a binary.
    Returns:
        The `BUILD` content.
    """
    branches = [
        '            "@bazel_tools//src/conditions:{condition}": "@{kind}-{platform}//file:downloaded",'.format(
            condition = condition,
            kind = kind,
            platform = platform,
        )
        for platform in platforms
        for condition in _PLATFORMS[platform].conditions
    ]
    return """
alias(
    name = "{name}",
    actual = select(
        {{
{branches}
        }},
        no_match_error = "No `{tool}` binary is available for this platform with the selected Pkl version. Available: {platforms}",
    ),
)
""".format(
        name = name,
        tool = tool,
        branches = "\n".join(branches),
        platforms = ", ".join(platforms),
    )

def pkl_toolchains_build_file(cli_platforms, doc_platforms):
    """Generates the `BUILD` file of the toolchains repository.

    Args:
        cli_platforms: The platforms that have a `pkl` binary.
        doc_platforms: The platforms that have a `pkldoc` binary.
    Returns:
        The `BUILD` content.
    """
    return """load({defs}, "pkl_doc_toolchain", "pkl_toolchain")

package(default_visibility = ["//visibility:public"])
{cli_alias}{doc_alias}{cli_toolchains}{doc_toolchains}""".format(
        defs = repr(str(Label("//pkl:defs.bzl"))),
        cli_alias = _alias("pkl", "pkl", "pkl-cli", cli_platforms),
        doc_alias = _alias("pkl_doc_cli", "pkldoc", "pkl-doc-cli", doc_platforms),
        cli_toolchains = _toolchains("pkl", "pkl-cli", "pkl_toolchain", str(Label("//pkl:toolchain_type")), cli_platforms),
        doc_toolchains = _toolchains("pkl_doc", "pkl-doc-cli", "pkl_doc_toolchain", str(Label("//pkl:doc_toolchain_type")), doc_platforms),
    )

def _pkl_toolchains_impl(rctx):
    version = rctx.attr.version
    rctx.file("BUILD.bazel", content = pkl_toolchains_build_file(VERSIONS[version].keys(), DOC_VERSIONS[version].keys()))

pkl_toolchains = repository_rule(
    _pkl_toolchains_impl,
    attrs = {
        "version": attr.string(
            doc = "The Pkl version. Its platforms are those of `VERSIONS` and `DOC_VERSIONS` in `constants.bzl`, and expects a `pkl-cli-<platform>` and `pkl-doc-cli-<platform>` repository for each.",
            mandatory = True,
        ),
    },
    doc = "Defines toolchains for the platforms that have a Pkl binary.",
)
