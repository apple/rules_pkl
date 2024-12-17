#!/usr/bin/env bash

set -eufo pipefail

WORKING_DIRECTORY="${1}"

ROOT_BAZEL_VERSION="${WORKING_DIRECTORY}/.bazelversion"

BAZEL_VERSIONS=$(find "${WORKING_DIRECTORY}" -name .bazelversion)

for BAZEL_VERSION in ${BAZEL_VERSIONS}; do
  cmp -b "${ROOT_BAZEL_VERSION}" "${BAZEL_VERSION}"
done

echo "All .bazelversion files are identical"
