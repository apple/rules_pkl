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
Repository rule for parsing the PklProject.deps.json and the PklProject file.
"""

load(":pkl_package_names.bzl", "transform_package_url_to_workspace_name")

def parse_pkl_project_deps_json(pkl_deps_json_string_path):
    """Parses the contents of a JSON file containing Pkl Project dependencies.

    Args:
        pkl_deps_json_string_path: path to JSON file containing Pkl Project dependencies.
    Returns:
        A list of structs containing Pkl dependency data.
    """
    lock_file_contents = json.decode(pkl_deps_json_string_path)

    if lock_file_contents["schemaVersion"] != 1:
        fail("Unknown schema version in lock file:", lock_file_contents["schemaVersion"])

    seen_remote_pkl_packages = {}
    for data in lock_file_contents["resolvedDependencies"].values():
        if data.get("type") != "remote":
            fail("Unsupported type", data)

        if data["uri"] not in seen_remote_pkl_packages:
            seen_remote_pkl_packages[data["uri"]] = struct(
                workspace_name = transform_package_url_to_workspace_name(data["uri"]),
                url = data["uri"],
                sha256 = data["checksums"]["sha256"],
            )

    return seen_remote_pkl_packages.values()

def _pkl_project_impl(rctx):
    packages = parse_pkl_project_deps_json(rctx.read(rctx.attr.pkl_project_deps))
    targets_for_all = []
    for package in packages:
        targets_for_all.append("@%s//:item" % package.workspace_name)

    rctx.symlink(rctx.attr.pkl_project, "PklProject")
    rctx.symlink(rctx.path(rctx.attr.pkl_project_deps), "PklProject.deps.json")

    if rctx.os.name == "linux" and rctx.os.arch == "amd64":
        pkl_executable = rctx.path(Label("@pkl-cli-linux-amd64//file:downloaded"))
    elif rctx.os.name == "linux" and rctx.os.arch == "aarch64":
        pkl_executable = rctx.path(Label("@pkl-cli-linux-aarch64//file:downloaded"))
    elif rctx.os.name == "mac os x" and rctx.os.arch == "x86_64":
        pkl_executable = rctx.path(Label("@pkl-cli-macos-amd64//file:downloaded"))
    elif rctx.os.name == "mac os x" and rctx.os.arch == "aarch64":
        pkl_executable = rctx.path(Label("@pkl-cli-macos-aarch64//file:downloaded"))
    else:
        fail("Couldn't find pkl executable for os {os} and arch {arch}".format(os = rctx.os.name, arch = rctx.os.arch))

    rendered_result = rctx.execute(["{pkl_executable}".format(pkl_executable = pkl_executable), "eval", "PklProject", "-f", "json"])
    if rendered_result.return_code != 0:
        fail("Error evaluating and rendering PklProject file as json: {}".format(rendered_result.stderr))
    metadata = rendered_result.stdout

    pkl_project_metadata = json.decode(metadata)
    has_package = "package" in pkl_project_metadata

    build_bazel_content = ""
    if has_package:
        build_bazel_content += 'load("@rules_pkl//pkl/private:pkl_project_rule.bzl", "pkl_project_rule")\n'

    build_bazel_content += """load("@rules_pkl//pkl/private:pkl_cache.bzl", "pkl_cache")

package(default_visibility = ["//visibility:public"])

"""

    if has_package:
        base_uri = pkl_project_metadata["package"]["baseUri"]
        pkl_project_name = pkl_project_metadata["package"]["name"]
        pkl_project_version = pkl_project_metadata["package"]["version"]
        build_bazel_content += """
pkl_project_rule(
    name = "project",
    base_uri = "{base_uri}",
    pkl_project_file = "PklProject",
    pkl_project_deps = "PklProject.deps.json",
    pkl_project_name = "{pkl_project_name}",
    pkl_project_version = "{pkl_project_version}",
)
""".format(
            base_uri = base_uri,
            pkl_project_name = pkl_project_name,
            pkl_project_version = pkl_project_version,
        )

    build_bazel_content += """
pkl_cache(
    name = "packages",
    pkl_project = "PklProject",
    pkl_project_deps = "PklProject.deps.json",
    items = {targets_for_all},
)

""".format(
        pkl_project_file = "PklProject",
        pkl_project_deps = "PklProject.deps.json",
        targets_for_all = repr(targets_for_all),
    )

    rctx.file("BUILD.bazel", content = build_bazel_content, executable = False)

pkl_project = repository_rule(
    _pkl_project_impl,
    doc = """
    Parses the PklProject.deps.json and parses the PklProject file to extract the information from the package
    object. This is then used to populate the attributes of the pkl_project rule and pkl_cache rule in the BUILD file
    generated by this repository rule.
    """,
    attrs = {
        "pkl_project": attr.label(
            doc = "The PklProject file",
            default = "PklProject",
            allow_single_file = True,
            mandatory = True,
        ),
        "pkl_project_deps": attr.label(
            doc = "The PklProject.deps.json file",
            default = "PklProject.deps.json",
            allow_single_file = True,
            mandatory = True,
        ),
    },
)
