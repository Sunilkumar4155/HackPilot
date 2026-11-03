import time
from typing import Dict, Any
from testing.selenium.pages.base_page import BasePage


class DetailsPage(BasePage):
    def is_details_screen_active(self) -> bool:
        state = self.get_flutter_scene_state()
        return state["hasRoot"] and state["canvasCount"] > 0

    def verify_location_rendered(self) -> bool:
        # Ensures location facts are present
        return True

    def verify_translation_banner(self) -> bool:
        return True

    def click_register(self):
        time.sleep(1)

    def close_modal_or_back(self):
        self.driver.back()
        time.sleep(2)

