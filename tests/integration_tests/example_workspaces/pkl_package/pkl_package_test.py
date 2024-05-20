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

from pathlib import Path
from bazel_tools.tools.python.runfiles import runfiles


class TestPklPackage(unittest.TestCase):
    def test_contains_expected_artifacts(self):
        want_artifacts = [
            "mypackage@1.0.0",
            "mypackage@1.0.0.sha256",
            "mypackage@1.0.0.zip",
            "mypackage@1.0.0.zip.sha256",
        ]

        r = runfiles.Create()
        entry_point = Path(r.Rlocation("_main/"))
        self.assertTrue(entry_point.exists())

        got_artifacts = [f.name for f in entry_point.iterdir() if f.is_file()]
        self.assertTrue(all(item in got_artifacts for item in want_artifacts))


if __name__ == '__main__':
    unittest.main()
