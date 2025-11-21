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
Implementation of 'pkl_project_rule'.
"""

load("@rules_pkl//pkl/private:providers.bzl", "PklMetadataInfo")

def _pkl_project_rule_impl(ctx):
    return [
        PklMetadataInfo(
            pkl_project_file = ctx.file.pkl_project_file,
            pkl_project_deps = ctx.file.pkl_project_deps,
        ),
    ]

pkl_project_rule = rule(
    _pkl_project_rule_impl,
    attrs = {
        "pkl_project_file": attr.label(
            allow_single_file = True,
            default = "PklProject",
        ),
        "pkl_project_deps": attr.label(
            allow_single_file = True,
            default = "PklProject.deps.json",
        ),
    },
)
