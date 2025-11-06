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

"""Hawkeye bzlmod extensions"""

load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

HAWKEYE_COORDINATES = [
    {
        "name": "hawkeye-aarch64-apple-darwin",
        "url": "https://github.com/korandoru/hawkeye/releases/download/v6.0.2/hawkeye-aarch64-apple-darwin.tar.xz",
        "sha256": "9f300ad84201e500c4eb09ed710239797d2a6a17de5b7c08e1d3af1704ca6bb7",
    },
    {
        "name": "hawkeye-x86_64-apple-darwin",
        "url": "https://github.com/korandoru/hawkeye/releases/download/v6.0.2/hawkeye-x86_64-apple-darwin.tar.xz",
        "sha256": "6f8850adb9204b6218f4912fb987106a71fcd8d742ce20227697ddccc44cec38",
    },
    {
        "name": "hawkeye-x86_64-unknown-linux-gnu",
        "url": "https://github.com/korandoru/hawkeye/releases/download/v6.0.2/hawkeye-x86_64-unknown-linux-gnu.tar.xz",
        "sha256": "d5b9d3cdb4293ac84fa27e5021c77b6c062c61071760ab05fcacfbec1ac14850",
    },
]

def _hawkeye_impl(_ctx):
    for coords in HAWKEYE_COORDINATES:
        http_archive(
            name = coords["name"],
            build_file = "//tools/lint/hawkeye:hawkeye.BUILD",
            sha256 = coords["sha256"],
            strip_prefix = coords["name"],
            url = coords["url"],
        )

hawkeye = module_extension(implementation = _hawkeye_impl)
