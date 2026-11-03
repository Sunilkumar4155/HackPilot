# HackPilot — Comprehensive Testing Implementation Plan

## 1. Objectives & Scope

This plan specifies the testing strategy across all testing disciplines:
1. **Flutter Unit & Widget Tests**: Dart test framework covering models, services, widgets, screens, and integration logic.
2. **Selenium Web E2E Automation**: Python + pytest Page Object Model (POM) testing the built Flutter Web application running on a local HTTP server.
3. **Appium Mobile Automation**: Python + pytest POM framework targeting the Android mobile application.
4. **Backend Security Testing**: Automated scripts and manual assessment verifying Firestore rules, authorization, and input sanitization.
5. **Performance & Load Testing**: k6 load test scripts covering Baseline, Load, Stress, Spike, and Endurance profiles.
6. **Reporting Automation**: Automated generation of `HackPilot_Test_Report.xlsx` (via Python `openpyxl`) and `HTML_E2E_Test_Report.html`.
7. **CI/CD Automation**: GitHub Actions workflows running automated builds, tests, security audits, and report generation.

---

## 2. Test Execution Matrix & Tooling

| Tier | Technology / Framework | Execution Command | Target Coverage | Output Artifact |
|---|---|---|---|---|
| **Flutter Unit & Widget** | Flutter Test (`flutter_test`) | `flutter test --reporter json` | Models, Services, Widgets, Screens | `testing/reports/flutter-test-results.json` |
| **Flutter Analysis** | Dart Analyzer (`flutter analyze`) | `flutter analyze` | 0 issues across all Dart source code | Console output |
| **Selenium E2E (Web)** | Python 3.13 + pytest + Selenium | `pytest testing/selenium --junitxml=...` | User journeys 1-6, responsive, filters, forms | `testing/reports/selenium-results.xml` |
| **Appium E2E (Android)** | Python + Appium 2 + UiAutomator2 | `pytest testing/appium --junitxml=...` | 32 Mobile lifecycle and feature scenarios | `testing/reports/appium-results.xml` |
| **Security Audit** | Python custom scanners + Dart audit | `python testing/security/run_security_audit.py` | Firestore, Auth, Keys, Input sanitization | `testing/reports/security-findings.json` |
| **Performance Testing** | k6 (`C:\Program Files\k6\k6.exe`) | `k6 run testing/performance/baseline_test.js` | Baseline, Load, Stress, Spike, Endurance | `testing/reports/performance-summary.json` |
| **Excel Master Report** | Python `openpyxl` | `python testing/scripts/generate_excel_report.py` | 10 Worksheets with metrics and charts | `testing/reports/excel/HackPilot_Test_Report.xlsx` |
| **HTML Master Report** | Python HTML builder | `python testing/scripts/generate_html_report.py` | Executive visual HTML report | `testing/reports/html/HTML_E2E_Test_Report.html` |

---

## 3. End-to-End User Journeys (Web & Mobile)

1. **Journey 1: Authentication & Navigation**
   - Splash screen display -> MainNavigation
   - New user signup validation (invalid format vs valid)
   - Login with email/password
   - Protected tab navigation (Team Finder, Bookmarks, Profile)
   - Sign-out and route guard verification

2. **Journey 2: Hackathon Discovery & Filtering**
   - India-first default view verification
   - Search by keyword (`AI`, `Dev`, `Security`)
   - Scope switcher (`India` -> `International` -> `All Locations`)
   - Secondary filters (`Online`, `In-person`, `Hybrid`, `State`, `City`)
   - "Active & Upcoming Only" toggle verification
   - Deadline countdown list interaction

3. **Journey 3: Details & Auto-Translation**
   - Tap hackathon card -> Details screen transition
   - Accurate location display (`City, State, Country`, `Online`, or `Hybrid`)
   - Auto-translation of non-English content
   - Language indicator banner and "Show Original" / "Show English" toggle
   - Key facts grid and prize display verification
   - Safe registration URL launch verification

4. **Journey 4: Bookmark Management**
   - Bookmark toggle from card & details screen
   - Navigation to Bookmarks tab
   - Verify saved event metadata and status
   - Unbookmark action and list auto-refresh

5. **Journey 5: Team Finder & Squad Assembly**
   - Navigate to Team Finder tab
   - Search teams by skill keyword
   - Open Create Team screen -> Validate required fields
   - Submit new team squad
   - Verify created squad in feed
   - Join team transaction with member capacity check

6. **Journey 6: Profile & Personalization**
   - Navigate to Profile tab
   - Verify user identity, email, activity counts
   - Toggle Dark/Light mode theme switch
   - Confirm theme visual adaptation across app
   - Sign out confirmation dialog and redirection

---

## 4. Execution Schedule & Milestones

- **Phase 1**: Architecture, Feature, API, Security, and Test Plans (Completed)
- **Phase 2**: Comprehensive Flutter test suite expansion & execution
- **Phase 3**: Selenium Web E2E automation framework & test execution
- **Phase 4**: Appium Android mobile automation framework configuration
- **Phase 5**: Complete E2E user journeys validation
- **Phase 6**: Backend security audit and hardened `firestore.rules` generation
- **Phase 7**: k6 performance test execution (Baseline, Load, Stress, Spike, Endurance)
- **Phase 8**: Master Excel Report generation with 10 worksheets
- **Phase 9**: Visual HTML Report generation
- **Phase 10**: Repository structure & setup documentation
- **Phase 11**: GitHub Actions CI/CD workflows implementation
- **Phase 12 & 13**: Final verification, defect remediation, and acceptance

