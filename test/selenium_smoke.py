"""Selenium smoke test for the built HACKPILOT Flutter Web app.

Usage: flutter build web; serve build/web on port 8765; pip install -r test/requirements-selenium.txt; python test/selenium_smoke.py
"""
import json
import os
import tempfile
import time
from pathlib import Path

from selenium import webdriver
from selenium.webdriver.chrome.options import Options
from selenium.webdriver.support.ui import WebDriverWait

URL = os.environ.get("HACKPILOT_TEST_URL", "http://127.0.0.1:8765")


def main():
    options = Options()
    options.add_argument("--headless=new")
    options.add_argument("--disable-gpu")
    options.add_argument("--window-size=1440,1200")
    options.set_capability("goog:loggingPrefs", {"browser": "ALL"})

    with webdriver.Chrome(options=options) as driver:
        driver.set_page_load_timeout(45)
        driver.get(URL)
        WebDriverWait(driver, 45).until(
            lambda browser: browser.execute_script(
                "return !!document.querySelector('flt-glass-pane, flutter-view')"
            )
        )
        # Let Firestore and the external listings feed reach success/error states.
        time.sleep(25)
        state = driver.execute_script(
            """const root = document.querySelector('flt-glass-pane, flutter-view');
            const rect = root ? root.getBoundingClientRect() : {width: 0, height: 0};
            return {
              title: document.title,
              root: !!root,
              rootChildren: root ? Array.from(root.children).map(el => el.tagName) : [],
              rootRect: [rect.width, rect.height],
              canvases: document.querySelectorAll('canvas').length,
              semantics: document.querySelectorAll('flt-semantics').length,
              bodyText: document.body.innerText || '',
              viewport: [innerWidth, innerHeight]
            };"""
        )
        screenshot = Path(tempfile.gettempdir()) / "hackpilot-selenium-home.png"
        driver.save_screenshot(str(screenshot))
        logs = driver.get_log("browser")
        severe = [entry for entry in logs if entry.get("level") == "SEVERE"]
        print(json.dumps({
            "url": URL,
            "page": state,
            "screenshot": str(screenshot),
            "consoleEntries": logs,
            "severeConsoleEntries": severe,
        }, indent=2))
        assert state["title"].startswith("HACKPILOT"), state
        assert state["root"], "Flutter web root did not render"
        assert state["rootChildren"], "Flutter root has no rendered scene children"
        assert all(size > 0 for size in state["rootRect"]), "Flutter root has no visible size"
        assert screenshot.exists() and screenshot.stat().st_size > 10_000, "Rendered screenshot is unexpectedly small"


if __name__ == "__main__":
    main()
