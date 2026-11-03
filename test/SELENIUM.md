# Selenium smoke test

This smoke test opens the built Flutter Web app in headless Chrome, waits for
the Flutter scene to render, saves a screenshot, and reports browser console
errors.

1. Build and serve the app from the project root:

   ```powershell
   flutter build web
   python -m http.server 8765 --directory build/web
   ```

2. In a second terminal, install Selenium and run the test:

   ```powershell
   pip install -r test/requirements-selenium.txt
   python test/selenium_smoke.py
   ```

Selenium Manager resolves the matching ChromeDriver. The test uses
`http://127.0.0.1:8765` by default; set `HACKPILOT_TEST_URL` to override it.
The screenshot is saved to the system temporary directory as
`hackpilot-selenium-home.png`.
