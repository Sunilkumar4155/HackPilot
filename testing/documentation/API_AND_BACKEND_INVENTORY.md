# HackPilot — API & Backend Service Inventory

This document details all backend systems, database schemas, and external API endpoints integrated into HackPilot.

---

## 1. Firebase Backend Services

### 1.1 Project Identification
- **Project ID**: `ai-hackathon-finder`
- **Default Database**: `(default)`
- **Firebase Auth Domain**: `ai-hackathon-finder.firebaseapp.com`
- **Storage Bucket**: `ai-hackathon-finder.firebasestorage.app`

### 1.2 Authentication Endpoints (Firebase Auth REST & SDK)
- `signInWithEmailAndPassword`: Email and password authentication.
- `createUserWithEmailAndPassword`: Account registration.
- `signInWithPopup` (Web): Google OAuth 2.0 popup handler.
- `signInWithCredential` (Android): Google OAuth credential exchange with ID Token.
- `signOut`: Token invalidation and session termination.

### 1.3 Cloud Firestore Collections

#### Collection 1: `hackathon collections`
Holds the catalog of hackathons displayed in the discovery view.
- Document ID: Custom alphanumeric or auto-generated ID (e.g., `blr_ai_2026`).
- **Fields**:
  - `title` (*String*): Official event title.
  - `organizer` (*String*): Organizing entity or company.
  - `deadline` (*String*): ISO-8601 date string (`YYYY-MM-DD`).
  - `prize` (*String*): Reward string (e.g., `₹15,00,000 Cash Pool` or `$50,000`).
  - `description` (*String*): Markdown-formatted event description.
  - `location` (*String* or *Map*): Raw location or structured map containing `city`, `state`, `country`, `venue`.
  - `city` (*String*, optional): City name (e.g. `Bengaluru`).
  - `state` (*String*, optional): State name or code (e.g. `Karnataka`, `CA`).
  - `country` (*String*, optional): Country name (e.g. `India`, `USA`).
  - `mode` (*String*): `Online`, `In-person`, or `Hybrid`.
  - `teamSize` (*String*): Team constraints (e.g., `2-4 Members`).
  - `registrationLink` (*String*): External registration portal URL.
  - `imageUrl` (*String*, optional): Custom banner image URL.

#### Collection 2: `users/{uid}/bookmarks`
Subcollection isolated per authenticated user containing bookmarked hackathons.
- Document ID: Matches the bookmarked `hackathonId`.
- **Fields**: Complete serialized snapshot of `Hackathon.toMap()`.

#### Collection 3: `teams`
Public collection storing developer squads created through Team Finder.
- Document ID: Auto-generated Firestore document ID.
- **Fields**:
  - `teamName` (*String*): Squad title.
  - `hackathon` (*String*): Target hackathon name.
  - `leader` (*String*): Email of the team creator.
  - `requiredSkills` (*String*): Required technical expertise (e.g. `Flutter, Python, LLMs`).
  - `maxMembers` (*int*): Maximum member capacity (typically 2 to 6).
  - `members` (*List<String>*): Array of member email addresses.
  - `location` (*String*): City, hybrid, or online squad location.

---

## 2. External REST APIs

### 2.1 Hackalendar Events API
- **Endpoint**: `GET https://hackalendar.com/api/events`
- **Query Parameters**:
  - `from`: Start date filter in `YYYY-MM-DD` format (defaults to current date).
  - `limit`: Number of results requested (e.g. `100`).
- **Headers**: `Accept: application/json`
- **Response Format**:
  ```json
  {
    "data": [
      {
        "id": "event_123",
        "title": "Global Hackathon",
        "organizer": "Tech Community",
        "start": "2026-11-15T00:00:00Z",
        "end": "2026-11-17T00:00:00Z",
        "location": "Online",
        "is_online": true,
        "prize_amount": "$25,000",
        "url": "https://example.com/register",
        "cancelled": false
      }
    ]
  }
  ```
- **Error Handling**: 20-second timeout with fallback to Firestore/Sample catalog.

### 2.2 Google Translate Public API (GTx)
- **Endpoint**: `GET https://translate.googleapis.com/translate_a/single`
- **Query Parameters**:
  - `client`: `gtx`
  - `sl`: `auto` (Source language auto-detection)
  - `tl`: `en` (Target language: English)
  - `dt`: `t` (Translate text parameter)
  - `q`: URL-encoded source text
- **Authentication**: None required (public web engine).
- **Rate Limits**: Respected with local in-memory caching and paragraph chunking.

### 2.3 MyMemory Translation API (Secondary Fallback)
- **Endpoint**: `GET https://api.mymemory.translated.net/get`
- **Query Parameters**:
  - `q`: Encoded chunk (truncated to <= 500 chars)
  - `langpair`: `autodetect|en`
- **Response Format**:
  ```json
  {
    "responseData": {
      "translatedText": "Translated text in English",
      "match": 0.95
    },
    "responseStatus": 200
  }
  ```

### 2.4 Unsplash Image CDN
- **Endpoint**: `GET https://images.unsplash.com/...`
- **Query Parameters**: Standard Unsplash dynamic sizing parameters (`auto=format&fit=crop&w=1200&q=80`).
- **Caching**: Handled via `cached_network_image: ^4.0.3` with local asset fallbacks.

