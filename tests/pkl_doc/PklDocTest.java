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

package tests.pkl_doc;

import com.google.devtools.build.runfiles.Runfiles;

import java.io.IOException;
import java.nio.file.FileSystem;
import java.nio.file.FileSystems;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.Set;
import java.util.stream.Collectors;

import org.junit.Test;

import static org.junit.Assert.assertTrue;


public class PklDocTest {
    @Test
    public void testContainsExpectedFiles() throws IOException {
        var expectedFiles = Set.of(
                "/index.html",
                "/com.animals/1.2.3/Rabbits/Animal.html",
                "/com.animals/1.2.3/Rabbits/index.html",
                "/com.animals/1.2.3/package-data.json"
        );

        var runfiles = Runfiles.preload().unmapped();
        var docsZipPath = Paths.get(runfiles.rlocation("_main/tests/pkl_doc/pkl_doc_docs.zip"));
        var contents = listZipContents(docsZipPath);

        for (var expectedFile : expectedFiles) {
            assertTrue("looking for: %s".formatted(expectedFile), contents.contains(expectedFile));
        }
    }

    private Set<String> listZipContents(Path zipFilePath) throws IOException {
        try (FileSystem zipFs = FileSystems.newFileSystem(zipFilePath)) {
            // Get the root path inside the ZIP
            Path root = zipFs.getPath("/");

            // Walk through all entries in the ZIP
            return Files.walk(root)
                    .filter(path -> !path.equals(root))
                    .filter(path -> !Files.isDirectory(path))
                    .map(path -> path.toString())
                    .collect(Collectors.toSet());
        }
    }
}
