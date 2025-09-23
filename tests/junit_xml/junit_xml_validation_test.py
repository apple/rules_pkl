#!/usr/bin/env python3
# Copyright © 2025 Apple Inc. and the Pkl project authors. All rights reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#   https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

"""Test that validates the JUnit XML output from pkl_test."""

import os
import subprocess
import sys
import tempfile
import unittest
import xml.etree.ElementTree as ET

from pathlib import Path
from functools import cached_property


class JUnitXMLValidationTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        with tempfile.NamedTemporaryFile(suffix=".xml", delete=False) as xml_file:
            cls.xml_file = Path(xml_file.name)

        # Set environment and get script path
        env = os.environ | {"XML_OUTPUT_FILE": str(cls.xml_file)}
        script_path = os.environ.get("SAMPLE_XML_GENERATOR_PATH")

        if not script_path:
            raise RuntimeError("SAMPLE_XML_GENERATOR_PATH environment variable not set")

        # Run the pkl_test with XML output enabled
        try:
            result = subprocess.run(
                [script_path], env=env, capture_output=True, text=True, check=True
            )
        except subprocess.CalledProcessError as e:
            raise RuntimeError(
                f"""Failed to run pkl_test: {e}
                STDOUT:
                {result.stdout}
                STDERR:
                {result.stderr}
                """
            ) from e

        if not cls.xml_file.exists():
            raise RuntimeError(f"XML output file was not created at {cls.xml_file}")

    @cached_property
    def xml_root(self):
        return ET.parse(self.xml_file).getroot()

    def test_xml_file_exists_and_parseable(self):
        self.assertTrue(
            self.xml_file.exists(), f"XML file {self.xml_file} does not exist"
        )

        try:
            self.assertIsNotNone(self.xml_root)
        except ET.ParseError as e:
            self.fail(f"Failed to parse XML: {e}")

    def test_root_element_structure(self):
        root = self.xml_root

        self.assertEqual(
            root.tag,
            "testsuites",
            f"Root element should be 'testsuites', got '{root.tag}'",
        )

        required_attrs = ["name", "tests", "failures"]
        missing_attrs = [attr for attr in required_attrs if attr not in root.attrib]
        self.assertFalse(
            missing_attrs, f"testsuites missing attributes: {missing_attrs}"
        )

        self.assertEqual(root.attrib["name"], "tests.junit_xml.sample_xml_generator")

    def test_testsuite_structure(self):
        testsuites = self.xml_root.findall("testsuite")
        self.assertGreater(len(testsuites), 0, "No testsuite elements found")

        required_attrs = ["name", "tests", "failures"]
        for i, testsuite in enumerate(testsuites):
            missing_attrs = [
                attr for attr in required_attrs if attr not in testsuite.attrib
            ]
            self.assertFalse(
                missing_attrs, f"testsuite {i} missing attributes: {missing_attrs}"
            )

    def test_testcase_structure(self):
        testcases = self.xml_root.findall(".//testcase")
        self.assertGreater(len(testcases), 0, "No testcase elements found")

        required_attrs = ["name", "classname"]
        for i, testcase in enumerate(testcases):
            missing_attrs = [
                attr for attr in required_attrs if attr not in testcase.attrib
            ]
            self.assertFalse(
                missing_attrs, f"testcase {i} missing attributes: {missing_attrs}"
            )

    def test_expected_test_cases(self):
        testcases = self.xml_root.findall(".//testcase")
        testcase_names = {tc.attrib["name"] for tc in testcases}
        expected_names = {"dummy test line item 1", "dummy test line item 2"}
        missing_names = expected_names - testcase_names
        self.assertFalse(
            missing_names, f"Expected test cases not found: {missing_names}"
        )

    def test_xml_declaration(self):
        content = self.xml_file.read_text()
        self.assertIn("<?xml version", content, "XML declaration not found")

    def test_suite_name_matches_target(self):
        expected_name = "tests.junit_xml.sample_xml_generator"
        self.assertEqual(
            self.xml_root.attrib["name"],
            expected_name,
            "Root testsuites name should match target path",
        )


if __name__ == "__main__":
    unittest.main()
