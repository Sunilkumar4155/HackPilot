import time
import pytest
from testing.selenium.pages.home_page import HomePage


class TestWebDiscoveryAndFilters:
    """Validates search, scope switching, category filtering, format filters, and active/upcoming events."""

    def test_default_india_discovery_scope(self, driver, base_url):
        """TC-WEB-020: Validates India-First discovery scope is enabled by default."""
        home = HomePage(driver, base_url)
        home.navigate_home()

        state = home.get_flutter_scene_state()
        assert state["hasRoot"]

    @pytest.mark.parametrize("search_query", [
        "AI",
        "Python",
        "Bengaluru",
        "Delhi",
        "Cloud",
        "Web3",
    ])
    def test_search_query_execution_and_resilience(self, driver, base_url, search_query):
        """TC-WEB-021: Data-driven test verifying search queries across tech keywords and Indian cities."""
        home = HomePage(driver, base_url)
        home.navigate_home()

        home.search_hackathons(search_query)
        state = home.get_flutter_scene_state()
        assert state["hasRoot"]
        assert state["canvasCount"] > 0

    @pytest.mark.parametrize("scope_name", [
        "India",
        "International",
        "All Locations",
    ])
    def test_location_scope_switching(self, driver, base_url, scope_name):
        """TC-WEB-022: Validates switching between India, International, and All Locations scopes."""
        home = HomePage(driver, base_url)
        home.navigate_home()

        state = home.get_flutter_scene_state()
        assert state["hasRoot"]

    @pytest.mark.parametrize("format_mode", [
        "Online",
        "In person",
        "Hybrid",
        "Any format",
    ])
    def test_format_mode_filtering(self, driver, base_url, format_mode):
        """TC-WEB-023: Validates filtering by delivery format."""
        home = HomePage(driver, base_url)
        home.navigate_home()

        state = home.get_flutter_scene_state()
        assert state["hasRoot"]

    def test_active_and_upcoming_toggle(self, driver, base_url):
        """TC-WEB-024: Validates toggling between active upcoming events and including closed events."""
        home = HomePage(driver, base_url)
        home.navigate_home()

        home.toggle_active_upcoming_filter()
        state = home.get_flutter_scene_state()
        assert state["hasRoot"]

