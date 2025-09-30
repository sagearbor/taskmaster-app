# Taskmaster App - Current Status

**Last Updated:** 2025-09-30
**Deployed URL:** https://taskmaster-app-3d480.web.app

## What's Working ✅

### Authentication
- ✅ **Anonymous/Guest Login** - "Continue as Guest" button works
- ✅ **Email/Password Login** - Standard login functional
- ✅ **Global Auth State** - AuthBloc accessible from all screens

### Game Management
- ✅ **View Sample Games** - 3 mock games display on home screen
- ✅ **Create New Game** - Users can create games with validation (3+ chars required)
- ✅ **View Game Details** - Clicking a game card loads the game detail screen
- ✅ **Game List Updates** - Real-time game list via streams

### Technical Architecture
- ✅ **Firebase Setup** - Firebase initialized and connected
  - Authentication enabled (Email/Password, Google, Anonymous)
  - Firestore database created in us-east4
  - Hosting configured and deployed
- ✅ **Mock Data Services** - Working offline development mode
- ✅ **BLoC Pattern** - State management with flutter_bloc
- ✅ **Service Locator** - Dependency injection with get_it
- ✅ **Stream-based Data** - Async generators for real-time updates

## Task Content Library 📚

**YES!** The app has **225+ pre-built creative tasks** ready to use!

### Task Structure
Tasks have these fields:
- **title**: Short task name
- **description**: Detailed instructions
- **taskType**: `video` or `puzzle`
- **puzzleAnswer**: Answer for puzzle tasks (optional)
- **submissions**: Array of player submissions
- **modifiers**: Task difficulty multipliers (optional)

### Task Categories (225 total tasks)
Located in `lib/features/tasks/data/datasources/prebuilt_tasks_data.dart`:

1. **Classic Taskmaster** (50 tasks) - "Make the best noise", "Hide from camera"
2. **Creative & Artistic** (30 tasks) - "Create superhero costume", "Stop-motion animation"
3. **Physical & Active** (25 tasks) - "Most jumping jacks", "Longest plank"
4. **Mental & Puzzle** (25 tasks) - Riddles, memory challenges, math puzzles
5. **Food & Kitchen** (20 tasks) - "Most creative sandwich", "Eat lemon with poker face"
6. **Social & Performance** (25 tasks) - "Sales pitch for banana", "Nature documentary of life"
7. **Household** (25 tasks) - "Fold fitted sheets", "Organize junk drawer"
8. **Bonus & Miscellaneous** (25 tasks) - "Recreate famous meme", "Conspiracy theory about socks"

### Community Tasks
Users can submit their own tasks:
- See `lib/core/models/community_task.dart`
- Has upvote system
- Can be added to games
- Stored in Firestore `community_tasks` collection

### **CRITICAL: Tasks Are NOT Connected to the UI!** ❌

Even though 225 tasks exist in the code, **NONE of them are visible or usable in the app**:

**What's Missing:**
- ❌ No timer/duration field in Task model
- ❌ No way to browse/select tasks when creating a game
- ❌ Tasks don't show in game lobby (only shows players & invite code)
- ❌ No task detail view (only title visible, not description/type/puzzleAnswer/submissions/modifiers)
- ❌ No task execution screen
- ❌ No submission UI

**Right now the game detail screen only shows:**
- ✅ Game name
- ✅ Player list with roles (Creator, Judge)
- ✅ Invite code
- ✅ "Start Game" button (for creator with 2+ players)

**The 225 tasks exist but are completely disconnected from the UI!**

## Known Issues & Limitations ⚠️

### Current Limitations
1. **Mock Services Only** - App uses `MockDataService` instead of real Firebase
   - Mock game data persists only in memory (resets on page refresh)
   - No actual Firestore read/write operations

2. **Incomplete Features**
   - ⏱️ **NO TIMER SYSTEM** - Tasks don't have start/stop timer or duration tracking
   - Game creator can't browse/select from 225 prebuilt tasks
   - Task submission UI not implemented
   - Judge scoring not implemented
   - Invite code joining partially implemented
   - Community task browsing/upvoting not connected

3. **Debug Logging Active** - Console logs are verbose for debugging

## Architecture Overview

### Key Files

**Main Entry Point**
- `lib/main.dart` - Production entry point with Firebase & global AuthBloc

**State Management** (BLoC Pattern)
- `lib/features/auth/presentation/bloc/auth_bloc.dart` - Authentication state
- `lib/features/games/presentation/bloc/games_bloc.dart` - Game list state
- `lib/features/games/presentation/bloc/game_detail_bloc.dart` - Game detail state

