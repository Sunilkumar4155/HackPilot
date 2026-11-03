import os
from pathlib import Path

# Base configuration for HackPilot Web Automation
BASE_URL = os.environ.get("HACKPILOT_TEST_URL", "http://127.0.0.1:8765")

# Directories
PROJECT_ROOT = Path(__file__).resolve().parent.parent.parent
TESTING_DIR = PROJECT_ROOT / "testing"
SCREENSHOTS_DIR = TESTING_DIR / "screenshots"
LOGS_DIR = TESTING_DIR / "logs"
REPORTS_DIR = TESTING_DIR / "reports"

SCREENSHOTS_DIR.mkdir(parents=True, exist_ok=True)
LOGS_DIR.mkdir(parents=True, exist_ok=True)
REPORTS_DIR.mkdir(parents=True, exist_ok=True)

# Timeouts
DEFAULT_TIMEOUT = int(os.environ.get("SELENIUM_TIMEOUT", "30"))
PAGE_LOAD_TIMEOUT = int(os.environ.get("PAGE_LOAD_TIMEOUT", "60"))
FLUTTER_RENDER_WAIT = int(os.environ.get("FLUTTER_RENDER_WAIT", "15"))

# Viewports
VIEWPORT_DESKTOP = (1440, 900)
VIEWPORT_TABLET = (768, 1024)
VIEWPORT_MOBILE = (390, 844)

