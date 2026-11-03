import pytest
from testing.selenium.pages.home_page import HomePage
from testing.selenium.config import VIEWPORT_DESKTOP


class TestWebAvailabilityAndLaunch:
    """Validates baseline web availability, Flutter CanvasKit initialization, and console health."""

    def test_application_launch_and_availability(self, driver, base_url):
        """TC-WEB-001: Validates that the application loads successfully with HTTP 200 equivalent."""
        home = HomePage(driver, base_url)
        home.navigate_home()

        state = home.get_flutter_scene_state()
        assert state["hasRoot"], "Flutter root (<flutter-view> or <flt-glass-pane>) was not detected."
        assert state["canvasCount"] > 0, "No <canvas> elements rendered by Flutter web engine."

    def test_application_title_branding(self, driver, base_url):
        """TC-WEB-002: Validates page title carries the HACKPILOT branding."""
        home = HomePage(driver, base_url)
        home.navigate_home()

        title = home.get_page_title()
        assert "HACKPILOT" in title.upper() or "HACKATHON" in title.upper(), (
            f"Unexpected page title: '{title}'"
        )

    def test_viewport_geometry_and_canvas_bounds(self, driver, base_url):
        """TC-WEB-003: Validates viewport dimensions match desktop layout without collapse."""
        home = HomePage(driver, base_url)
        home.navigate_home()

        state = home.get_flutter_scene_state()
        width = state["rootRect"]["width"]
        height = state["rootRect"]["height"]

        assert width >= 1000, f"Rendered Flutter root width is abnormally small: {width}px"
        assert height >= 600, f"Rendered Flutter root height is abnormally small: {height}px"

    def test_browser_console_severe_errors_absence(self, driver, base_url):
        """TC-WEB-004: Audits browser console logs for fatal script or rendering errors."""
        home = HomePage(driver, base_url)
        home.navigate_home()

        severe_errors = home.get_severe_console_errors()
        # Filter out expected network failures if offline or external API timeouts
        critical_unhandled = [
            err for err in severe_errors
            if "Uncaught" in err.get("message", "") or "SyntaxError" in err.get("message", "")
        ]
        assert len(critical_unhandled) == 0, f"Found critical unhandled console errors: {critical_unhandled}"

    def test_flutter_web_canvas_resilience_after_scroll(self, driver, base_url):
        """TC-WEB-005: Validates that scrolling through hackathon listings preserves rendered scene."""
        home = HomePage(driver, base_url)
        home.navigate_home()

        home.scroll_by(0, 600)
        state_after_scroll = home.get_flutter_scene_state()
        assert state_after_scroll["hasRoot"], "Flutter root disappeared after scroll event."
        assert state_after_scroll["canvasCount"] > 0, "Canvases were purged after scrolling."

