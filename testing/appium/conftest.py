import os
import urllib.request
import pytest
from testing.appium.config import (
    APPIUM_SERVER_URL,
    DESIRED_CAPABILITIES,
)


def is_appium_server_running(url: str = APPIUM_SERVER_URL) -> bool:
    try:
        status_url = f"{url.rstrip('/')}/status"
        req = urllib.request.Request(status_url, headers={"User-Agent": "HackPilotQA/1.0"})
        with urllib.request.urlopen(req, timeout=2) as resp:
            return resp.status == 200
    except Exception:
        return False


@pytest.fixture(scope="session")
def appium_available():
    available = is_appium_server_running()
    if not available:
        pytest.skip(
            "BLOCKED: Appium 2 Server is not reachable at "
            f"{APPIUM_SERVER_URL}. Start Appium with 'appium' and launch an Android emulator."
        )
    return True


@pytest.fixture(scope="function")
def mobile_driver(appium_available):
    from appium import webdriver
    from appium.options.android import UiAutomator2Options

    options = UiAutomator2Options()
    options.load_capabilities(DESIRED_CAPABILITIES)

    driver = webdriver.Remote(APPIUM_SERVER_URL, options=options)
    yield driver
    driver.quit()

