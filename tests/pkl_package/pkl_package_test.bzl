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

"""Tests for the pkl_package rule."""

load("@bazel_skylib//lib:unittest.bzl", "analysistest", "asserts", "unittest")
load("//pkl:defs.bzl", "pkl_package")
load("//pkl/private:pkl_project_rule.bzl", "pkl_project_rule")  # buildifier: disable=bzl-visibility
load("//pkl/private:providers.bzl", "PklPackageInfo")  # buildifier: disable=bzl-visibility

def _pkl_package_test_impl(ctx):
    env = analysistest.begin(ctx)
    target = analysistest.target_under_test(env)
    package_info = target[PklPackageInfo]
    asserts.true(env, package_info.pkl_package_dir.is_directory)
    asserts.equals(env, "package.name", package_info.name_file.basename)
    asserts.equals(env, "package.version", package_info.version_file.basename)
    asserts.equals(env, "package.base_uri", package_info.base_uri_file.basename)
    asserts.equals(env, "package.package_zip_url", package_info.package_zip_url_file.basename)
    return analysistest.end(env)

pkl_package_test = analysistest.make(_pkl_package_test_impl)

def _pkl_package_contents_test_impl(ctx):
    package_info = ctx.attr.pkl_package_under_test[PklPackageInfo]
    test_script = ctx.outputs.executable

    ctx.actions.write(
        test_script,
        """
        set -eu -o pipefail

        assert_equals() {{
          local expect=$1
          local actual=$2
          local subject=${{3:+ for \\'$3\\'}}

          if [[ "$expect" != "$actual" ]]; then
            echo "Assertion failed${{subject:-}}: expected '$expect' but got: '$actual'." >&2
            exit 1
          fi
        }}

        assert_exists() {{
          local file_path=$1
          local subject=${{2:+ for \\'$2\\'}}

          if ! [[ -e "$file_path" ]]; then
            echo "Assertion failed${{subject:-}}: expected '$file_path' to exist but it doesn't" >&2
            exit 1
          fi
        }}

        name_file={name_file}
        version_file={version_file}
        base_uri_file={base_uri_file}
        package_zip_url_file={package_zip_url_file}
        pkl_package_dir_file={pkl_package_dir_file}

        name=$(cat "$name_file")
        version=$(cat "$version_file")
        base_uri=$(cat "$base_uri_file")
        package_zip_url=$(cat "$package_zip_url_file")

        assert_equals "{expected_name}" "$name" "name file contents"
        assert_equals "{expected_version}" "$version" "version file contents"
        assert_equals "{expected_base_uri}" "$base_uri" "base_uri file contents"
        assert_equals "{expected_package_zip_url}" "$package_zip_url" "package_zip_url file contents"

        echo "Contents of $pkl_package_dir_file:" >&2
        ls "$pkl_package_dir_file" >&2

        basename="${{name}}@${{version}}"
        assert_exists "$pkl_package_dir_file/$basename.zip"
        assert_exists "$pkl_package_dir_file/$basename.zip.sha256"
        assert_exists "$pkl_package_dir_file/$basename"
        assert_exists "$pkl_package_dir_file/$basename.sha256"

        """.format(
            name_file = package_info.name_file.short_path,
            version_file = package_info.version_file.short_path,
            base_uri_file = package_info.base_uri_file.short_path,
            package_zip_url_file = package_info.package_zip_url_file.short_path,
            pkl_package_dir_file = package_info.pkl_package_dir.short_path,
            expected_name = ctx.attr.expected_name,
            expected_version = ctx.attr.expected_version,
            expected_base_uri = ctx.attr.expected_base_uri,
            expected_package_zip_url = ctx.attr.expected_package_zip_url,
        ),
        is_executable = True,
    )
    return [DefaultInfo(
        runfiles = ctx.runfiles(files = [
            package_info.name_file,
            package_info.version_file,
            package_info.base_uri_file,
            package_info.package_zip_url_file,
            package_info.pkl_package_dir,
        ]),
    )]

pkl_package_contents_test = rule(
    implementation = _pkl_package_contents_test_impl,
    attrs = {
        "pkl_package_under_test": attr.label(mandatory = True),
        "expected_name": attr.string(mandatory = True),
        "expected_version": attr.string(mandatory = True),
        "expected_base_uri": attr.string(mandatory = True),
        "expected_package_zip_url": attr.string(mandatory = True),
    },
    test = True,
)

unittest.make(
    _pkl_package_contents_test_impl,
    attrs = {"target_under_test": attr.label()},
)

def pkl_package_test_suite(name):
    pkl_project_rule(
        name = "project",
        pkl_project_file = "//tests/pkl_package:PklProject",
        pkl_project_deps = "//tests/pkl_package:PklProject.deps.json",
    )
    pkl_package(
        name = "package",
        project = ":project",
    )
    pkl_package_test(
        name = "pkl_package_test",
        target_under_test = ":package",
    )
    pkl_package_contents_test(
        name = "pkl_package_contents_test",
        pkl_package_under_test = ":package",
        expected_name = "my-package",
        expected_version = "1.2.3",
        expected_base_uri = "package://example.com/my-package",
        expected_package_zip_url = "https://example.com/my-package/my-package@1.2.3.zip",
    )
