#!/usr/bin/env python3

import unittest
from selenium import webdriver
from testpack_helper_library.unittests.dockertests import Test1and1Common
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions
from selenium.common.exceptions import TimeoutException
import time


class Test1and1NextcloudImage(Test1and1Common):

    @classmethod
    def setUpClass(cls):
        Test1and1Common.setUpClass(environment={"SKIPINSTALL": "true"})

    # <tests to run>

    def test_docker_logs(self):
        expected_log_lines = [
            "Process 'apache-2.4' changed state to 'STARTING'",
            "Unpacking nextcloud"
        ]
        container_logs = self.container.logs().decode('utf-8')
        for expected_log_line in expected_log_lines:
            self.assertTrue(
                container_logs.find(expected_log_line) > -1,
                msg="Docker log line missing: %s from (%s)" % (expected_log_line, container_logs)
            )

    def test_php72_cli(self):
        self.assertPackageIsInstalled("php7.2-cli")

    def test_default_app(self):
        # Wait for nextcloud to be unpacked before testing
        driver = self.getChromeDriver()
        url = "http://%s:8080" % Test1and1Common.container_ip
        time.sleep(20) # Allow the nextcloud package to be unzipped into DOCUMENT_ROOT
        driver.get(url)
        try:
            WebDriverWait(driver, 20).until(expected_conditions.title_contains('Nextcloud'))
        except TimeoutException:
            pass
        self.assertTrue(driver.title.find('Nextcloud') > -1, msg="App not available")

    # </tests to run>

if __name__ == '__main__':
    unittest.main(verbosity=1)
