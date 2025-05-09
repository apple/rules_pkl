# Copyright © 2025 Apple Inc. and the Pkl project authors. All rights reserved.
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
This Starlark file provides a custom analysistest rule, which can be used to validate the contents of a JAR file in
use by a given `pkl_java_library` target.
"""

load("@bazel_skylib//lib:unittest.bzl", "analysistest", "asserts")
load("@rules_java//java:defs.bzl", "JavaInfo")

def _pkl_java_library_deps_test_impl(ctx):
    env = analysistest.begin(ctx)

    target_under_test = ctx.attr.target_under_test
    target_library = ctx.attr.target_library

    java_target = target_under_test[JavaInfo]
    all_jars = java_target.transitive_compile_time_jars.to_list()

    asserts.true(
        env,
        len(all_jars) > 0,
        "transitive_compile_time_jars cannot be empty",
    )

    found_pkl_config_java_jar = [jar for jar in all_jars if "pkl-config-java" in jar.basename]
    if len(found_pkl_config_java_jar) == 0 or len(found_pkl_config_java_jar) > 1:
        analysistest.fail(
            env,
            "There should only ever be one pkl-config-java jar file, but had length ({}) for: {}".format(
                len(found_pkl_config_java_jar),
                found_pkl_config_java_jar,
            ),
        )

    found_pkl_config_java_jar = found_pkl_config_java_jar[0]
    target_library_jar = target_library[JavaInfo].compile_jars.to_list()[0]

    asserts.equals(
        env,
        found_pkl_config_java_jar.path,
        target_library_jar.path,
        "Expected to see the same pkl-config-java JAR file, but was different (expected: {}, found: {})".format(target_library_jar.path, found_pkl_config_java_jar.path),
    )

    return analysistest.end(env)

pkl_java_library_deps_test = analysistest.make(
    impl = _pkl_java_library_deps_test_impl,
    attrs = {
        "target_under_test": attr.label(
            doc = "The pkl_java_library under test.",
            mandatory = True,
            providers = [DefaultInfo, JavaInfo],
        ),
        "target_library": attr.label(
            doc = "The java_library target whose output JAR we want to find.",
            providers = [JavaInfo],
            mandatory = True,
        ),
    },
)
