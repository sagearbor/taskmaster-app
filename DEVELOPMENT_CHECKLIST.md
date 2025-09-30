# DEVELOPMENT CHECKLIST - Taskmaster Async Game

**Last Updated:** 2025-09-30
**Current Phase:** Phase 1 - Fix Critical Bugs (Async-First)
**Progress:** 0% (0/21 days completed)

---

## 🎯 **KEY DESIGN DECISIONS**

### **Video Privacy Feature** ⭐
> Players CANNOT see others' videos until they complete the task themselves
> Once submitted → get access to shared video links
> **Psychology:** Creates urgency + FOMO → drives task completion

### **Testing Strategy**
- Use Flutter's built-in test framework (`flutter test`)
- Unit tests for BLoCs and repositories
- Widget tests for UI components
- Integration tests for full flows
- Run tests continuously during development
- Regression test suite runs before each commit

---

## **PHASE 1: FIX CRITICAL BUGS (Async-First)**
*Goal: Playable end-to-end async game*
*Timeline: 3 weeks (21 days)*

### **Week 1: Connect Tasks & Build Execution**

#### **Day 1-2: Update Data Models** ✅ COMPLETED
- [x] **File:** `lib/core/models/task.dart`
  - [ ] Add `TaskStatus` enum (waiting_for_submissions, ready_to_judge, judging, completed)
  - [ ] Add `DateTime? deadline` field
  - [ ] Add `int? durationSeconds` field
  - [ ] Add `Map<String, PlayerTaskStatus> playerStatuses` field
  - [ ] Update `fromMap()` and `toMap()` methods
  - [ ] Add `copyWith()` for new fields
  - [ ] **💡 TODO LATER:** Add `revealVideoAfterSubmit` bool field for privacy control

- [ ] **File:** `lib/core/models/game.dart`
  - [ ] Add `GameMode` enum (async, same_device, live)
  - [ ] Add `GameSettings` class with deadline, autoAdvance, allowSkips
  - [ ] Add `int currentTaskIndex` field
  - [ ] Add `GameMode mode` field (default: async)
  - [ ] Add `GameSettings settings` field
  - [ ] Update `fromMap()`, `toMap()`, `copyWith()`
  - [ ] **💡 TODO LATER:** Add `sharedVideoLinks` map for privacy feature

- [ ] **File:** `lib/core/models/player_task_status.dart` (NEW)
  - [ ] Create PlayerTaskStatus class
  - [ ] Add TaskPlayerState enum
  - [ ] Add fromMap, toMap, copyWith methods
  - [ ] **💡 TODO LATER:** Add `canViewVideos` computed property

- [ ] **File:** `lib/core/models/game_settings.dart` (NEW)
  - [ ] Create GameSettings class
  - [ ] Fields: taskDeadline, autoAdvance, allowSkips, maxPlayers
  - [ ] Add sensible defaults (24h deadline, autoAdvance=true)

- [ ] **Tests:** `test/core/models/`
  - [ ] task_test.dart - test serialization, copyWith, status transitions
  - [ ] game_test.dart - test game state changes
  - [ ] player_task_status_test.dart - test status flow

**Comments:**
- Need to ensure backward compatibility with existing mock data
- Consider migration strategy for existing Firestore data (if any)

---

#### **Day 3-4: Task Selection in Game Creation** ✅ FULLY COMPLETED
- [x] **File:** `lib/features/games/presentation/screens/create_game_screen.dart`
  - [x] Add "Select Tasks" step after game name
  - [x] Add `selectedTasks` list to state
  - [x] Add "Quick Presets" buttons:
    - [x] "Quick (5 tasks)" - random selection
    - [x] "Party (10 tasks)" - more tasks
    - [x] "Browse" (Custom) - manual selection
  - [x] Navigate to TaskBrowserScreen
  - [x] Show selected task count badge
  - [x] Show horizontal scrolling preview of selected tasks
  - [x] "Change Tasks" button to modify selection
  - [ ] **💡 IMPROVEMENT:** Add drag-to-reorder selected tasks (DEFERRED)

- [x] **File:** `lib/features/tasks/presentation/screens/task_browser_screen.dart` (NEW)
  - [x] Build grid view of tasks from `PrebuiltTasksData.getAllTasks()`
  - [x] Add category filter tabs (Classic, Creative, Physical, Mental, Food, Social, Household, Bonus, All)
  - [x] Add search bar with live filtering
  - [x] Task cards show: icon, title, type badge (video/puzzle), estimated duration
  - [x] Tap to preview full description modal (inline implementation)
  - [x] Multi-select with checkboxes
  - [x] Bottom bar: "X tasks selected" + "Done" button
  - [x] Return selected tasks to CreateGameScreen
  - [x] **💡 IMPROVEMENT:** Add "Random 5" and "Random 10" shuffle buttons
  - [ ] **💡 IMPROVEMENT:** Save favorite tasks to SharedPreferences (DEFERRED)

