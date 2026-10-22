# Copyright © 2024-2026 Apple Inc. and the Pkl project authors. All rights reserved.
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

def _parse_deps_json(pkl_deps_json_string):
    """Returns `(remote_packages, local_paths)` from the contents of a PklProject.deps.json."""
    lock_file_contents = json.decode(pkl_deps_json_string)
    if lock_file_contents["schemaVersion"] != 1:
        fail("Unknown schema version in lock file:", lock_file_contents["schemaVersion"])

    remote_packages = {}
    local_paths = {}
    for data in lock_file_contents["resolvedDependencies"].values():
        dependency_type = data.get("type")
        if dependency_type == "local":
            path = data["path"].rstrip("/")
            if not path or path.startswith("/") or ".." in path.split("/"):
                fail("Unsupported local project dependency path (must be relative, non-empty and not contain '..'):", data)
            local_paths[path] = True
        elif dependency_type == "remote":
            if data["uri"] not in remote_packages:
                remote_packages[data["uri"]] = struct(
                    workspace_name = transform_package_url_to_workspace_name(data["uri"]),
                    url = data["uri"],
                    sha256 = data["checksums"]["sha256"],
                )
        else:
            fail("Unsupported type", data)

    return remote_packages.values(), sorted(local_paths.keys())

def parse_pkl_project_deps_json(pkl_deps_json_string_path):
    """Parses the contents of a JSON file containing Pkl Project dependencies.

    Local project dependencies are skipped, as there is nothing to download.

    Args:
        pkl_deps_json_string_path: path to JSON file containing Pkl Project dependencies.
    Returns:
        A list of structs containing Pkl dependency data for remote packages.
    """
    return _parse_deps_json(pkl_deps_json_string_path)[0]

def parse_pkl_project_local_deps(pkl_deps_json_string):
    """Extracts the paths of local project dependencies from the contents of a PklProject.deps.json.

    Args:
        pkl_deps_json_string: contents of a PklProject.deps.json file.
    Returns:
        A sorted, de-duplicated list of paths (relative to the directory containing the root PklProject)
        of the local projects the root project depends on.
    """
    return _parse_deps_json(pkl_deps_json_string)[1]

def _eval_pkl_project(ctx, pkl_project_path, extra_args = [], project_dir = None):
    """Evaluates a PklProject file as JSON and returns the decoded object.

    Args:
        ctx: A repository context or module context.
        pkl_project_path: Path to the PklProject file to evaluate.
        extra_args: Additional arguments to pass to `pkl eval`.
        project_dir: If set, passed as `--project-dir` so that Pkl loads the project from this directory
            instead of searching up from the working directory (which could find a symlinked copy).
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

    project_dir_args = ["--project-dir", str(project_dir)] if project_dir else []
    result = ctx.execute([pkl_executable, "eval", str(pkl_project_path), "--format", "json"] + project_dir_args + extra_args)
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

def _watch_symlink_target(rctx, label):
    """Validates that a label points to an existing file and watches it for changes.

    Args:
        rctx: The repository context.
        label: The label to validate.
    Returns:
        The resolved path.
    """
    path = rctx.path(label)
    if not path.exists:
        fail("Cannot symlink '{}': file does not exist.".format(label))
    rctx.watch(path)
    return path

def _pkl_project_impl(rctx):
    pkl_project_path = _watch_symlink_target(rctx, rctx.attr.pkl_project)
    pkl_project_deps_path = _watch_symlink_target(rctx, rctx.attr.pkl_project_deps)

    packages, local_paths = _parse_deps_json(rctx.read(pkl_project_deps_path))
    targets_for_all = []
    for package in packages:
        targets_for_all.append("@%s//:item" % package.workspace_name)

    rctx.symlink(pkl_project_path, "PklProject")
    rctx.symlink(pkl_project_deps_path, "PklProject.deps.json")

    # Local project dependencies are staged next to the root PklProject at build time, which only lines up
    # when the root PklProject lives in the root package of the main repository.
    local_projects = {}
    if local_paths:
        label = rctx.attr.pkl_project
        if label.workspace_name != "" or label.package != "":
            fail("Local project dependencies require the root PklProject to be //:PklProject (got {})".format(label))

        for path in local_paths:
            local_project_path = pkl_project_path.dirname
            for segment in path.split("/"):
                local_project_path = local_project_path.get_child(segment)
            local_project_path = local_project_path.get_child("PklProject")
            if not local_project_path.exists:
                fail("Local project dependency '{}' has no PklProject at {}".format(path, local_project_path))

            # Watch the local PklProject so that changes re-evaluate this repository.
            rctx.watch(local_project_path)
            staged = "local/{}/PklProject".format(path)
            rctx.symlink(local_project_path, staged)
            local_projects[staged] = path

    env_vars = convert_dict_to_options("--env-var", rctx.attr.environment)

    # Point Pkl at the real project directory. Otherwise Pkl finds the symlinked PklProject in this
    # repository's directory, and relative imports of local projects resolve inside the external repository.
    pkl_project_metadata = _eval_pkl_project(
        rctx,
        pkl_project_path,
        extra_args = env_vars + rctx.attr.extra_flags,
        project_dir = pkl_project_path.dirname,
    )
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
    local_projects = {local_projects},
)

""".format(
        pkl_project_file = "PklProject",
        pkl_project_deps = "PklProject.deps.json",
        targets_for_all = repr(targets_for_all),
        local_projects = repr(local_projects),
    )

    rctx.file("BUILD.bazel", content = build_bazel_content, executable = False)

def _pkl_project_http_rewrites_impl(rctx):
    pkl_project_path = _watch_symlink_target(rctx, rctx.attr.pkl_project)
    rules = _eval_pkl_project(rctx, pkl_project_path, extra_args = [
        "--expression",
        # Render the rewrite rules as list, to make sure the order is preserved.
        """
        new JsonRenderer {}
          .renderValue(
            (evaluatorSettings?.http?.rewrites?.toMap() ?? Map())
              .entries
              .map(
                (_rule) -> Map(_rule.key, _rule.value)
              )
          )
        """,
    ])
    rctx.file("rules.json", content = json.encode(rules))
    rctx.file("BUILD.bazel", content = 'exports_files(["rules.json"])\n')

pkl_project_http_rewrites = repository_rule(
    _pkl_project_http_rewrites_impl,
    doc = "Evaluates a PklProject file once to extract HTTP rewrite rules.",
    attrs = {
        "pkl_project": attr.label(
            doc = "The PklProject file to evaluate for HTTP rewrite rules.",
            allow_single_file = True,
            mandatory = True,
        ),
    },
)

pkl_project = repository_rule(
    _pkl_project_impl,
    doc = """
    Parses the PklProject.deps.json and parses the PklProject file to extract the information from the package
    object. This is then used to populate the attributes of the pkl_project rule and pkl_cache rule in the BUILD file
    generated by this repository rule.

    Local project dependencies (type `local` in PklProject.deps.json) are not downloaded. Their PklProject files are
    watched and exposed to the generated pkl_cache so they get staged next to the root PklProject when running Pkl.
    This requires the root PklProject to be `//:PklProject` of the main repository.
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
