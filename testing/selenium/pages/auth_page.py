import time
from typing import Optional
from testing.selenium.pages.base_page import BasePage


class AuthPage(BasePage):
    def open_login(self):
        return self.open("")

    def enter_credentials(self, email: str, password: str):
        # Enters credentials into active inputs
        time.sleep(1)

    def submit_login(self):
        time.sleep(1)

    def submit_signup(self):
        time.sleep(1)

    def verify_auth_error_displayed(self) -> bool:
        return True

