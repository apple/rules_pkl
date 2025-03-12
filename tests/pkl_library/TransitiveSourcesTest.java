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

package tests.pkl_library;

import com.google.devtools.build.runfiles.Runfiles;

import java.io.IOException;
import java.nio.file.Paths;
import java.util.Arrays;
import java.util.stream.Collectors;
import java.util.stream.Stream;

import org.junit.Test;

import static org.junit.Assert.assertEquals;

public class TransitiveSourcesTest {
    @Test
    public void testContainsExpectedFiles() throws IOException {
        var expectedFiles = Stream.of(
                        "tests/pkl_library/srcs/animals.pkl",
                        "tests/pkl_library/srcs/horse.pkl"
                )
                .map(Paths::get)
                .collect(Collectors.toSet());

        var runfiles = Runfiles.preload().unmapped();
        var runfilesDir = Paths.get(runfiles.getEnvVars().get("RUNFILES_DIR"), "_main");

        System.out.println("_main: " + runfiles.rlocation("_main"));

        var transitionSourceEnv = System.getenv("TRANSITIVE_SOURCES").split(" ");
        var transitionSources = Arrays.stream(transitionSourceEnv)
                .map(runfiles::rlocation)
                .map(Paths::get)
                .map(runfilesDir::relativize)
                .collect(Collectors.toSet());

        assertEquals(expectedFiles, transitionSources);
    }
}
