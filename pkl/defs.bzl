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
Public API re-exports
"""

load(
    "//pkl/private:pkl.bzl",
    _pkl_eval = "pkl_eval",
    _pkl_test = "pkl_test",
)
load(
    "//pkl/private:pkl_codegen.bzl",
    _pkl_config_java_library = "pkl_config_java_library",
    _pkl_config_src = "pkl_config_src",
)
load(
    "//pkl/private:pkl_doc.bzl",
    _pkl_doc = "pkl_doc",
)
load(
    "//pkl/private:pkl_library.bzl",
    _pkl_library = "pkl_library",
)
load(
    "//pkl/private:pkl_package.bzl",
    _pkl_package = "pkl_package",
)
load(
    "//pkl/private:pkl_test_suite.bzl",
    _pkl_test_suite = "pkl_test_suite",
)
load(
    "//pkl/private:toolchain.bzl",
    _pkl_codegen_java_toolchain = "pkl_codegen_java_toolchain",
    _pkl_doc_toolchain = "pkl_doc_toolchain",
    _pkl_toolchain = "pkl_toolchain",
)

pkl_codegen_java_toolchain = _pkl_codegen_java_toolchain
pkl_config_java_library = _pkl_config_java_library
pkl_config_src = _pkl_config_src
pkl_doc = _pkl_doc
pkl_doc_toolchain = _pkl_doc_toolchain
pkl_library = _pkl_library
pkl_eval = _pkl_eval
pkl_package = _pkl_package
pkl_test = _pkl_test
pkl_test_suite = _pkl_test_suite
pkl_toolchain = _pkl_toolchain
