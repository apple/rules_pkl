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

"""Tests for //pkl/private:remote_pkl_package.bzl"""

load("@bazel_skylib//lib:unittest.bzl", "asserts", "unittest")

# buildifier: disable=bzl-visibility
load("//pkl/private:remote_pkl_package.bzl", "rewrite_url")

def _no_mirrors_test(ctx):
    env = unittest.begin(ctx)
    asserts.equals(env, ["https://pkg.pkl-lang.org/pkl-k8s/k8s@1.0.1"], rewrite_url("https://pkg.pkl-lang.org/pkl-k8s/k8s@1.0.1", {}))
    return unittest.end(env)

no_mirrors_test = unittest.make(_no_mirrors_test)

def _mirror_matches_test(ctx):
    env = unittest.begin(ctx)
    mirrors = {"https://pkg.pkl-lang.org/": "https://my-mirror.example.com/"}
    result = rewrite_url("https://pkg.pkl-lang.org/pkl-k8s/k8s@1.0.1", mirrors)
    asserts.equals(env, ["https://my-mirror.example.com/pkl-k8s/k8s@1.0.1", "https://pkg.pkl-lang.org/pkl-k8s/k8s@1.0.1"], result)
    return unittest.end(env)

mirror_matches_test = unittest.make(_mirror_matches_test)

def _mirror_does_not_match_test(ctx):
    env = unittest.begin(ctx)
    mirrors = {"https://other.example.com/": "https://my-mirror.example.com/"}
    result = rewrite_url("https://pkg.pkl-lang.org/pkl-k8s/k8s@1.0.1", mirrors)
    asserts.equals(env, ["https://pkg.pkl-lang.org/pkl-k8s/k8s@1.0.1"], result)
    return unittest.end(env)

mirror_does_not_match_test = unittest.make(_mirror_does_not_match_test)

def _first_matching_mirror_is_used_test(ctx):
    env = unittest.begin(ctx)
    mirrors = {
        "https://other.example.com/": "https://mirror-a.example.com/",
        "https://pkg.pkl-lang.org/": "https://mirror-b.example.com/",
    }
    result = rewrite_url("https://pkg.pkl-lang.org/pkl-k8s/k8s@1.0.1", mirrors)
    asserts.equals(env, ["https://mirror-b.example.com/pkl-k8s/k8s@1.0.1", "https://pkg.pkl-lang.org/pkl-k8s/k8s@1.0.1"], result)
    return unittest.end(env)

first_matching_mirror_is_used_test = unittest.make(_first_matching_mirror_is_used_test)

def rewrite_url_test_suite(name):
    """Macro to provide tests within this file to run in BUILD.bazel

    Args:
      name: the name to be provided to `unittest.suite`.
    """
    unittest.suite(
        name,
        no_mirrors_test,
        mirror_matches_test,
        mirror_does_not_match_test,
        first_matching_mirror_is_used_test,
    )
