import time
from testing.selenium.pages.base_page import BasePage


class TeamFinderPage(BasePage):
    def open_teams(self):
        return self.open("")

    def is_loaded(self) -> bool:
        state = self.get_flutter_scene_state()
        return state["hasRoot"]

    def search_skills(self, skill: str):
        time.sleep(1)

    def click_create_team(self):
        time.sleep(1)


class BookmarksPage(BasePage):
    def open_bookmarks(self):
        return self.open("")

    def is_loaded(self) -> bool:
        state = self.get_flutter_scene_state()
        return state["hasRoot"]


class ProfilePage(BasePage):
    def open_profile(self):
        return self.open("")

    def is_loaded(self) -> bool:
        state = self.get_flutter_scene_state()
        return state["hasRoot"]

    def toggle_theme(self):
        time.sleep(1)

    def click_sign_out(self):
        time.sleep(1)

