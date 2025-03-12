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

# Patch the version number in our MODULE.bazel
cat MODULE.bazel | \
  awk -vversion=${VERSION} 'BEGIN {matched=0} /version = / {if (matched) { print $0 } else { print "    version = \"" version "\","; matched=1}} !/version = / {print $0}' >MODULE.tmp && \
  mv MODULE.tmp MODULE.bazel
git diff MODULE.bazel >"${RULES_PKL_DIR}/update-version.patch"

cd "${BCR_REPO}"

# Create the input file so we don't need to be prompted for anything
cat >"${INPUT_JSON}" <<EOF
{
    "build_file": null,
    "build_targets": [
        "@rules_pkl//..."
    ],
    "compatibility_level": "1",
    "deps": [],
    "module_dot_bazel": "${RULES_PKL_DIR}/MODULE.bazel",
    "name": "rules_pkl",
    "patch_strip": 1,
    "patches": [
        "${RULES_PKL_DIR}/update-version.patch"
    ],
    "presubmit_yml": null,
    "strip_prefix": "rules_pkl-${VERSION}",
    "test_module_build_targets": [
        "//..."
    ],
    "test_module_path": "examples/pkl_project",
    "test_module_test_targets": [
        "//..."
    ],
    "url": "${ARCHIVE_URL}",
    "version": "${VERSION}"
}
EOF

bazel run //tools:add_module -- --input "${INPUT_JSON}"
