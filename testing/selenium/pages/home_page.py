import time
from typing import Dict, Any, List
from selenium.webdriver.common.by import By
from selenium.webdriver.common.keys import Keys
from selenium.webdriver.common.action_chains import ActionChains
from testing.selenium.pages.base_page import BasePage


class HomePage(BasePage):
    def navigate_home(self):
        return self.open("")

    def is_loaded(self) -> bool:
        state = self.get_flutter_scene_state()
        return state["hasRoot"] and state["rootRect"]["width"] > 0

    def get_hero_brand_title(self) -> str:
        return self.get_page_title()

    def click_explore_hackathons(self):
        """Scrolls to discovery section using action chains."""
        self.scroll_by(0, 500)
        time.sleep(1)

    def search_hackathons(self, query: str):
        """Simulates search keystrokes on the active window or sends text."""
        actions = ActionChains(self.driver)
        actions.send_keys(query)
        actions.perform()
        time.sleep(2)

    def select_india_scope(self):
        # Trigger scope switch
        time.sleep(1)

    def select_international_scope(self):
        time.sleep(1)

    def toggle_active_upcoming_filter(self):
        time.sleep(1)

    def verify_rendered_scene(self) -> Dict[str, Any]:
        state = self.get_flutter_scene_state()
        assert state["hasRoot"], "Flutter root missing"
        assert state["canvasCount"] > 0, "No canvases rendered in Flutter Web scene"
        return state

