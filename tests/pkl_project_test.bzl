# Copyright © 2026 Apple Inc. and the Pkl project authors. All rights reserved.
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

"""Tests for the PklProject.deps.json parsing in //pkl/private:pkl_project.bzl"""

load("@bazel_skylib//lib:unittest.bzl", "asserts", "unittest")

# buildifier: disable=bzl-visibility
load("//pkl/private:pkl_project.bzl", "parse_pkl_project_deps_json", "parse_pkl_project_local_deps")

_DEPS_JSON = json.encode({
    "schemaVersion": 1,
    "resolvedDependencies": {
        "package://example.com/platform@1": {
            "type": "local",
            "uri": "projectpackage://example.com/platform@1.0.0",
            "path": "platform/pkl",
        },
        "package://example.com/other@1": {
            "type": "local",
            "uri": "projectpackage://example.com/other@1.0.0",
            "path": "other/",
        },
        "package://pkg.pkl-lang.org/pkl-k8s/k8s@1": {
            "type": "remote",
            "uri": "projectpackage://pkg.pkl-lang.org/pkl-k8s/k8s@1.0.1",
            "checksums": {"sha256": "75c6d66d94c335417a3c502e107aaeadf7a60b4e1d34b2c979afe11193205a1a"},
        },
    },
})

def _local_deps_are_skipped_test(ctx):
    env = unittest.begin(ctx)
    packages = parse_pkl_project_deps_json(_DEPS_JSON)
    asserts.equals(env, 1, len(packages))
    asserts.equals(env, "projectpackage://pkg.pkl-lang.org/pkl-k8s/k8s@1.0.1", packages[0].url)
    return unittest.end(env)

local_deps_are_skipped_test = unittest.make(_local_deps_are_skipped_test)

def _local_deps_paths_test(ctx):
    env = unittest.begin(ctx)
    asserts.equals(env, ["other", "platform/pkl"], parse_pkl_project_local_deps(_DEPS_JSON))
    return unittest.end(env)

local_deps_paths_test = unittest.make(_local_deps_paths_test)

def _no_local_deps_test(ctx):
    env = unittest.begin(ctx)
    deps_json = json.encode({"schemaVersion": 1, "resolvedDependencies": {}})
    asserts.equals(env, [], parse_pkl_project_local_deps(deps_json))
    return unittest.end(env)

no_local_deps_test = unittest.make(_no_local_deps_test)

def pkl_project_test_suite(name):
    """Macro to provide tests within this file to run in BUILD.bazel

    Args:
      name: the name to be provided to `unittest.suite`.
    """
    unittest.suite(
        name,
        local_deps_are_skipped_test,
        local_deps_paths_test,
        no_local_deps_test,
    )
