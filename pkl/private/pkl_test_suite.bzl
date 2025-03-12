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
Implementation of 'pkl_test_suite' macro.
"""

load("@rules_pkl//pkl/private:pkl_library.bzl", "pkl_library")
load(":pkl.bzl", "pkl_test")

def pkl_test_suite(
        name,
        srcs,
        deps = None,
        tags = [],
        visibility = None,
        size = None,
        test_suffix = None,
        **kwargs):
    """Create a suite of Pkl tests from the provided files.

    Given the list of `srcs`, this macro will generate:

    1. A `pkl_test` target (with visibility:private) per `src` that ends with `test_suffix`
    2. A `pkl_library` that accumulates any files that don't match `test_suffix`
    3. A `native.test_suite` that accumulates all of the `pkl_test` targets

    Args:
        name: A unique name for this target.
        srcs: The source files, containing Pkl test files. Accepts files with the .pkl extension.
        deps: Other targets to include in the Pkl module path when building this configuration. Must be pkl_* targets.
        tags: Tags to add to each Pkl test target.
        visibility: The visibility of non test Pkl source files.
        size: Size of Pkl test.
        test_suffix: A custom suffix indicating a source file is a Pkl test file.
        **kwargs: Further keyword arguments.

    """
    if test_suffix == None:
        test_suffix = "_test.pkl"

    if deps == None:
        deps = []

    test_srcs = [test for test in srcs if test.endswith(test_suffix)]
    nontest_srcs = [test for test in srcs if not test.endswith(test_suffix)]

    if nontest_srcs:
        lib_dep_name = "%s-test-lib" % name
        lib_dep_label = ":%s" % lib_dep_name

        pkl_library(
            name = lib_dep_name,
            srcs = nontest_srcs,
            deps = deps,
            visibility = visibility,
        )

        if lib_dep_label not in deps:
            deps.append(lib_dep_label)

    tests = []

    for src in test_srcs:
        test_name = src.replace(".pkl", "")

        pkl_test(
            name = test_name,
            srcs = [src],
            size = size,
            deps = deps,
            tags = tags,
            visibility = ["//visibility:private"],
            **kwargs
        )

        tests.append(test_name)

    native.test_suite(
        name = name,
        tests = tests,
        tags = tags,
        visibility = visibility,
    )
