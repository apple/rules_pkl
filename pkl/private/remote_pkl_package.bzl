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
Repository rule for downloading remote Pkl packages.
"""

load(":pkl_package_names.bzl", "get_terminal_package_name")

def _remote_pkl_package_impl(rctx):
    if not rctx.attr.url.startswith("projectpackage://"):
        fail("URL does not look like a Pkl project:", rctx.attr.url)

    url = rctx.attr.url.replace("projectpackage://", "https://")
    url_without_scheme = url.removeprefix("https://")

    file_name = get_terminal_package_name(url)

    metadata_file = "package-1/%s/%s.json" % (url_without_scheme, file_name)
    package_archive = "package-1/%s/%s.zip" % (url_without_scheme, file_name)

    # Grab the JSON from the original location
    rctx.download(url, sha256 = rctx.attr.sha256, output = metadata_file)

    metadata = json.decode(rctx.read(metadata_file))
    rctx.download(metadata["packageZipUrl"], sha256 = metadata["packageZipChecksums"]["sha256"], output = package_archive)

    rctx.file(
        "BUILD.bazel",
        content = """
load("@rules_pkl//pkl/private:pkl_cache.bzl", "pkl_cached_package")

package(default_visibility = ["//visibility:public"])

pkl_cached_package(
    name = "item",
    package_name = %s,
    json = %s,
    zip = %s,
)
""" % (repr(url_without_scheme), repr(metadata_file), repr(package_archive)),
    )

remote_pkl_package = repository_rule(
    _remote_pkl_package_impl,
    attrs = {
        "url": attr.string(
            doc = "URL of the package metadata file.",
            mandatory = True,
        ),
        "sha256": attr.string(
            doc = "SHA256 hash of the package's metadata file.",
            mandatory = True,
        ),
    },
)
