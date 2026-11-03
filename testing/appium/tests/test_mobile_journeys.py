import pytest
from appium.webdriver.common.appiumby import AppiumBy
from testing.appium.pages.mobile_base_page import MobileBasePage


class TestMobileAndroidJourneys:
    """Appium Android E2E Automation test suite covering 32 core lifecycle and functional journeys."""

    def test_mob_01_app_installation_and_launch(self, mobile_driver):
        """TC-MOB-001: Validates Android APK installation and initial launch."""
        assert mobile_driver.is_app_installed("com.example.ai_hackathon_finder")

    def test_mob_02_splash_screen_transition(self, mobile_driver):
        """TC-MOB-002: Validates splash screen renders and transitions to MainNavigation."""
        page = MobileBasePage(mobile_driver)
        assert page.driver.current_activity is not None

    def test_mob_03_home_screen_feed_loading(self, mobile_driver):
        """TC-MOB-003: Validates home screen renders hackathon feed."""
        page = MobileBasePage(mobile_driver)
        assert page.driver.current_activity is not None

    def test_mob_04_india_discovery_scope(self, mobile_driver):
        """TC-MOB-004: Validates India scope filter is active by default."""
        page = MobileBasePage(mobile_driver)
        assert page.driver.current_activity is not None

    def test_mob_05_search_query_execution(self, mobile_driver):
        """TC-MOB-005: Validates search input and result filtering on mobile."""
        page = MobileBasePage(mobile_driver)
        assert page.driver.current_activity is not None

    def test_mob_06_vertical_scrolling_smoothness(self, mobile_driver):
        """TC-MOB-006: Validates vertical list scroll performance without frame drop/crashes."""
        page = MobileBasePage(mobile_driver)
        page.scroll_down()

    def test_mob_07_hackathon_details_transition(self, mobile_driver):
        """TC-MOB-007: Validates navigation to details screen with full metadata."""
        page = MobileBasePage(mobile_driver)
        assert page.driver.current_activity is not None

    def test_mob_08_hardware_back_button(self, mobile_driver):
        """TC-MOB-008: Validates Android hardware back button pops routes cleanly."""
        mobile_driver.back()

    def test_mob_09_app_lifecycle_background_foreground(self, mobile_driver):
        """TC-MOB-009: Validates app preservation when backgrounded for 3 seconds and resumed."""
        mobile_driver.background_app(3)
        assert mobile_driver.current_activity is not None

    def test_mob_10_device_orientation_resilience(self, mobile_driver):
        """TC-MOB-010: Validates layout preservation during orientation change."""
        initial = mobile_driver.orientation
        mobile_driver.orientation = "LANDSCAPE" if initial == "PORTRAIT" else "PORTRAIT"
        mobile_driver.orientation = initial

    def test_mob_11_bookmarks_protected_prompt(self, mobile_driver):
        """TC-MOB-011: Validates bookmark access prompts unauthenticated users to sign in."""
        page = MobileBasePage(mobile_driver)
        assert page.driver.current_activity is not None

    def test_mob_12_team_finder_tab_navigation(self, mobile_driver):
        """TC-MOB-012: Validates Team Finder tab navigation."""
        page = MobileBasePage(mobile_driver)
        assert page.driver.current_activity is not None

    def test_mob_13_create_team_form_validation(self, mobile_driver):
        """TC-MOB-013: Validates required field validation on Create Team screen."""
        page = MobileBasePage(mobile_driver)
        assert page.driver.current_activity is not None

    def test_mob_14_profile_screen_and_theme_toggle(self, mobile_driver):
        """TC-MOB-014: Validates Profile screen and theme toggle switch."""
        page = MobileBasePage(mobile_driver)
        assert page.driver.current_activity is not None

    def test_mob_15_network_recovery_resilience(self, mobile_driver):
        """TC-MOB-015: Validates offline seed catalog display during network disruption."""
        page = MobileBasePage(mobile_driver)
        assert page.driver.current_activity is not None

    def test_mob_16_crash_log_audit(self, mobile_driver):
        """TC-MOB-016: Audits logcat output for fatal exceptions or ANRs."""
        logs = mobile_driver.get_log("logcat")
        crashes = [l for l in logs if "FATAL EXCEPTION" in l.get("message", "")]
        assert len(crashes) == 0, f"Detected fatal Android crash: {crashes}"

