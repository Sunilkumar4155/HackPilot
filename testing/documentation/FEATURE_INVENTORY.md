# HackPilot — Comprehensive Feature Inventory

This document details every user-facing and architectural feature present in the HackPilot Flutter application.

---

## 1. Authentication & Session Management

| Feature ID | Feature Name | Component / Screen | Description | Status |
|---|---|---|---|---|
| AUTH-001 | Email/Password Registration | `SignupScreen` | New user sign-up with email, password, and confirmation validation. | Functional |
| AUTH-002 | Email/Password Login | `LoginScreen` | Authenticate existing user with credential error messaging. | Functional |
| AUTH-003 | Google OAuth Sign-In | `LoginScreen`, `GoogleAuthService` | Single-click Google login (popup on Web, native dialog on Android). | Functional |
| AUTH-004 | Session Persistence | `AuthService`, `MainNavigation` | Persists user session across app restarts via `FirebaseAuth.authStateChanges()`. | Functional |
| AUTH-005 | Sign-Out Flow | `ProfileScreen` | Secure session termination with confirmation dialog. | Functional |
| AUTH-006 | Protected Route Guards | `MainNavigation` | Restricts Teams, Bookmarks, and Profile behind authentication. | Functional |

---

## 2. Hackathon Discovery & Navigation

| Feature ID | Feature Name | Component / Screen | Description | Status |
|---|---|---|---|---|
| DISC-001 | Hero Section & Statistics | `HomeScreen` | Hero banner with live statistics (total listed, open, closing soon). | Functional |
| DISC-002 | India-First Scope Selector | `HomeScreen` | One-tap scope switcher: `India (Default)`, `International`, `All Locations`. | Functional |
| DISC-003 | Full-Text Search | `HomeScreen` | Real-time search with 250ms debouncing across title, organizer, city, state, prize. | Functional |
| DISC-004 | Tech Domain Categories | `HomeScreen` | Filter by 8+ domains: AI/ML, Web, Security, Robotics, Web3, Cloud, Climate, Startup. | Functional |
| DISC-005 | Format Filter | `HomeScreen` | Filter by delivery mode: `Any format`, `Online`, `In person`, `Hybrid`. | Functional |
| DISC-006 | State & City Filter | `HomeScreen` | Drill down by Indian states and major cities (Bengaluru, Delhi, Mumbai, etc.). | Functional |
| DISC-007 | Active & Upcoming Toggle | `HomeScreen` | Hides closed/expired hackathons by default with one-tap toggle to reveal past events. | Functional |
| DISC-008 | Multi-Tier Priority Sorting | `HomeScreen` | Sorts Indian in-person/hybrid first, then online, then international by deadline. | Functional |
| DISC-009 | Featured Opportunities | `HomeScreen` | Horizontal carousel showcasing top active hackathons. | Functional |
| DISC-010 | Deadlines Countdown | `HomeScreen` | Visual countdown strip highlighting events closing in <= 7 days. | Functional |
| DISC-011 | Offline Seed & Sample Feed | `HomeScreen` | Rich seed dataset across Indian & global hubs when network/Firestore sync is slow. | Functional |
| DISC-012 | External API Sync | `ExternalHackathonService` | Real-time ingest from Hackalendar REST feed with 10-minute cache. | Functional |

---

## 3. Hackathon Details & Registration

| Feature ID | Feature Name | Component / Screen | Description | Status |
|---|---|---|---|---|
| DET-001 | Hero Cover & Photography | `HackathonDetailsScreen` | Dynamic cover image resolution with gradient overlay and category badge. | Functional |
| DET-002 | Accurate Location Display | `HackathonDetailsScreen` | Normalized location rendering: `Online`, `Hybrid • [City]`, or `City, State, Country`. | Functional |
| DET-003 | Key Facts Grid | `HackathonDetailsScreen` | 6-card summary: Prize pool, deadline, team size, format, location, organizer. | Functional |
| DET-004 | Markdown Description Parser | `HackathonDetailsScreen` | Formatted rendering with automated section parsing (Eligibility, Schedule, Rules). | Functional |
| DET-005 | Prize Pool Banner | `HackathonDetailsScreen` | Highlighted prize card supporting INR (₹) and USD ($) amounts. | Functional |
| DET-006 | Mobile Registration Modal | `HackathonDetailsScreen` | Bottom-sheet confirmation on mobile with domain display and copy link option. | Functional |
| DET-007 | External Registration Launch | `HackathonDetailsScreen` | Safe URL launch via `url_launcher` with external browser mode. | Functional |
| DET-008 | Event Link Sharing | `HackathonDetailsScreen` | Copies sanitized registration link to clipboard with snackbar confirmation. | Functional |

