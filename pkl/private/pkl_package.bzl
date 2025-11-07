# Copyright © 2024-2025 Apple Inc. and the Pkl project authors. All rights reserved.
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
Implementation of the pkl project package command as a Bazel rule.
"""

load("@rules_pkl//pkl/private:providers.bzl", "PklMetadataInfo", "PklPackageInfo")

def _pkl_package_impl(ctx):
    pkl_toolchain = ctx.toolchains["@rules_pkl//pkl:toolchain_type"]
    executable = pkl_toolchain.cli[DefaultInfo].files_to_run.executable

    project_metadata_info = ctx.attr.project[PklMetadataInfo]
    pkl_project_file = project_metadata_info.pkl_project_file
    pkl_project_deps = project_metadata_info.pkl_project_deps

    extra_flags = list(ctx.attr.extra_flags) or []

    output_dir = ctx.actions.declare_directory(ctx.label.name)
    working_dir = "%s.workdir" % ctx.label.name

    src_symlinks = []

    pkl_project_symlink = ctx.actions.declare_file("{}/{}".format(working_dir, "PklProject"))
    ctx.actions.symlink(
        target_file = pkl_project_file,
        output = pkl_project_symlink,
    )
    src_symlinks.append(pkl_project_symlink)

    pkl_project_deps_symlink = ctx.actions.declare_file("{}/{}".format(working_dir, "PklProject.deps.json"))
    ctx.actions.symlink(
        target_file = pkl_project_deps,
        output = pkl_project_deps_symlink,
    )
    src_symlinks.append(pkl_project_deps_symlink)

    for f in ctx.files.srcs:
        f_path = f.short_path
        bin_path = ctx.bin_dir.path + "/"
        if f_path.startswith(bin_path):
            f_path = f_path.removeprefix(bin_path)
        if ctx.attr.strip_prefix:
            strip_prefix = ctx.attr.strip_prefix + "/"
            if not f_path.startswith(strip_prefix):
                fail("User asked to strip '{}' prefix from srcs, but source file {} does not start with the prefix".format(
                    strip_prefix,
                    f_path,
                ))
            f_path = f_path.removeprefix(strip_prefix)
        src_symlink = ctx.actions.declare_file("{}/{}".format(working_dir, f_path))
        ctx.actions.symlink(
            target_file = f,
            output = src_symlink,
        )
        src_symlinks.append(src_symlink)

    args = ctx.actions.args()
    args.add_all(["project", "package", pkl_project_symlink.dirname])
    args.add_all(["--output-path", "{output_dir}".format(output_dir = output_dir.path)])
    args.add_all(extra_flags)

    ctx.actions.run(
        executable = executable,
        outputs = [output_dir],
        inputs = [pkl_project_file, pkl_project_deps] + src_symlinks,
        arguments = [args],
    )

    # Extract some metadata.
    name_file = ctx.actions.declare_file(ctx.label.name + ".name")
    version_file = ctx.actions.declare_file(ctx.label.name + ".version")
    base_uri_file = ctx.actions.declare_file(ctx.label.name + ".base_uri")
    package_zip_url_file = ctx.actions.declare_file(ctx.label.name + ".package_zip_url")

    metadata_eval_args = ctx.actions.args()
    metadata_eval_args.add(executable)
    metadata_eval_args.add(pkl_project_symlink)
    metadata_eval_args.add(name_file)
    metadata_eval_args.add(version_file)
    metadata_eval_args.add(base_uri_file)
    metadata_eval_args.add(package_zip_url_file)
    metadata_eval_args.add_all(extra_flags)

    ctx.actions.run_shell(
        command = """set -eu -o pipefail
        pkl=$1  # Path to the pkl cli
        pkl_project=$2  # Path to the input PklProject file to eval
        name_file=$3  # Output file to write the name to
        version_file=$4  # Output file to write the version to
        base_uri_file=$5  # Output file to write the base_uri to
        package_zip_url_file=$6  # Output file to write the package_zip_url to
        shift 6
        extra_args=("$@")  # Extra pkl arguments

        pkl_expr='"\\(package.name)\\n\\(package.version)\\n\\(package.baseUri)\\n\\(package.packageZipUrl)\\n"'

        {
            read name
            read version
            read base_uri
            read package_zip_url
        } < <("$pkl" eval "$pkl_project" "${extra_args[@]:+${extra_args[@]}}" -x "$pkl_expr")

        printf "%s\n" "$name" > "$name_file"
        printf "%s\n" "$version" > "$version_file"
        printf "%s\n" "$base_uri" > "$base_uri_file"
        printf "%s\n" "$package_zip_url" > "$package_zip_url_file"
        """,
        arguments = [metadata_eval_args],
        inputs = [pkl_project_symlink],
        outputs = [name_file, version_file, base_uri_file, package_zip_url_file],
        tools = [executable],
    )

    return [
        DefaultInfo(files = depset([output_dir])),
        PklPackageInfo(
            pkl_package_dir = output_dir,
            name_file = name_file,
            version_file = version_file,
            base_uri_file = base_uri_file,
            package_zip_url_file = package_zip_url_file,
        ),
    ]

pkl_package = rule(
    _pkl_package_impl,
    doc = """
    Prepares a Pkl project to be published as a package as per the `pkl project package` command, using Bazel.
    You should have at most one `pkl_package` rule per `pkl_project` repo rule.
    """,
    attrs = {
        "project": attr.label(
            providers = [
                PklMetadataInfo,
            ],
            mandatory = True,
        ),
        "srcs": attr.label_list(allow_files = [".pkl"]),
        "strip_prefix": attr.string(doc = "Strip a directory prefix from the srcs."),
        "extra_flags": attr.string_list(default = []),
    },
    toolchains = [
        "@rules_pkl//pkl:toolchain_type",
    ],
)
