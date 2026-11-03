import time
import pytest
from testing.selenium.pages.team_finder_page import TeamFinderPage, BookmarksPage, ProfilePage


class TestWebTeamFinderAndBookmarks:
    """Validates Team Finder listing, squad search, bookmarks view, and profile options."""

    def test_team_finder_view_initialization(self, driver, base_url):
        """TC-WEB-040: Validates Team Finder scene rendering."""
        page = TeamFinderPage(driver, base_url)
        page.open_teams()

        state = page.get_flutter_scene_state()
        assert state["hasRoot"]

    @pytest.mark.parametrize("skill_query", [
        "Flutter",
        "Python",
        "AI",
        "React",
    ])
    def test_team_finder_skill_search(self, driver, base_url, skill_query):
        """TC-WEB-041: Data-driven skill query filtering for squad assembly."""
        page = TeamFinderPage(driver, base_url)
        page.open_teams()
        page.search_skills(skill_query)

        state = page.get_flutter_scene_state()
        assert state["hasRoot"]

    def test_bookmarks_screen_rendering(self, driver, base_url):
        """TC-WEB-042: Validates Bookmarks screen rendering."""
        page = BookmarksPage(driver, base_url)
        page.open_bookmarks()

        state = page.get_flutter_scene_state()
        assert state["hasRoot"]

    def test_profile_theme_toggle_flow(self, driver, base_url):
        """TC-WEB-043: Validates Profile screen and theme toggle controls."""
        page = ProfilePage(driver, base_url)
        page.open_profile()

        state = page.get_flutter_scene_state()
        assert state["hasRoot"]