---

## 4. Automatic English Translation

| Feature ID | Feature Name | Component / Screen | Description | Status |
|---|---|---|---|---|
| TRANS-001 | Multi-Script Language Detection | `TranslationService` | Fast heuristic detection for Indic, Cyrillic, CJK, Arabic, and accented Latin scripts. | Functional |
| TRANS-002 | English Pass-Through | `TranslationService` | Bypasses translation for English content with 0ms latency. | Functional |
| TRANS-003 | Zero-Cost Automated Translation | `TranslationService` | Translates non-English titles & descriptions to English using Google Translate GTx endpoint. | Functional |
| TRANS-004 | Secondary Translation Fallback | `TranslationService` | Fallback to MyMemory API if primary engine fails. | Functional |
| TRANS-005 | In-Memory Translation Cache | `TranslationService` | LRU caching of translated text to prevent duplicate network calls. | Functional |
| TRANS-006 | Translation Status Banner | `HackathonDetailsScreen` | Shows detected language and "Show Original" / "Show English" toggle button. | Functional |
| TRANS-007 | Offline & Failure Notice | `HackathonDetailsScreen` | Graceful fallback to original text if device is offline or translation is unavailable. | Functional |

---

## 5. Bookmark Management

| Feature ID | Feature Name | Component / Screen | Description | Status |
|---|---|---|---|---|
| BOOK-001 | Quick Toggle from Card | `HackathonCard` | One-tap bookmark icon to save or remove events from discovery grid. | Functional |
| BOOK-002 | Details Screen Bookmark | `HackathonDetailsScreen` | Real-time bookmark indicator and toggle button in app bar. | Functional |
| BOOK-003 | Real-Time Sync | `BookmarkService` | Syncs bookmarks to Cloud Firestore under `users/{uid}/bookmarks/{id}`. | Functional |
| BOOK-004 | Bookmarks Screen Listing | `BookmarksScreen` | Lists all saved hackathons with status badges, prize, deadline, and location. | Functional |
| BOOK-005 | Empty State & CTA | `BookmarksScreen` | Informative empty screen with one-tap navigation to Explore. | Functional |

---

## 6. Team Finder & Assembly

| Feature ID | Feature Name | Component / Screen | Description | Status |
|---|---|---|---|---|
| TEAM-001 | Team Finder Listing | `TeamFinderScreen` | Real-time stream of developer teams seeking members. | Functional |
| TEAM-002 | Team Search & Filters | `TeamFinderScreen` | Search by team name, hackathon title, or required technical skills. | Functional |
| TEAM-003 | Create Team Workflow | `CreateTeamScreen` | Form to create a squad with hackathon name, skills required, max members, location. | Functional |
| TEAM-004 | Join Team Action | `TeamFinderScreen`, `TeamService` | Atomic Firestore transaction adding current user email to team members array. | Functional |
| TEAM-005 | Member Capacity Enforcement | `TeamService` | Blocks joining when team has reached `maxMembers`. | Functional |

---

## 7. Profile & Personalization

| Feature ID | Feature Name | Component / Screen | Description | Status |
|---|---|---|---|---|
| PROF-001 | User Profile Identity | `ProfileScreen` | Displays avatar initial, display name, email, and Builder status badge. | Functional |
| PROF-002 | Activity Metrics | `ProfileScreen` | Real-time counts of saved hackathons and teams joined. | Functional |
| PROF-003 | Technical Skills Badges | `ProfileScreen` | Visual badges for core domains (AI, Web, Mobile, Cloud, Security, etc.). | Functional |
| PROF-004 | Dark/Light Theme Switch | `ProfileScreen`, `ThemeProvider` | High-contrast Hackathon Dark Mode vs. Light Mode switch. | Functional |
| PROF-005 | Theme Persistence | `ThemeStorage` | Persists preference to disk across sessions. | Functional |

