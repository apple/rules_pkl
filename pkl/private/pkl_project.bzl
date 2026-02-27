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

def eval_pkl_project(ctx, pkl_project_path, extra_args = []):
    """Evaluates a PklProject file as JSON and returns the decoded object.

    Args:
        ctx: A repository context or module context.
        pkl_project_path: Path to the PklProject file to evaluate.
        extra_args: Additional arguments to pass to `pkl eval`.
    Returns:
        The JSON object output of `pkl eval <pkl_project_path> -f json`.
    """
    if ctx.os.name == "linux" and ctx.os.arch == "amd64":
        pkl_executable = ctx.path(Label("@pkl-cli-linux-amd64//file:downloaded"))
    elif ctx.os.name == "linux" and ctx.os.arch == "aarch64":
        pkl_executable = ctx.path(Label("@pkl-cli-linux-aarch64//file:downloaded"))
    elif ctx.os.name == "mac os x" and ctx.os.arch == "x86_64":
        pkl_executable = ctx.path(Label("@pkl-cli-macos-amd64//file:downloaded"))
    elif ctx.os.name == "mac os x" and ctx.os.arch == "aarch64":
        pkl_executable = ctx.path(Label("@pkl-cli-macos-aarch64//file:downloaded"))
    else:
        fail("Couldn't find pkl executable for os {os} and arch {arch}".format(os = ctx.os.name, arch = ctx.os.arch))

    result = ctx.execute([pkl_executable, "eval", str(pkl_project_path), "--format", "json"] + extra_args)
    if result.return_code != 0:
        fail("Error evaluating PklProject: {}".format(result.stderr))
    return json.decode(result.stdout)

def convert_dict_to_options(option_name, items_dict):
    """Converts the dictioinary to a list with each "key=value" pair preceded by the option name (e.g. --my-option).

    Args:
        option_name (str): The name of the option, typically in the form of `--option` or `-o`.
        items_dict (dict[str, str]): A dictionary of items where:
            - **Keys** are the names of the item (e.g., "key1", "key2").
            - **Values** are the corresponding values for each item (e.g., "value1", "value2").
    Returns:
        A list of strings containing Pkl CLI options.
    """

    list = []
    for key, value in items_dict.items():
        list.append(option_name)
        list.append("{key}={value}".format(key = key, value = value))
    return list

def _pkl_project_impl(rctx):
    packages = parse_pkl_project_deps_json(rctx.read(rctx.attr.pkl_project_deps))
    targets_for_all = []
    for package in packages:
        targets_for_all.append("@%s//:item" % package.workspace_name)

    rctx.symlink(rctx.attr.pkl_project, "PklProject")
    rctx.symlink(rctx.path(rctx.attr.pkl_project_deps), "PklProject.deps.json")

    env_vars = convert_dict_to_options("--env-var", rctx.attr.environment)
    pkl_project_metadata = eval_pkl_project(rctx, "PklProject", extra_args = env_vars + rctx.attr.extra_flags)
    has_package = "package" in pkl_project_metadata

    build_bazel_content = ""
    if has_package:
        build_bazel_content += 'load("@rules_pkl//pkl/private:pkl_project_rule.bzl", "pkl_project_rule")\n'

    build_bazel_content += """load("@rules_pkl//pkl/private:pkl_cache.bzl", "pkl_cache")

package(default_visibility = ["//visibility:public"])

"""

    if has_package:
        build_bazel_content += """
pkl_project_rule(
    name = "project",
    pkl_project_file = "PklProject",
    pkl_project_deps = "PklProject.deps.json",
)
"""

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
        "extra_flags": attr.string_list(
            doc = """Dictionary of name value pairs used to pass in Pkl external flags.
                See the Pkl docs: https://pkl-lang.org/main/current/pkl-cli/index.html#command-eval""",
            default = [],
        ),
        "environment": attr.string_dict(
            doc = """Dictionary of name value pairs used to pass in Pkl env vars.
                See the Pkl docs: https://pkl-lang.org/main/current/pkl-cli/index.html#command-eval""",
            default = {},
        ),
    },
)
