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
Module extension for using rules_pkl with bzlmod.
"""

load("//pkl:repositories.bzl", "pkl_cli_binaries")
load("//pkl/private:pkl_project.bzl", "parse_pkl_project_deps_json", _pkl_project = "pkl_project")
load("//pkl/private:remote_pkl_package.bzl", "remote_pkl_package")

pkl_project = tag_class(
    attrs = {
        "name": attr.string(
            doc = "Name of the workspace to generate",
        ),
        "pkl_project": attr.label(
            doc = "The PklProject file",
            allow_single_file = True,
            mandatory = True,
        ),
        "pkl_project_deps": attr.label(
            doc = "The PklProject.deps.json file",
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

def _toolchain_extension(module_ctx):
    pkl_cli_binaries()

    workspaces = []
    for mod in module_ctx.modules:
        for proj in mod.tags.project:
            if proj.name in workspaces:
                fail("May only declare workspace with name %s once." % proj.name)
            workspaces.append(proj.name)

            # Make sure all the remote files are downloaded and unpacked
            packages = parse_pkl_project_deps_json(module_ctx.read(proj.pkl_project_deps))
            for package in packages:
                remote_pkl_package(
                    name = package.workspace_name,
                    url = package.url,
                    sha256 = package.sha256,
                )

            # Now set up all the targets that people will rely on in their builds.
            _pkl_project(
                name = proj.name,
                pkl_project = proj.pkl_project,
                pkl_project_deps = proj.pkl_project_deps,
                environment = proj.environment,
                extra_flags = proj.extra_flags,
            )

pkl = module_extension(
    implementation = _toolchain_extension,
    tag_classes = {
        "project": pkl_project,
    },
)
