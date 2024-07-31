## Copyright © 2024 Apple Inc. and the Pkl project authors. All rights reserved.
##
## Licensed under the Apache License, Version 2.0 (the "License");
## you may not use this file except in compliance with the License.
## You may obtain a copy of the License at
##
##     https://www.apache.org/licenses/LICENSE-2.0
##
## Unless required by applicable law or agreed to in writing, software
## distributed under the License is distributed on an "AS IS" BASIS,
## WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
## See the License for the specific language governing permissions and
## limitations under the License.
"""
Implementation of the pkl project package command as a Bazel rule.
"""

load("@rules_pkl//pkl/private:providers.bzl", "PklMetadataInfo", "PklPackageInfo")

def _pkl_package_impl(ctx):
    pkl_toolchain = ctx.toolchains["@rules_pkl//pkl:toolchain_type"]
    executable = pkl_toolchain.cli[DefaultInfo].files_to_run.executable

    project_metadata_info = ctx.attr.project[PklMetadataInfo]
    pkl_project_file = project_metadata_info.pkl_project_file
    pkl_project_deps = project_metadata_info.pkl_project_deps
    pkl_project_name = project_metadata_info.pkl_project_name
    pkl_project_version = project_metadata_info.pkl_project_version

    artifact_prefix = "{name}@{version}".format(name = pkl_project_name, version = pkl_project_version)

    metadata_file = ctx.actions.declare_file("{prefix}".format(prefix = artifact_prefix))
    metadata_file_checksum = ctx.actions.declare_file("{prefix}.sha256".format(prefix = artifact_prefix))
    package_archive = ctx.actions.declare_file("{prefix}.zip".format(prefix = artifact_prefix))
    package_archive_checksum = ctx.actions.declare_file("{prefix}.zip.sha256".format(prefix = artifact_prefix))

    outputs = [metadata_file, metadata_file_checksum, package_archive, package_archive_checksum]

    parts = [ctx.var["BINDIR"]]
    if ctx.label.package:
        parts.append(ctx.label.package)
    output_dir = "/".join(parts)

    args = ctx.actions.args()
    args.add_all(["project", "package", "{file_dir}".format(file_dir = pkl_project_file.dirname)])
    args.add_all(["--output-path", "{output_dir}".format(output_dir = output_dir)])
    args.add("{extra_flags}".format(extra_flags = " ".join(ctx.attr.extra_flags)))

    ctx.actions.run(
        executable = executable,
        outputs = outputs,
        inputs = [pkl_project_file, pkl_project_deps] + ctx.files.srcs,
        arguments = [args],
    )

    return [
        DefaultInfo(files = depset(outputs)),
        PklPackageInfo(
            metadata_file = metadata_file,
            metadata_file_checksum = metadata_file_checksum,
            package_archive = package_archive,
            package_archive_checksum = package_archive_checksum,
            project_metadata_info = project_metadata_info,
        ),
    ]

pkl_package = rule(
    _pkl_package_impl,
    doc = """
    Prepares a Pkl project to be published as a package as per the pkl project package command, using Bazel.
    You should have at most one pkl_package rule per pkl_project repo rule.
    """,
    attrs = {
        "project": attr.label(
            providers = [
                PklMetadataInfo,
            ],
            mandatory = True,
        ),
        "srcs": attr.label_list(allow_files = [".pkl"]),
        "extra_flags": attr.string_list(default = []),
    },
    toolchains = [
        "@rules_pkl//pkl:toolchain_type",
    ],
)
