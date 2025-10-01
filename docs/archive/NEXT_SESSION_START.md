# How to Start Next Session

## Quick Start Prompt

Copy and paste this to Claude in your next session:

```
I'm continuing Day 26-30 work on the Taskmaster Flutter app.

Branch: feature/day26-30-testing-and-quick-play

Day 26-30 Original Goals:
✅ Day 29-30: Quick Play feature - DONE
⏳ Day 26-27: Multi-device testing - PENDING
⏳ Day 28: Cloud Functions - OPTIONAL (deferred)

What was completed:
- Quick Play feature implemented and tested
- Firebase Auth fixed (was using mocks, now real Firebase)
- 3D Avatar specification added (Phase 10 in checklist)

What needs to be done to finish Day 26-30:
1. Fix bugs discovered during testing (tasks not showing, game list filtering)
2. Multi-device testing with real Firebase
3. Mark Day 26-30 as complete in NEXT_SESSION_INSTRUCTIONS.md

Current blockers:
- Tasks not showing in GameDetailScreen (blocking testing)
- Games not appearing in user's list (blocking testing)

Please read:
- NEXT_SESSION_INSTRUCTIONS.md (original Day 26-30 plan)
- FIXES_APPLIED.md (what was fixed last session)
- HANDOFF_STATUS.md (overall project status)

Priority: Fix the 2 blockers so we can complete Day 26-27 multi-device testing.
```

---

## Detailed Context for Next Session

### ✅ What's Working
- Firebase Authentication (anonymous, email/password)
- Real Firebase UIDs (no more mock_user_*)
- Game creation works
- Quick Play button creates games
- Permissions no longer blocked

### ⚠️ Known Issues

**Priority 1: Tasks Not Showing**
- User creates game, clicks on it
- GameDetailScreen shows title but no tasks
- Need to debug GameDetailView rendering

**Priority 2: Game List Filter**
- Games created but don't appear in creator's list
- Filtering logic in `firestore_game_data_source.dart` needs review
- Extensive logging added - check browser console

**Priority 3: Auth Restrictions**
- Guests can currently create games (should only join)
- Need to implement: Check `isAnonymous` → redirect to signup
- See HANDOFF_STATUS.md Priority 2

### 📂 Key Files to Check

**Game Detail Issue:**
- `lib/features/games/presentation/screens/game_detail_screen.dart`
- `lib/features/games/presentation/bloc/game_detail_bloc.dart`
- Check if tasks are in the Game object from Firestore

**Game List Issue:**
- `lib/features/games/data/datasources/firestore_game_data_source.dart:29-58`
- Debug logs show filtering logic
- Check browser console for: "Total games in Firestore", "Filtered to X games"

**Auth Restrictions:**
- `lib/features/games/presentation/screens/create_game_screen.dart`
- `lib/features/home/presentation/screens/home_screen.dart` (Quick Play)
- Need to add `if (isAnonymous) showSignupDialog()`

### 🔍 Debugging Steps

1. **Open browser DevTools Console**
2. **Look for debug logs:**
   - `[CreateGameScreen] Game created successfully with ID: ...`
   - `Total games in Firestore: X`
   - `Filtered to Y games for user ABC`
   - `Game XYZ: isCreator=..., isPlayer=..., shouldShow=...`

3. **Check Firestore Console:**
   - https://console.firebase.google.com/project/taskmaster-app-3d480/firestore
   - Look at `games` collection
   - Verify `tasks` array has data
   - Verify `players` array has creator

### 🎯 Success Criteria for Next Session

Fix these in order:
1. ✅ Tasks appear in GameDetailScreen
2. ✅ Games appear in creator's game list
3. ✅ Guests cannot create games (redirect to signup)
4. ✅ Test full flow: Guest login → Join game → Play works

### 📚 Reference Documents

Read these first:
- `FIXES_APPLIED.md` - What was fixed last session
- `HANDOFF_STATUS.md` - Complete project status
- `development_checklist.md` - Full roadmap (Phase 10 = 3D avatars)

### 🚀 Commands

```bash
# Current branch
git checkout feature/day26-30-testing-and-quick-play

# Run locally
flutter run -d chrome

# Deploy
flutter build web --release
firebase deploy --only hosting

# Check recent commits
git log --oneline -10
```

### 💡 Testing URLs

- **Local:** http://localhost:8080 (after `flutter run`)
- **Deployed:** https://taskmaster-app-3d480.web.app

Test flow:
1. Click "Continue as Guest"
2. Create game (name = "TEST")
3. Check if game appears in list
4. Click game
5. Verify tasks show up

---

## Alternative: Quick Debug Prompt

If you just want to fix the tasks issue:

```
The Taskmaster app GameDetailScreen shows game title but no tasks.

Debug this issue:
- Branch: feature/day26-30-testing-and-quick-play
- File: lib/features/games/presentation/screens/game_detail_screen.dart
- Problem: Tasks aren't rendering
- Check if tasks exist in Game object from Firestore
- Fix the UI to display tasks

Start by reading the file and checking the BLoC logic.
```

---

## Git Status

```bash
Branch: feature/day26-30-testing-and-quick-play
Commits ahead of main: ~10
Status: Clean, all changes committed
Latest commit: "fix: Remove AutofillGroup causing form submission errors"
```

**Ready to merge to main** once tasks/game list issues are resolved.
