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

import os
import unittest
import zipfile
import tempfile

from pathlib import Path
from bazel_tools.tools.python.runfiles import runfiles


class TestPklPackage(unittest.TestCase):
    def test_contains_expected_artifacts(self):
        want_artifacts = [
            "package_version_override@3.0.0",
            "package_version_override@3.0.0.sha256",
            "package_version_override@3.0.0.zip",
            "package_version_override@3.0.0.zip.sha256",
        ]

        r = runfiles.Create()
        entry_point = Path(r.Rlocation("_main/"))
        self.assertTrue(entry_point.exists())

        got_artifacts = [f.name for f in entry_point.iterdir() if f.is_file()]
        self.assertTrue(all(item in got_artifacts for item in want_artifacts))

    def test_zipfile_contains_srcs(self):
        r = runfiles.Create()
        entry_point = Path(r.Rlocation("_main/"))

        zip_file = None
        for item in entry_point.iterdir():
            if item.is_file() and item.suffix == ".zip":
                zip_file = item
                break

        self.assertIsNotNone(zip_file)

        with tempfile.TemporaryDirectory() as temp_dir:
            extract_to = Path(temp_dir)

            with zipfile.ZipFile(zip_file, "r") as zipped:
                zipped.extractall(extract_to)

            want_srcs = [extract_to/"srcs/pkg1/tortoise.pkl", "srcs/pkg2/hare-generated.pkl"]

            for src in want_srcs:
                file_path = extract_to / src
                self.assertTrue(file_path.exists())

if __name__ == '__main__':
    unittest.main()
