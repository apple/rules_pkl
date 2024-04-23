# Copyright © 2024 Apple Inc. and the Pkl project authors. All rights reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
"""
Repository rule that prepopulates Pkl's cache with required packages.
"""

load(":pkl_package_names.bzl", "transform_package_url_to_workspace_name")

def parse_pkl_project_deps_json(pkl_deps_json_string):
    """Parses the contents of a JSON file containing Pkl Project dependencies.

    Args:
        pkl_deps_json_string: path to JSON file containing Pkl Project dependencies.
    Returns:
        A list of structs containing Pkl dependency data.
    """
    lock_file_contents = json.decode(pkl_deps_json_string)

    if lock_file_contents["schemaVersion"] != 1:
        fail("Unknown schema version in lock file:", lock_file_contents["schemaVersion"])

    seen_remote_pkl_packages = {}
    for (_, data) in lock_file_contents["resolvedDependencies"].items():
        if data.get("type") != "remote":
            fail("Unsupported type", data)

        if data["uri"] not in seen_remote_pkl_packages.keys():
            seen_remote_pkl_packages[data["uri"]] = struct(
                workspace_name = transform_package_url_to_workspace_name(data["uri"]),
                url = data["uri"],
                sha256 = data["checksums"]["sha256"],
            )

    return seen_remote_pkl_packages.values()

def _pkl_deps_impl(rctx):
    packages = parse_pkl_project_deps_json(rctx.read(rctx.attr.pkl_project_deps))

    rctx.symlink(rctx.attr.pkl_project, "PklProject")
    rctx.symlink(rctx.attr.pkl_project_deps, "PklProject.deps.json")

    targets_for_all = []

    for package in packages:
        targets_for_all.append("@%s//:item" % package.workspace_name)

    build_file_contents = """
load("@rules_pkl//pkl/private:pkl_cache.bzl", "pkl_cache")

package(default_visibility = ["//visibility:public"])

pkl_cache(
    name = "packages",
    pkl_project = "PklProject",
    pkl_project_deps = "PklProject.deps.json",
    items = %s,
)

""" % (repr(targets_for_all))

    rctx.file("BUILD.bazel", content = build_file_contents, executable = False)

pkl_deps = repository_rule(
    _pkl_deps_impl,
    attrs = {
        "pkl_project": attr.label(
            doc = "The PklProject file",
            mandatory = True,
        ),
        "pkl_project_deps": attr.label(
            doc = "The PklProject.deps.json file",
            mandatory = True,
        ),
    },
)
