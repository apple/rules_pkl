#!/usr/bin/env bash
set -eufo pipefail

VERSION="$1"

# Check that the tag exists
[[ -z "$(git tag -l v${VERSION})" ]] && echo "Unknown tag: ${VERSION}" && exit

ARCHIVE_NAME="rules_pkl-${VERSION}.tar.gz"

# Note: we use `.gitattributes` to filter things from the release archive
git archive --format=tar --prefix=rules_pkl-${VERSION}/ "v${VERSION}" | gzip > "${ARCHIVE_NAME}"
gh release upload "v${VERSION}" "${ARCHIVE_NAME}" --clobber
