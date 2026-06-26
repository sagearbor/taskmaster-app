# Google Play release (Android)

The app is configured for Google Play internal testing, mirroring the
`fitRival` setup.

## What's already set up
- **Application id:** `com.sagearbor.taskcaster.app` (permanent once published)
- **App name:** "TaskCaster Party" (`android:label`)
- **Launcher icon:** gold star on purple, generated via `flutter_launcher_icons`
  from `assets/icons/app_icon.png` (regenerate with `dart run flutter_launcher_icons`)
- **SDK levels:** `minSdk 23` (Firebase requirement), `targetSdk 35`, `compileSdk 35`, Java 17
- **Release signing:** `android/app/build.gradle` loads `android/key.properties`
  (gitignored). If it's missing, release builds fall back to debug signing.

## Upload keystore
A keystore was generated at:

```
~/taskmaster-upload-keystore.jks   (alias: taskmaster)
```

Its credentials live in **`android/key.properties`** (gitignored — never
committed). 

> ⚠️ **Back up the keystore.** Copy `~/taskmaster-upload-keystore.jks` and the
> `key.properties` values to a password manager (1Password / iCloud Keychain).
> If you lose this keystore you cannot publish updates to the same Play listing
> — Google requires the same signature for every release. (Play App Signing can
> help recover, but don't rely on it.)

To create a fresh keystore instead:

```bash
~/jdk17/Contents/Home/bin/keytool -genkeypair -v \
  -keystore ~/taskmaster-upload-keystore.jks \
  -keyalg RSA -keysize 2048 -validity 10000 -alias taskmaster
```

Then fill `android/key.properties`:

```properties
storePassword=<your password>
keyPassword=<your password>
keyAlias=taskmaster
storeFile=/Users/<you>/taskmaster-upload-keystore.jks
```

## Build the App Bundle

```bash
scripts/make-release.sh
# → build/app/outputs/bundle/release/app-release.aab
```

(That script sets `JAVA_HOME` to `~/jdk17` and runs `flutter build appbundle --release`.)

Bump the version in `pubspec.yaml` (`version: 1.0.0+1` → `1.0.1+2`, etc.) before
each new upload — Play rejects duplicate `versionCode`s.

## Upload to Internal testing
1. Play Console → your app → **Testing → Internal testing → Create new release**
2. Upload `app-release.aab`
3. Add tester emails (or an internal testing email list), save, **review**, roll out
4. Share the opt-in URL with testers; they install via the Play Store link

## Firebase on Android (needed before it runs on a device)
The app uses Firebase. Mobile Firebase config is **not** generated yet — see
`docs/MOBILE_SETUP.md`. Run `flutterfire configure --project=taskmaster-app-3d480`
to produce `android/app/google-services.json` and real
`lib/firebase_options.dart` Android options, then rebuild. Without this,
`Firebase.initializeApp` fails at launch on Android.
