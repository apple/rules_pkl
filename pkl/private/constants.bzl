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
    "0.28.1": [
        "org.pkl-lang:pkl-tools:0.28.1",
        "com.google.code.gson:gson:2.12.1",
    ],
    "0.27.2": [
        "org.pkl-lang:pkl-tools:0.27.2",
        "com.google.code.gson:gson:2.10.1",
    ],
    "0.27.1": [
        "org.pkl-lang:pkl-tools:0.27.1",
        "com.google.code.gson:gson:2.10.1",
    ],
    "0.27.0": [
        "org.pkl-lang:pkl-tools:0.27.0",
        "com.google.code.gson:gson:2.10.1",
    ],
    "0.26.3": [
        "org.pkl-lang:pkl-doc:0.26.3",
        "org.pkl-lang:pkl-tools:0.26.3",
        "com.google.code.gson:gson:2.10.1",
    ],
    "0.26.1": [
        "com.google.code.gson:gson:2.10.1",
        "org.junit.vintage:junit-vintage-engine:5.7.0",
        "org.pkl-lang:pkl-codegen-java:0.26.1",
        "org.pkl-lang:pkl-config-java:0.26.1",
        "org.pkl-lang:pkl-doc:0.26.1",
        "org.pkl-lang:pkl-tools:0.26.1",
    ],
}

VERSIONS = {
    "0.28.1": {
        "macos-aarch64": "d393dedaa7067eb5c96ff99c89e73f463a96f64b4e231bfeee42b98547b10fe0",
        "macos-amd64": "5b09bd610dae5317a52ed0c34a58cd868bb1340ab1b9556359d1ac2373d1b254",
        "linux-aarch64": "20d74c09ef04520011ffbac22e567778ab2cae092afaa9269ee6ef2913e20f06",
        "linux-amd64": "fde743ed2a5fda1cc24ce2c9902ea0d1bc5e911a2df7847c74a77ce13056bf39",
    },
    "0.27.2": {
        "macos-aarch64": "e5d3ceaa776cbd43423c564e7ee1997a39ac219608ed86250c5be6298674fa9a",
        "macos-amd64": "e10afb55efb51c17a0461445237b4c02734693307d4e37e3bb936e77cf266b69",
        "linux-aarch64": "cb9fb3cad4b3016674b489363d45bb2dcc6676e3f133413ebae529d322075d45",
        "linux-amd64": "e220577f9d48d872e358e939702d3d38f34d4afd29aecd34cc96b5dc67d880d5",
    },
    "0.27.1": {
        "macos-aarch64": "195e6213deaf5c171846a0963b96ab7a6f0bb4eb2672762d2bab8a6363e47aa3",
        "macos-amd64": "100c5e9123576e21d1311f9c4e83da6f5c4cf8c7e721ec9b3668d35943ea24a5",
        "linux-aarch64": "56d13d340a397c47799bdaa18227a9546a5d0d5c1f117b11983900fd21b6a20a",
        "linux-amd64": "a78766b239442e341537c6fa8c4bfe95839f7765d58f81a3ac3c4b923a13a149",
    },
    "0.27.0": {
        "macos-aarch64": "33f9941c6830e6ff0ad0dcbe954ba028638a5c2b7c2f9d7c04b04c7dbc961432",
        "macos-amd64": "d64904d44f5e0db9d1c4cf69c32be45083daa0fdec02056a37b65d4020b3017b",
        "linux-aarch64": "e38c1102ce1b5fc453dc4fbc35b41b35907fe5ac84c1b7cbfb142d402fb77c07",
        "linux-amd64": "e4c76b6dd02456dac8d300ea1f1c50102f6414cb947567436477cbf7c2dab3aa",
    },
    "0.26.3": {
        "macos-aarch64": "07002064e60f2b911db9f04798de29345c83155a0b140bf0852296761dbd83a0",
        "macos-amd64": "80a7ba06439c6c09468f83173f8ef72c042144a1414aee0d2c6c043d691f8fa4",
        "linux-aarch64": "fd4ade3411d382eaf3685edf1a976e3244ff4999fde0f5a470ee549f9aed8e6e",
        "linux-amd64": "34a082cb603b7924788762058a230e238b6b3e1b5c525549fac5a0765769c47e",
    },
    "0.26.1": {
        "macos-aarch64": "2913405367694d3ac37e58200095b99a6ae61fe50a2b3ec5f5c9f49cf05484e2",
        "macos-amd64": "2668d3f6398dcbacdcc633bc0cca71741ff64ae6824a221e719da5b3de72aa39",
        "linux-aarch64": "d953e2908d13e1fcc90b4807de9d2d49dc879efcb110dcc7a97b27ef4a9fddf7",
        "linux-amd64": "9c9692c8585ff3effd8a4f9c1ada62b99b292a40525a801145560a562730f946",
    },
}
