# Mobile Setup (Android / iOS)

The `android/` and `ios/` platform directories now exist (scaffolded via
`flutter create --platforms=android,ios --org com.taskmaster`). **Mobile will
not run yet** — Firebase is only configured for web. Follow these steps to
finish wiring it.

## 1. Generate Firebase config for mobile

```bash
# One-time tooling
dart pub global activate flutterfire_cli

# Interactive — requires `firebase login` and picks the existing project
flutterfire configure --project=taskmaster-app-3d480
```

This regenerates `lib/firebase_options.dart` with real Android/iOS options
(replacing the current `UnsupportedError` placeholders for those platforms) and
writes:
- `android/app/google-services.json`
- `ios/Runner/GoogleService-Info.plist`

Until this runs, `DefaultFirebaseOptions.currentPlatform` throws on mobile and
`Firebase.initializeApp` in `main.dart` will fail at launch.

## 2. Push notifications (FCM) extras

`firebase_messaging` is already a dependency and `NotificationService` is wired
in `main.dart`. To make push actually deliver on mobile:

- **Android:** `flutterfire configure` adds the `google-services` Gradle plugin.
  Confirm `android/app/build.gradle` applies it and the project-level
  `android/build.gradle` has the classpath. Minimum `minSdkVersion 21`.
- **iOS:** enable the **Push Notifications** capability and a Background Modes →
  Remote notifications in Xcode, and upload an APNs key to the Firebase console.

## 3. Bundle / application IDs

Scaffolded with org `com.taskmaster` → application id `com.taskmaster.taskmaster_app`.
Change in `android/app/build.gradle` (`applicationId`) and Xcode
(`PRODUCT_BUNDLE_IDENTIFIER`) before store submission, then re-run
`flutterfire configure` so the registered apps match.

## 4. Build

```bash
flutter build apk            # Android
flutter build ios            # iOS (needs macOS + Xcode)
```

## 5. CI/CD

Codemagic is the intended pipeline (see project docs). Add the generated
`google-services.json` / `GoogleService-Info.plist` as encrypted environment
files there rather than committing them.
