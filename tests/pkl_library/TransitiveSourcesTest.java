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
