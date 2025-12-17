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
Repository rules for defining dependencies.
"""

load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_file")
load("@bazel_tools//tools/build_defs/repo:utils.bzl", "maybe")
load("@rules_jvm_external//:defs.bzl", "maven_install")
load("//pkl/private:constants.bzl", "DOC_VERSIONS", "PKL_DEPS", "VERSIONS")
load("//pkl/private:repositories.bzl", _project_cache_path_and_dependencies = "root_caches_and_dependencies")

DEFAULT_PKL_VERSION = "0.30.2"

def pkl_cli_binaries(version = DEFAULT_PKL_VERSION):
    """
    Sets up the `http_file` repositories for the Pkl binaries.

    Args:
      version: the Pkl version you want to use

    Returns:
      A list of the binary names.
    """
    binary_names = []

    for arch, sha256 in VERSIONS[version].items():
        cli_name = "pkl-cli-{arch}".format(arch = arch)
        binary_names.append(cli_name)

        maybe(
            http_file,
            name = cli_name,
            url = "https://github.com/apple/pkl/releases/download/{version}/pkl-{arch}".format(version = version, arch = arch),
            sha256 = sha256,
            executable = True,
        )

    return binary_names

def pkl_doc_cli_binaries(version = DEFAULT_PKL_VERSION):
    """
    Sets up the `http_file` repositories for the Pkl doc binaries.

    Args:
      version: the Pkl version you want to use

    Returns:
      A list of the binary names.
    """
    binary_names = []

    for arch, sha256 in DOC_VERSIONS[version].items():
        cli_name = "pkl-doc-cli-{arch}".format(arch = arch)
        binary_names.append(cli_name)

        maybe(
            http_file,
            name = cli_name,
            url = "https://github.com/apple/pkl/releases/download/{version}/pkldoc-{arch}".format(version = version, arch = arch),
            sha256 = sha256,
            executable = True,
        )

    return binary_names

def pkl_setup(version = DEFAULT_PKL_VERSION):
    """
    Setup all repositories for Pkl.

    Args:
          version: the Pkl version you want to use
    """

    pkl_cli_binaries(version)

    maven_install(
        name = "rules_pkl_deps",
        artifacts = PKL_DEPS[version],
        repositories = [
            "https://repo1.maven.org/maven2/",
        ],
    )

project_cache_path_and_dependencies = _project_cache_path_and_dependencies
