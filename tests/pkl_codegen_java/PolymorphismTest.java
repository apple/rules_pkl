/*
 * Copyright © 2025-2026 Apple Inc. and the Pkl project authors. All rights reserved.
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

import static org.junit.Assert.*;

import org.Animals;
import org.junit.Test;
import org.pkl.config.java.Config;
import org.pkl.config.java.ConfigEvaluator;
import org.pkl.config.java.JavaType;
import org.pkl.core.ModuleSource;

public class PolymorphismTest {

  @Test
  public void testPolymorphicDeserialization() {
    // Evaluate and deserialize using the mapper
    try (ConfigEvaluator evaluator = ConfigEvaluator.preconfigured()) {
      Config config = evaluator.evaluate(ModuleSource.modulePath("srcs/shelter.pkl"));
      var shelter = config.get("shelter").as(JavaType.of(Animals.Shelter.class));

      // Verify we got the right number of animals
      assertEquals(3, shelter.getAnimals().size());

      // Verify polymorphic deserialization worked correctly
      var animals = shelter.getAnimals();

      // First animal should be a Dog
      assertTrue("First animal should be a Dog", animals.get(0) instanceof Animals.Dog);
      Animals.Dog dog1 = (Animals.Dog) animals.get(0);
      assertEquals("Buddy", dog1.getName());
      assertEquals("Golden Retriever", dog1.getBreed());

      // Second animal should be a Cat
      assertTrue("Second animal should be a Cat", animals.get(1) instanceof Animals.Cat);
      Animals.Cat cat = (Animals.Cat) animals.get(1);
      assertEquals("Whiskers", cat.getName());
      assertEquals("Orange", cat.getColor());

      // Third animal should be a Dog
      assertTrue("Third animal should be a Dog", animals.get(2) instanceof Animals.Dog);
      Animals.Dog dog2 = (Animals.Dog) animals.get(2);
      assertEquals("Max", dog2.getName());
      assertEquals("German Shepherd", dog2.getBreed());
      assertEquals("Dog {\n  name = Max\n  age = 30.d\n  breed = German Shepherd\n}", dog2.toString());
    }
  }
}
