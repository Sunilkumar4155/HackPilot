import time
from typing import Optional, List
from appium.webdriver.common.appiumby import AppiumBy
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC


class MobileBasePage:
    def __init__(self, driver):
        self.driver = driver
        self.wait = WebDriverWait(driver, 20)

    def find(self, by: AppiumBy, value: str):
        return self.wait.until(EC.presence_of_element_located((by, value)))

    def click(self, by: AppiumBy, value: str):
        el = self.wait.until(EC.element_to_be_clickable((by, value)))
        el.click()

    def send_keys(self, by: AppiumBy, value: str, text: str):
        el = self.find(by, value)
        el.clear()
        el.send_keys(text)

    def is_visible(self, by: AppiumBy, value: str) -> bool:
        try:
            return self.find(by, value).is_displayed()
        except Exception:
            return False

    def scroll_down(self):
        size = self.driver.get_window_size()
        start_x = size["width"] / 2
        start_y = size["height"] * 0.8
        end_y = size["height"] * 0.2
        self.driver.swipe(start_x, start_y, start_x, end_y, 800)
        time.sleep(1)

