/*
 * Copyright © 2024-2025 Apple Inc. and the Pkl project authors. All rights reserved.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   https://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

package org.pkl_lang.bazel.symlinks;

import com.google.gson.Gson;
import com.google.gson.reflect.TypeToken;

import java.io.BufferedReader;
import java.io.FileReader;
import java.io.IOException;
import java.lang.reflect.Type;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Paths;
import java.util.Map;

class Symlinks {
    private static final Type MAP_TYPE = new TypeToken<Map<String, String>>() { }.getType();

    private Symlinks() {
    }

    public static void main(String[] args) throws IOException {
        if (args.length < 1) {
            throw new RuntimeException("Expected the first argument to be a path to a symlinks JSON file.");
        }

        var jsonFile = args[0];

        if (!Files.exists(Paths.get(args[0]))) {
            throw new RuntimeException("No symlinks JSON file exists at " + jsonFile);
        }

        try (
            FileReader file = new FileReader(jsonFile, StandardCharsets.UTF_8);
            BufferedReader buf = new BufferedReader(file);
        ) {
            var gson = new Gson();
            Map<String, String> symlinks = gson.fromJson(buf, MAP_TYPE);

            for (Map.Entry<String, String> entry : symlinks.entrySet()) {
                var target = Paths.get(entry.getKey()).toAbsolutePath().normalize();
                var link = Paths.get(entry.getValue()).toAbsolutePath().normalize();

                if (Files.exists(link)) {
                    continue;
                }

                Files.createDirectories(link.getParent());
                Files.copy(target, link);
            }
        }
    }
}
