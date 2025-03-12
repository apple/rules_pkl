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
This test file is implemented as a `py_binary` to allow us to pass in the
WORKSPACE_ROOT, which isn't available to us through `py_test`, which is
sandboxed.
"""

import os
import re
import unittest

WORKING_DIRECTORY_ENV = "WORKING_DIRECTORY"
WORKING_DIRECTORY = os.getenv(WORKING_DIRECTORY_ENV)


class TestWorkingDirectory(unittest.TestCase):
    def test_not_none(self):
        self.assertIsNotNone(
            WORKING_DIRECTORY,
            f"Pass the root directory of this repository when running this test file by prefixing the command with {WORKING_DIRECTORY_ENV}=\"$(pwd)\""
        )


class TestBazelVersionFiles(unittest.TestCase):
    def setUp(self):
        self.root_bazel_version_path = f"{WORKING_DIRECTORY}/.bazelversion"

    def test_all_bazel_version_files_match(self):
        with open(self.root_bazel_version_path) as f:
            root_bazel_version = f.read().strip()

        bazel_version_file_count = 0
        for root, _, filenames in os.walk(WORKING_DIRECTORY):
            for filename in filenames:
                path = os.path.join(root, filename)

                if path.endswith("/.bazelversion"):
                    bazel_version_file_count += 1
                    with open(path) as f:
                        content = f.read().strip()
                        self.assertEqual(root_bazel_version, content, f"path: {path}")

        self.assertGreater(
            bazel_version_file_count,
            2,
            "we should find more than 2 .bazelversion files"
        )

    def test_bazel_binaries_matches_bazel_version(self):
        with open(self.root_bazel_version_path) as f:
            root_bazel_version = f.read().strip()

        root_bazel_module_path = f"{WORKING_DIRECTORY}/MODULE.bazel"
        with open(root_bazel_module_path) as f:
            content = f.read().strip()
            self.assertIn(
                f"bazel_binaries.download(version = \"{root_bazel_version}\"",
                content,
                f"Content of '{self.root_bazel_version_path}' didn't match '{root_bazel_module_path}'"
            )


class TestPklModuleVersion(unittest.TestCase):
    def test_readme_matches_module(self):
        root_bazel_module_path = f"{WORKING_DIRECTORY}/MODULE.bazel"
        with open(root_bazel_module_path) as f:
            root_bazel_module = f.read().strip()

        root_readme_path = f"{WORKING_DIRECTORY}/README.md"
        with open(root_readme_path) as f:
            root_bazel_readme = f.read().strip()

        pattern = re.compile(r"version = \"(\d+.\d+.\d+)\"")
        self.assertEqual(
            pattern.findall(root_bazel_readme)[0],
            pattern.findall(root_bazel_module)[0],
            f"`version` provided in '{root_readme_path}' didn't match '{root_bazel_module_path}'"
        )


if __name__ == "__main__":
    unittest.main()
