# Contributing to Faith Journal

Welcome. This doc gets you from `git clone` to a working dev loop in ~30 minutes.

## 1. Prerequisites

Install these before cloning:

| Tool | Version | macOS install |
|---|---|---|
| **Python** | ≥ 3.12 (3.13 recommended) | `brew install python@3.13` |
| **Flutter** | ≥ 3.22 (stable channel) | `brew install --cask flutter` |
| **Firebase CLI** | latest | `npm i -g firebase-tools` |
| **Android Studio** | latest | https://developer.android.com/studio (for Android SDK + emulator) |
| **Xcode** | 15+ (iOS dev only) | App Store |
| **GitHub CLI** (optional) | latest | `brew install gh` |

Verify your environment:
```bash
python3.13 --version    # Python 3.13.x
flutter doctor          # all green checkmarks (or yellow OK for what you don't need)
```

## 2. Clone & get secrets

```bash
git clone https://github.com/SelinyxTech/faith-journal.git
cd faith-journal
```

**Ask Sam (or check 1Password) for these gitignored files** — the build won't work without them:

| File | Where it goes |
|---|---|
| `google-services.json` | `apps/mobile/android/app/` |
| `GoogleService-Info.plist` (iOS only) | `apps/mobile/ios/Runner/` |
| `.env` (start from `.env.example`) | `services/api/.env` |

These contain Firebase project IDs and (in `.env`) AI provider API keys. **Never commit them.**

## 3. One-time setup

```bash
make api.venv      # creates services/api/.venv and installs Python deps (~2 min)
make app.setup     # flutter pub get + Dart codegen (~3 min)
```

## 4. Daily dev loop

Two terminals:

```bash
# Terminal 1 — backend on http://127.0.0.1:8080
make api.dev

# Terminal 2 — mobile on your connected device/emulator
make app.run
```

The mobile app talks to the local API via `AppConfig.dev` (see [apps/mobile/lib/core/config/app_config.dart](apps/mobile/lib/core/config/app_config.dart)). On Android emulator the API host is `10.0.2.2:8080`; on iOS simulator it's `127.0.0.1:8080`.

### Useful endpoints while developing

- **Swagger UI**: http://127.0.0.1:8080/docs (interactive — click any endpoint → "Try it out")
- **OpenAPI spec**: http://127.0.0.1:8080/openapi.json
- **Health**: http://127.0.0.1:8080/api/v1/health

## 5. Running tests

```bash
make api.test       # backend pytest (9 tests, ~1s)
make app.test       # Flutter widget tests
```

Before opening a PR, run both locally — CI ([.github/workflows](.github/workflows)) runs the same suites on every push and PR.

## 6. Branching & PR workflow

We use **trunk-based development with feature branches**:

- `main` is **protected** — no direct pushes, PR + 1 approval required
- Branch names: `<initials>/<short-description>` — e.g. `ss/add-prayer-reminders`, `jb/fix-login-loop`
- Keep branches short-lived (< 3 days) and PRs small (< 400 lines if possible)
- One logical change per PR — easier to review, easier to revert

### Creating a PR

```bash
git checkout -b ss/my-feature
# ... make changes ...
git commit -m "feat: add prayer reminder scheduling"
git push -u origin ss/my-feature
gh pr create --fill   # or open in the browser
```

### Commit message style

Use [Conventional Commits](https://www.conventionalcommits.org/):

- `feat: ...` — new user-facing feature
- `fix: ...` — bug fix
- `refactor: ...` — code change with no behavior change
- `docs: ...` — README/docs only
- `test: ...` — tests only
- `chore: ...` — tooling, deps, build config

Example: `feat(bible): add cross-reference popover`

## 7. Code style

### Backend (Python)

- Formatted by `ruff` — CI fails if `ruff check app` reports issues
- Type hints on all public functions
- Follow the existing Clean Architecture layout: `domain/` → `application/` → `infrastructure/` → `api/`
- New AI provider? Add it under [services/api/app/infrastructure/ai/](services/api/app/infrastructure/ai/) and register in [factory.py](services/api/app/infrastructure/ai/factory.py)

### Mobile (Dart/Flutter)

- Formatted by `dart format` (run `dart format lib test`)
- Lints from `flutter_lints` — keep `flutter analyze` clean before pushing
- State management: **Riverpod** with `riverpod_generator` (see existing `@riverpod` annotations)
- Routing: **GoRouter** — add new routes in [apps/mobile/lib/core/router/app_router.dart](apps/mobile/lib/core/router/app_router.dart)
- Models: **Freezed** + `json_serializable` — run `dart run build_runner build --delete-conflicting-outputs` after editing
- Design tokens: use [apps/mobile/lib/core/theme/tokens.dart](apps/mobile/lib/core/theme/tokens.dart) — never hardcode colors or spacing

## 8. Project layout (where to put things)

```
apps/mobile/lib/
  core/         router · theme · network · config (cross-cutting)
  features/     auth · journal · prayer · bible · home · profile (one folder per feature)
  shared/       ai_service · bible_repository (shared between features)
packages/
  fj_core/      utilities used by both mobile and (future) web
  fj_ui/        reusable UI widgets (category chips, etc.)
  fj_models/    DTOs shared with the API
services/api/app/
  api/          FastAPI routes + Pydantic schemas
  application/  use cases (orchestration)
  domain/       entities + ports (interfaces)
  infrastructure/ concrete adapters (Gemini, OpenAI, Firebase, local Bible)
firebase/       Firestore rules, indexes, Cloud Functions
infra/          Docker, Cloud Run, Terraform
```

A new feature usually touches: `features/<feature>/` in mobile + a route in `services/api/app/api/v1/routes/` if it needs backend logic.

## 9. Common issues

**`make api.dev` fails with "python: command not found"**
The Makefile uses `services/api/.venv/bin/python` automatically — run `make api.venv` first.

**Android build fails: "core library desugaring"**
Already fixed in [apps/mobile/android/app/build.gradle.kts](apps/mobile/android/app/build.gradle.kts). If you see this after a rebase, `cd apps/mobile && flutter clean && flutter pub get`.

**iOS build fails: "Firebase not configured"**
Run `flutterfire configure` in `apps/mobile/` — generates `firebase_options.dart` + `GoogleService-Info.plist`. Ask Sam if you don't have access to the Firebase project.

**Fonts not rendering on emulator**
The app bundles Inter + Playfair Display as assets — if you see fallback fonts, run `flutter clean && flutter pub get`.

**Hot reload not picking up `.g.dart` / `.freezed.dart` changes**
Codegen needs to re-run: `dart run build_runner build --delete-conflicting-outputs` (or `watch` instead of `build` to keep it running).

## 10. Who owns what

| Area | Owner |
|---|---|
| Backend (services/api) | Sam |
| Mobile app | TBD — assign in first sprint |
| Firebase rules & functions | Sam |
| CI / infra | Sam |
| Design tokens & theme | TBD |

For anything cross-cutting or unclear, ask in the team Slack channel before opening a PR.

## 11. Getting help

- Architecture questions → [docs/Faith_Journal_Architecture.md](docs/Faith_Journal_Architecture.md)
- API behavior → http://127.0.0.1:8080/docs (Swagger)
- Stuck? Ping the team channel before going down a rabbit hole

Welcome aboard.
