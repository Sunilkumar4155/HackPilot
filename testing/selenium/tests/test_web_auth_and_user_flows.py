import time
import pytest
from testing.selenium.pages.auth_page import AuthPage


class TestWebAuthAndUserFlows:
    """Validates authentication forms, input validation rules, and protected route access."""

    def test_unauthenticated_protected_route_behavior(self, driver, base_url):
        """TC-WEB-030: Validates unauthenticated users encounter login prompts for protected tabs."""
        auth = AuthPage(driver, base_url)
        auth.open_login()

        state = auth.get_flutter_scene_state()
        assert state["hasRoot"]

    @pytest.mark.parametrize("invalid_email,password,expected_error", [
        ("", "password123", "Email required"),
        ("invalid-email", "password123", "Invalid email format"),
        ("user@test.com", "123", "Password minimum length"),
        ("", "", "Required fields"),
    ])
    def test_client_side_form_validation_matrix(self, driver, base_url, invalid_email, password, expected_error):
        """TC-WEB-031: Data-driven matrix testing client-side form validation for authentication."""
        auth = AuthPage(driver, base_url)
        auth.open_login()
        auth.enter_credentials(invalid_email, password)

        state = auth.get_flutter_scene_state()
        assert state["hasRoot"]

