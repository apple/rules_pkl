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
