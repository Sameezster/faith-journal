# Faith Journal — Solution Architecture & Implementation Plan

**Document type:** Production-ready architecture & engineering plan (MVP)
**Owner:** Solution Architecture
**Version:** 1.0
**Date:** 2026-06-22
**Status:** Approved for build
**Source of truth for UI/UX:** `Faith_Journal_final.pptx` (21 screens)

---

## Table of Contents

1. [Executive Summary](#1-executive-summary)
2. [Product Scope (MVP)](#2-product-scope-mvp)
3. [Architecture Principles & Decisions](#3-architecture-principles--decisions)
4. [System Architecture](#4-system-architecture)
5. [Design System (extracted from the design file)](#5-design-system-extracted-from-the-design-file)
6. [Monorepo Folder Structure](#6-monorepo-folder-structure)
7. [Flutter Project Structure](#7-flutter-project-structure)
8. [Riverpod State-Management Structure](#8-riverpod-state-management-structure)
9. [Data Model — Firestore Collections](#9-data-model--firestore-collections)
10. [Data Model — Relational (FastAPI Bible & AI services)](#10-data-model--relational-fastapi-bible--ai-services)
11. [FastAPI API Contracts](#11-fastapi-api-contracts)
12. [AI Verse Categorization Workflow](#12-ai-verse-categorization-workflow)
13. [Bible Provider Abstraction](#13-bible-provider-abstraction)
14. [Authentication & Security](#14-authentication--security)
15. [Notifications (FCM) Architecture](#15-notifications-fcm-architecture)
16. [Smart Search](#16-smart-search)
17. [Screen → Feature → Data Traceability Matrix](#17-screen--feature--data-traceability-matrix)
18. [Sprint-by-Sprint Implementation Plan](#18-sprint-by-sprint-implementation-plan)
19. [Developer Task Breakdown (3 Developers)](#19-developer-task-breakdown-3-developers)
20. [Testing, CI/CD & DevOps](#20-testing-cicd--devops)
21. [Non-Functional Requirements](#21-non-functional-requirements)
22. [Risks, Assumptions & Phase 2](#22-risks-assumptions--phase-2)

---

## 1. Executive Summary

Faith Journal is a mobile-first Christian spiritual-growth application that lets a believer read the Bible, save meaningful verses, write and record reflections, track prayer requests from request to answered, search spiritual content, and stay consistent through reminders. The MVP targets **Android and iOS** (Flutter); a **read-only Web Portal** follows in Phase 2.

The architecture is **Firebase-first**: Firebase Authentication, Cloud Firestore, Firebase Storage, and Firebase Cloud Messaging handle identity, user-generated content, media, and reminders with offline support out of the box. A **FastAPI (Python 3.12) service layer** sits alongside Firebase to own the two responsibilities Firebase is poorly suited for: **AI verse/reflection categorization** (a provider-agnostic LLM abstraction over OpenAI and Gemini, with a deterministic keyword fallback) and the **Bible content service** (a provider abstraction serving bundled public-domain translations now and licensed translations later, with fast chapter loading and cross-translation search).

This document is the single engineering reference for the MVP. It defines the system architecture, the monorepo and Flutter/Riverpod structures, the complete data model (Firestore + relational), all API contracts, the AI categorization workflow, the Bible provider abstraction, and a sprint-by-sprint plan with a task breakdown for a **three-developer team**. The UI/UX is recreated faithfully from the 21-screen design file, whose design system is documented in Section 5.

---

## 2. Product Scope (MVP)

The MVP delivers nine capability areas, each traceable to specific screens in the design file (full matrix in Section 17).

| # | Capability | What it does | Primary screens |
|---|-----------|--------------|-----------------|
| 1 | **Authentication** | Email/password, Google, Apple sign-in; password reset; session persistence | Splash, Onboarding 1–3, Welcome, Create Account, Login, Reset Password |
| 2 | **Bible Reading** | Browse OT/NT books, open a chapter, read with verse numbers, switch translation (KJV/WEB), offline reading | Bible browser, Bible reader |
| 3 | **Verse Saving** | Save a verse, tag it, filter by category, revisit saved verses | Verse reader actions, Saved Verses |
| 4 | **Reflection Notes** | Write a text reflection against a verse with AI-suggested tags | Add Reflection |
| 5 | **Voice Notes** | Record, preview, re-record, and save an audio reflection | Voice Reflection |
| 6 | **Prayer Tracker** | Create prayers, categorize, track status (Active → In Progress → Answered), add testimony/notes | Prayers list, New Prayer, Prayer Detail |
| 7 | **Smart Search** | Search verses & reflections; suggested topics; cross-translation | Search |
| 8 | **Notifications** | Bible reading, reflection, verse review, prayer reminders via FCM + local scheduling | Reminders |
| 9 | **AI Verse Categorization** | Suggest categories for verses/reflections/prayers; user accepts, edits, or removes | Add Reflection, New Prayer, Save Verse |

**Out of scope for MVP (Phase 2):** Web Portal (read-only dashboard), NIV/ESV licensed translations, Tamil translation, social/sharing features beyond native share sheet, multi-device prayer collaboration.

**Initial AI category taxonomy (11):** Strength, Faith, Hope, Wisdom, Prayer, Love, Forgiveness, Healing, Peace, Gratitude, Encouragement.

---

## 3. Architecture Principles & Decisions

The following decisions are recorded as lightweight ADRs (Architecture Decision Records).

### ADR-001 — Firebase as the primary backend for user data
**Decision:** Use Cloud Firestore as the system of record for all user-generated content (profiles, saved verses, reflections, voice-note metadata, prayers, reminder settings). Use Firebase Auth for identity, Firebase Storage for media, and FCM for push.
**Why:** Mobile-first product with a small team; Firestore gives real-time sync, offline persistence, and per-user security rules with near-zero ops. It removes the need to build/operate a relational CRUD API for the MVP.
**Consequences:** Querying is denormalized and index-driven; cross-entity reporting is limited (acceptable for MVP; the Phase-2 web portal reads the same collections). Server-side business logic that must not live on the client goes to Cloud Functions or FastAPI.

### ADR-002 — FastAPI service layer for AI and Bible content
**Decision:** Stand up a FastAPI (Python 3.12) backend, organized in Clean Architecture (API / Application / Domain / Infrastructure), responsible for (a) AI categorization and (b) the Bible content service. It does **not** proxy Firestore CRUD.
**Why:** LLM calls require secret keys and provider abstraction that must never ship in the client; Bible text needs full-text search and a relational store that Firestore handles poorly. Keeping these in Python also matches the team's AI tooling.
**Consequences:** Two backends (Firebase + FastAPI). Clear ownership boundaries (Section 4) prevent overlap. FastAPI is stateless and horizontally scalable.

### ADR-003 — Provider abstraction for AI (OpenAI + Gemini + fallback)
**Decision:** All AI categorization goes through an `AICategorizationProvider` interface. Concrete adapters: **`GeminiProvider` (default for MVP)**, `OpenAIProvider` (addable later, no code change beyond config). A `KeywordRuleProvider` is the deterministic fallback used when no key is configured or the LLM call fails/times out. Selection is config-driven (`AI_PROVIDER=gemini` by default).
**Why:** The requirement is a configurable provider with graceful degradation. AI **only suggests**; the user accepts/edits/removes — so a non-AI fallback is fully acceptable UX.
**Consequences:** Categorization never hard-fails. Adding a provider = one adapter class. (Full design in Section 12.)

### ADR-004 — Provider abstraction for Bible content (bundled-first)
**Decision:** All Bible reads go through a `BibleProvider` interface. MVP ships `LocalBundledProvider` (KJV + WEB, public domain). `ExternalApiProvider` and `LicensedProvider` (NIV/ESV) are pluggable later. A translation switcher is built from day one.
**Why:** KJV/WEB are public-domain and can be bundled for instant, offline, license-clean reading; NIV/ESV require licensing and are deferred without changing the app.
**Consequences:** Offline-first reading on mobile (bundled assets + Firestore offline cache). Search runs across bundled translations server-side. (Full design in Section 13.)

### ADR-005 — Flutter feature-first clean architecture with Riverpod
**Decision:** One Flutter codebase for Android, iOS (and Phase-2 Web). Feature-first folders, each split into `data / domain / presentation`. State via **Riverpod** (code-gen), routing via **GoRouter**, models via **Freezed + json_serializable**, networking via **Dio**, secrets via **flutter_secure_storage**, local DB/cache via Hive/Drift, hooks via **flutter_hooks**.
**Why:** Matches the requested stack, scales across a 3-dev team, keeps UI/state/data testable and decoupled.
**Consequences:** More boilerplate (mitigated by code-gen). Clear seams for unit/widget testing.

### ADR-006 — AI suggests, the human decides
**Decision:** AI category output is always a **suggestion set** rendered as selectable chips. The user can accept, edit, add, or remove tags before saving. No content is auto-tagged silently.
**Why:** Spiritual content is personal; trust and user control are core. Also de-risks AI errors.
**Consequences:** Tag UX must show suggested vs. selected states (the design's outlined vs. filled chips map to this directly).

### Decision summary table

| Concern | Choice | Alternatives considered |
|--------|--------|------------------------|
| User datastore | Cloud Firestore | PostgreSQL + CRUD API (more ops) |
| Identity | Firebase Auth (email, Google, Apple) | Custom JWT auth (rebuild social login) |
| Media | Firebase Storage | S3 (extra infra/IAM) |
| Push | FCM + flutter_local_notifications | OneSignal (extra vendor) |
| AI | FastAPI + provider abstraction (Gemini default, OpenAI later) + keyword fallback | Single hard-coded provider |
| Bible text | FastAPI Bible service, bundled KJV/WEB | Bundle-only (no search/scale) or API-only (needs key, no offline) |
| Mobile | Flutter + Riverpod + GoRouter | Native (2 codebases) |
| Bible/AI store | PostgreSQL (FastAPI side) | Firestore (poor full-text search) |

---

## 4. System Architecture

### 4.1 Component responsibilities

```
┌──────────────────────────────────────────────────────────────────────────┐
│                              CLIENTS                                       │
│   Flutter Mobile (Android, iOS)        Flutter Web Portal (Phase 2, RO)    │
└───────────────┬──────────────────────────────────┬───────────────────────┘
                │                                    │
   Firebase SDK │ (Auth, Firestore, Storage, FCM)    │ HTTPS + Firebase ID token
                │                                    │
┌───────────────▼───────────────────────┐   ┌────────▼───────────────────────┐
│            FIREBASE                    │   │      FASTAPI SERVICE LAYER       │
│  • Auth (email, Google, Apple)         │   │  Clean Architecture:             │
│  • Cloud Firestore (user data, RT,     │   │   API / Application / Domain /   │
│    offline)                            │   │   Infrastructure                 │
│  • Storage (voice notes, avatars)      │   │  • AI Categorization service     │
│  • Cloud Messaging (push)              │   │  • Bible Content service         │
│  • Cloud Functions (triggers, scheduled│   │  • Smart Search service          │
│    reminders, token mint helper)       │   │  • Verifies Firebase ID tokens   │
└───────────────┬───────────────────────┘   └───┬─────────────┬───────────────┘
                │                                │             │
                │                       ┌────────▼───┐   ┌─────▼──────────────┐
                │                       │ PostgreSQL │   │  AI PROVIDERS       │
                │                       │ (Bible text│   │  • OpenAI GPT       │
                │                       │  + FTS,    │   │  • Google Gemini    │
                │                       │  taxonomy) │   │  • Keyword fallback │
                │                       └────────────┘   └─────────────────────┘
                │                                │
                │                       ┌────────▼─────────────────────────────┐
                │                       │  BIBLE PROVIDERS                      │
                │                       │  • Local bundled (KJV, WEB)           │
                │                       │  • External Bible API (pluggable)     │
                │                       │  • Licensed (NIV/ESV — Phase 2)       │
                │                       └───────────────────────────────────────┘
```

### 4.2 Ownership boundaries (who owns what)

| Domain | Owner | Notes |
|--------|-------|-------|
| Identity / sessions | Firebase Auth | Tokens verified by FastAPI on each AI/Bible call |
| Saved verses, reflections, prayers, reminders, profile | **Firestore** | Client writes directly under per-user security rules |
| Voice-note & avatar binaries | **Firebase Storage** | Firestore stores the download URL + metadata |
| AI category suggestions | **FastAPI** (`/ai`) | Stateless; never writes user data |
| Bible books/chapters/verses/search | **FastAPI** (`/bible`) + Postgres | Cached on device for offline |
| Push delivery & scheduling | FCM + Cloud Functions + on-device local notifications | Reminder prefs live in Firestore |

### 4.3 Key end-to-end flows

**Save a verse + AI tags.** Reader → user taps *Save* → client calls `POST /ai/categorize` (FastAPI) with verse text → receives suggested categories → renders chips → user accepts/edits → client writes the `saved_verses` doc to Firestore with the final tags. If the AI call fails, the keyword fallback still returns suggestions; if even that is unavailable, the user tags manually.

**Read a chapter offline.** Reader requests John 3 → Riverpod checks the on-device cache (Hive/Drift) → on miss, calls `GET /bible/{translation}/{book}/{chapter}` → caches the response → renders. Subsequent reads are offline and instant.

**Record a reflection.** Voice screen records audio → on Save, uploads the file to Firebase Storage (`users/{uid}/voice_notes/{id}.m4a`) → writes a `reflections` doc (type=voice) with the storage URL, duration, and verse reference.

**Reminder fires.** User toggles "Bible Reading Reminder 7:00 AM" → pref saved to Firestore `reminders` → device schedules a local notification; a Cloud Function also stores the FCM token for server-initiated daily-verse pushes.

---

## 5. Design System (extracted from the design file)

The 21 screens establish a calm, reverent, editorial aesthetic: serif display headings, a goldenrod call-to-action, cream canvas, and white cards. These tokens are the contract between design and Flutter `ThemeData`.

### 5.1 Color tokens

| Token | Hex | Usage |
|-------|-----|-------|
| `navy.900` (primary text) | `#16314E` | Display headings, body headings, active nav |
| `navy.700` | `#1F3D5C` | Secondary headings, icons on cream |
| `gold.500` (primary action) | `#C8962F` | Primary buttons, active chips/tabs, FAB, highlights |
| `gold.300` | `#E4C77D` | Pressed/hover, subtle accents, "Save"/"Hope" accent text |
| `cream.50` (canvas) | `#F4F0E6` | App background, onboarding canvas |
| `surface.0` (cards) | `#FFFFFF` | Cards, sheets, input fields |
| `sage.500` | `#8A9A7B` | Success/positive secondary text ("Recording…", journal dates) |
| `gray.500` | `#8C8C8C` | Secondary/body text, captions, placeholders |
| `gray.300` | `#D9D6CC` | Dividers, inactive chips, unfilled toggles |
| `status.active` | `#C8962F` | Prayer "Active" |
| `status.waiting` | `#B98A2E` | Prayer "Waiting" |
| `status.answered` | `#5E7D5A` | Prayer "Answered" |

> **Note on brand palette.** The design file is the single source of truth for the *app's* visual identity (navy / gold / cream). The corporate brand palette (Viamedia purple, LocalFactor yellow, BF navy) is reserved for company-facing collateral and is used in this document's diagrams, not inside the product UI.

### 5.2 Typography

| Style | Family | Weight | Size (logical px) | Used for |
|-------|--------|--------|-------------------|----------|
| Display / H1 | Serif (Playfair Display) | Bold | 30–34 | "Welcome Back", "Bible", "Prayers", screen titles |
| H2 | Serif (Playfair Display) | SemiBold | 22–24 | Card titles, verse references ("John 3:16") |
| Title | Sans (Inter) | SemiBold | 16–18 | Section labels ("Your Reflection", "Testimony") |
| Body | Sans (Inter) | Regular | 14–16 | Verse text, descriptions, reflections |
| Caption | Sans (Inter) | Regular/Medium | 12–13 | Dates, counters (0/1000), helper text |
| Button | Sans (Inter) | SemiBold/Bold | 16 | CTAs |

Verse/scripture body uses a serif for a "scripture" feel in the reader; UI chrome uses the sans family.

### 5.3 Spacing, radius, elevation

- **Spacing scale:** 4 / 8 / 12 / 16 / 20 / 24 / 32 (base unit = 4). Screen gutters = 20–24.
- **Corner radius:** inputs & chips 12; cards 16–20; primary buttons 14–16 (near-pill); FAB & record button full-circle.
- **Elevation:** cards use a soft, low-opacity shadow (y≈4, blur≈16, ~8% navy). Primary buttons have a subtle gold glow.
- **Touch targets:** ≥ 44×44 (meets accessibility; record/FAB are larger).

### 5.4 Core reusable components (map 1:1 to the design)

`PrimaryButton` (gold, full-width), `SecondaryButton` (outlined), `SocialButton` (Google/Apple), `AppTextField`, `PasswordField` (eye toggle), `VerseCard`, `VerseOfDayCard`, `QuickActionTile` (Home grid), `CategoryChip` (filled/outlined = selected/suggested), `FilterChipBar`, `ReflectionEditor` (with char counter), `VoiceRecorder` (mic button + waveform + timer + transport), `PrayerCard` (with status badge), `StatusPill` (Active/In Progress/Answered), `ReminderToggleTile`, `SettingsRow`, `SectionHeader` (title + "See All"/"View all"), `BottomNavBar`, `BibleBookTile`, `VerseText` (numbered, selectable, highlightable), `OnboardingPage` (with page dots), `EmptyState`.

### 5.5 Navigation pattern

Persistent bottom tab bar with five primary destinations — **Home · Bible · Journal · Prayer · Profile** — using a `StatefulShellRoute` (GoRouter) so each tab keeps its own navigation stack. Active tab = navy icon + label with a gold underline indicator. Search is reachable from Home's quick-action grid and surfaces its own screen (the design shows Search inserted into the bar contextually). Secondary screens (Reset Password, Add Reflection, Voice Reflection, New Prayer, Prayer Detail, Reminders) are pushed routes with a back chevron.

---

## 6. Monorepo Folder Structure

A single Git repository holds the mobile app, the FastAPI services, shared assets, infrastructure, and docs. Tooling: **Melos** is optional for Dart package orchestration; **Make** + per-service tooling for the rest.

```
faith-journal/
├── README.md
├── Makefile                      # one-liners: make app.run, make api.dev, make seed, make test
├── .github/
│   └── workflows/
│       ├── mobile_ci.yaml        # flutter analyze + test + build
│       ├── backend_ci.yaml       # ruff + mypy + pytest + docker build
│       └── release.yaml          # tagged releases → Play/App Store, Cloud Run
│
├── apps/
│   └── mobile/                   # Flutter app (Android, iOS; Web in Phase 2)
│       └── (see Section 7)
│
├── services/
│   └── api/                      # FastAPI service layer (AI + Bible + Search)
│       ├── pyproject.toml
│       ├── app/
│       │   ├── main.py
│       │   ├── api/              # API layer (routers, deps, schemas)
│       │   ├── application/      # use-cases / services
│       │   ├── domain/           # entities, value objects, interfaces (ports)
│       │   ├── infrastructure/   # adapters: providers, db, firebase
│       │   └── core/             # config, logging, security, errors
│       ├── alembic/              # migrations for Postgres (Bible + taxonomy)
│       ├── data/
│       │   └── bibles/           # KJV.json, WEB.json (public-domain seed)
│       ├── scripts/seed_bible.py
│       └── tests/
│
├── packages/                     # shared Dart packages (optional, for code reuse)
│   ├── fj_core/                  # theme, tokens, constants, utils, failures
│   ├── fj_ui/                    # design-system widgets (Section 5.4)
│   └── fj_models/                # Freezed models shared by app & web portal
│
├── firebase/
│   ├── firestore.rules           # security rules (Section 9.4)
│   ├── firestore.indexes.json    # composite indexes
│   ├── storage.rules
│   └── functions/                # Cloud Functions (reminders, daily verse, token store)
│
├── infra/
│   ├── docker/                   # Dockerfile(s) for the API
│   ├── cloud_run/                # service.yaml, env templates
│   └── terraform/                # GCP project, Cloud Run, Secret Manager (optional)
│
└── docs/
    ├── Faith_Journal_Architecture.md   # this document
    ├── adr/                            # ADR-001 … ADR-006 (Section 3)
    ├── api/openapi.json                # generated FastAPI spec
    └── design/                         # exported screens + token sheet
```

**Why a monorepo:** one source of truth, atomic cross-cutting changes (e.g., a new model used by both app and Cloud Functions), shared CI, and a single place for docs. The mobile app and API still deploy independently.

---

## 7. Flutter Project Structure

Feature-first Clean Architecture. Every feature owns three layers — `data` (DTOs, datasources, repository impls), `domain` (entities, repository interfaces, use-cases), and `presentation` (Riverpod providers/controllers + widgets). Cross-feature concerns live in `core/`.

```
apps/mobile/
├── pubspec.yaml
├── analysis_options.yaml
├── firebase_options.dart          # FlutterFire config (gitignored per-env variants)
└── lib/
    ├── main.dart                  # bootstrap: Firebase.init, ProviderScope, runApp
    ├── app.dart                   # MaterialApp.router + theme + GoRouter
    │
    ├── core/
    │   ├── config/                # env, flavors (dev/staging/prod), AppConfig
    │   ├── theme/                 # tokens.dart, app_theme.dart (Section 5)
    │   ├── router/                # app_router.dart (GoRouter, StatefulShellRoute)
    │   ├── network/               # dio_client.dart, interceptors (auth, retry, logging)
    │   ├── storage/               # secure_storage.dart, hive/drift cache
    │   ├── error/                 # failures, exceptions, error mapper
    │   ├── di/                    # provider overrides, service locators
    │   ├── utils/                 # formatters, validators, extensions
    │   └── widgets/               # shared design-system widgets (or via packages/fj_ui)
    │
    ├── features/
    │   ├── auth/
    │   │   ├── data/
    │   │   │   ├── datasources/firebase_auth_datasource.dart
    │   │   │   ├── models/app_user_dto.dart
    │   │   │   └── repositories/auth_repository_impl.dart
    │   │   ├── domain/
    │   │   │   ├── entities/app_user.dart
    │   │   │   ├── repositories/auth_repository.dart
    │   │   │   └── usecases/{sign_in_email,sign_in_google,sign_in_apple,
    │   │   │                  register,reset_password,sign_out,watch_auth_state}.dart
    │   │   └── presentation/
    │   │       ├── controllers/auth_controller.dart   # Riverpod Notifier
    │   │       ├── screens/{splash,onboarding,welcome,login,register,reset_password}_screen.dart
    │   │       └── widgets/{social_button,auth_text_field}.dart
    │   │
    │   ├── home/                   # greeting, verse of the day, quick actions, recent reflections
    │   ├── bible/                  # browser (OT/NT tabs, book list) + reader (chapter, highlight)
    │   ├── verses/                 # saved verses list + filters + save action
    │   ├── reflections/            # add text reflection + AI tags
    │   ├── voice_notes/            # record/preview/save audio
    │   ├── journal/                # unified timeline (verses + reflections + voice)
    │   ├── prayer/                 # list, new prayer, detail, status, testimony/notes
    │   ├── search/                 # smart search + suggested topics
    │   ├── reminders/              # toggles + times (FCM/local notifications)
    │   └── profile/                # profile & settings, translation, theme
    │
    ├── shared/
    │   ├── ai/                     # AiCategorizationService client (calls FastAPI /ai)
    │   ├── bible_provider/         # BibleRepository client (calls FastAPI /bible + cache)
    │   └── models/                 # cross-feature Freezed models (or packages/fj_models)
    │
    └── l10n/                       # localization (en now; ta scaffolded for Phase 2 Tamil)
```

**Conventions**
- Models are **Freezed + json_serializable**; DTOs live in `data/models`, domain entities are plain immutable classes.
- Repositories are interfaces in `domain/`, implemented in `data/`; the implementation is injected via Riverpod so tests can swap fakes.
- No widget calls Firebase/Dio directly — always through a repository behind a provider.
- Flavors (`dev`, `staging`, `prod`) select Firebase project + API base URL at build time.

---

## 8. Riverpod State-Management Structure

Riverpod (with `riverpod_generator` code-gen) is the single state solution. Layering: **datasource → repository (provider) → controller/notifier (provider) → widget (`ConsumerWidget`/`HookConsumerWidget`)**.

### 8.1 Provider taxonomy

| Layer | Provider kind | Example | Lifetime |
|-------|---------------|---------|----------|
| Infra clients | `Provider` | `dioProvider`, `firebaseAuthProvider`, `firestoreProvider`, `secureStorageProvider` | app |
| Repositories | `Provider` | `authRepositoryProvider`, `bibleRepositoryProvider`, `verseRepositoryProvider`, `prayerRepositoryProvider`, `aiServiceProvider` | app |
| Auth state | `StreamProvider` | `authStateProvider` (drives router redirect) | app |
| Screen state | `@riverpod` Notifier / AsyncNotifier | `LoginController`, `AddReflectionController`, `NewPrayerController` | autoDispose |
| Reactive data | `StreamProvider.family` | `savedVersesProvider(filter)`, `prayersProvider(status)`, `journalProvider(range)` | autoDispose |
| Async fetch | `FutureProvider.family` | `chapterProvider((translation,book,chapter))`, `searchProvider(query)` | autoDispose (kept-alive cache for chapters) |
| Derived/UI | `Provider` / `NotifierProvider` | `categoryFilterProvider`, `selectedTagsProvider`, `bibleTranslationProvider` | autoDispose |

### 8.2 Representative providers (illustrative Dart)

```dart
// Infra
@riverpod
FirebaseFirestore firestore(FirestoreRef ref) => FirebaseFirestore.instance;

// Auth state drives GoRouter redirects
@riverpod
Stream<AppUser?> authState(AuthStateRef ref) =>
    ref.watch(authRepositoryProvider).watchAuthState();

// Reactive Firestore stream, parameterized by filter
@riverpod
Stream<List<SavedVerse>> savedVerses(SavedVersesRef ref, String category) {
  final repo = ref.watch(verseRepositoryProvider);
  return repo.watch(category: category); // 'All' | 'Faith' | 'Hope' | ...
}

// Async chapter fetch with offline cache; kept alive so re-entry is instant
@Riverpod(keepAlive: true)
Future<Chapter> chapter(ChapterRef ref, ChapterKey key) =>
    ref.watch(bibleRepositoryProvider).getChapter(key);

// Screen controller: builds reflection, calls AI for suggestions, persists
@riverpod
class AddReflectionController extends _$AddReflectionController {
  @override
  AddReflectionState build(VerseRef verse) =>
      AddReflectionState.initial(verse);

  Future<void> requestSuggestions(String text) async {
    state = state.copyWith(suggesting: true);
    final tags = await ref.read(aiServiceProvider).categorize(text);
    state = state.copyWith(suggested: tags, suggesting: false);
  }

  void toggleTag(String tag) => state =
      state.copyWith(selected: state.selected.toggle(tag));

  Future<void> save() =>
      ref.read(reflectionRepositoryProvider).add(state.toReflection());
}
```

### 8.3 State modeling rules
- Async UI states use `AsyncValue<T>` (loading / data / error) so every screen renders skeleton, content, and error consistently.
- Screen view-models are **Freezed** immutable state classes (e.g., `AddReflectionState`, `VoiceRecorderState`, `NewPrayerState`).
- `ref.listen` handles side effects (snackbars, navigation on success); widgets stay declarative.
- `autoDispose` is the default; only chapter cache and auth are kept alive.

---

## 9. Data Model — Firestore Collections

Firestore is the system of record for all user-generated content. The model is **per-user, denormalized, and offline-first**. Top-level collections key on `uid` so security rules and queries are simple. Timestamps use Firestore `Timestamp`; IDs are auto-generated unless noted.

### 9.1 Collection map

```
users/{uid}                                  ← profile + settings
  saved_verses/{verseId}                      ← subcollection
  reflections/{reflectionId}                  ← subcollection (text OR voice)
  prayers/{prayerId}                          ← subcollection
    prayer_notes/{noteId}                     ← subcollection (timeline notes)
  reminders/{reminderId}                      ← subcollection (4 fixed types)
  devices/{deviceId}                          ← FCM tokens
journal_index/{uid}/entries/{entryId}         ← optional denormalized timeline (see 9.3)
```

> **Why subcollections under `users/{uid}`:** every read/write is naturally scoped to the owner, security rules reduce to `request.auth.uid == uid`, and offline cache hydrates per-user with no cross-tenant leakage.

### 9.2 Document schemas

**`users/{uid}`**

| Field | Type | Notes |
|-------|------|-------|
| `uid` | string | == Firebase Auth UID |
| `displayName` | string | "Sarah Joseph" |
| `email` | string | from Auth |
| `photoUrl` | string? | Storage URL |
| `provider` | string | `password` \| `google.com` \| `apple.com` |
| `bibleTranslation` | string | default `KJV` (switcher) |
| `theme` | string | `light` \| `dark` \| `system` |
| `createdAt` / `updatedAt` | timestamp | |
| `notificationsEnabled` | bool | master toggle |

**`users/{uid}/saved_verses/{verseId}`**

| Field | Type | Notes |
|-------|------|-------|
| `reference` | string | `John 3:16` |
| `book` / `chapter` / `verseStart` / `verseEnd` | string/int | structured ref for linking back to reader |
| `translation` | string | `KJV` \| `WEB` |
| `text` | string | verse snapshot (so saved view works offline) |
| `categories` | array<string> | from the 11-tag taxonomy; AI-suggested then user-confirmed |
| `aiSuggested` | array<string> | what AI proposed (analytics on accept/edit rate) |
| `note` | string? | optional inline note |
| `createdAt` | timestamp | sort key |

**`users/{uid}/reflections/{reflectionId}`** — unifies text and voice (drives the Journal timeline)

| Field | Type | Notes |
|-------|------|-------|
| `type` | string | `text` \| `voice` |
| `verseReference` | string? | `Philippians 4:13` (reflections attach to a verse) |
| `book`/`chapter`/`verseStart` | … | structured ref (nullable for free reflections) |
| `bodyText` | string? | text reflections (≤ 1000 chars, matches the 0/1000 counter) |
| `audioUrl` | string? | voice reflections → Storage URL |
| `audioDurationMs` | int? | for the player |
| `categories` | array<string> | AI-suggested + confirmed |
| `aiSuggested` | array<string> | |
| `createdAt` | timestamp | sort key |

**`users/{uid}/prayers/{prayerId}`**

| Field | Type | Notes |
|-------|------|-------|
| `title` | string | "Healing for My Mother" |
| `description` | string | |
| `category` | string | Family, Work, Health, … (free + suggested) |
| `status` | string | `active` \| `in_progress` \| `answered` (design: Active/Waiting use same field; "Waiting" maps to `in_progress`) |
| `requestedDate` | timestamp | the chosen date |
| `answeredDate` | timestamp? | set on "Mark Answered" |
| `testimony` | string? | answered-prayer testimony |
| `aiSuggested` | array<string> | suggested categories |
| `createdAt`/`updatedAt` | timestamp | |

**`users/{uid}/prayers/{prayerId}/prayer_notes/{noteId}`** — the Notes timeline on Prayer Detail

| Field | Type | Notes |
|-------|------|-------|
| `body` | string | "Mom has been feeling better…" |
| `createdAt` | timestamp | |

**`users/{uid}/reminders/{reminderId}`** — four fixed reminder types

| Field | Type | Notes |
|-------|------|-------|
| `type` | string | `bible_reading` \| `reflection` \| `verse_review` \| `prayer` \| `daily_verse` |
| `enabled` | bool | toggle state |
| `time` | string | `HH:mm` local ("07:00", "21:00") |
| `daysOfWeek` | array<int>? | 1–7; null = daily |
| `updatedAt` | timestamp | |

**`users/{uid}/devices/{deviceId}`**

| Field | Type | Notes |
|-------|------|-------|
| `fcmToken` | string | for server-initiated daily-verse push |
| `platform` | string | `android` \| `ios` |
| `lastSeenAt` | timestamp | prune stale tokens |

### 9.3 Journal timeline strategy

The Journal screen merges saved verses + text reflections + voice reflections into one date-grouped timeline. Two viable approaches:

- **Client-merge (MVP):** read recent docs from `saved_verses` + `reflections`, merge and sort by `createdAt` in the repository. Simple; fine at MVP data volumes.
- **Denormalized `journal_index` (scale):** a Cloud Function fans out each create into `journal_index/{uid}/entries` with `{kind, refId, title, snippet, createdAt}` so the timeline is a single indexed query. Recommended once a user exceeds a few hundred entries.

The repository interface hides which is used, so the switch is invisible to the UI.

### 9.4 Security rules (excerpt)

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{db}/documents {
    function isOwner(uid) {
      return request.auth != null && request.auth.uid == uid;
    }
    match /users/{uid} {
      allow read, write: if isOwner(uid);
      match /{sub=**} {
        allow read, write: if isOwner(uid);
      }
    }
    // journal_index is owner-only and written by Cloud Functions (admin) only
    match /journal_index/{uid}/entries/{entryId} {
      allow read: if isOwner(uid);
      allow write: if false; // server-only
    }
  }
}
```

Storage rules mirror this: `users/{uid}/voice_notes/**` and `users/{uid}/avatars/**` readable/writable only by the owner, with content-type and size limits (audio ≤ 25 MB, images ≤ 5 MB).

### 9.5 Composite indexes

- `reflections`: `type ==` + `createdAt desc`
- `saved_verses`: `categories array-contains` + `createdAt desc`
- `prayers`: `status ==` + `createdAt desc`
- `reminders`: `type ==` (single-field, auto)

---

## 10. Data Model — Relational (FastAPI Bible & AI services)

The FastAPI side uses **PostgreSQL** for Bible text (needs full-text search and fast chapter loads) and AI taxonomy/telemetry. Modeled with SQLAlchemy 2.0 + Alembic migrations. No user-generated content lives here — that is Firestore's job.

### 10.1 ER overview

```
translations ──< books ──< chapters ──< verses
                                           │
                                  (full-text search index)
categories (taxonomy)         categorization_logs (telemetry, optional)
```

### 10.2 Tables

**`translations`**

| Column | Type | Notes |
|--------|------|-------|
| `id` | PK | |
| `code` | varchar unique | `KJV`, `WEB`, (future `NIV`,`ESV`) |
| `name` | varchar | "King James Version" |
| `language` | varchar | `en`, (future `ta`) |
| `license` | varchar | `public_domain` \| `licensed` |
| `is_enabled` | bool | gates licensed translations |
| `source` | varchar | `bundled` \| `external_api` \| `licensed` |

**`books`**

| Column | Type | Notes |
|--------|------|-------|
| `id` | PK | |
| `translation_id` | FK | |
| `osis_code` | varchar | `John`, `Gen` (stable cross-translation key) |
| `name` | varchar | display name |
| `testament` | varchar | `OT` \| `NT` (drives the tabs) |
| `book_order` | int | canonical order for the list |
| `chapter_count` | int | |

**`chapters`**

| Column | Type | Notes |
|--------|------|-------|
| `id` | PK | |
| `book_id` | FK | |
| `number` | int | |
| `verse_count` | int | |

**`verses`**

| Column | Type | Notes |
|--------|------|-------|
| `id` | PK | |
| `chapter_id` | FK | |
| `number` | int | verse number |
| `text` | text | |
| `search_tsv` | tsvector | GIN-indexed for full-text search |

Unique constraint `(chapter_id, number)`; index `(book_id, number)` on chapters; GIN index on `verses.search_tsv`.

**`categories`** (the 11-tag taxonomy + future growth)

| Column | Type | Notes |
|--------|------|-------|
| `id` | PK | |
| `slug` | varchar unique | `faith`, `hope`, `healing`, … |
| `label` | varchar | "Faith" |
| `synonyms` | text[] | powers the keyword fallback (Section 12.4) |
| `is_active` | bool | |

**`categorization_logs`** (optional telemetry — provider quality & accept rates)

| Column | Type | Notes |
|--------|------|-------|
| `id` | PK | |
| `provider` | varchar | `openai` \| `gemini` \| `keyword` |
| `input_hash` | varchar | de-dup / cache key (no raw PII stored) |
| `suggested` | text[] | |
| `latency_ms` | int | |
| `created_at` | timestamptz | |

Bundled KJV/WEB JSON is loaded by `scripts/seed_bible.py` into these tables at deploy time; the device caches chapters returned by the API for offline reading.

---

## 11. FastAPI API Contracts

Base URL `/{stage}/api/v1`. All non-public endpoints require `Authorization: Bearer <Firebase ID token>`; FastAPI verifies it with the Firebase Admin SDK and resolves `uid`. Responses are JSON; errors use a consistent envelope. OpenAPI is auto-generated at `/docs`.

### 11.1 Conventions

- **Auth:** Firebase ID token in `Authorization` header. (Internal service-to-service calls — e.g., Cloud Functions — use a separate signed JWT; hence both Firebase Admin SDK and JWT are in the stack.)
- **Errors:** `{ "error": { "code": "string", "message": "string", "details": {...} } }` with appropriate HTTP status.
- **Pagination:** `?limit=&cursor=` (opaque cursor), responses include `nextCursor`.
- **Versioning:** path-versioned (`/v1`).
- **Idempotency:** AI categorize is safe to retry (hash-cached).

### 11.2 Endpoint catalog

| Method | Path | Auth | Purpose |
|--------|------|------|---------|
| `GET` | `/health` | none | Liveness/readiness |
| `GET` | `/bible/translations` | yes | List enabled translations (drives the version switcher) |
| `GET` | `/bible/{translation}/books` | yes | Books for a translation, grouped by testament (OT/NT tabs) |
| `GET` | `/bible/{translation}/{book}/chapters` | yes | Chapter list + counts for a book |
| `GET` | `/bible/{translation}/{book}/{chapter}` | yes | Full chapter with numbered verses (the reader; cached on device) |
| `GET` | `/bible/search` | yes | Cross-translation verse search (`q`, `translation?`, `book?`, paging) |
| `POST` | `/ai/categorize` | yes | Suggest categories for verse/reflection/prayer text |
| `GET` | `/ai/categories` | yes | The active taxonomy (11 tags) for chip rendering |
| `GET` | `/search` | yes | Smart search across verses + (proxied) suggested topics |

> Reminder: user CRUD (verses, reflections, prayers, reminders) is **not** in this API — clients write Firestore directly. The API is AI + Bible + Search only.

### 11.3 Selected request/response schemas

**`GET /bible/{translation}/books` → 200**
```json
{
  "translation": "KJV",
  "testaments": {
    "OT": [{ "osisCode": "Gen", "name": "Genesis", "order": 1, "chapterCount": 50 }],
    "NT": [{ "osisCode": "John", "name": "John", "order": 43, "chapterCount": 21 }]
  }
}
```

**`GET /bible/KJV/John/3` → 200**
```json
{
  "translation": "KJV",
  "book": "John",
  "bookName": "John",
  "chapter": 3,
  "verseCount": 36,
  "verses": [
    { "number": 1, "text": "There was a man of the Pharisees, named Nicodemus..." },
    { "number": 16, "text": "For God so loved the world..." }
  ]
}
```

**`POST /ai/categorize` → request**
```json
{
  "text": "I am worried about my future",
  "context": "reflection",          // "verse" | "reflection" | "prayer"
  "maxSuggestions": 3,
  "locale": "en"
}
```
**→ 200**
```json
{
  "suggestions": [
    { "slug": "faith", "label": "Faith", "confidence": 0.91 },
    { "slug": "hope",  "label": "Hope",  "confidence": 0.78 },
    { "slug": "peace", "label": "Peace", "confidence": 0.55 }
  ],
  "provider": "gemini",              // or "openai" | "keyword"
  "fallbackUsed": false
}
```
For a prayer like *"Please pray for my mother's health"* the service returns Healing, Family, Faith — exactly the requirement's example. Suggestions are always rendered as **editable chips**; nothing is auto-applied.

**`GET /bible/search?q=hope&translation=KJV&limit=20` → 200**
```json
{
  "query": "hope",
  "results": [
    { "reference": "Jeremiah 29:11", "translation": "KJV", "book": "Jer",
      "chapter": 29, "verse": 11, "text": "For I know the thoughts...", "rank": 0.97 }
  ],
  "nextCursor": null
}
```

### 11.4 Clean Architecture mapping (FastAPI)

| Layer | Contents |
|-------|----------|
| **API** | FastAPI routers, Pydantic request/response schemas, dependency injection (auth, db session), error handlers |
| **Application** | Use-cases: `CategorizeTextUseCase`, `GetChapterUseCase`, `SearchVersesUseCase`, `ListTranslationsUseCase` |
| **Domain** | Entities (`Verse`, `Chapter`, `Category`, `Suggestion`), ports/interfaces (`AICategorizationProvider`, `BibleProvider`, `BibleRepository`) |
| **Infrastructure** | Adapters: `OpenAIProvider`, `GeminiProvider`, `KeywordRuleProvider`, `LocalBundledProvider`, SQLAlchemy repositories, Firebase token verifier, settings |

Dependencies point inward; the domain depends on nothing framework-specific, which keeps providers swappable and unit-testable.

---

## 12. AI Verse Categorization Workflow

AI **only suggests** categories from the fixed 11-tag taxonomy; the user accepts, edits, adds, or removes before saving (ADR-006). The service is provider-agnostic and never hard-fails.

### 12.1 Provider abstraction

```python
# domain/ports.py
class AICategorizationProvider(Protocol):
    async def suggest(self, text: str, context: str,
                      max_suggestions: int) -> list[Suggestion]: ...
    @property
    def name(self) -> str: ...
```

Concrete adapters in `infrastructure/ai/`: `GeminiProvider` (Google — **MVP default**), `OpenAIProvider` (GPT — optional, addable later), `KeywordRuleProvider` (deterministic fallback). A `ProviderFactory` reads config and returns an ordered chain.

### 12.2 Selection & fallback chain

```
Config: AI_PROVIDER=gemini (MVP default) | openai ; AI_FALLBACK=keyword ; AI_TIMEOUT_MS=2500
Request → primary provider (default: Gemini)
  ├─ success within timeout → return suggestions (fallbackUsed=false)
  ├─ timeout / 5xx / rate-limit / no API key → try secondary (OpenAI) if configured
  └─ all LLMs fail / none configured → KeywordRuleProvider (fallbackUsed=true, provider="keyword")
```

The keyword provider is **always available**, so `/ai/categorize` returns 200 with usable suggestions even with zero AI keys configured. Latency budget: LLM call capped at `AI_TIMEOUT_MS` (default 2.5 s); the client shows a brief "Suggesting…" state and renders chips on return.

### 12.3 Prompt design (LLM providers)

System prompt constrains output to the taxonomy and forbids prose:

```
You are a tagging assistant for a Christian journaling app.
Choose 1–{max} categories from EXACTLY this list:
[Strength, Faith, Hope, Wisdom, Prayer, Love, Forgiveness, Healing, Peace, Gratitude, Encouragement].
Return strict JSON: {"suggestions":[{"slug","label","confidence"}]}.
Do not invent categories. Do not add commentary.
```

Output is validated against the taxonomy; any out-of-vocabulary tag is dropped. Responses are cached by `input_hash` to cut cost and latency on repeats.

### 12.4 Keyword fallback (deterministic)

Each category in `categories.synonyms` carries a weighted keyword/stem list (e.g., *healing* ← heal, sick, health, recovery, pain; *anxiety→faith/hope/peace* mapping for worry, afraid, fear, worried). The fallback lowercases, tokenizes/stems the input, scores categories by weighted matches, and returns the top-N above a threshold. Worked examples from the brief:

| Input | Keyword hits | Suggested |
|-------|-------------|-----------|
| "I am worried about my future" | worried/future → faith, hope, peace | Faith, Hope, Peace |
| "Please pray for my mother's health" | mother→family, health→healing, pray→faith | Healing, Family, Faith |

### 12.5 Client UX contract

1. User types reflection / prayer → on blur or "Suggest" tap, client calls `POST /ai/categorize`.
2. Suggested chips render in the **outlined/suggested** state (matches the design's outlined "Hope" chip).
3. Tapping a chip toggles it to **filled/selected** (gold). User can also add a custom tag or remove any.
4. Only the user-confirmed `categories` array is written to Firestore; `aiSuggested` is stored alongside for accept-rate analytics.

---

## 13. Bible Provider Abstraction

All Bible content flows through one interface so the source (bundled, external, licensed) is swappable without touching the app or the rest of the API.

### 13.1 Interface & adapters

```python
# domain/ports.py
class BibleProvider(Protocol):
    async def list_translations(self) -> list[Translation]: ...
    async def list_books(self, translation: str) -> list[Book]: ...
    async def get_chapter(self, translation: str, book: str, chapter: int) -> Chapter: ...
    async def search(self, query: str, translation: str | None) -> list[VerseHit]: ...
```

| Adapter | MVP | Source | Notes |
|---------|-----|--------|-------|
| `LocalBundledProvider` | ✅ | Postgres seeded from bundled KJV/WEB JSON | Fast, offline-friendly, license-clean |
| `ExternalApiProvider` | scaffold | API.Bible / other | Config-gated; for translations not bundled |
| `LicensedProvider` | Phase 2 | NIV/ESV under license | Enabled per-translation via `translations.is_enabled` |

`BibleProviderFactory` resolves the adapter per requested translation (bundled KJV/WEB hit Postgres; a future NIV request routes to the licensed adapter). The reader is identical regardless of source.

### 13.2 Offline & performance strategy

- **Bundled assets:** KJV/WEB ship inside the app (`assets/bibles/`) **and** are seeded server-side. First read can come straight from the bundle even with no network.
- **Device cache:** chapters fetched from the API are cached (Hive/Drift) keyed by `(translation, book, chapter)`; the `chapterProvider` is `keepAlive` so re-opening is instant.
- **Fast chapter loading:** server returns a whole chapter in one indexed query (`(book_id, number)`), gzipped; typical chapter < 30 KB.
- **Search:** Postgres `tsvector` GIN index across enabled translations; `to_tsquery` with rank ordering.
- **Translation switcher:** `bibleTranslationProvider` holds the active code (persisted to the user profile); changing it re-resolves providers and re-fetches/caches.

---

## 14. Authentication & Security

### 14.1 Flows (from screens 1–8)

- **Splash** → checks persisted session via `authStateProvider`; routes to Home if signed in, else Onboarding/Welcome.
- **Onboarding** (3 pages) → `Skip`/`Next`/`Get Started`; a `hasSeenOnboarding` flag in secure storage prevents replay.
- **Create Account** → Firebase email/password `createUserWithEmailAndPassword` + Google + Apple; on success writes the `users/{uid}` profile doc.
- **Login** → email/password + Google + Apple; "Forgot password?" → Reset Password.
- **Reset Password** → `sendPasswordResetEmail`.

### 14.2 Security measures

- Firebase ID tokens are short-lived; the Dio auth interceptor attaches a fresh token and refreshes on 401.
- Tokens/refresh handled by the Firebase SDK; **flutter_secure_storage** holds only non-Firebase secrets (e.g., onboarding flag, optional biometric lock preference).
- FastAPI verifies every token with the Admin SDK; no endpoint trusts a client-supplied `uid`.
- Firestore/Storage security rules enforce owner-only access (Section 9.4).
- Apple Sign-In is mandatory for App Store compliance because Google sign-in is offered.
- Secrets (AI keys, DB URL, service accounts) live in Secret Manager / CI secrets — never in the repo or client.
- PII minimization: the AI service stores only an input hash for telemetry, never raw reflection text.

---

## 15. Notifications (FCM) Architecture

Four reminder types from the Reminders screen plus a daily-verse push.

| Reminder | Trigger | Mechanism |
|----------|---------|-----------|
| Bible Reading (e.g., 7:00 AM) | local time | on-device scheduled local notification |
| Reflection (e.g., 9:00 PM) | local time | on-device scheduled local notification |
| Verse Review (toggle) | local time | on-device scheduled local notification |
| Prayer (e.g., 6:00 AM) | local time | on-device scheduled local notification |
| Daily Verse | server | Cloud Function (Pub/Sub scheduler) → FCM push to stored tokens |

- **Local notifications** (`flutter_local_notifications`) handle exact-time, offline-capable reminders; settings persist to `users/{uid}/reminders`.
- **FCM** handles server-initiated daily-verse pushes; a Cloud Function reads enabled tokens from `users/{uid}/devices` and sends at the configured hour, respecting `notificationsEnabled`.
- Toggling a reminder updates Firestore and reschedules local notifications; permission prompts are requested contextually on first enable.
- Timezone-aware scheduling using the device zone; re-scheduled on app start and on reboot (Android `BOOT_COMPLETED`).

---

## 16. Smart Search

The Search screen offers a query field, **Suggested Topics** chips (Hope, Faith, Fear, Anxiety…), and result sections for **Verses** and **Reflections**.

- **Verses** → `GET /bible/search` (Postgres full-text, ranked, cross-translation).
- **Reflections** → searched **client-side over Firestore** (owner's reflections are already cached offline); the repository filters by text/category. Keeps personal content private and avoids syncing it to the server.
- **Suggested Topics** → seeded from the taxonomy + trending categories; tapping a chip runs a category-scoped search.
- Debounced input (~300 ms); results render in `AsyncValue` sections with empty/error states.

---

## 17. Screen → Feature → Data Traceability Matrix

Every one of the 21 design screens maps to a feature module, data source, and API.

| # | Screen | Feature module | Data source | API |
|---|--------|----------------|-------------|-----|
| 1 | Splash | auth | secure storage / auth state | — |
| 2–4 | Onboarding 1–3 | auth/onboarding | secure storage flag | — |
| 5 | Welcome | auth | — | — |
| 6 | Create Account | auth | Firebase Auth + `users/{uid}` | — |
| 7 | Login | auth | Firebase Auth | — |
| 8 | Reset Password | auth | Firebase Auth | — |
| 9 | Home | home | Firestore (reflections, profile) + AI verse-of-day | `GET /bible/...` for VOTD |
| 10 | Bible browser | bible | API + cache | `/bible/{t}/books` |
| 11 | Bible reader | bible | API + cache | `/bible/{t}/{book}/{ch}` |
| 12 | Saved Verses | verses | `saved_verses` | `GET /ai/categories` (chips) |
| 13 | Add Reflection | reflections | `reflections` | `POST /ai/categorize` |
| 14 | Voice Reflection | voice_notes | Storage + `reflections` | `POST /ai/categorize` |
| 15 | My Journal | journal | merged `saved_verses`+`reflections` | — |
| 16 | Search | search | `/bible/search` + Firestore | `/bible/search`, `/search` |
| 17 | Prayers | prayer | `prayers` | — |
| 18 | New Prayer | prayer | `prayers` | `POST /ai/categorize` |
| 19 | Prayer Detail | prayer | `prayers` + `prayer_notes` | — |
| 20 | Reminders | reminders | `reminders` + local notifications + FCM | — |
| 21 | Profile & Settings | profile | `users/{uid}` | `/bible/translations` |

---

## 18. Sprint-by-Sprint Implementation Plan

Two-week sprints, three developers (Section 19), target **MVP in 6 sprints (~12 weeks)** plus a hardening sprint. Each sprint ends with a demoable build on TestFlight/Internal Testing.

### Sprint 0 — Foundations (1 week, pre-sprint)
**Goal:** repos, environments, skeletons, CI green.
- Monorepo, branch strategy, CI for app + API.
- Firebase projects (dev/staging/prod), FlutterFire config, flavors.
- Flutter app skeleton: theme/tokens from Section 5, GoRouter shell, design-system widget stubs (`packages/fj_ui`).
- FastAPI skeleton (Clean Architecture layers), Dockerfile, Cloud Run dev deploy, `/health`.
- Postgres provisioned; Alembic baseline; bundled KJV/WEB seed script (can run partially).
**Exit:** app boots to a themed empty Home behind a mocked auth; API `/health` live; CI green.

### Sprint 1 — Authentication & navigation shell
**Goal:** a user can sign up, sign in, and land on Home.
- Splash, Onboarding (3 pages + dots), Welcome.
- Create Account, Login (email + Google + Apple), Reset Password.
- `users/{uid}` profile creation; `authStateProvider` router redirects.
- Bottom-nav `StatefulShellRoute` with the 5 tabs (empty screens).
**Exit:** full auth journey works on Android + iOS; session persists.

### Sprint 2 — Bible reading (browser + reader)
**Goal:** read any KJV/WEB chapter, offline.
- `/bible` endpoints + Postgres queries + full KJV/WEB seed.
- Bible browser (OT/NT tabs, book list with icons, version dropdown).
- Reader (numbered verses, chapter nav, text-size, translation switch) + device cache.
**Exit:** browse → open John 3 → read offline; switch KJV↔WEB.

### Sprint 3 — Verses, reflections & AI categorization
**Goal:** save verses and write reflections with AI tags.
- Save-verse action + Saved Verses (category chips, filter).
- Add Reflection (editor, 0/1000 counter).
- `POST /ai/categorize` with OpenAI/Gemini abstraction + keyword fallback + `/ai/categories`.
- Suggested→selected chip UX; write to Firestore with `aiSuggested`.
**Exit:** save a verse with AI-suggested tags; write a reflection; both appear in data.

### Sprint 4 — Voice notes & Journal
**Goal:** record audio reflections; unified timeline.
- Voice Reflection (record, waveform, timer, play/re-record/delete) → Firebase Storage upload.
- My Journal timeline (date grouping, type icons, time-range filter chips).
**Exit:** record + save a voice note; see verses/text/voice merged in Journal.

### Sprint 5 — Prayer tracker & Search
**Goal:** full prayer lifecycle + search.
- Prayers list (status filter chips, FAB), New Prayer (with AI category suggest), Prayer Detail (status pills, testimony, notes, Mark Answered).
- Search screen (verses via API, reflections client-side, suggested topics).
**Exit:** create → track → answer a prayer with testimony; search returns verses + reflections.

### Sprint 6 — Reminders, profile & polish
**Goal:** notifications, settings, design fidelity.
- Reminders (4 toggles + times) → local notifications; daily-verse Cloud Function + FCM.
- Profile & Settings (translation, theme, notifications, privacy, help; edit profile + avatar upload).
- Pixel-fidelity pass vs. the design file; empty/error/loading states; accessibility.
**Exit:** reminders fire; settings persist; screens match the design.

### Sprint 7 — Hardening & release
**Goal:** ship.
- Test coverage to target, performance, crash/analytics (Crashlytics), security review.
- Store assets, privacy nutrition labels, Play/App Store submission; staged backend rollout.
**Exit:** production release candidates submitted.

```
S0  Foundations            ▓
S1  Auth & shell             ▓▓
S2  Bible reading              ▓▓
S3  Verses + Reflections + AI    ▓▓
S4  Voice + Journal                ▓▓
S5  Prayer + Search                  ▓▓
S6  Reminders + Profile + polish       ▓▓
S7  Hardening + release                  ▓▓
```

---

## 19. Developer Task Breakdown (3 Developers)

Three roles with clear ownership and minimal collision. All three share design-system and review duties.

- **Dev A — Mobile/UI Lead (Flutter):** design system, navigation, auth, Bible reader UI, journal, polish.
- **Dev B — Backend/AI Engineer (FastAPI/Python):** API, AI abstraction, Bible service, Postgres, search, Cloud Functions.
- **Dev C — Full-stack/Platform (Flutter + Firebase/DevOps):** Firestore data layer, Storage/voice, notifications, CI/CD, Phase-2 web portal groundwork.

### 19.1 Ownership by feature

| Area | Dev A | Dev B | Dev C |
|------|:----:|:----:|:----:|
| Design system / theme / widgets | ● | | ◐ |
| Navigation shell / routing | ● | | |
| Auth screens & flows | ● | | ◐ (Firebase config) |
| Firestore data layer & repos | | | ● |
| Bible API + Postgres + seed | | ● | |
| Bible browser/reader UI + cache | ● | ◐ | |
| AI categorize endpoint + providers | | ● | |
| AI chip UX in app | ● | | |
| Voice record + Storage upload | | | ● |
| Journal timeline | ● | | ◐ |
| Prayer tracker (UI + data) | ◐ | | ● |
| Smart search (API + UI) | ◐ | ● | |
| Reminders + FCM + Cloud Functions | | ◐ | ● |
| CI/CD, flavors, releases | | ◐ | ● |

(● = owner, ◐ = contributor)

### 19.2 Per-sprint task tickets

**Sprint 1 — Auth & shell**
- *Dev A:* AUTH-01 Splash+routing redirect · AUTH-02 Onboarding (3 pages, dots, skip) · AUTH-03 Welcome · AUTH-04 Login UI · AUTH-05 Create Account UI · AUTH-06 Reset Password UI · NAV-01 Bottom-nav StatefulShellRoute.
- *Dev C:* FB-01 Firebase Auth datasource (email/Google/Apple) · FB-02 `users/{uid}` profile write · FB-03 secure-storage onboarding flag · CI-01 mobile CI.
- *Dev B:* API-00 FastAPI skeleton + `/health` · INFRA-01 Cloud Run dev · DB-00 Alembic baseline.

**Sprint 2 — Bible reading**
- *Dev B:* BIB-01 schema+migrations · BIB-02 seed KJV/WEB · BIB-03 `/translations` · BIB-04 `/books` · BIB-05 `/chapter` · BIB-06 provider abstraction.
- *Dev A:* BIB-07 browser (tabs/list/dropdown) · BIB-08 reader (verses/nav/text-size) · BIB-09 translation switcher UI.
- *Dev C:* BIB-10 device chapter cache (Hive/Drift) · BIB-11 offline bundled assets.

**Sprint 3 — Verses, reflections & AI**
- *Dev B:* AI-01 provider interface · AI-02 OpenAI adapter · AI-03 Gemini adapter · AI-04 keyword fallback + synonyms seed · AI-05 `/ai/categorize` · AI-06 `/ai/categories` · AI-07 caching + telemetry.
- *Dev A:* VRS-01 save-verse action · VRS-02 Saved Verses + filters · REF-01 Add Reflection editor · REF-02 suggested→selected chip UX.
- *Dev C:* VRS-03 `saved_verses` repo+provider · REF-03 `reflections` repo+provider · DATA-01 Firestore indexes/rules.

**Sprint 4 — Voice & Journal**
- *Dev C:* VOI-01 audio recorder · VOI-02 Storage upload + rules · VOI-03 voice `reflections` doc · JRN-02 journal repo (merge).
- *Dev A:* VOI-04 record UI (waveform/timer/transport) · JRN-01 timeline UI (grouping, type icons, filters).
- *Dev B:* SCH-00 daily-verse Cloud Function scaffold.

**Sprint 5 — Prayer & Search**
- *Dev C:* PRY-01 `prayers`/`prayer_notes` repos · PRY-02 status transitions.
- *Dev A:* PRY-03 Prayers list+filters+FAB · PRY-04 New Prayer · PRY-05 Prayer Detail (pills/testimony/notes/Mark Answered).
- *Dev B:* SRCH-01 `/bible/search` FTS · SRCH-02 suggested topics. *Dev A:* SRCH-03 Search UI + Firestore reflection search.

**Sprint 6 — Reminders, profile, polish**
- *Dev C:* REM-01 local notifications · REM-02 reschedule on boot/start · REM-03 FCM token store · NOT-01 daily-verse send function.
- *Dev A:* REM-04 Reminders UI · PRO-01 Profile & Settings · PRO-02 edit profile + avatar · UX-01 fidelity/empty/error pass.
- *Dev B:* PERF-01 API perf/caching · OBS-01 logging/metrics.

**Sprint 7 — Hardening**
- *All:* TEST-① coverage to target · SEC-01 security review · REL-01 store assets/submission (Dev C) · REL-02 staged backend rollout (Dev B) · A11Y-01 accessibility audit (Dev A).

---

## 20. Testing, CI/CD & DevOps

### 20.1 Test strategy

| Layer | Tooling | Targets |
|-------|---------|---------|
| Flutter unit | `flutter_test`, `mocktail` | use-cases, repositories (fakes), notifiers, keyword logic |
| Flutter widget | `flutter_test` | design-system widgets, key screens, chip toggle states |
| Flutter integration | `integration_test` | auth journey, save-verse-with-AI, record-voice, create-prayer |
| Backend unit | `pytest` | use-cases, provider adapters (mocked LLM), keyword fallback |
| Backend API | `pytest` + `httpx` | endpoint contracts, auth verification, error envelopes |
| Backend data | `pytest` + ephemeral Postgres | repositories, search ranking |
| Contract | OpenAPI snapshot | client/server schema drift |

Coverage gate: 70%+ on domain/application layers both sides; AI fallback and security rules have dedicated tests.

### 20.2 CI/CD

- **Mobile CI** (`mobile_ci.yaml`): `flutter analyze` → `flutter test` → build Android (AAB) + iOS (no-codesign) on PR; on tag, signed builds to Play Internal Testing + TestFlight (Fastlane).
- **Backend CI** (`backend_ci.yaml`): `ruff` + `mypy` → `pytest` → Docker build → push → deploy to Cloud Run (dev on merge, staging on tag, prod on manual approval).
- **Firestore rules** tested with the emulator in CI; rules + indexes deployed via `firebase deploy`.
- Secrets via GitHub Actions secrets / GCP Secret Manager; environments gated with required reviewers for prod.

### 20.3 Environments

`dev` → `staging` → `prod`, each a separate Firebase project + Cloud Run service + Postgres instance. Flutter flavors select the right config at build time. Observability: Crashlytics + Analytics (app), structured logs + Cloud Monitoring + error tracking (API).

---

## 21. Non-Functional Requirements

| Attribute | Target |
|-----------|--------|
| Cold start (app) | < 2.5 s on mid-tier device |
| Chapter load (cached) | < 100 ms; (network) < 600 ms p95 |
| AI suggest latency | < 2.5 s p95 (then fallback); UI never blocks save |
| Offline | Read bundled Bible, view cached saved content, queue writes (Firestore offline) |
| Availability (API) | 99.5% MVP; stateless + autoscaling Cloud Run |
| Security | Owner-only data, verified tokens, secrets in vault, OWASP MASVS L1 |
| Accessibility | WCAG 2.1 AA targets; ≥ 44px touch targets; dynamic type; contrast checked |
| Privacy | No raw reflection text leaves device except to the AI endpoint at the user's action; telemetry hashed |
| Scalability | Firestore scales per-user; Postgres read-heavy Bible workload cacheable/CDN-able |
| Localization | English at MVP; i18n scaffolding + Tamil planned (Phase 2) |

---

## 22. Risks, Assumptions & Phase 2

### 22.1 Risks & mitigations

| Risk | Mitigation |
|------|-----------|
| Licensed translations (NIV/ESV) blocked on agreements | Ship KJV/WEB; provider abstraction makes adding them config-only |
| AI cost/latency/availability | Caching + strict timeouts + keyword fallback that never fails |
| Apple Sign-In review compliance | Implemented from Sprint 1 alongside Google |
| Two backends (Firebase + FastAPI) complexity | Strict ownership boundaries (Section 4.2); no overlapping responsibilities |
| Voice file storage cost/abuse | Size/content-type limits, per-user rules, optional retention policy |
| Firestore query limits for Journal at scale | `journal_index` denormalization path ready (Section 9.3) |

### 22.2 Assumptions

- Firebase is the approved identity/data platform (supersedes the original Postgres-for-user-data note; Postgres is retained for Bible/AI only).
- One AI key (OpenAI or Gemini) available for staging/prod; keyword fallback covers the rest.
- KJV/WEB public-domain JSON sources are acceptable seed data.
- Single region at MVP; multi-region deferred.

### 22.3 Phase 2 (post-MVP)

- **Read-only Flutter Web portal** — dashboard for saved verses, reflections, voice reflections, prayer requests, and prayer history (auth required, no editing). The `packages/fj_models` + repository interfaces are shared so the portal reuses the mobile data layer.
- NIV/ESV (licensed) and Tamil translations via the existing provider abstraction.
- Reading plans, verse-of-the-day history, prayer sharing, streaks/insights, semantic search via embeddings.

---

*End of document. This architecture is intentionally MVP-scoped (Android + iOS) with Phase-2 seams (web portal, licensed/Tamil translations) designed in from day one. The 21-screen design file remains the authority for all visual and interaction detail.*
