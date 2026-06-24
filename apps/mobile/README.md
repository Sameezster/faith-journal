# Faith Journal — Mobile (Flutter)

Feature-first Clean Architecture. State: Riverpod (code-gen). Routing: GoRouter
(`StatefulShellRoute` for the 5-tab shell). Models: Freezed + json_serializable.

## Setup
    flutter pub get
    dart run build_runner build --delete-conflicting-outputs
    # configure Firebase: flutterfire configure  (generates lib/firebase_options.dart)
    flutter run --flavor dev

## Structure
- `lib/core`      — theme/tokens, router, network (Dio), config/flavors, DI
- `lib/features`  — auth, home, bible, verses, reflections, voice_notes, journal,
                    prayer, search, reminders, profile  (each: data/domain/presentation)
- `lib/shared`    — AI service client (FastAPI /ai), Bible repository (FastAPI /bible + cache)

The API base URL is selected per flavor in `lib/core/config/app_config.dart`.
