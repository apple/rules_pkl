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
import unittest
import zipfile

from bazel_tools.tools.python.runfiles import runfiles


class TestPklDoc(unittest.TestCase):
    def test_contains_expected_files(self):
        want_files = [
            "index.html",
            "com.animals/1.2.3/Rabbits/Animal.html",

            "com.animals/1.2.3/Rabbits/index.html",
            "com.animals/1.2.3/package-data.json"
        ]

        r = runfiles.Create()
        path = r.Rlocation("_main/tests/pkl_doc/pkl_doc_docs.zip")

        with zipfile.ZipFile(path) as zf:
            got_files = zf.namelist()
        for want_file in want_files:
            self.assertIn(want_file, got_files)


if __name__ == "__main__":
    unittest.main()