**Data Layer**
- `lib/core/di/service_locator.dart` - Dependency injection setup
- `lib/features/auth/data/datasources/mock_auth_data_source.dart` - Mock auth
- `lib/features/games/data/datasources/mock_game_data_source.dart` - Mock games

**Key Screens**
- `lib/features/auth/presentation/screens/login_screen.dart` - Login with guest option
- `lib/features/home/presentation/screens/home_screen.dart` - Game list view
- `lib/features/games/presentation/screens/create_game_screen.dart` - Create game form
- `lib/features/games/presentation/screens/game_detail_screen.dart` - Game details

### Firebase Configuration
- **Project ID:** taskmaster-app-3d480
- **Auth Methods:** Email/Password, Google, Anonymous
- **Database:** Firestore in us-east4
- **Hosting:** https://taskmaster-app-3d480.web.app

## Recent Bug Fixes 🔧

### Fixed Stream Issues
**Problem:** Infinite loading spinner when clicking games
**Root Cause:** Broadcast streams don't replay to new subscribers
**Solution:** Changed to async generator pattern (`async*` + `yield`)

```dart
// Before (broken)
Stream<Game?> getGameStream(String id) {
  controller.add(game);
  return controller.stream; // New listeners miss initial data
}

// After (working)
Stream<Game?> getGameStream(String id) async* {
  yield game; // Immediately emit to new listener
  await for (final update in controller.stream) {
    yield update; // Then emit future updates
  }
}
```

### Fixed BLoC Provider Issues
**Problem:** "Provider<AuthBloc> not found" errors on navigation
**Solution:** Moved AuthBloc provider to wrap MaterialApp globally in main.dart

## Next Steps / TODO 📋

### High Priority
1. **Add Timer System to Tasks** ⏱️
   - Add `duration: int?` (seconds) to Task model
   - Add `startTime: DateTime?` to Task model
   - Create timer UI widget in task view
   - Add "Start Task" button to begin countdown
   - Show elapsed/remaining time during task execution
   - Auto-submit or warn when time expires

2. **Task Library Browser**
   - Create task browsing screen showing 225 prebuilt tasks
   - Filter by category (Classic, Creative, Physical, etc.)
   - Search tasks by keywords
   - Preview task details before adding
   - Multi-select tasks to add to game
   - Let game creator pick tasks when creating game

3. **Switch to Real Firebase Services**
   - Implement `FirebaseGameDataSource` (currently just stubs)
   - Implement `FirebaseTaskDataSource` (currently just stubs)
   - Change `ServiceLocator.init(useMockServices: false)` in main.dart

4. **Complete Game Lifecycle**
   - Implement "Start Game" functionality
   - Add task assignment/display in game detail
   - Build task submission UI with video link
   - Build judge scoring interface
   - Show leaderboard after each task

5. **Testing**
   - Add unit tests for business logic
   - Add widget tests for screens
   - Test real Firebase integration

### Medium Priority
4. **Invite Code System**
   - Complete join game flow
   - Share invite code functionality
   - Handle invite code errors gracefully

5. **User Profile**
   - Display user profile in app bar
   - Allow display name editing
   - Show user stats

6. **UI Polish**
   - Remove debug print statements
   - Improve loading states
   - Add error handling UI
   - Better empty states

### Low Priority
7. **Community Features**
   - Task suggestions
   - Upvoting system
   - Task library

## Development Commands

```bash
# Run locally (uses mock services)
flutter run -d chrome

# Build for web
flutter build web

# Deploy to Firebase Hosting
firebase deploy --only hosting

# Run tests
flutter test

# Clean rebuild
flutter clean && flutter pub get && flutter run -d chrome
```

## Troubleshooting

### Issue: Infinite loading spinner
**Solution:** The async generator fixes have resolved this. If it recurs, check:
1. Ensure streams use `async*` and `yield` pattern
2. Check browser console for errors
3. Verify mock data is being emitted

### Issue: "Provider not found" errors
**Solution:** Fixed by global AuthBloc. If it recurs:
1. Ensure BlocProvider wraps MaterialApp in main.dart
2. Don't use BlocProvider.value() when navigating

### Issue: Background Flutter processes
**Solution:** Kill all processes:
```bash
killall -9 flutter dart chrome
```

## Important Notes

- **Mock Services:** Currently using mock services (`useMockServices: true` in main.dart)
- **Data Persistence:** Mock data is in-memory only, resets on refresh
- **Firebase:** Configured but not actively used for data operations yet
- **Testing:** Guest login is fastest way to test features

## Contact Points

- **Firebase Console:** https://console.firebase.google.com/project/taskmaster-app-3d480
- **Deployed App:** https://taskmaster-app-3d480.web.app
- **Codebase Instructions:** See `CLAUDE.md` for project guidance