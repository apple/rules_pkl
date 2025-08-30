#!/usr/bin/env bash

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

test_output=$(cat bazel-testlogs/**/test.xml)

echo $test_output

if [ -z "${test_output}" ]; then
    echo "Expected test.xml output, got none"
    exit 1
fi


if [[ -n "${XML_EXPECTED_CONTENT}" ]]; then
    if [[ $test_output != *"${XML_EXPECTED_CONTENT}"* ]]; then
        echo "Missing expected '${XML_EXPECTED_CONTENT}' in test.xml"
        exit 1
    fi
fi


exit $ret
