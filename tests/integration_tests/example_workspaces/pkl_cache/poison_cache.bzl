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
Repository Rule to poison a Pkl cache item for testing.
"""

# buildifier: disable=bzl-visibility
load("@rules_pkl//pkl/private:providers.bzl", "PklCacheInfo", "PklFileInfo")

def _poisoned_pkl_cache(ctx):
    pkl_cache = ctx.attr.cache[PklFileInfo].caches.to_list()

    root_dir = pkl_cache[0].root
    pkl_project = pkl_cache[0].pkl_project
    pkl_project_deps = pkl_cache[0].pkl_project_deps

    shell_script = ctx.executable._shell_script

    # Declare Poisoned files to fully replicate a valid cache item.
    poisoned_pklproject_file = ctx.actions.declare_file("PklProject-poisoned")
    poisoned_pklproject_deps = ctx.actions.declare_file("PklProject-poisoned.deps.json")
    poisoned_root_dir = ctx.actions.declare_directory("poisoned-packages")

    ctx.actions.run(
        inputs = [
            root_dir,
            pkl_project,
            pkl_project_deps,
        ],
        executable = shell_script,
        outputs = [
            poisoned_pklproject_file,
            poisoned_pklproject_deps,
            poisoned_root_dir,
        ],
        arguments = [
            ctx.attr.mangle_repository,
            root_dir.path,  # path to directory containing cache directory
            pkl_project.dirname,  # path to directory containing the PklProject file
            poisoned_pklproject_file.path,  # move poisoned PklProject to this path
            poisoned_pklproject_deps.path,  # move poisoned PklProject.deps.json to this declared file
            poisoned_root_dir.path,  # copy edited cache directory to this location
        ],
    )

    # Construct valid Pkl cache item with poisoned files.
    poisoned_cache = PklFileInfo(
        caches = depset([
            PklCacheInfo(
                pkl_project = poisoned_pklproject_file,
                pkl_project_deps = poisoned_pklproject_deps,
                root = poisoned_root_dir,
            ),
        ]),
        dep_files = depset(),
    )

    return [
        poisoned_cache,
        DefaultInfo(files = depset([
            poisoned_pklproject_file,
            poisoned_pklproject_deps,
        ])),
    ]

poisoned_pkl_cache = rule(
    _poisoned_pkl_cache,
    attrs = {
        "cache": attr.label(
            providers = [
                PklFileInfo,
            ],
        ),
        "_shell_script": attr.label(
            default = "//:poison_cache_script",
            executable = True,
            cfg = "exec",
        ),
        "mangle_repository": attr.string(
            default = "pkg.pkl-lang.org",
        ),
    },
)
