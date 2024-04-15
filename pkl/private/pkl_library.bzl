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
Implementation of 'pkl_library' rule.
"""

load(":providers.bzl", "PklFileInfo")

def _pkl_library_impl(ctx):
    src_files = ctx.files.srcs + ctx.files.data

    dep_files = depset(
        direct = src_files,
        transitive = [dep[PklFileInfo].dep_files for dep in ctx.attr.deps],
    )

    caches = depset(
        transitive = [dep[PklFileInfo].caches for dep in ctx.attr.deps] +
                     [src[PklFileInfo].caches for src in ctx.attr.srcs if PklFileInfo in src],
    )

    return [
        DefaultInfo(
            files = depset(src_files),
        ),
        PklFileInfo(
            dep_files = dep_files,
            caches = caches,
        ),
        OutputGroupInfo(
            pkl_sources = depset(src_files, transitive = [dep_files]),
        ),
    ]

pkl_library = rule(
    _pkl_library_impl,
    doc = "Collect Pkl sources together so they can be used by other `rules_pkl` rules.",
    attrs = {
        "srcs": attr.label_list(
            mandatory = True,
            allow_files = [".pkl"],
            doc = "The Pkl source files to include in this library.",
        ),
        "deps": attr.label_list(
            providers = [
                [PklFileInfo],
            ],
            doc = "Other targets to include in the pkl module path when building this library. Must be pkl_* targets.",
        ),
        "data": attr.label_list(
            allow_files = True,
            doc = "Files to make available in the filesystem when building this library target. These can be accessed by relative path.",
        ),
    },
)
