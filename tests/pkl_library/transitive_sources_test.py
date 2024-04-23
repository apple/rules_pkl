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
import runfiles
import unittest
from pathlib import Path


class TestTransitiveSources(unittest.TestCase):
    def test_contains_expected_files(self):
        want_files = set(
            [
                Path(p)
                for p in [
                    "tests/pkl_library/srcs/animals.pkl",
                    "tests/pkl_library/srcs/horse.pkl",
                ]
            ]
        )

        r = runfiles.Create()
        own_repo = r.CurrentRepository()

        runfiles_root = Path(own_repo)
        path = runfiles_root / "tests" / "pkl_library" / "srcs"
        got_files = set(
            [p.relative_to(runfiles_root) for p in Path(path).glob("*")]
        )
        self.assertSetEqual(want_files, got_files)


if __name__ == "__main__":
    unittest.main()