- [x] **File:** `lib/features/tasks/presentation/widgets/task_card.dart` (NEW)
  - [x] Icon based on task type
  - [x] Title (max 2 lines, ellipsis)
  - [x] Short description (max 3 lines)
  - [x] Video/Puzzle badge
  - [x] Visual checkbox indicator for selection
  - [x] Duration display (if available)
  - [ ] **💡 IMPROVEMENT:** Add difficulty indicator (1-5 stars) (DEFERRED)

- [x] **File:** Task preview modal (inline in task_browser_screen.dart)
  - [x] Full task description
  - [x] Task type icon and title
  - [x] "Add to Game" / "Remove from Game" button
  - [x] Draggable scrollable sheet

- [x] **Tests:** `test/features/tasks/` ✅ COMPLETED
  - [x] task_browser_screen_test.dart - widget test for filtering/search (16 tests)
  - [x] task_card_test.dart - widget test for selection (20 tests)

**Comments:**
- PrebuiltTasksData has 225 tasks - may need pagination or lazy loading
- Consider caching task list in memory (don't reload from source each time)

---

#### **Day 5-7: Task Execution Screen** ✅ COMPLETED
- [x] **File:** `lib/features/games/presentation/screens/task_execution_screen.dart` ✅
  - [x] Accept params: `gameId`, `taskIndex`, `userId`
  - [x] Load task from game
  - [x] Check if user already submitted → show "Already submitted ✅" state
  - [x] Display:
    - [x] Task title + description
    - [x] Task number (2 of 5)
    - [x] Timer widget (countdown for task duration)
    - [x] Deadline ("Submit by: Tomorrow 6pm")
    - [x] Submission progress widget (3/5 players done)
    - [x] Input field for video URL (YouTube, Google Photos, etc.)
    - [x] "Skip Task" button (if game.settings.allowSkips)
    - [x] "Submit" button (disabled until URL entered)
  - [x] On submit:
    - [x] Validate URL format
    - [x] Update playerStatuses[userId] to submitted
    - [x] Show success animation
    - [x] **🔒 PRIVACY:** Unlock video viewing for this user
    - [x] Navigate to video viewing screen OR next task
  - [ ] **💡 IMPROVEMENT:** Add camera integration for direct video recording
  - [ ] **💡 IMPROVEMENT:** Add preview thumbnail from YouTube/Google Photos API

- [x] **File:** `lib/features/games/presentation/bloc/task_execution_bloc.dart` ✅
  - [x] Events:
    - [x] LoadTask(gameId, taskIndex, userId)
    - [x] StartTask(userId) - marks in_progress
    - [x] SubmitTask(userId, videoUrl) - marks submitted
    - [x] SkipTask(userId) - marks skipped
  - [x] States:
    - [x] TaskExecutionLoading
    - [x] TaskExecutionLoaded(task, userStatus, otherPlayerStatuses)
    - [x] TaskExecutionSubmitted
    - [x] TaskExecutionError(message)
  - [x] Handle network errors gracefully
  - [ ] **💡 IMPROVEMENT:** Add offline mode (queue submissions)

- [x] **File:** `lib/features/games/presentation/widgets/task_timer_widget.dart` ✅
  - [x] Circular countdown timer
  - [x] Shows remaining time (0:42)
  - [x] Color changes: green → yellow → red
  - [x] Haptic feedback at 10s, 5s, 0s (if mobile)
  - [x] Auto-submit warning when time expires
  - [ ] **💡 IMPROVEMENT:** Add pause/resume for timer

- [x] **File:** `lib/features/games/presentation/widgets/submission_progress_widget.dart` ✅
  - [x] Shows player list with status icons
  - [x] Icons: ✅ submitted, ⏳ in progress, ⬜ not started
  - [x] Current user highlighted with border
  - [x] Live updates via stream
  - [x] Add avatars (first letter of name)
  - [x] Show timestamp of submission

- [x] **File:** `lib/features/games/presentation/screens/video_viewing_screen.dart` ✅
  - [x] **🔒 PRIVACY CHECK:** Only show if user has submitted
  - [x] Grid of video links (clickable)
  - [x] Player name labels
  - [x] "Open in browser" button for each video
  - [ ] **💡 IMPROVEMENT:** Embedded video player (webview_flutter)
  - [ ] **💡 IMPROVEMENT:** Add reactions (😂🔥💀) to videos

- [x] **Tests:** `test/features/games/presentation/` ✅
  - [x] task_execution_bloc_test.dart - test all events/states (9 tests passing)
  - [ ] task_execution_screen_test.dart - widget test (deferred)
  - [ ] video_viewing_screen_test.dart - test privacy logic (deferred)

**Comments:**
- URL validation regex needed for YouTube, Google Photos, Dropbox, etc.
- Consider using `url_launcher` package for opening video links
- Privacy feature is CRITICAL - must enforce server-side too (Firestore rules)

---

### **Week 2: Implement "Start Game" & Judging**

#### **Day 8-9: Start Game Functionality** ✅ COMPLETED
- [x] **File:** `lib/features/games/data/repositories/game_repository_impl.dart` ✅
  - [x] Enhanced `startGame()` method:
    - [x] Validate: at least 2 players AND tasks selected
    - [x] Change game.status from `lobby` to `inProgress`
    - [x] Set `currentTaskIndex = 0`
    - [x] Initialize `playerStatuses` for ALL tasks (all `not_started`)
    - [x] Calculate deadline (now + settings.taskDeadline)
    - [x] Update game via repository
  - [ ] Add `AdvanceToNextTask` event (deferred to Day 13-14):
    - [ ] Increment `currentTaskIndex`
    - [ ] Initialize playerStatuses for next task
    - [ ] Reset video visibility locks
    - [ ] Notify all players via Firestore update
  - [ ] **⚠️ TODO:** Handle edge case where all tasks are completed

- [x] **File:** `lib/features/games/presentation/widgets/game_lobby_view.dart` ✅
  - [x] Update "Start Game" button:
    - [x] Enable only if: 2+ players AND tasks selected
    - [x] Show descriptive status message
    - [x] Styled with green color when ready
    - [x] Show task and player count
  - [ ] **💡 IMPROVEMENT:** Add "Preview Tasks" button in lobby (deferred)

- [x] **Tests:** ✅
  - [x] game_detail_bloc_test.dart - test StartGame event (5 tests passing)
  - [ ] Integration test: full game start flow (deferred)

**Comments:**
- Need to handle race condition if multiple players try to start simultaneously
- Consider adding "creator only" permission check

---

#### **Day 10-12: Judging Screen (Async)** ✅ COMPLETED
- [x] **File:** `lib/features/games/presentation/screens/judging_screen.dart` (NEW) ✅
  - [x] Accept params: `gameId`, `taskIndex`
  - [x] Load task + all submissions
  - [x] Show two states:
    - [x] **Waiting:** "3/5 submitted - wait or judge now?"
    - [x] **Ready:** "All submitted - ready to judge!"
  - [x] "Judge Now" button (works even with partial submissions)
  - [x] Navigate to SubmissionReviewScreen
  - [ ] **💡 IMPROVEMENT:** Show preview thumbnails of submissions (DEFERRED)

- [x] **File:** `lib/features/games/presentation/screens/submission_review_screen.dart` (NEW) ✅
  - [x] PageView for swipeable submission cards
  - [x] Each card shows:
    - [x] Player name + avatar
    - [x] Video link (clickable with url_launcher)
    - [x] Quick score buttons: [1⭐] [2⭐] [3⭐] [4⭐] [5⭐]
    - [x] "Skip" button (don't score this one)
    - [ ] **💡 IMPROVEMENT:** Embedded video player (DEFERRED)
    - [ ] Optional: Comment text field (DEFERRED)
  - [x] Navigation: "← Prev | 1/4 | Next →"
  - [x] Progress indicator (scored 2/4)
  - [x] "Finish Judging" button (enabled when at least one scored)
  - [x] On finish:
    - [x] Update all scored submissions in Firestore
    - [x] Update player.totalScore
    - [x] Auto-advance back to game detail
    - [ ] Update task.status to "completed" (TODO: add logic)
    - [ ] Trigger Cloud Function notification (DEFERRED)
  - [ ] **💡 IMPROVEMENT:** Add "Undo Last Score" button (DEFERRED)
  - [ ] **💡 IMPROVEMENT:** Drag-to-rank interface (Tinder-style) (DEFERRED)

- [x] **File:** `lib/features/games/presentation/bloc/judging_bloc.dart` (NEW) ✅
  - [x] Events:
    - [x] LoadSubmissions(gameId, taskIndex)
    - [x] ScoreSubmission(playerId, score)
    - [x] SkipSubmission(playerId)
    - [x] FinishJudging
  - [x] States:
    - [x] JudgingLoading
    - [x] JudgingLoaded(submissions, currentIndex, totalCount, scores)
    - [x] JudgingCompleted
    - [x] JudgingError(message)
  - [x] ✅ Validate score range (1-5)

- [x] **Tests:** ✅
  - [x] judging_bloc_test.dart - 10 tests passing
  - [ ] submission_review_screen_test.dart - widget test (DEFERRED)
  - [ ] Integration test: judge all submissions flow (DEFERRED)

- [x] **Repository:** ✅
  - [x] Implemented `judgeSubmission()` in GameRepositoryImpl
  - [x] Updates player scores and task statuses
  - [x] Persists changes to Firestore

**Comments:**
- Consider adding "Best Submission" auto-award (highest score gets badge)
- Judge might want to review their scores before finalizing (confirmation dialog?)
- Need to handle case where judge leaves mid-judging (save progress)

---

#### **Day 13-14: Scoreboard & Task Advancement** ⬜ NOT STARTED
- [ ] **File:** `lib/features/games/presentation/screens/task_scoreboard_screen.dart` (NEW)
  - [ ] Show results for just-completed task:
    - [ ] Animated score reveal (stagger each player, 0.5s delay)
    - [ ] Player name + points earned this task
    - [ ] Running total count-up animation
    - [ ] Position change indicators (↑↗↓)
  - [ ] Show current standings (leaderboard)
  - [ ] Celebration animation for task winner (confetti, trophy icon)
  - [ ] Auto-advance countdown: "Next task in 5... 4... 3..."
  - [ ] OR manual: "Continue to Next Task" button
  - [ ] **💡 IMPROVEMENT:** Add "Watch All Videos" button (rewatch submissions)
  - [ ] **💡 IMPROVEMENT:** Share scoreboard as image (social media)

- [ ] **File:** `lib/features/games/presentation/widgets/animated_score_reveal.dart` (NEW)
  - [ ] Staggered animation (reveal one player at a time)
  - [ ] Number count-up animation (0 → final score)
  - [ ] Confetti package for winner
  - [ ] Haptic feedback for each reveal (if mobile)
  - [ ] Sound effects (optional, muted by default)

- [ ] **File:** Update `game_detail_bloc.dart`
  - [ ] Add `ViewTaskResults` event → navigate to scoreboard
  - [ ] Add `CompleteGame` event (when all tasks judged):
    - [ ] Set game.status to `completed`
    - [ ] Calculate final winner
    - [ ] Navigate to final scoreboard
    - [ ] Show "Play Again?" button

- [ ] **Tests:**
  - [ ] task_scoreboard_screen_test.dart - widget test
  - [ ] animated_score_reveal_test.dart - animation test

**Comments:**
- Animations are critical for "feel good" factor - invest time here
- Consider adding achievements ("Perfect Score", "Comeback King", etc.)
- Final scoreboard should have special "Winner" screen with trophy

---

### **Week 3: Polish & Bug Fixes**

#### **Day 15-17: UI States & Error Handling** ⬜ NOT STARTED
- [ ] **All Screens:** Replace CircularProgressIndicator with skeleton screens
  - [ ] game_detail_screen.dart
  - [ ] task_execution_screen.dart
  - [ ] judging_screen.dart
  - [ ] task_browser_screen.dart
  - [ ] **Package:** Use `shimmer` package for skeleton effect

- [ ] **All Screens:** Add error states with retry buttons
  - [ ] Consistent error UI component
  - [ ] Clear error messages (not raw exceptions)
  - [ ] Retry button triggers re-fetch
  - [ ] **💡 IMPROVEMENT:** Add "Report Bug" button in error state

- [ ] **Game Detail:** Add state-specific views
  - [ ] "Waiting for submissions" banner
  - [ ] "Ready to judge" banner (judge only)
  - [ ] "Scores posted" banner
  - [ ] "Game completed" banner

- [ ] **Judging:** Handle edge cases
  - [ ] What if no submissions? (show "No submissions yet")
  - [ ] What if judge skips all? (disallow, require at least 1 score)
  - [ ] What if judge leaves mid-judging? (auto-save scores)

- [ ] **Task Execution:** Handle already-submitted state
  - [ ] Show submitted video link
  - [ ] Show "Edit Submission" button (if deadline not passed)
  - [ ] Show other players' videos (privacy unlock)

- [ ] **Navigation:** Proper back button handling
  - [ ] Don't break game flow (ask "Are you sure?" if in middle of task)
  - [ ] **💡 IMPROVEMENT:** Add "Save & Exit" option

- [ ] **File:** `lib/features/games/presentation/widgets/game_status_banner.dart` (NEW)
  - [ ] Floating banner showing current game state
  - [ ] "3/5 players submitted - waiting on you!"
  - [ ] "Judge is reviewing - check back soon"
  - [ ] "Scores posted - you're in 2nd place!"
  - [ ] Dismissible with swipe

- [ ] **Tests:**
  - [ ] Error handling integration tests
  - [ ] Navigation flow tests

**Comments:**
- Error messages should be user-friendly, not technical
- Consider adding "offline mode" indicator
- Skeleton screens MUCH better UX than spinners

---

#### **Day 18-19: Async Flow Testing** ⬜ NOT STARTED
- [ ] **Test Suite:** Full end-to-end async game flow
  - [ ] Test 1: Create game → select tasks → start → submit → judge → score → next task
  - [ ] Test 2: Multiple players (use different browsers/incognito)
  - [ ] Test 3: Player submits out of order (player 3 before player 1)
  - [ ] Test 4: Judge scores before all submitted (partial judging)
  - [ ] Test 5: Skip task functionality
  - [ ] Test 6: Game completion (all tasks done)
  - [ ] Test 7: Privacy feature (can't see videos until submitted)
  - [ ] Test 8: Deadline passed (auto-move to judging)
  - [ ] **⚠️ CRITICAL:** Document all bugs found in GitHub issues

- [ ] **Performance Testing:**
  - [ ] Test with 10 players (max load)
  - [ ] Test with 20 tasks (long game)
  - [ ] Test on slow network (throttle to 3G)
  - [ ] Test offline → online transition

- [ ] **Bug Fixes:**
  - [ ] Fix all bugs found during testing
  - [ ] Prioritize: blocking bugs first, polish later

**Comments:**
- Use Flutter DevTools for performance profiling
- Consider adding analytics to track where users drop off

---

#### **Day 20-21: Mock Data Enhancements** ⬜ NOT STARTED
- [ ] **File:** `lib/features/games/data/datasources/mock_game_data_source.dart`
  - [ ] Update mock games to include new fields:
    - [ ] tasks with playerStatuses maps
    - [ ] currentTaskIndex
    - [ ] GameSettings
    - [ ] deadlines
  - [ ] Add realistic sample data (3-5 mock games in different states)
  - [ ] Simulate async delays (Future.delayed 500ms-2s for realism)
  - [ ] Support state transitions:
    - [ ] lobby → inProgress (when StartGame called)
    - [ ] task submissions update playerStatuses
    - [ ] judging updates scores
    - [ ] inProgress → completed (when all tasks done)
  - [ ] **💡 IMPROVEMENT:** Add mock notification service (print to console)

- [ ] **Tests:**
  - [ ] mock_game_data_source_test.dart - test all CRUD operations
  - [ ] Test data persistence (within session, not across restarts)

**Comments:**
- Mock data should be realistic enough to catch edge cases
- Consider adding "reset mock data" button in debug builds

---

## **PHASE 2: SWITCH TO FIREBASE (Real Multiplayer)** ⬜ NOT STARTED
*Goal: Actual async multiplayer works*
*Timeline: 1-2 weeks*

### **Week 4: Firebase Data Sources**

#### **Day 22-23: Firestore Structure Setup** ⬜ NOT STARTED
- [ ] **Firebase Console:** Review Firestore security rules
  - [ ] Rule: Users can only edit games they're in
  - [ ] Rule: Only judge can update scores
  - [ ] Rule: Players can only update their own playerStatus
  - [ ] **🔒 CRITICAL:** Enforce video privacy (players can't read submissions until they submit)

- [ ] **Firebase Console:** Set up indexes
  - [ ] Compound index: `games` collection on `creatorId` + `status`
  - [ ] Compound index: `games` collection on `players` + `status`
  - [ ] Array-contains index: `games.players` for user queries

- [ ] **File:** `lib/features/games/data/datasources/firebase_game_data_source.dart`
  - [ ] Implement `createGame()`: Generate invite code, create doc, return ID
  - [ ] Implement `getGamesStream()`: Query games where user is player
  - [ ] Implement `getGameStream(gameId)`: Real-time listener on single game
  - [ ] Implement `updateGame()`: Merge updates (don't overwrite)
  - [ ] Implement `joinGame(inviteCode)`: Query by code, add player to array
  - [ ] **⚠️ TODO:** Add error handling for network failures
  - [ ] **💡 IMPROVEMENT:** Add caching layer (reduce Firestore reads)

- [ ] **Tests:**
  - [ ] firebase_game_data_source_test.dart - mock Firestore with fake_cloud_firestore

**Comments:**
- Firestore security rules are CRITICAL - test thoroughly
- Consider using Firestore emulator for local testing

---

#### **Day 24-25: Task & Submission Operations** ⬜ NOT STARTED
- [ ] **File:** `lib/features/games/data/datasources/firebase_game_data_source.dart` (continued)
  - [ ] Implement `startGame(gameId)`: Update status, init task 0, set deadline
  - [ ] Implement `submitTask(gameId, taskIndex, playerId, videoUrl)`:
    - [ ] Update playerStatuses[playerId] to submitted
    - [ ] Check if all submitted → update task.status to ready_to_judge
    - [ ] **🔒 PRIVACY:** Update visibility permissions
  - [ ] Implement `scoreSubmission(gameId, taskIndex, playerId, score)`:
    - [ ] Update score in playerStatuses
    - [ ] Update player.totalScore
    - [ ] Check if all scored → update task.status to completed
  - [ ] Implement `advanceToNextTask(gameId)`:
    - [ ] Increment currentTaskIndex
    - [ ] Initialize next task playerStatuses
    - [ ] Set new deadline
  - [ ] **💡 IMPROVEMENT:** Batch writes for performance (Firestore batched writes)

- [ ] **Tests:**
  - [ ] Integration test: Full game flow with real Firestore emulator

**Comments:**
- Use Firestore transactions for critical updates (prevent race conditions)
- Consider adding undo functionality for judge scores

---

#### **Day 26-27: Firebase Integration Testing** ⬜ NOT STARTED
- [ ] **File:** `lib/main.dart`
  - [ ] Change `ServiceLocator.init(useMockServices: false)` ← **KEY CHANGE!**
  - [ ] Ensure Firebase initialized before app runs
  - [ ] Add try-catch for Firebase init errors

- [ ] **Multi-Device Testing:**
  - [ ] Test 1: Create game on phone, join on laptop
  - [ ] Test 2: Submit on device A, see update on device B instantly
  - [ ] Test 3: Judge on tablet, see scores on phone
  - [ ] Test 4: 3+ devices simultaneously (stress test)
  - [ ] **⚠️ CRITICAL:** Test video privacy feature (can't see until submit)

- [ ] **Real-Time Update Testing:**
  - [ ] Player joins → everyone sees instantly
  - [ ] Task submission → judge gets notified
  - [ ] Scores update → leaderboard animates
  - [ ] Game state changes broadcast to all

- [ ] **Offline Testing:**
  - [ ] Disconnect network mid-game
  - [ ] Submit while offline → queues submission
  - [ ] Reconnect → submission syncs
  - [ ] Firestore offline persistence enabled

- [ ] **Bug Fixes:**
  - [ ] Fix all multi-device bugs
  - [ ] Fix all real-time sync issues

**Comments:**
- Use Firebase emulator suite for faster testing (no real Firestore writes)
- Consider adding "sync status" indicator (synced, syncing, offline)

---

#### **Day 28: Cloud Functions Setup** ⬜ NOT STARTED
- [ ] **File:** `functions/src/index.ts` (NEW - Firebase Functions)
  - [ ] Function: `onGameStarted` - Send notification when game starts
  - [ ] Function: `onAllSubmitted` - Notify judge when all players submit
  - [ ] Function: `onTaskScored` - Notify players when scores posted
  - [ ] Function: `onNextTaskUnlocked` - Notify players of next task
  - [ ] Function: `onDeadlinePassed` - Auto-move to judging if deadline expires
  - [ ] **💡 IMPROVEMENT:** Batch notifications (don't spam)

- [ ] **Setup Firebase Cloud Messaging (FCM):**
  - [ ] Configure iOS APNs certificates (if building iOS)
  - [ ] Configure Android FCM keys
  - [ ] Test push notifications on real device

- [ ] **Deploy Functions:**
  - [ ] `firebase deploy --only functions`
  - [ ] Test each trigger in Firebase console
  - [ ] Monitor function logs for errors

- [ ] **Tests:**
  - [ ] Use Firebase Functions emulator for local testing
  - [ ] Test notification payloads

**Comments:**
- Cloud Functions add cost but are CRITICAL for async notifications
- Keep function execution time < 1s (cold start can be slow)
- Consider using Pub/Sub for batched notifications

---

## **PHASE 3: REDUCE FRICTION (Async-Optimized)** ⬜ NOT STARTED
*Goal: <10 second time-to-first-task*
*Timeline: 1 week*

### **Week 5: Quick Play & Smart Defaults**

#### **Day 29-30: Quick Play Button** ⬜ NOT STARTED
- [ ] **File:** `lib/features/home/presentation/screens/home_screen.dart`
  - [ ] Add prominent "⚡ Quick Play" FAB or hero banner
  - [ ] Style: Big, colorful, unmissable (gradient button?)
  - [ ] On tap: dispatch `QuickPlayGame` event
  - [ ] Show loading indicator during creation

- [ ] **File:** `lib/features/games/presentation/bloc/games_bloc.dart`
  - [ ] Add `QuickPlayGame` event:
    - [ ] Get current user
    - [ ] Generate fun game name ("Epic Game #1234" or "Sarah's Adventure")
    - [ ] Select 5 random tasks (diverse categories)
    - [ ] Set mode = async, deadline = 24h, autoAdvance = true
    - [ ] Create game in Firestore
    - [ ] Start game immediately (no lobby wait)
    - [ ] Navigate to TaskExecutionScreen(taskIndex: 0)
  - [ ] **Optimization:** Pre-fetch random tasks on app start (cache in memory)
  - [ ] **💡 IMPROVEMENT:** Add "Quick Play Settings" (customize task count, deadline)

- [ ] **Tests:**
  - [ ] Test Quick Play flow end-to-end
  - [ ] Test task randomization (no duplicates)

**Comments:**
- Quick Play is THE killer feature - must be fast (<3s)
- Consider adding haptic feedback when tapping Quick Play
- Game name generator could be fun (random adjective + noun)

---

#### **Day 31: In-Game Invite Flow** ⬜ NOT STARTED
- [ ] **File:** `lib/features/games/presentation/widgets/floating_invite_button.dart` (NEW)
  - [ ] Floating button always visible during game
  - [ ] Compact view: just shows invite code
  - [ ] Tap to expand: full invite options modal
  - [ ] "Share Link" → generates deep link (Firebase Dynamic Links)
  - [ ] "Copy Code" → copies to clipboard + haptic + snackbar
  - [ ] "Show QR" → generates QR code for scanning
  - [ ] **💡 IMPROVEMENT:** Add "Invite via SMS" option

- [ ] **File:** `lib/features/games/presentation/screens/task_execution_screen.dart`
  - [ ] Add FloatingInviteButton to screen
  - [ ] Position: bottom-right, semi-transparent
  - [ ] Don't block submit button

- [ ] **Setup:** Firebase Dynamic Links
  - [ ] Domain: `taskmaster.page.link` (or custom domain)
  - [ ] Create link format: `https://taskmaster.app/join/ABC123`
  - [ ] Handle deep link in app:
    - [ ] Parse invite code from URL
    - [ ] Auto-join game
    - [ ] Navigate to game detail
  - [ ] **⚠️ TODO:** Handle edge case where game is full

- [ ] **File:** `lib/core/services/deep_link_service.dart` (NEW)
  - [ ] Listen for incoming deep links
  - [ ] Parse invite code
  - [ ] Auto-join game
  - [ ] Handle errors (invalid code, full game, etc.)

- [ ] **Tests:**
  - [ ] Test deep link parsing
  - [ ] Test auto-join flow

**Comments:**
- QR code package: `qr_flutter`
- Deep link package: `firebase_dynamic_links` or `uni_links`
- Make sure QR code works in low light (high contrast)

---

#### **Day 32: Smart Defaults Everywhere** ⬜ NOT STARTED
- [ ] **Create Game Screen:**
  - [ ] Auto-fill game name: "Game on [Day]" or "[User]'s Game"
  - [ ] Pre-select 5 diverse tasks (default checked)
  - [ ] Default deadline: 24 hours
  - [ ] Default mode: Async
  - [ ] User can change but doesn't have to (principle: smart defaults)

- [ ] **Task Selection:**
  - [ ] "Popular" tab default (most-used tasks)
  - [ ] Show task count badge on each category tab
  - [ ] Remember last-used filters (SharedPreferences)
  - [ ] **💡 IMPROVEMENT:** Machine learning to recommend tasks based on past games

- [ ] **Judging:**
  - [ ] Default score: 3 points (middle)
  - [ ] Quick tap = use default score
  - [ ] Long press = customize score slider
  - [ ] **💡 IMPROVEMENT:** "Quick Judge" mode (swipe right = 5pt, left = 1pt)

- [ ] **General:**
  - [ ] Save user preferences (SharedPreferences)
  - [ ] Remember last game mode (async vs live)
  - [ ] Auto-login (if guest user, stay logged in)

**Comments:**
- Principle: Every decision should have a smart default
- Users shouldn't need to think - just tap and play

---

#### **Day 33-34: Notification System** ⬜ NOT STARTED
- [ ] **File:** `lib/core/services/notification_service.dart` (NEW)
  - [ ] Initialize Firebase Cloud Messaging (FCM)
  - [ ] Request notification permissions (iOS requires explicit request)
  - [ ] Handle foreground notifications (show in-app banner)
  - [ ] Handle background notifications (wake app)
  - [ ] Handle notification taps (deep link to correct screen)
  - [ ] **💡 IMPROVEMENT:** Add notification preferences (which types to receive)

- [ ] **File:** `lib/main.dart`
  - [ ] Initialize NotificationService on app start
  - [ ] Request permissions on first launch (with explanation dialog)
  - [ ] Store FCM token in Firestore (user document)

- [ ] **Firebase Console:**
  - [ ] Enable Cloud Messaging
  - [ ] Configure iOS APNs certificates (if building iOS)
  - [ ] Configure Android FCM keys
  - [ ] Test message via Firebase console

- [ ] **Cloud Functions:** (integrate with Day 28 functions)
  - [ ] Send FCM notifications to player devices
  - [ ] Notification types:
    - [ ] Game started: "Sarah started 'Weekend Fun'! Do your first task 🎬"
    - [ ] All submitted: "Everyone submitted! Time to judge ⚖️"
    - [ ] Scores posted: "Scores are in - you got 4/5 points! 🎉"
    - [ ] Next task: "Task 3 unlocked: Make creative sandwich 🥪"
    - [ ] Deadline soon: "⏰ 4 hours left to submit Task 2!"
    - [ ] You're last: "You're the last one! 4/5 submitted ⏳"
    - [ ] Game complete: "🏆 Alex won Weekend Fun! Play again?"
  - [ ] Batch notifications (don't spam)
  - [ ] Respect Do Not Disturb times (9pm-9am quiet hours)

- [ ] **Tests:**
  - [ ] Test foreground notification
  - [ ] Test background notification
  - [ ] Test notification tap (deep link)
  - [ ] Test on iOS and Android (if applicable)

**Comments:**
- Notifications are CRITICAL for async games (bring users back)
- iOS notification permissions are tricky - explain why before asking
- Consider adding rich notifications (images, actions)

---

#### **Day 35: In-App Notification Badges** ⬜ NOT STARTED
- [ ] **File:** `lib/features/home/presentation/screens/home_screen.dart`
  - [ ] Add badge counter in app bar (red circle with number)
  - [ ] Count games needing action:
    - [ ] Tasks waiting for your submission
    - [ ] Submissions waiting for your judging
    - [ ] Scores posted (unviewed)
  - [ ] Tap badge → navigate to first action-needed game
  - [ ] Update badge count in real-time (stream from Firestore)

- [ ] **File:** `lib/features/home/presentation/widgets/game_card.dart`
  - [ ] Add "ACTION NEEDED" red badge on game card
  - [ ] Show specific action: "Your turn!" or "Judge now!" or "New scores!"
  - [ ] Sorting: action-needed games first, then by last activity
  - [ ] **💡 IMPROVEMENT:** Add timestamp "5 minutes ago"

- [ ] **File:** `lib/core/services/badge_service.dart` (NEW)
  - [ ] Calculate badge count from game states
  - [ ] Provide stream of badge count
  - [ ] Update when game state changes

- [ ] **Tests:**
  - [ ] Test badge count calculation
  - [ ] Test real-time badge updates

**Comments:**
- Badge is powerful psychological trigger (must address it!)
- Consider iOS app badge (on home screen icon) - requires native code

---

## **TESTING STRATEGY** 📝

### **Unit Tests** (Run continuously)
- Location: `test/` directory (mirrors `lib/`)
- Framework: `flutter_test` (built-in)
- Run: `flutter test`
- Coverage target: >80% for BLoCs and repositories

### **Widget Tests**
- Test UI components in isolation
- Test user interactions (tap, swipe, input)
- Use `testWidgets()` from flutter_test

### **Integration Tests**
- Location: `integration_test/` directory
- Test full user flows (create game → play → judge → complete)
- Run: `flutter test integration_test/`
- Use real Firebase emulator (not production)

### **Regression Test Suite**
- Run before every commit
- All unit tests + critical integration tests
- CI/CD: Run on GitHub Actions (if using Git)

### **Manual Testing Checklist** (Before each phase completion)
- [ ] Test on multiple devices (phone, tablet, laptop)
- [ ] Test on multiple browsers (Chrome, Safari, Firefox)
- [ ] Test offline → online transition
- [ ] Test slow network (throttle to 3G)
- [ ] Test with 10 players (stress test)
- [ ] Test privacy feature (critical!)

---

## **PROGRESS TRACKING** 📊

### **Overall Progress**
- **Phase 1:** 0% (0/21 days) ⬜
- **Phase 2:** 0% (0/7 days) ⬜
- **Phase 3:** 0% (0/7 days) ⬜
- **Total:** 0% (0/35 days)

### **Current Sprint**
- **Week:** 1 of 5
- **Days Completed:** 0 of 7
- **Blockers:** None yet

### **Next Up**
1. Day 1-2: Update Data Models
2. Day 3-4: Task Selection in Game Creation
3. Day 5-7: Task Execution Screen

---

## **NOTES & LEARNINGS** 💡

### **Key Insights**
- Async-first design is MUCH better for party games (no scheduling hassle)
- Video privacy feature is genius - creates FOMO and drives completion
- Quick Play is killer feature - must be <3 seconds to first task
- Notifications are critical for bringing users back

### **Technical Decisions**
- Using Flutter's built-in test framework (not pytest, since this is Dart)
- Using BLoC pattern for state management (already in codebase)
- Using Firebase for backend (already set up)
- Using Cloud Functions for notifications (necessary for async)

### **Future Considerations**
- AR tasks (requires ar_flutter_plugin)
- Haptic feedback tasks (requires HapticFeedback API)
- Live mode (real-time gameplay)
- Same-device mode (pass & play)
- Tournament mode (brackets)
- Monetization (premium task packs)

---

## **BUGS & ISSUES** 🐛

### **Open Issues**
- (None yet - will populate as development progresses)

### **Fixed Issues**
- (Will populate as bugs are fixed)

---

## **REFERENCES** 📚
- Flutter docs: https://flutter.dev/docs
- Firebase docs: https://firebase.google.com/docs
- BLoC pattern: https://bloclibrary.dev
- Flutter testing: https://flutter.dev/docs/testing

---

**Last Updated:** 2025-09-30 by Claude Code
**Next Review:** After Day 2 (Data Models Complete)
