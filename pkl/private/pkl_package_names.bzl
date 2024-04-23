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
Functionality for working with Pkl Package names.
"""

_TRANSFORM_TO_UNDERSCORE = ["/", "@", ".", "-"]

def transform_package_url_to_workspace_name(name):
    """Transforms a Pkl package url into a corresponding workspace name.

    Args:
        name: Url of Pkl package.
    Returns:
        A valid workspace name for the Pkl package.
    """

    if "://" not in name:
        fail("Name does not look like it's a URL. ", name)

    to_return = name.partition("://")[2]

    for symbol in _TRANSFORM_TO_UNDERSCORE:
        to_return = to_return.replace(symbol, "_")

    return to_return

def get_terminal_package_name(url):
    return url.rpartition("/")[2]
