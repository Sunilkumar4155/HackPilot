import time
from typing import Tuple, List, Dict, Any, Optional
from selenium.webdriver.remote.webdriver import WebDriver
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.common.by import By
from selenium.webdriver.common.action_chains import ActionChains

from testing.selenium.config import DEFAULT_TIMEOUT, FLUTTER_RENDER_WAIT


class BasePage:
    def __init__(self, driver: WebDriver, base_url: str):
        self.driver = driver
        self.base_url = base_url

    def open(self, path: str = ""):
        target = f"{self.base_url.rstrip('/')}/{path.lstrip('/')}"
        self.driver.get(target)
        self.wait_for_flutter_initialization()
        return self

    def wait_for_flutter_initialization(self, timeout: int = DEFAULT_TIMEOUT):
        """Waits until Flutter's web engine (CanvasKit or HTML) is initialized in DOM."""
        WebDriverWait(self.driver, timeout).until(
            lambda d: d.execute_script(
                "return !!document.querySelector('flutter-view, flt-glass-pane, flt-renderer')"
            )
        )
        # Give initial render tree a few seconds to paint
        time.sleep(2)

    def get_page_title(self) -> str:
        return self.driver.title

    def get_body_text(self) -> str:
        return self.driver.execute_script("return document.body.innerText || '';")

    def get_flutter_scene_state(self) -> Dict[str, Any]:
        """Inspects Flutter CanvasKit/HTML scene metrics piercing shadow DOM where necessary."""
        return self.driver.execute_script(
            """
            const root = document.querySelector('flutter-view, flt-glass-pane, flt-renderer');
            const gp = document.querySelector('flt-glass-pane');
            const rect = root ? root.getBoundingClientRect() : {width: 0, height: 0, top: 0, left: 0};
            
            let count = document.querySelectorAll('canvas').length;
            if (count === 0 && gp && gp.shadowRoot) {
                count += gp.shadowRoot.querySelectorAll('canvas').length;
            }
            if (count === 0 && root && root.shadowRoot) {
                count += root.shadowRoot.querySelectorAll('canvas').length;
            }

            return {
                title: document.title,
                hasRoot: !!root,
                rootTag: root ? root.tagName : null,
                rootRect: {
                    width: rect.width,
                    height: rect.height,
                    top: rect.top,
                    left: rect.left
                },
                canvasCount: count,
                bodyText: document.body.innerText || '',
                viewport: [window.innerWidth, window.innerHeight],
                url: window.location.href
            };
            """
        )

    def get_browser_logs(self) -> List[Dict[str, Any]]:
        try:
            return self.driver.get_log("browser")
        except Exception:
            return []

    def get_severe_console_errors(self) -> List[Dict[str, Any]]:
        logs = self.get_browser_logs()
        return [entry for entry in logs if entry.get("level") in ("SEVERE", "ERROR")]

    def set_viewport(self, width: int, height: int):
        self.driver.set_window_size(width, height)
        time.sleep(1)

    def scroll_by(self, x: int = 0, y: int = 400):
        self.driver.execute_script(f"window.scrollBy({x}, {y});")
        time.sleep(1)

    def take_screenshot(self, filepath: str):
        self.driver.save_screenshot(filepath)

