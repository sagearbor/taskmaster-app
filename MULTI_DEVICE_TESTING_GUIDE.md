# Multi-Device Testing Guide

**Purpose:** Test real-time synchronization across multiple devices/browser sessions

**Live URL:** https://taskmaster-app-3d480.web.app

---

## ✅ Real-Time Sync Verification

The app uses Firestore `.snapshots()` for real-time updates:

### What's Being Synchronized:
1. **Game List** (`getGamesStream`) - Home screen updates when games are created/deleted
2. **Game Details** (`getGameStream`) - All game state changes sync instantly:
   - Players joining/leaving
   - Tasks being added/updated
   - Game status changes (lobby → in-progress → completed)
   - Submissions being made
   - Scores being updated

### How It Works:
```dart
// Home screen listens to all user's games
_firestore.collection('games')
  .orderBy('createdAt', descending: true)
  .snapshots()  // ← Real-time listener!

// Game detail screen listens to specific game
_firestore.collection('games')
  .doc(gameId)
  .snapshots()  // ← Real-time listener!
```

---

## 🧪 Testing Procedure

### Setup (Choose One):

**Option A: Multiple Browser Windows**
1. Open Chrome: https://taskmaster-app-3d480.web.app
2. Open Firefox: https://taskmaster-app-3d480.web.app
3. Or open Chrome Incognito: https://taskmaster-app-3d480.web.app

**Option B: Multiple Tabs (Same Browser)**
1. Open Tab 1: https://taskmaster-app-3d480.web.app
2. Open Tab 2: https://taskmaster-app-3d480.web.app (Ctrl+T, paste URL)

---

## 📋 Test Cases

### Test 1: Game Creation Sync ✅
**Device A:**
1. Sign in (or continue as guest)
2. Click "Create Game" button
3. Enter game name: "Multi-Device Test"
4. Create game

**Device B:**
- Game should appear in list within 1-2 seconds
- Click on the game to open it

**Expected:** Both devices see the same game

---

### Test 2: Player Join Sync ✅
**Device A (Creator):**
- Open the game you created
- Note the invite code

**Device B:**
1. Click "Join Game" button (floating action button)
2. Enter the invite code
3. Click "Join"

**Expected:**
- Device B navigates to game lobby
- Device A sees Device B's player appear in player list (within 1-2 seconds)
- Both devices show player count updated

---

### Test 3: Game Start Sync ✅
**Device A (Creator):**
- Click "Start Game" button

**Expected:**
- Device A: Game status changes to "In Progress"
- Device B: Game status updates to "In Progress" (within 1-2 seconds)
- Both see first task activated
- Both see "waiting for submissions" status

---

### Test 4: Quick Play Solo (Single User) ✅
**Device A:**
1. Click "Quick Play" banner
2. Game creates and navigates to detail screen

**Device B (same user signed in):**
- Game should appear in game list
- Can open the same game

**Expected:**
- Quick Play games appear in game list
- Real-time sync works for solo games too

---

### Test 5: Task Submission Sync ✅
**Device B (Player):**
1. In the in-progress game, click on current task
2. Submit a video URL: `https://example.com/video.mp4`
3. Click "Submit"

**Expected:**
- Device B: Submission confirmed, status changes to "submitted"
- Device A (Judge): Sees submission appear (within 1-2 seconds)
- Device A: Can now judge the submission

---

### Test 6: Scoring Sync ✅
**Device A (Judge):**
1. View player submissions
2. Assign score (1-5 points)
3. Submit score

**Expected:**
- Device A: Score recorded, task marked as judged
- Device B: Player sees their score update (within 1-2 seconds)
- Both devices: Scoreboard updates with new total

---

## 🐛 Common Issues & Solutions

### Issue: Changes don't sync
**Possible Causes:**
- Network connection lost
- Firestore security rules blocking read/write
- Browser cache issues

**Solutions:**
1. Check browser console for errors (F12)
2. Refresh both devices (Ctrl+R or Cmd+R)
3. Check Firestore console: https://console.firebase.google.com/project/taskmaster-app-3d480/firestore

### Issue: "Permission denied" errors
**Solution:**
- Ensure both users are authenticated (not signed out)
- Check Firestore rules allow read access
- Anonymous users can read but not create games

### Issue: Lag/delay in sync
**Normal Behavior:**
- 1-2 second delay is normal for Firestore
- Mobile networks may be slower (3-5 seconds)
- First sync after page load may take longer

---

## ✅ Success Criteria

Multi-device testing is complete when:
- [x] Real-time listeners properly implemented (`.snapshots()`)
- [ ] Game creation syncs across devices (< 2 seconds)
- [ ] Player joins sync across devices (< 2 seconds)
- [ ] Game status changes sync (lobby → in-progress)
- [ ] Task submissions sync to judge
- [ ] Score updates sync to all players
- [ ] No console errors during testing
- [ ] Works in at least 2 different browsers/windows

---

## 📊 Performance Benchmarks

**Expected Latency:**
- Same WiFi network: 200-500ms
- Different networks: 1-2 seconds
- Mobile 4G: 2-5 seconds

**Firestore Reads:**
- Each `.snapshots()` listener = 1 read per update
- Free tier: 50,000 reads/day
- Typical game with 4 players over 10 tasks = ~500 reads

---

## 🎯 Next Steps After Testing

If all tests pass:
1. Mark Day 26-27 (Multi-device testing) as complete ✅
2. Update development checklist
3. Merge `feature/day26-30-testing-and-quick-play` to `main`
4. Push to remote repository
5. Consider mobile deployment (Phase 4)

If issues found:
1. Document issues in GitHub Issues
2. Fix bugs before merging
3. Re-run tests after fixes
