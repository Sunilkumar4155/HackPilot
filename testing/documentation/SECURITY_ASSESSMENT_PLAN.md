# HackPilot — Security Assessment & Threat Model Plan

## 1. Executive Summary & Objective

The objective of the HackPilot Security Audit is to evaluate the application's vulnerability posture across authentication, client-side data exposure, Firestore authorization rules, external API integration, input validation, and package dependencies without disrupting production services or exposing sensitive credentials.

---

## 2. Threat Modeling & Attack Surface Decomposition

| Threat Vector | Description | Affected Area | Severity Potential |
|---|---|---|---|
| **TV-01: Insecure Firestore Rules** | Missing or overly permissive Firestore security rules allowing unauthenticated or cross-tenant document read/write/deletion. | Cloud Firestore (`hackathon collections`, `users`, `teams`) | **Critical** |
| **TV-02: User Impersonation & IDOR** | Manipulating user IDs to read or overwrite another user's bookmarks or team entries. | `users/{uid}/bookmarks`, `teams` | **High** |
| **TV-03: Team Member Array Poisoning** | Malicious users forging team member lists, exceeding `maxMembers`, or ejecting members. | `teams` collection | **Medium** |
| **TV-04: API Key Abuse & Over-Privilege** | Public exposure of Firebase Web/Android API keys without proper referer/package restrictions in Google Cloud Console. | `firebase_options.dart`, `google-services.json` | **Medium** |
| **TV-05: Insecure URL Launching (Open Redirect)** | Launching unvalidated `javascript:` or malicious deep links via `url_launcher`. | `HackathonDetailsScreen` registration launcher | **High** |
| **TV-06: Cross-Site Scripting (XSS) via Markdown** | Malicious script execution injected into hackathon descriptions or team details via `flutter_markdown`. | Markdown renderers | **Medium** |
| **TV-07: Sensitive Information in Logs** | Printing user credentials, tokens, or PII into system log streams (`debugPrint`, console). | Mobile logs, Browser console | **Low** |
| **TV-08: Dependency Vulnerabilities** | Outdated or compromised Dart/Flutter packages in `pubspec.lock`. | Package dependencies | **Medium** |

---

## 3. Detailed Audit Methodology

### 3.1 Firebase Configuration & Security Rules Audit
1. Verify if `firestore.rules` exists in source control.
2. Evaluate rule constraints for:
   - `match /hackathon collections/{docId}`: Must be read-only for public/authenticated users, write restricted to administrators.
   - `match /users/{userId}/bookmarks/{bookmarkId}`: Must enforce `request.auth != null && request.auth.uid == userId`.
   - `match /teams/{teamId}`: Read allowed for authenticated users; create allowed with valid schema; update restricted to joining via atomic transaction.
3. Validate Firebase Storage rules if storage buckets are utilized.

### 3.2 Authentication & Token Handling
1. Test invalid credential rejection (empty password, short password, malformed email).
2. Validate that user sessions terminate cleanly upon sign out.
3. Check for token leaks in HTTP query parameters or local storage.

### 3.3 Static Code Analysis & Secrets Scanning
1. Run static analysis rules for hardcoded private keys, passwords, and service account JSONs.
2. Verify that `.gitignore` prevents check-in of `*.keystore`, `*.jks`, `google-services.json` (if containing private keys), and `.env` files.
3. Scan for insecure HTTP endpoints (`http://` vs `https://`).

### 3.4 Client-Side Input Validation & Sanitization
1. Test URL sanitization in `_parseRegistrationUri`: Ensure non-HTTP/HTTPS schemes are blocked.
2. Test team creation constraints: `maxMembers` must be positive integer, `teamName` cannot be empty.
3. Verify that `url_launcher` uses `LaunchMode.externalApplication` to prevent WebView session hijacking.

---

## 4. Security Findings Classification Framework

Findings are classified according to standard CVSS v3.1 severity metrics:
- **CRITICAL**: Immediate risk of remote code execution, database-wide unauthenticated read/write, or complete authentication bypass.
- **HIGH**: Insecure direct object references (IDOR) allowing unauthorized user data access, or open redirects leading to credential theft.
- **MEDIUM**: Unrestricted API key scope, lack of rate limiting, or potential denial of service via schema tampering.
- **LOW**: Minor information leakage, missing security headers, or overly verbose error messages.
- **INFORMATIONAL**: Hardening opportunities, best practice recommendations, and architecture improvements.

