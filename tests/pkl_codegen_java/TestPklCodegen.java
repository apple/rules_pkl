import org.junit.Test;

import static org.junit.Assert.assertEquals;

import org.pkl.config.java.ConfigEvaluator;
import org.pkl.config.java.Config;
import org.pkl.config.java.JavaType;
import org.pkl.core.ModuleSource;

import java.util.List;

import org.Dogs;


public class TestPklCodegen {
    @Test
    public void verifyReadingPklFiles() {
        ConfigEvaluator evaluator = ConfigEvaluator.preconfigured();
        Config config = evaluator.evaluate(ModuleSource.modulePath("srcs/litter.pkl"));

        org.Dogs.Litter actual = config.get("puppies").as(JavaType.of(Dogs.Litter.class));
        org.Dogs.Litter expected = new org.Dogs.Litter(List.of(new Dogs.Dog("Bruno"), new Dogs.Dog("Bruce")));

        assertEquals(expected, actual);
    }

    @Test
    public void verifyGeneratedClasses() {
        org.Dogs.Litter litter = new org.Dogs.Litter(List.of(
                new Dogs.Dog("A"),
                new Dogs.Dog("B")
        ));

        org.Dogs.Litter expected = new org.Dogs.Litter(List.of(new Dogs.Dog("A"), new Dogs.Dog("B")));

        assertEquals(expected, litter);
    }

}
