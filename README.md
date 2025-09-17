# Taskmaster Party App
An unofficial, fan-made mobile and web application for playing Taskmaster-style party games with friends, whether you're in the same room or across the globe.

🚀 Project Status
**Current Version**: MVP Complete with 200+ Tasks and Advanced Features
**Mode**: Mock Services (No Firebase Required for Testing)

## ✨ Features Implemented

### Core Features ✅
- **Game Creation & Management**: Create and manage party games
- **User Authentication**: Login/Register with mock auth service  
- **Real-time Gameplay**: Live task updates and score tracking
- **Remote Judging**: Designated Taskmaster awards points
- **Cross-Platform**: iOS, Android, and Web support

### Advanced Features ✅  
- **200+ Prebuilt Tasks**: Across 8 categories (Physical, Creative, Mental, etc.)
- **Team vs Team Mode**: Divide players into competing teams
- **Secret Missions**: 17 hidden individual tasks
- **Task Modifiers**: 18 random challenges that multiply points
- **Community Tasks**: Submit and browse user-generated tasks
- **Geo-Located Tasks**: 12 location-based challenge types
- **AR Tasks**: 7 augmented reality task types (UI ready)
- **AI Task Generation**: Smart task creation system
- **Episode Creator**: Build custom task sequences with timestamps

### Monetization (UI Ready) 💰
- **Store Interface**: Complete with Pro version upgrade
- **Ad Spaces**: Placeholder ads ready for AdMob
- **Task Packs**: Premium content marketplace UI
- **Mock Purchase Flow**: Test the full purchase experience

🛠️ Technology Stack
Frontend & App Logic: Flutter - For a single codebase across all platforms.

Backend Services: Firebase

Authentication: For secure user login (Google Sign-In, Email/Password).

Firestore: As the real-time NoSQL database for game state, tasks, scores, and video links.

Hosting: For deploying the web version of the app.

CI/CD & Deployment: Codemagic - To automate the build and release process for the iOS and Android app stores.

## ⚙️ Quick Start

### Prerequisites
- Flutter SDK installed ([Installation Guide](https://flutter.dev/docs/get-started/install))
- Chrome browser (for web testing) or any modern browser
- Git

### Running the App

```bash
# Clone the repository
git clone <your-repo-url>
cd taskmaster-app

# Install dependencies
flutter pub get

# Run on Chrome
flutter run -d chrome

# OR run on web server (opens in any browser)
flutter run -d web-server --web-port=8080
```

### What Works in Mock Mode
- ✅ Complete game flow from creation to scoring
- ✅ All 200+ tasks available
- ✅ User authentication (mock login)
- ✅ Team assignments with drag-and-drop
- ✅ Community task submission and browsing
- ✅ Task modifiers and secret missions
- ✅ Store interface (mock purchases)
- ✅ All advanced features functional

### Production Setup (When Ready)
1. **Firebase Setup**: Configure Firebase project and run `flutterfire configure`
2. **AdMob Integration**: Add real ad unit IDs in `ad_service.dart`
3. **In-App Purchases**: Configure products in App Store/Play Store
4. **Deploy**: Build for production with `flutter build web/ios/android`

## 📱 Platform Support
- **Web**: ✅ Fully functional (recommended for testing)
- **Android**: ✅ Ready (requires Android SDK)
- **iOS**: ✅ Ready (requires macOS and Xcode)
- **Linux Desktop**: ✅ Supported
- **Windows**: ⚠️ Requires additional setup
- **macOS**: ⚠️ Requires additional setup

This is an independent project created by a fan and is not affiliated with the official Taskmaster show or its creators.
