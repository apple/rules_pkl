#!/usr/bin/env bash

set -eufo pipefail

WORKING_DIRECTORY="${1}"

ROOT_BAZEL_VERSION="${WORKING_DIRECTORY}/.bazelversion"
ROOT_BAZEL_MODULE="${WORKING_DIRECTORY}/MODULE.bazel"

BAZEL_VERSIONS=$(find "${WORKING_DIRECTORY}" -name .bazelversion)

for BAZEL_VERSION in ${BAZEL_VERSIONS}; do
  cmp -b "${ROOT_BAZEL_VERSION}" "${BAZEL_VERSION}"
done

if ! grep -q "bazel_binaries.download(version = \"$(cat "${ROOT_BAZEL_VERSION}")\")" "${ROOT_BAZEL_MODULE}"; then
  echo "${ROOT_BAZEL_MODULE} 'bazel_binaries.download' version doesn't match .bazelversion"
  echo "Expected: bazel_binaries.download(version = \"$(cat "${ROOT_BAZEL_VERSION}")\")"
  echo "Found:    $(grep -E "^bazel_binaries.download" "${ROOT_BAZEL_MODULE}")"
  exit 1
fi

echo "All .bazelversion files are identical"
