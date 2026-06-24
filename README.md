# Faith Journal — Monorepo

Mobile-first Christian spiritual-growth app. **Android + iOS** (Flutter) for the MVP;
a read-only **Web Portal** follows in Phase 2.

Architecture is **Firebase-first** (Auth, Firestore, Storage, FCM) with a **FastAPI**
service layer that owns only **AI categorization** and **Bible content**.
Full design rationale in [`docs/Faith_Journal_Architecture.md`](docs/Faith_Journal_Architecture.md).

## Layout
```
apps/mobile     Flutter app (Riverpod · GoRouter · Freezed · Dio · Firebase)
services/api    FastAPI (Clean Architecture): AI (Gemini default + keyword fallback) + Bible
packages        Shared Dart packages: fj_core · fj_ui · fj_models
firebase        Firestore/Storage rules, indexes, Cloud Functions
infra           Docker, Cloud Run, Terraform
docs            Architecture doc + ADRs + system diagram
```

## Quick start
```bash
make api.dev     # run FastAPI locally (keyword fallback, bundled KJV/WEB — no keys needed)
make api.test    # run backend tests (9 passing)
make app.setup   # flutter pub get + codegen
make app.run     # run the Flutter app (dev flavor)
```

## Decisions (locked)
- Delivery: mobile first; read-only web portal in Phase 2.
- AI: configurable provider, **Gemini default**, OpenAI addable later, keyword fallback.
- Bible: bundle KJV + WEB; provider abstraction for external/licensed (NIV/ESV/Tamil) later.
- Data: Firebase Auth + Firestore + Storage + FCM; FastAPI only for AI + Bible.
