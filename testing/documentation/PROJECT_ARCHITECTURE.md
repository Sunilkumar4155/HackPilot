# HackPilot — Project Architecture & Technical Stack

## 1. Executive Overview

**HackPilot** (formerly AI Hackathon Finder) is an enterprise-grade cross-platform application designed to discover, track, and assemble teams for developer hackathons globally and across India. The application targets Android mobile devices and desktop/mobile Web platforms from a unified codebase built on Flutter.

- **Repository**: [https://github.com/Sunilkumar4155/HackPilot](https://github.com/Sunilkumar4155/HackPilot)
- **Root Directory**: `C:\FLutter\ai_hackathon_finder`
- **Application Version**: `1.0.0+1`
- **SDK Target**: Flutter 3.x / Dart SDK `^3.12.2`
- **Platforms**: Android, Web (with desktop shells for Windows, macOS, Linux, and iOS)

---

## 2. Architecture & Layer Decomposition

The application adheres to a clean layered architecture separating presentation, business logic/state, domain models, and service integration layers:

```
               ┌────────────────────────────────────────────────────────┐
               │                   Presentation Layer                   │
               │   (Screens, Custom Widgets, Layouts, Responsive UI)    │
               └───────────────────────────┬────────────────────────────┘
                                           │
               ┌───────────────────────────▼────────────────────────────┐
               │                State & Provider Layer                  │
               │  (ThemeProvider, Local State, Reactive StreamBuilders) │
               └───────────────────────────┬────────────────────────────┘
                                           │
               ┌───────────────────────────▼────────────────────────────┐
               │                  Domain & Model Layer                  │
               │      (Hackathon, Team, TranslationResult, Constants)   │
               └───────────────────────────┬────────────────────────────┘
                                           │
               ┌───────────────────────────▼────────────────────────────┐
               │                     Service Layer                      │
               │  - AuthService & GoogleAuthService (Firebase Auth)     │
               │  - FirestoreService & BookmarkService (Cloud Firestore)│
               │  - TeamService (Real-time Team Operations)             │
               │  - TranslationService (Language Detection & GTx/MyMem) │
               │  - ExternalHackathonService (Hackalendar REST Feed)    │
               └───────────────────────────┬────────────────────────────┘
                                           │
               ┌───────────────────────────▼────────────────────────────┐
               │                 External Infrastructure                │
               │  - Firebase Authentication                             │
               │  - Google Cloud Firestore (NoSQL)                      │
               │  - External REST API: hackalendar.com                  │
               │  - Translation API: translate.googleapis.com (GTx)     │
               │  - Unsplash Image CDN                                  │
               └────────────────────────────────────────────────────────┘
```

---

## 3. Frontend Architecture

### 3.1 Routing & Navigation
The application uses a persistent bottom/rail navigation shell via `MainNavigation` (`lib/screens/main_navigation.dart`):
1. **Explore (Tab 0)**: `HomeScreen` — Discovery hub with India-first prioritization, scope selector, search bar, format filters, categories, and deadline countdowns.
2. **Teams (Tab 1)**: `TeamFinderScreen` — Protected route listing active developer squads, team requirements, and team joining actions.
3. **Bookmarks (Tab 2)**: `BookmarksScreen` — Protected route listing user-saved hackathons synchronized with Firestore.
4. **Profile (Tab 3)**: `ProfileScreen` — User identity details, stats, skills badges, dark/light theme switch, and sign-out.

Direct push navigation (`MaterialPageRoute`) is utilized for detail flows:
- `HackathonDetailsScreen`: Comprehensive event dossier, auto-translation banner, prize breakdown, facts grid, and mobile viewport registration launcher.
- `CreateTeamScreen`: Validated form to establish new developer squads.
- `LoginScreen` & `SignupScreen`: Authentication workflows with callback redirection.

### 3.2 State Management
- **`provider` (`^6.1.5+1`)**: Powers `ThemeProvider` for app-wide reactive theme switching (Hackathon Dark Mode vs. Light Mode) with platform-specific persistence (`SharedPreferences` on native, `window.localStorage` on Web via conditional imports).
- **Reactive StreamBuilders**: Direct binding to Firestore `snapshots()` streams for real-time hackathon listings, bookmarks, and team collections.
- **Local Ephemeral State**: Managed with `StatefulWidget` for search query debouncing (250ms), dropdown filter caches, and translation toggles.

---

## 4. Backend & Database Architecture

The backend infrastructure is built on **Firebase (Google Cloud Platform)**:
- **Firebase Project ID**: `ai-hackathon-finder`
- **Firebase Web App ID**: `1:931938207103:web:5b0b3405b21f4f87b3464a`
- **Firebase Android App ID**: `1:931938207103:android:f572a06f9aea3c67b3464a`
- **Cloud Firestore Database**: Multi-tenant NoSQL document database.
  - Collection `hackathon collections`: Master repository of curated and community hackathons.
  - Subcollection `users/{uid}/bookmarks`: User-isolated bookmarked events indexed by `hackathonId`.
  - Collection `teams`: Developer squad listings with atomic array updates for `members`.
- **Firebase Authentication**:
  - Email/Password authentication.
  - Google Sign-In via popup for Web (`GoogleAuthProvider`) and native Android credentials (`google_sign_in: ^7.2.0`).

---

## 5. External Integration Services

1. **Hackalendar Public API** (`https://hackalendar.com/api/events`):
   - Ingests real-time developer hackathons.
   - Caching strategy: 10-minute in-memory caching with date-keyed invalidation.
2. **Google Translate Public Engine (GTx)** (`https://translate.googleapis.com/translate_a/single?client=gtx&...`):
   - Provides automated language translation into English.
   - Zero-cost, zero API-key requirement (no secret leakage risk).
   - Secondary fallback: MyMemory Translation API (`api.mymemory.translated.net`).
3. **Unsplash Image CDN** (`https://images.unsplash.com/...`):
   - Curated domain-specific photography based on technology category (AI/ML, Web, Cybersecurity, Robotics, Web3, Cloud, Climate, Startup).
   - Local offline fallback assets stored in `assets/images/hackathons/`.

---

## 6. Build & Deployment Architecture

- **Android Target**:
  - Gradle 8.x / Kotlin DSL build system (`android/app/build.gradle`).
  - Min SDK: 21, Target SDK: 34, Compile SDK: 34.
  - Impeller / Skia rendering engine compatibility.
- **Web Target**:
  - Renderers: CanvasKit and HTML renderers supported.
  - Base href: `/` for local/Firebase Hosting, adaptable for GitHub Pages.
  - `firebase.json` hosting target: `build/web` with single-page app rewrite to `/index.html`.

