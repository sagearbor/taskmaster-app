# agent.md — taskmaster-app

## Overview
Cross-platform Flutter app for Taskmaster-style party games. Firebase backend, targets iOS/Android/Web simultaneously. Live at https://taskmaster-app-3d480.web.app

## Tech Stack
- Flutter / Dart
- Firebase (Auth, Firestore, Hosting)
- Provider / flutter_bloc state management
- Codemagic (CI/CD)

## Status (last commits)
- **Phase 5 COMPLETE** — MVP done (21/21 days)
- Quick Play feature live
- Firebase Auth + Firestore connected and working
- 225+ prebuilt tasks across 9 categories
- Real-time multi-device sync verified
- 3 critical bugs fixed (tasks display, game list, auth restrictions)
- **Next:** Phase 3 remainder (Async-Optimized features) or mobile deployment

## How to Run
```bash
flutter pub get
flutter run -d chrome    # web
flutter run -d linux     # desktop
flutter doctor           # check environment
```

## Open Tasks
- Phase 3: Reduce Friction (Async-Optimized features)
- Mobile deployment (Google Play + App Store)
- Cloud Functions (deferred, optional)
- See `DEVELOPMENT_CHECKLIST.md` — start next incomplete section

## Branch
- Main: `main`
- Sophie working branch: `sophieArborBot_firstBranch`

## Test Strategy
```bash
flutter test             # all tests
flutter test test/unit/  # unit tests only
```
- Unit tests for BLoCs and repositories
- Widget tests for UI components
- Multi-device testing: see `MULTI_DEVICE_TESTING_GUIDE.md`
- Manual: verify game creation, real-time sync, Quick Play on web
