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

import os
import unittest
import zipfile

from pathlib import Path
from python.runfiles import runfiles


class PklPackageExternalStripPrefixTest(unittest.TestCase):
    def test_zipfile_contains_srcs_with_strip_prefix(self):
        r = runfiles.Create()
        package_dir = Path(r.Rlocation(os.environ["PKL_PACKAGE_DIR"]))

        zip_files = [item for item in package_dir.iterdir() if item.is_file() and item.suffix == ".zip"]
        self.assertEqual(len(zip_files), 1, zip_files)

        with zipfile.ZipFile(zip_files[0], "r") as zipped:
            srcs = sorted(name for name in zipped.namelist() if not name.endswith("/"))

        # The `srcs/` prefix is stripped relative to the external repository's
        # root, and nothing of the `../<repo>/` part of their `short_path` remains.
        self.assertEqual(srcs, ["pkg1/tortoise.pkl", "pkg2/hare-generated.pkl"])


if __name__ == "__main__":
    unittest.main()
