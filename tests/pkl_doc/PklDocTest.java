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
