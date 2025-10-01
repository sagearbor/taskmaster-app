# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Hygiene Rules

### IMPORTANT: Keep the Repository Clean
- **DO NOT create temporary instruction files** (e.g., IMPLEMENTATION.md, TODO.md, NOTES.md)
- **DO NOT create session-specific files** that won't be used long-term
- **ALWAYS use existing files** for documentation:
  - `DEVELOPMENT_CHECKLIST.md` - for implementation plans and tasks
  - `CLAUDE.md` - for AI instructions and guidelines
  - `README.md` - for project overview and setup
- **ALWAYS work in feature branches** for new development:
  - Create branch: `git checkout -b feature/feature-name`
  - Example: `git checkout -b feature/avatar-system`
- **Clean up before ending session**: Delete any temporary files created during work

## Session Continuity Pattern

When pausing work mid-task, use empty commits for context preservation:

```bash
# Create descriptive branch
git checkout -b <type>/<brief-description>

# Empty commit with session context
git commit --allow-empty -m "<Subject line>

BUGS/FEATURES:
- <What needs to be done>

CONTEXT:
- <Key details from investigation>

NEXT SESSION:
- <First steps to take>

STATUS: <Not started|In progress>
Session: <YYYY-MM-DD>"

# Push to preserve across machines
git push -u origin <branch-name>

# Stay on branch (DO NOT return to main)
```

**Next session:** Branch will be active, `git log -1` shows full context.

## Project Overview

This is a cross-platform Flutter application for hosting Taskmaster-style party games. The app uses Firebase as the backend and targets iOS, Android, and Web platforms simultaneously.

## Technology Stack

- **Framework**: Flutter (latest stable version)
- **Language**: Dart
- **Backend**: Google Firebase (Authentication, Firestore, Hosting)
- **State Management**: Provider or flutter_bloc (be consistent)
- **CI/CD**: Codemagic for mobile deployment

## Development Commands

### Project Setup
```bash
# Create new Flutter project (if not exists)
flutter create taskmaster_app

# IMPORTANT: Add platform support (required for web/desktop)
flutter create --platforms=web,linux,windows .

# Install dependencies
flutter pub get

# Run the app
flutter run -d chrome  # For web
flutter run -d linux   # For Linux desktop

# Check Flutter environment
flutter doctor
```

### Testing
```bash
# Run all tests
flutter test

# Run specific test file
flutter test test/widget_test.dart

# Run integration tests
flutter test integration_test/
```

### Building
```bash
# Build for web
flutter build web

# Build for Android APK
flutter build apk

# Build for iOS (requires macOS)
flutter build ios
```

## Architecture

### Service Layer Pattern
The app follows a service-oriented architecture with dependency injection:

- **Abstract Services**: Define interfaces in `services/` directory
- **Firebase Implementation**: `FirebaseDataService` implements real Firebase logic
- **Mock Implementation**: `MockDataService` provides offline development and testing
- **Dependency Injection**: Use Provider package to inject services into UI

### Data Models (Firestore Collections)

#### `games` Collection
- `gameName`: String
- `creatorId`: String (UID)
- `judgeId`: String (UID)  
- `status`: String ("lobby", "in-progress", "completed")
- `inviteCode`: String (unique shareable code)
- `players`: Array of player objects with userId, displayName, totalScore
- `tasks`: Array of task objects with title, description, taskType, submissions

#### `users` Collection
- Document ID: Firebase Auth UID
- `displayName`: String
- `email`: String
- `createdAt`: Timestamp

#### `community_tasks` Collection
- `title`: String
- `description`: String
- `submittedBy`: String (UID)
- `upvotes`: Number

## Development Workflow

### Mock-First Development
1. Always develop UI against `MockDataService` first
2. Create realistic mock data with `Future.delayed()` to simulate network calls
3. Switch to `FirebaseDataService` only after UI is complete
4. Use dependency injection to swap services

### Testing Requirements
- All new features must include unit tests and widget tests
- Use `MockDataService` for all widget tests
- Test business logic separately from UI components
- Use `flutter_test` framework

### Key Screens Architecture
- **Home Screen**: Game list and "Create New Game" button
- **Create Game Screen**: Game setup form
- **Game Lobby Screen**: Player list, invite code, tasks, start button
- **Task View Screen**: Task display and video link submission
- **Judging Screen**: Judge interface for scoring submissions
- **Scoreboard Screen**: Player scores display

## Firebase Configuration

The app uses Firebase free tier (Spark Plan) with:
- Authentication (Google Sign-In, Email/Password)
- Firestore Database (real-time NoSQL)
- Hosting for web deployment

Firestore should start in Test Mode during development, then switch to production rules before launch.

## Development Phases

Refer to `development_checklist.md` for the complete development roadmap. Key phases:
1. Foundation & Setup (accounts, tools)
2. Core App Development (MVP features)
3. Web Deployment
4. Mobile Deployment
5. Post-launch Polish & Community Features

## Important Notes

- Default to mock services for initial development
- Use streams for real-time Firestore updates
- Follow Flutter material design guidelines
- Maintain zero ongoing costs architecture using Firebase free tier
- All video content is user-hosted (Google Photos, YouTube, etc.)