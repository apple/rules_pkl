#!/usr/bin/env bash
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

# This script runs bazel integration tests and verifies there's an expected junit xml output.
# Also checks availability of XML_EXPECTED_CONTENT env variable content inside test output.

exit_with_msg() {
  echo >&2 "${@}"
  exit 1
}

bazel="${BIT_BAZEL_BINARY:-}"
workspace_dir="${BIT_WORKSPACE_DIR:-}"

[[ -n "${bazel:-}" ]] || exit_with_msg "Must specify the location of the Bazel binary."
[[ -n "${workspace_dir:-}" ]] || exit_with_msg "Must specify the path of the workspace directory."

cd "${workspace_dir}" || exit

"${bazel}" test //...
ret=$?

xml_files=(bazel-testlogs/**/test.xml)
if [[ ${#xml_files[@]} -eq 0 || ! -f "${xml_files[0]}" ]]; then
    exit_with_msg "No test.xml files found in bazel-testlogs"
fi

test_output=$(cat "${xml_files[@]}")

if [[ -n "${XML_EXPECTED_CONTENT}" ]]; then
    if [[ $test_output != *"${XML_EXPECTED_CONTENT}"* ]]; then
        exit_with_msg "Missing expected '${XML_EXPECTED_CONTENT}' in test.xml, got: '${test_output}'"
    fi
fi


exit $ret
