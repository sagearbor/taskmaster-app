# Next Session Instructions: Day 22-25 Firebase Integration

**Branch:** `feature/day22-25-firebase-integration`
**Status:** Ready to start development
**Timeline:** Day 22-23 + Day 24-25 (4 days of work)

---

## 📋 Overview

You will be implementing **Firebase Firestore integration** to replace the mock data source and enable real multiplayer async gameplay. This is Phase 2 of the development plan.

### What's Already Done ✅
- Phase 1 complete (21/21 days)
- All data models have async game fields (playerStatuses, currentTaskIndex, GameSettings, etc.)
- Mock data source fully functional with 5 realistic game scenarios
- 30+ unit tests + 11 integration tests all passing
- UI complete: game creation, task execution, judging, scoreboard
- Repository pattern implemented (`GameRepositoryImpl`)

### What You Need to Do 🎯
Implement Firebase Firestore data source to enable **real multiplayer** functionality.

---

## 🎯 Day 22-23: Firestore Structure Setup

### Task 1: Review & Update Firestore Security Rules

**File:** `firestore.rules`

**Requirements:**
- [ ] Ensure users can only read/write games they're in
- [ ] Only judge can update scores
- [ ] Players can only update their own playerStatus
- [ ] **🔒 CRITICAL:** Enforce video privacy (players can't read submissions until they submit)

**Example Rules Structure:**
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /games/{gameId} {
      // Users can read games they're a player in
      allow read: if request.auth != null &&
        request.auth.uid in resource.data.players[].userId;

      // Only creator can create/delete games
      allow create: if request.auth != null;
      allow delete: if request.auth != null &&
        request.auth.uid == resource.data.creatorId;

      // Players can update their own status
      allow update: if request.auth != null && (
        // Judge can update scores
        request.auth.uid == resource.data.judgeId ||
        // Players can update their own submissions
        request.auth.uid in resource.data.players[].userId
      );
    }

    match /users/{userId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

**Action Items:**
1. Read existing `firestore.rules` file
2. Update rules to match async game requirements
3. Deploy rules: `firebase deploy --only firestore:rules`
4. Test rules in Firebase console

---

### Task 2: Set Up Firestore Indexes

**Firebase Console Actions:**

Navigate to: https://console.firebase.google.com/project/taskmaster-app-3d480/firestore/indexes

**Required Indexes:**
1. **games** collection:
   - Compound index: `creatorId` (Ascending) + `status` (Ascending)
   - Compound index: `players` (Array-contains) + `status` (Ascending)

2. **games** collection (queries):
   - Index for: WHERE `players` array-contains userId ORDER BY `createdAt` DESC

**Why These Indexes:**
- Query games where user is a player, filtered by status
- Get user's active games sorted by creation date
- Firebase will prompt you to create these when you run queries

**Action Items:**
1. Note: You'll likely get index creation prompts when testing queries
2. Click the links Firebase provides to auto-create indexes
3. Wait for indexes to build (usually 1-5 minutes)

---

### Task 3: Implement FirebaseGameDataSource

**File:** `lib/features/games/data/datasources/firebase_game_data_source.dart`

**Status:** ⚠️ This file may already exist. Check first, then implement missing methods.

**Interface to Implement:**
```dart
abstract class GameRemoteDataSource {
  Stream<List<Map<String, dynamic>>> getGamesStream();
  Stream<Map<String, dynamic>?> getGameStream(String gameId);
  Future<String> createGame(Map<String, dynamic> gameData);
  Future<void> updateGame(String gameId, Map<String, dynamic> updates);
  Future<void> deleteGame(String gameId);
  Future<String> joinGame(String inviteCode, String userId);
}
```

**Key Implementation Details:**

1. **Constructor:**
```dart
class FirebaseGameDataSource implements GameRemoteDataSource {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  FirebaseGameDataSource({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;
```

2. **getGamesStream() - Get all games for current user:**
```dart
@override
Stream<List<Map<String, dynamic>>> getGamesStream() {
  final userId = _auth.currentUser?.uid;
  if (userId == null) return Stream.value([]);

  return _firestore
      .collection('games')
      .where('players', arrayContains: {'userId': userId})
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((snapshot) => snapshot.docs
          .map((doc) => {'id': doc.id, ...doc.data()})
          .toList());
}
```

3. **getGameStream(gameId) - Real-time listener on single game:**
```dart
@override
Stream<Map<String, dynamic>?> getGameStream(String gameId) {
  return _firestore
      .collection('games')
      .doc(gameId)
      .snapshots()
      .map((doc) => doc.exists ? {'id': doc.id, ...doc.data()!} : null);
}
```

4. **createGame() - Generate invite code, create doc:**
```dart
@override
Future<String> createGame(Map<String, dynamic> gameData) async {
  final docRef = await _firestore.collection('games').add(gameData);
  return docRef.id;
}
```

5. **updateGame() - Merge updates (don't overwrite):**
```dart
@override
Future<void> updateGame(String gameId, Map<String, dynamic> updates) async {
  await _firestore
      .collection('games')
      .doc(gameId)
      .update(updates);
}
```

6. **joinGame(inviteCode) - Query by code, add player:**
```dart
@override
Future<String> joinGame(String inviteCode, String userId) async {
  final query = await _firestore
      .collection('games')
      .where('inviteCode', isEqualTo: inviteCode)
      .limit(1)
      .get();

  if (query.docs.isEmpty) {
    throw Exception('Game not found with invite code: $inviteCode');
  }

  final gameDoc = query.docs.first;
  final gameData = gameDoc.data();
  final players = List<Map<String, dynamic>>.from(gameData['players'] ?? []);

  // Check if user already in game
  if (players.any((p) => p['userId'] == userId)) {
    return gameDoc.id;
  }

  // Add player
  players.add({
    'userId': userId,
    'displayName': 'Player ${userId.substring(0, 8)}', // Get from user profile
    'totalScore': 0,
  });

  await gameDoc.reference.update({'players': players});
  return gameDoc.id;
}
```

**Action Items:**
1. Check if `firebase_game_data_source.dart` exists
2. If not, create it; if yes, update it
3. Implement all 6 methods above
4. Add proper error handling with try-catch
5. Add logging for debugging

---

## 🎯 Day 24-25: Task & Submission Operations

### Task 4: Implement Advanced Firebase Operations

**File:** `lib/features/games/data/datasources/firebase_game_data_source.dart` (continued)

You'll add these methods to support game lifecycle:

**1. startGame(gameId) - Initialize first task:**
```dart
Future<void> startGame(String gameId) async {
  final gameDoc = await _firestore.collection('games').doc(gameId).get();
  final gameData = gameDoc.data()!;

  // Validation
  final players = List.from(gameData['players'] ?? []);
  final tasks = List.from(gameData['tasks'] ?? []);

  if (players.length < 2) {
    throw Exception('Need at least 2 players to start');
  }
  if (tasks.isEmpty) {
    throw Exception('Need at least 1 task to start');
  }

  // Initialize first task playerStatuses
  final firstTask = Map<String, dynamic>.from(tasks[0]);
  final playerStatuses = <String, Map<String, dynamic>>{};

  for (final player in players) {
    playerStatuses[player['userId']] = {
      'state': 'not_started',
      'videoUrl': null,
      'textAnswer': null,
      'score': null,
      'submittedAt': null,
    };
  }

  firstTask['playerStatuses'] = playerStatuses;
  firstTask['status'] = 'waiting_for_submissions';
  firstTask['deadline'] = DateTime.now()
      .add(Duration(hours: gameData['settings']['taskDeadlineHours']))
      .toIso8601String();

  tasks[0] = firstTask;

  // Update game
  await gameDoc.reference.update({
    'status': 'inProgress',
    'currentTaskIndex': 0,
    'tasks': tasks,
  });
}
```

**2. submitTask() - Update player submission:**
```dart
Future<void> submitTask(
  String gameId,
  int taskIndex,
  String playerId,
  String videoUrl,
) async {
  final gameDoc = await _firestore.collection('games').doc(gameId).get();
  final gameData = gameDoc.data()!;
  final tasks = List.from(gameData['tasks']);
  final task = Map<String, dynamic>.from(tasks[taskIndex]);

  // Update playerStatus
  final playerStatuses = Map<String, dynamic>.from(task['playerStatuses'] ?? {});
  playerStatuses[playerId] = {
    'state': 'submitted',
    'videoUrl': videoUrl,
    'textAnswer': null,
    'score': null,
    'submittedAt': DateTime.now().toIso8601String(),
  };

  // Add submission
  final submissions = List.from(task['submissions'] ?? []);
  final existingIndex = submissions.indexWhere((s) => s['userId'] == playerId);
  final submission = {
    'id': existingIndex >= 0 ? submissions[existingIndex]['id'] : 'sub_${DateTime.now().millisecondsSinceEpoch}',
    'userId': playerId,
    'videoUrl': videoUrl,
    'textAnswer': null,
    'score': null,
    'isJudged': false,
    'submittedAt': DateTime.now().toIso8601String(),
  };

  if (existingIndex >= 0) {
    submissions[existingIndex] = submission;
  } else {
    submissions.add(submission);
  }

  // Check if all players submitted
  final allSubmitted = playerStatuses.values.every(
    (status) => status['state'] == 'submitted' || status['state'] == 'skipped'
  );

  task['playerStatuses'] = playerStatuses;
  task['submissions'] = submissions;
  if (allSubmitted) {
    task['status'] = 'ready_to_judge';
  }

  tasks[taskIndex] = task;

  await gameDoc.reference.update({'tasks': tasks});
}
```

**3. scoreSubmission() - Judge scores a submission:**
```dart
Future<void> scoreSubmission(
  String gameId,
  int taskIndex,
  String playerId,
  int score,
) async {
  final gameDoc = await _firestore.collection('games').doc(gameId).get();
  final gameData = gameDoc.data()!;

  // Update task
  final tasks = List.from(gameData['tasks']);
  final task = Map<String, dynamic>.from(tasks[taskIndex]);

  final playerStatuses = Map<String, dynamic>.from(task['playerStatuses'] ?? {});
  if (playerStatuses[playerId] != null) {
    playerStatuses[playerId]['score'] = score;
    playerStatuses[playerId]['state'] = 'judged';
  }

  final submissions = List.from(task['submissions'] ?? []);
  final subIndex = submissions.indexWhere((s) => s['userId'] == playerId);
  if (subIndex >= 0) {
    submissions[subIndex]['score'] = score;
    submissions[subIndex]['isJudged'] = true;
  }

  // Check if all judged
  final allJudged = playerStatuses.values.every(
    (status) => status['state'] == 'judged' || status['state'] == 'skipped'
  );

  task['playerStatuses'] = playerStatuses;
  task['submissions'] = submissions;
  if (allJudged) {
    task['status'] = 'completed';
  }

  tasks[taskIndex] = task;

  // Update player total score
  final players = List.from(gameData['players']);
  final playerIndex = players.indexWhere((p) => p['userId'] == playerId);
  if (playerIndex >= 0) {
    players[playerIndex]['totalScore'] = (players[playerIndex]['totalScore'] ?? 0) + score;
  }

  await gameDoc.reference.update({
    'tasks': tasks,
    'players': players,
  });
}
```

**4. advanceToNextTask() - Move to next task:**
```dart
Future<void> advanceToNextTask(String gameId) async {
  final gameDoc = await _firestore.collection('games').doc(gameId).get();
  final gameData = gameDoc.data()!;

  final currentIndex = gameData['currentTaskIndex'] as int;
  final tasks = List.from(gameData['tasks']);

  if (currentIndex >= tasks.length - 1) {
    throw Exception('No more tasks');
  }

  final nextIndex = currentIndex + 1;

  // Initialize next task
  final nextTask = Map<String, dynamic>.from(tasks[nextIndex]);
  final playerStatuses = <String, Map<String, dynamic>>{};

  final players = List.from(gameData['players']);
  for (final player in players) {
    playerStatuses[player['userId']] = {
      'state': 'not_started',
      'videoUrl': null,
      'textAnswer': null,
      'score': null,
      'submittedAt': null,
    };
  }

  nextTask['playerStatuses'] = playerStatuses;
  nextTask['status'] = 'waiting_for_submissions';
  nextTask['deadline'] = DateTime.now()
      .add(Duration(hours: gameData['settings']['taskDeadlineHours']))
      .toIso8601String();

  tasks[nextIndex] = nextTask;

  await gameDoc.reference.update({
    'currentTaskIndex': nextIndex,
    'tasks': tasks,
  });
}
```

**Action Items:**
1. Add these 4 methods to `FirebaseGameDataSource`
2. Use Firestore transactions for critical updates (prevent race conditions)
3. Add error handling for each method
4. Consider adding `skipTask()` method as well

---

### Task 5: Update Service Locator

**File:** `lib/core/services/service_locator.dart`

**Current State:** Already uses mock data source

**What to Change:**
```dart
// Change this flag to switch between mock and Firebase
static const bool _useMockData = false; // Change from true to false

static Future<void> init({bool useMockServices = _useMockData}) async {
  // ... existing code ...

  if (useMockServices) {
    // Mock data source
    getIt.registerLazySingleton<GameRemoteDataSource>(
      () => MockGameDataSource(),
    );
  } else {
    // Firebase data source
    getIt.registerLazySingleton<GameRemoteDataSource>(
      () => FirebaseGameDataSource(),
    );
  }

  // ... rest of existing code ...
}
```

**Action Items:**
1. Read current `service_locator.dart`
2. Update the data source registration logic
3. Keep mock option for testing
4. Change default to Firebase when ready

---

### Task 6: Test Firebase Integration

**Multi-Device Testing:**

1. **Setup:**
   - Open app in 2 different browsers (Chrome + Firefox)
   - Or use Chrome normal + incognito mode
   - Sign in as different users in each

2. **Test Scenarios:**
   - [ ] Create game in Browser A → See it appear in Browser B after joining
   - [ ] Submit task in Browser A → See submission count update in Browser B instantly
   - [ ] Judge scores in Browser B → See scores update in Browser A
   - [ ] Advance to next task → Both browsers see new task

3. **Real-Time Update Testing:**
   - [ ] Player joins → everyone sees instantly
   - [ ] Task submission → judge gets notified
   - [ ] Scores update → leaderboard animates
   - [ ] Game state changes broadcast to all

4. **Offline Testing:**
   - [ ] Disconnect network mid-game
   - [ ] Try to submit → should queue
   - [ ] Reconnect → submission syncs
   - [ ] Verify Firestore offline persistence works

**Action Items:**
1. Test each scenario above
2. Fix any bugs found
3. Verify security rules work (try unauthorized actions)
4. Test with 3+ concurrent users

---

## 📝 Testing Requirements

### Unit Tests

**File:** `test/features/games/data/datasources/firebase_game_data_source_test.dart`

Use `fake_cloud_firestore` package for mocking:

```yaml
# pubspec.yaml
dev_dependencies:
  fake_cloud_firestore: ^2.4.1
```

**Test Structure:**
```dart
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';

void main() {
  late FakeFirebaseFirestore fakeFirestore;
  late MockFirebaseAuth fakeAuth;
  late FirebaseGameDataSource dataSource;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    fakeAuth = MockFirebaseAuth(signedIn: true);
    dataSource = FirebaseGameDataSource(
      firestore: fakeFirestore,
      auth: fakeAuth,
    );
  });

  group('createGame', () {
    test('should create game in Firestore', () async {
      // Test implementation
    });
  });

  // ... more tests
}
```

**Required Tests:**
- [ ] createGame - creates doc and returns ID
- [ ] getGamesStream - filters by current user
- [ ] getGameStream - real-time updates
- [ ] updateGame - merges updates correctly
- [ ] joinGame - adds player to array
- [ ] startGame - initializes playerStatuses
- [ ] submitTask - updates task status
- [ ] scoreSubmission - updates scores
- [ ] advanceToNextTask - increments index

---

## 🚀 Deployment Checklist

### Before Deploying to Production

- [ ] All tests passing (unit + integration)
- [ ] Firestore rules deployed and tested
- [ ] Indexes created and built
- [ ] Multi-device testing complete
- [ ] Offline mode tested
- [ ] Error handling verified
- [ ] Security rules prevent unauthorized access

### Deploy Steps

1. **Deploy Firestore Rules:**
```bash
firebase deploy --only firestore:rules
```

2. **Switch to Firebase in Code:**
   - Change `_useMockData = false` in service_locator.dart
   - Rebuild: `flutter build web --release`

3. **Deploy to Hosting:**
```bash
firebase deploy --only hosting
```

4. **Verify Deployment:**
   - Visit: https://taskmaster-app-3d480.web.app/
   - Test with multiple users
   - Check Firebase console for errors

---

## 🐛 Common Issues & Solutions

### Issue 1: "Missing or insufficient permissions"
**Solution:** Check Firestore rules. Make sure user is authenticated and has permission.

### Issue 2: "Index not found"
**Solution:** Click the link in the error message to create the index. Wait 1-5 minutes for it to build.

### Issue 3: Data not updating in real-time
**Solution:** Verify you're using `.snapshots()` stream, not `.get()` future. Check that listeners are properly set up in BLoC.

### Issue 4: Race conditions (players submitting simultaneously)
**Solution:** Use Firestore transactions for critical updates:
```dart
await _firestore.runTransaction((transaction) async {
  // Read-modify-write pattern
});
```

### Issue 5: "Array contains" query not working
**Solution:** Make sure you're using the exact map structure Firebase expects. For players array, use:
```dart
.where('players', arrayContains: {'userId': userId})
```

---

## 📚 Reference Documentation

### Key Files to Review
1. `lib/core/models/game.dart` - Game model with all async fields
2. `lib/core/models/task.dart` - Task model with playerStatuses
3. `lib/features/games/data/repositories/game_repository_impl.dart` - Repository pattern
4. `lib/features/games/data/datasources/mock_game_data_source.dart` - Reference implementation

### Firebase Documentation
- Firestore Web: https://firebase.google.com/docs/firestore/quickstart
- Security Rules: https://firebase.google.com/docs/firestore/security/get-started
- Queries: https://firebase.google.com/docs/firestore/query-data/queries
- Offline Persistence: https://firebase.google.com/docs/firestore/manage-data/enable-offline

### Project-Specific Notes
- Firebase project: `taskmaster-app-3d480`
- Firebase console: https://console.firebase.google.com/project/taskmaster-app-3d480
- Current deployment: https://taskmaster-app-3d480.web.app/
- CLAUDE.md has full project context

---

## ✅ Definition of Done

You're done when:
- [x] Firebase data source fully implements all methods
- [x] Firestore rules deployed and tested
- [x] Indexes created
- [x] All unit tests passing
- [x] Multi-device testing successful
- [x] Real-time updates working
- [x] Offline mode functional
- [x] App deployed to production
- [x] DEVELOPMENT_CHECKLIST.md updated
- [x] Git commit created with comprehensive message
- [x] Pull request created

**Expected PR Title:** `feat: Day 22-25 Firebase Integration`

**Expected Commit Format:**
```
feat: Implement Firebase Firestore Integration (#8)

## Day 22-23: Firestore Structure Setup ✅
- Firebase security rules implemented
- Indexes created for game queries
- FirebaseGameDataSource with basic CRUD operations

## Day 24-25: Task & Submission Operations ✅
- startGame() with playerStatuses initialization
- submitTask() with real-time updates
- scoreSubmission() with score aggregation
- advanceToNextTask() with task progression

## Testing
- Unit tests with fake_cloud_firestore
- Multi-device testing successful
- Real-time updates verified
- Offline mode functional

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>
```

---

## 💬 Starting the Session

**Recommended Prompt to Start:**
```
I'm ready to implement Day 22-25 Firebase Integration. I'm on the branch `feature/day22-25-firebase-integration`. Please read NEXT_SESSION_INSTRUCTIONS.md and DEVELOPMENT_CHECKLIST.md, then begin implementing the Firebase Firestore data source. Start with Day 22-23 tasks first, then move to Day 24-25. Work through all tasks systematically, test thoroughly, then commit, deploy, and create a PR when done.
```

Good luck! 🚀