# Taskmaster App - Setup Guide

## Quick Start (Development Mode)

### Prerequisites
1. **Flutter SDK** - [Install Flutter](https://flutter.dev/docs/get-started/install)
2. **Chrome Browser** - For web development
3. **Git** - For version control

### Installation Steps

1. **Clone the repository:**
```bash
git clone <repository-url>
cd taskmaster-app
```

2. **Install dependencies:**
```bash
flutter pub get
```

3. **Add platform support (if needed):**
```bash
# Add web and linux platform support
flutter create --platforms=web,linux .
```

4. **Run the app with mock services (no Firebase required):**
```bash
# Full app with mock services
flutter run -d chrome -t lib/main_mock.dart

# Simple auth test
flutter run -d chrome -t lib/main_auth_test.dart

# Ultra-simple test (no external dependencies)
flutter run -d chrome -t lib/main_test_simple.dart
```

## Available Entry Points

| Entry Point | Purpose | Command |
|------------|---------|---------|
| `main.dart` | Production app (requires Firebase) | `flutter run -d chrome` |
| `main_mock.dart` | Full app with mock services | `flutter run -d chrome -t lib/main_mock.dart` |
| `main_auth_test.dart` | Authentication testing | `flutter run -d chrome -t lib/main_auth_test.dart` |
| `main_simple.dart` | Simplified app structure | `flutter run -d chrome -t lib/main_simple.dart` |
| `main_test.dart` | Basic functionality test | `flutter run -d chrome -t lib/main_test.dart` |
| `main_test_simple.dart` | Minimal test | `flutter run -d chrome -t lib/main_test_simple.dart` |

## Testing

### Run all tests:
```bash
flutter test
```

### Run specific test:
```bash
flutter test test/path/to/test_file.dart
```

### Run with coverage:
```bash
flutter test --coverage
```

## Troubleshooting

### Issue: "flutter: command not found"
**Solution:** Make sure Flutter is in your PATH:
```bash
export PATH="$PATH:$HOME/flutter/bin"
source ~/.bashrc
```

### Issue: "No supported devices connected"
**Solution:** Add platform support:
```bash
flutter create --platforms=web,linux .
```

### Issue: Corporate Proxy/Zscaler Blocking Resources
**Problem:** Google Fonts and CanvasKit may be blocked by corporate proxies.

**Solutions:**
1. Temporarily disable proxy/Zscaler (if allowed)
2. Use HTML renderer instead of CanvasKit:
   ```bash
   flutter run -d chrome --web-renderer html
   ```
3. Use the simplified test entry points that don't require external resources

### Issue: "Firebase packages causing compilation errors"
**Solution:** Use the mock entry point instead:
```bash
flutter run -d chrome -t lib/main_mock.dart
```

### Issue: Authentication not working
**Note:** Mock authentication accepts:
- Any email containing "@"
- Any password with 6+ characters
- Example: test@example.com / password123

## Development Workflow

1. **Start with mock services** - Use `main_mock.dart` for development
2. **Test features locally** - All features work with mock data
3. **Run tests regularly** - `flutter test`
4. **Use hot reload** - Press 'r' in terminal while app is running
5. **Check different entry points** - Test various scenarios

## Mock Services Available

- **Authentication** - Login/Register with any valid email/password
- **Database** - All game data stored in memory
- **Tasks** - 200+ built-in tasks
- **Community Features** - Task submission, voting
- **Store** - Pro version and task packs (UI only)
- **Ads** - Placeholder ad spaces
- **Location** - Mock GPS for location tasks

## Production Setup (When Ready)

1. **Create Firebase Project** at [firebase.google.com](https://firebase.google.com)
2. **Install FlutterFire CLI:**
   ```bash
   dart pub global activate flutterfire_cli
   ```
3. **Configure Firebase:**
   ```bash
   flutterfire configure
   ```
4. **Update environment variables** in `.env` file
5. **Switch to production entry point:** `main.dart`

## Features Checklist

### ✅ Implemented (Mock)
- [x] User Authentication
- [x] Game Creation & Management
- [x] 200+ Built-in Tasks
- [x] Team Modes (Individual, Teams, Tournament)
- [x] Task Modifiers (18 types)
- [x] Secret Individual Tasks (17 types)
- [x] Location-based Tasks (12 types)
- [x] Community Task Submission
- [x] Voting System
- [x] Puzzle Tasks with Auto-grading
- [x] Store UI (Pro version, Task packs)
- [x] Ad Placeholders

### ⏳ Requires Production Setup
- [ ] Real Firebase Authentication
- [ ] Cloud Firestore Database
- [ ] Google AdMob Integration
- [ ] In-App Purchases
- [ ] Push Notifications
- [ ] Cloud Functions
- [ ] Analytics

## Support

For issues or questions, please check:
1. This setup guide
2. The [development_checklist.md](development_checklist.md)
3. GitHub Issues (if repository is public)