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
Export rules_pkl dependencies.
"""

load("//pkl/private:constants.bzl", _PKL_DEPS = "PKL_DEPS")
load("//pkl/private:pkl_project.bzl", _parse_pkl_project_deps_json = "parse_pkl_project_deps_json", _pkl_project = "pkl_project")
load("//pkl/private:remote_pkl_package.bzl", _remote_pkl_package = "remote_pkl_package")

PKL_DEPS = _PKL_DEPS
pkl_project = _pkl_project
parse_pkl_project_deps_json = _parse_pkl_project_deps_json
remote_pkl_package = _remote_pkl_package
