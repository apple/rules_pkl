/*
 * Copyright © 2024-2026 Apple Inc. and the Pkl project authors. All rights reserved.
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

import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Paths;
import java.util.List;

class Symlinks {
    private Symlinks() {
    }

    public static void main(String[] args) throws IOException {
        if (args.length < 2) {
            throw new RuntimeException("Expected arguments: a path to a symlinks file and a working directory.");
        }

        var symlinksFile = Paths.get(args[0]);
        var workingDir = Paths.get(args[1]);

        if (!Files.exists(symlinksFile)) {
            throw new RuntimeException("No symlinks file exists at " + symlinksFile);
        }

        // The file consists of pairs of lines: the file to copy, followed by where to copy it to (relative to the working directory).
        List<String> lines = Files.readAllLines(symlinksFile, StandardCharsets.UTF_8);
        if (lines.size() % 2 != 0) {
            throw new RuntimeException("Expected the symlinks file to contain pairs of lines: " + symlinksFile);
        }

        for (int i = 0; i < lines.size(); i += 2) {
            var target = Paths.get(lines.get(i)).toAbsolutePath().normalize();
            var link = workingDir.resolve(lines.get(i + 1)).toAbsolutePath().normalize();

            if (Files.exists(link)) {
                continue;
            }

            Files.createDirectories(link.getParent());
            Files.copy(target, link);
        }
    }
}
