import os
from pathlib import Path

# Appium and Android Configuration
APPIUM_SERVER_URL = os.environ.get("APPIUM_SERVER_URL", "http://127.0.0.1:4723")
ANDROID_DEVICE_NAME = os.environ.get("ANDROID_DEVICE_NAME", "emulator-5554")
ANDROID_PLATFORM_VERSION = os.environ.get("ANDROID_PLATFORM_VERSION", "14.0")
APP_PACKAGE = "com.example.ai_hackathon_finder"
APP_ACTIVITY = ".MainActivity"

PROJECT_ROOT = Path(__file__).resolve().parent.parent.parent
DEFAULT_APK_PATH = PROJECT_ROOT / "build" / "app" / "outputs" / "flutter-apk" / "app-debug.apk"
APK_PATH = os.environ.get("HACKPILOT_APK_PATH", str(DEFAULT_APK_PATH))

DESIRED_CAPABILITIES = {
    "platformName": "Android",
    "appium:automationName": "UiAutomator2",
    "appium:deviceName": ANDROID_DEVICE_NAME,
    "appium:platformVersion": ANDROID_PLATFORM_VERSION,
    "appium:app": APK_PATH,
    "appium:appPackage": APP_PACKAGE,
    "appium:appActivity": APP_ACTIVITY,
    "appium:noReset": False,
    "appium:newCommandTimeout": 120,
    "appium:autoGrantPermissions": True,
}

