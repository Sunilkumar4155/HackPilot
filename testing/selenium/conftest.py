import os
import sys
import time
from datetime import datetime
from pathlib import Path

# Ensure project root is in sys.path
PROJECT_ROOT = Path(__file__).resolve().parent.parent.parent
if str(PROJECT_ROOT) not in sys.path:
    sys.path.insert(0, str(PROJECT_ROOT))

import pytest
from selenium import webdriver
from selenium.webdriver.chrome.options import Options
from selenium.webdriver.chrome.service import Service

from testing.selenium.config import (
    BASE_URL,
    PAGE_LOAD_TIMEOUT,
    VIEWPORT_DESKTOP,
    SCREENSHOTS_DIR,
    LOGS_DIR,
)


def pytest_addoption(parser):
    parser.addoption(
        "--headless",
        action="store_true",
        default=True,
        help="Run browser in headless mode",
    )
    parser.addoption(
        "--app-url",
        action="store",
        default=BASE_URL,
        help="Base URL of the HackPilot Web Application",
    )


@pytest.fixture(scope="session")
def base_url(request):
    return request.config.getoption("--app-url")


@pytest.fixture(scope="function")
def driver(request, base_url):
    headless = request.config.getoption("--headless")

    chrome_options = Options()
    if headless:
        chrome_options.add_argument("--headless=new")
    chrome_options.add_argument("--disable-gpu")
    chrome_options.add_argument("--no-sandbox")
    chrome_options.add_argument("--disable-dev-shm-usage")
    chrome_options.add_argument(f"--window-size={VIEWPORT_DESKTOP[0]},{VIEWPORT_DESKTOP[1]}")
    chrome_options.set_capability("goog:loggingPrefs", {"browser": "ALL"})

    driver = webdriver.Chrome(options=chrome_options)
    driver.set_page_load_timeout(PAGE_LOAD_TIMEOUT)

    yield driver

    # Capture logs and screenshot on test failure
    failed = hasattr(request.node, "rep_call") and request.node.rep_call.failed
    test_name = request.node.name.replace("[", "_").replace("]", "_")
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")

    try:
        logs = driver.get_log("browser")
        log_file = LOGS_DIR / f"{test_name}_{timestamp}.log"
        with open(log_file, "w", encoding="utf-8") as f:
            for entry in logs:
                f.write(f"[{entry.get('timestamp')}] {entry.get('level')}: {entry.get('message')}\n")
    except Exception:
        pass

    if failed:
        screenshot_path = SCREENSHOTS_DIR / f"FAILURE_{test_name}_{timestamp}.png"
        try:
            driver.save_screenshot(str(screenshot_path))
        except Exception:
            pass

    driver.quit()


@pytest.hookimpl(tryfirst=True, hookwrapper=True)
def pytest_runtest_makereport(item, call):
    outcome = yield
    rep = outcome.get_result()
    setattr(item, f"rep_{rep.when}", rep)

