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

VERSION="$1"

# Check that the tag exists
[[ -z "$(git tag -l v${VERSION})" ]] && echo "Unknown tag: ${VERSION}" && exit

ARCHIVE_NAME="rules_pkl-${VERSION}.tar.gz"

# Note: we use `.gitattributes` to filter things from the release archive
git archive --format=tar --prefix=rules_pkl-${VERSION}/ "v${VERSION}" | gzip > "${ARCHIVE_NAME}"
gh release upload --repo github.com/apple/rules_pkl "v${VERSION}" "${ARCHIVE_NAME}" --clobber
