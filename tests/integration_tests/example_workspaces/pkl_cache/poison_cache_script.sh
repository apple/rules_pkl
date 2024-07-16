#!/bin/bash
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

# Poisons a Pkl cache directory by editing the uris for a Pkl package and the PklProject and PklProject.deps.json files.
set -e

mangle_repository=$1
cache_dir=$2
pkl_project_dir=$3
pkl_project_new_path=$4
pkl_project_deps_new_path=$5
new_cache_dir=$6


# Find the json file of the cached Pkl package to poison.
json_file=$(find "$cache_dir" -name "*.json")

# Find the zip file of the cached Pkl package to poison.
zip_file=$(find . -name "*.zip")

# Copy PklProject and PklProject.deps.json to location where Bazel expects.
cp -RL "$pkl_project_dir/PklProject" "$pkl_project_new_path"
cp -L "$pkl_project_dir/PklProject.deps.json" "$pkl_project_deps_new_path"

# Remove symlinks from cache files.
cp -RL "$json_file" tmpjson.json
mv tmpjson.json  "$json_file"

cp -RL "$zip_file" tmpzip.zip
mv tmpzip.zip "$zip_file"


# Replace all occurrences of `$mangle_repository` with `doesnotexist-$mangle_repository'.
# i.e. replaces all occurrences of `pkg.pkl-lang.org` to `doesnotexist-pkg.pkl-lang.org`
sed -i.bak "s,$mangle_repository,doesnotexist-$mangle_repository,g" \
"$pkl_project_new_path" \
"$pkl_project_deps_new_path" \
"$json_file" \
"$zip_file"

# Move the poisoned cache package to its expected location based on the poisoned uri of the Pkl package.
mv "$cache_dir/package-2/$mangle_repository" "$cache_dir/package-2/doesnotexist-$mangle_repository"

mv "$cache_dir/package-2" "$new_cache_dir"
