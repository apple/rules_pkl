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
"""
Constants.
"""

PKL_DEPS = {
    "0.26.1": [
        "org.pkl-lang:pkl-doc:0.26.1",
        "org.pkl-lang:pkl-tools:0.26.1",
        "com.google.code.gson:gson:2.10.1",
    ],
    "0.26.3": [
        "org.pkl-lang:pkl-doc:0.26.3",
        "org.pkl-lang:pkl-tools:0.26.3",
        "com.google.code.gson:gson:2.10.1",
    ],
}

VERSIONS = {
    "0.26.1": {
        "macos-aarch64": "2913405367694d3ac37e58200095b99a6ae61fe50a2b3ec5f5c9f49cf05484e2",
        "macos-amd64": "2668d3f6398dcbacdcc633bc0cca71741ff64ae6824a221e719da5b3de72aa39",
        "linux-aarch64": "d953e2908d13e1fcc90b4807de9d2d49dc879efcb110dcc7a97b27ef4a9fddf7",
        "linux-amd64": "9c9692c8585ff3effd8a4f9c1ada62b99b292a40525a801145560a562730f946",
    },
    "0.26.3": {
        "macos-aarch64": "07002064e60f2b911db9f04798de29345c83155a0b140bf0852296761dbd83a0",
        "macos-amd64": "80a7ba06439c6c09468f83173f8ef72c042144a1414aee0d2c6c043d691f8fa4",
        "linux-aarch64": "fd4ade3411d382eaf3685edf1a976e3244ff4999fde0f5a470ee549f9aed8e6e",
        "linux-amd64": "34a082cb603b7924788762058a230e238b6b3e1b5c525549fac5a0765769c47e",
    },
}
