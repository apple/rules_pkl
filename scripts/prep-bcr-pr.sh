#!/usr/bin/env bash
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

set -eufo pipefail

BCR_REPO="$1"
VERSION="$2"

ARCHIVE_URL="https://github.com/apple/rules_pkl/releases/download/v${VERSION}/rules_pkl-${VERSION}.tar.gz"
RULES_PKL_DIR="$(bazel info workspace)"
INPUT_JSON="$(mktemp)"

cd "${BCR_REPO}"

# Create the input file so we don't need to be prompted for anything
cat >"${INPUT_JSON}" <<EOF
{
    "build_file": null,
    "build_targets": [
        "@rules_pkl//pkl/..."
    ],
    "compatibility_level": "1",
    "deps": [],
    "matrix_platforms": ["debian11", "ubuntu2204", "macos", "macos_arm64"],
    "matrix_bazel_versions": ["8.x", "7.x"],
    "module_dot_bazel": "${RULES_PKL_DIR}/MODULE.bazel",
    "name": "rules_pkl",
    "patches": [],
    "presubmit_yml": null,
    "strip_prefix": "rules_pkl-${VERSION}",
    "test_module_build_targets": [
        "//..."
    ],
    "test_module_test_targets": [],
    "test_module_path": "examples",
    "url": "${ARCHIVE_URL}",
    "version": "${VERSION}"
}
EOF

bazel run //tools:add_module -- --input "${INPUT_JSON}"
