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
Definition for Pkl Providers.
"""

PklFileInfo = provider(
    doc = "A combination of base Pkl files (from `pkl_library`) and cache entries, required to evaluate `pkl_eval` rules",
    fields = {
        "dep_files": "Depset of the transitive closure of Pkl files and their dependencies",
        "caches": "Depset of `PklCacheInfo`. When executing Pkl commands, there must be at most one item in this depset",
    },
)

PklCacheInfo = provider(
    doc = "A provider of a cache used by Pkl rules",
    fields = {
        "root": "A `File` representing the root of the cache",
        "label": "The `Label` of the rule that produced this cache info",
        "pkl_project": "A `File` representing the PklProjet that this cache was created from. Used for mapping shortnames to cache entries.",
        "pkl_project_deps": "A `File` representing the PklProjet.deps.json that this cache was created from.",
    },
)
