import time
import pytest
from testing.selenium.pages.home_page import HomePage
from testing.selenium.config import (
    VIEWPORT_DESKTOP,
    VIEWPORT_TABLET,
    VIEWPORT_MOBILE,
)


class TestWebNavigationAndResponsive:
    """Validates responsive viewports (Desktop, Tablet, Mobile) and browser navigation history."""

    @pytest.mark.parametrize("viewport_name,dimensions", [
        ("Desktop_1440x900", VIEWPORT_DESKTOP),
        ("Tablet_768x1024", VIEWPORT_TABLET),
        ("Mobile_390x844", VIEWPORT_MOBILE),
    ])
    def test_responsive_layout_rendering(self, driver, base_url, viewport_name, dimensions):
        """TC-WEB-010: Validates responsive scene adaptation across devices without layout collapse."""
        home = HomePage(driver, base_url)
        home.open()

        home.set_viewport(dimensions[0], dimensions[1])
        state = home.get_flutter_scene_state()

        assert state["hasRoot"], f"Root missing for viewport {viewport_name}"
        assert state["rootRect"]["width"] > 0, f"Root width zero for viewport {viewport_name}"
        assert state["canvasCount"] > 0, f"Canvases missing for viewport {viewport_name}"

    def test_browser_back_and_forward_navigation_resilience(self, driver, base_url):
        """TC-WEB-011: Validates that browser back/forward buttons maintain application stability."""
        home = HomePage(driver, base_url)
        home.navigate_home()

        driver.get(f"{base_url.rstrip('/')}/#/explore")
        time.sleep(1)

        driver.back()
        time.sleep(1)

        driver.forward()
        time.sleep(1)

        state = home.get_flutter_scene_state()
        assert state["hasRoot"], "Flutter application failed to recover after browser back/forward."

    def test_page_refresh_state_persistence(self, driver, base_url):
        """TC-WEB-012: Validates page refresh (F5/Reload) cleanly restores Flutter Web engine."""
        home = HomePage(driver, base_url)
        home.navigate_home()

        driver.refresh()
        home.wait_for_flutter_initialization()

        state = home.get_flutter_scene_state()
        assert state["hasRoot"], "Flutter root missing after page refresh."
        assert state["canvasCount"] > 0, "Canvas missing after page refresh."

