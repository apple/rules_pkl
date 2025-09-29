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
Constants.
"""

PKL_DEPS = {
    "0.29.1": [
        "org.pkl-lang:pkl-tools:0.29.1",
        "com.google.code.gson:gson:2.13.1",
    ],
    "0.29.0": [
        "org.pkl-lang:pkl-tools:0.29.0",
        "com.google.code.gson:gson:2.13.1",
    ],
}

VERSIONS = {
    "0.29.1": {
        "macos-aarch64": "75ca92e3eee7746e22b0f8a55bf1ee5c3ea0a78eec14586cd5618a9195707d5c",
        "macos-amd64": "8561a2c9d0e01bf15d54905ad8bacdb1e40bb6e241f6e158d10dc9bc69547c09",
        "linux-aarch64": "e70ab2124748c3c10ffc789ee2961a43d7e5d5cb070cdaba88cf33b7ab1fd9bc",
        "linux-amd64": "0925a87b00f19d40c4cf8a3eadb0b2af3138f2a8c15071966d51f5c737b42804",
    },
    "0.29.0": {
        "macos-aarch64": "7d6028c3d37c205c0e5d43018a2b04b5252a6805a649a86612f2e43074a6a4d5",
        "macos-amd64": "4109af39172d4f97dc0bcadce513754d9447f208c69b78418d1afb4a5e71ebe3",
        "linux-aarch64": "f6f867a4d6c0064ab3cddbef94ccc97ab067acc1b73397f857f0abfe3168408c",
        "linux-amd64": "0882dbb511735b7282e9708399e5a372efc966827e45f9ffbc4034ca77f8f65a",
    },
}
