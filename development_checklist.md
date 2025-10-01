Taskmaster App: Full Development & Deployment Checklist
This checklist outlines every step required to build and launch your Taskmaster-style app using Flutter and Firebase, with a focus on simplicity and zero ongoing costs for the initial versions.

---

## 🎯 Current Status (Updated 2025-09-30)

**Phase Completed:** Phase 5 (V1.5 - Post-Launch Polish) ✅

**Live Deployment:** https://taskmaster-app-3d480.web.app

**Recent Accomplishments:**
- ✅ Quick Play feature implemented and tested
- ✅ Firebase Auth fully integrated (real auth, not mocks)
- ✅ Firebase Firestore connected and working
- ✅ 3 critical bugs fixed (tasks display, game list, auth restrictions)
- ✅ 225+ prebuilt tasks across 9 categories
- ✅ Anonymous user restrictions (guests can join, not create)

**What's Next:**
- [ ] Multi-device testing (open app in 2+ browser tabs/windows)
- [ ] Mobile deployment (Google Play + App Store)
- [ ] Phase 6-9 advanced features (optional)

**Branch:** `feature/day26-30-testing-and-quick-play` (ready to merge to main)

---

✅ Phase 1: Foundation & Setup (The "No-Code" Prep Work)
This entire phase requires no coding. It's about setting up the free accounts and tools you'll need.

[ ] 1. Create Developer Program Accounts:

[ ] Apple Developer Program: Enroll at developer.apple.com. ($99/year - This is the only mandatory cost in the entire process).

[ ] Google Play Developer: Create an account at play.google.com/console. ($25 one-time fee).

[ ] 2. Create Project Management & Code Hosting Accounts:

[ ] GitHub Account: Create a free account at github.com.

[ ] Create a New Repository: Make a new private repository on GitHub for your app's code.

[ ] 3. Set Up Firebase Project (Your Backend):

[ ] Create Firebase Account: Go to firebase.google.com and create a project.

[ ] Select the Spark Plan: Choose the free "Spark Plan" when prompted.

[ ] Enable Services:

[ ] Go to the "Authentication" section and enable the "Google" and "Email/Password" sign-in methods.

[ ] Go to the "Firestore Database" section and create a database. Start in Test Mode for now (this makes it easy to develop).

[ ] Go to the "Hosting" section and click "Get Started".

[ ] 4. Set Up Codemagic (Your Deployment Butler):

[ ] Create Codemagic Account: Sign up for free at codemagic.io using your GitHub account.

[ ] Authorize Access: Allow Codemagic to access the new repository you created.

[ ] 5. Install Local Development Software:

[ ] Install Flutter SDK: Follow the official guide for your operating system at flutter.dev.

[ ] Install VS Code: Download from code.visualstudio.com.

[ ] Install Flutter & Dart extensions in VS Code.

[ ] Run flutter doctor in your terminal and fix any reported issues.

✅ Phase 2: Core App Development (Writing the MVP Code)
This is where you'll build the app's essential features in Flutter.

[x] 1. Initialize Flutter Project & Connect Firebase:

[x] Create a new Flutter project: flutter create taskmaster_app

[x] Add Firebase packages (ready for configuration)

[x] Configure Firebase using flutterfire CLI tools (DONE - Firebase connected and deployed)

[x] 2. Implement Mocking & Service Layers:

[x] Create abstract service classes for Database and Authentication.

[x] Create mock service implementations that return hard-coded data for offline UI development and testing.

[x] 3. Build User Authentication:

[x] Create a "Login/Register" screen.

[x] Implement sign-in logic with mock auth service

[x] Create a "wrapper" widget that shows the Login screen if logged out, and the Home screen if logged in.

[x] Connect to real Firebase Auth (DONE - Using FirebaseAuthDataSource)

[x] 4. Design the Core App Screens:

[x] Home Screen: List of games, button to "Create New Game".

[x] Create Game Screen: Form to name the game.

[x] Game Lobby Screen: Shows players, invite code, and tasks. Button for creator to "Start Game".

[x] Task View Screen: Displays task description. Text field to paste video link and a "Submit" button.

[x] Judging Screen: For the judge. Shows list of submission links. Interface to assign points (e.g., 1 to 5).

[x] Scoreboard Screen: Simple table of player names and total scores.

[x] 5. Implement Firestore Logic (The "Brain"):

[x] Games Collection: Mock implementation ready

[x] Real-Time Updates: Simulated with streams in mock services

[x] Connect to real Firestore (DONE - Using FirestoreGameDataSource)

[x] 6. Implement Testing:

[x] Write Unit Tests for all business logic (e.g., score calculation).

[x] Write Widget Tests for every screen and component, using your mock services.

✅ Phase 3: Web Deployment (COMPLETED)

[x] Firebase Hosting Setup:
[x] Project deployed to https://taskmaster-app-3d480.web.app
[x] Firestore security rules configured
[x] Firebase Authentication enabled (Email/Password + Anonymous)
[x] Production build pipeline working (flutter build web --release)

✅ Phase 4: Mobile Deployment
Follow the original Phase 4 (Mobile) deployment steps to get the app on stores.

✅ Phase 5: V1.5 - Post-Launch Polish & Feedback

[x] Quick Play Feature (Session 2025-09-30):
[x] Add Quick Play hero banner to home screen
[x] Implement random game name generator (e.g., "Epic Adventure #4273")
[x] Auto-select 5 random tasks from 225+ prebuilt tasks
[x] Create solo game (user as both creator and judge)
[x] Skip lobby, go straight to in-progress status
[x] Set 24-hour deadline on first task
[x] Navigate directly to game detail screen
[x] Add 5 comprehensive unit tests for Quick Play flow

[x] Bug Fixes & Auth Improvements (Session 2025-09-30):
[x] Fix getCurrentUser() to return real Firebase Auth data (was hardcoded)
[x] Add getCurrentUserData() method to auth data sources
[x] Fix games not appearing in creator's list (display name mismatch)
[x] Add auth restrictions: prevent anonymous users from creating games
[x] Add isCurrentUserAnonymous() method to AuthRepository
[x] Show "Sign Up Required" dialog for guests trying to create games
[x] Fix tasks not showing in GameLobbyView (add numbered task list display)
[x] Guests can still join games via invite codes

[ ] Monitor Usage: Keep an eye on the free-tier usage quotas in the Firebase console.

[ ] Gather Feedback: Actively ask your first users (friends) for feedback on bugs and features.

[x] Basic Task Library: 225+ prebuilt tasks implemented across 9 categories.

✅ Phase 6: V2 - Enhancing Gameplay & Community (Novel & Easy)
Focus on features that dramatically increase fun and replayability with minimal code complexity.

[x] 1. User-Generated Content (UGC) Tasks:

[x] Task Submission: Add a screen where any user can write and submit a task idea to a central community_tasks collection.

[x] Community Task Browser: Create a "Community" tab in the app where users can browse all submitted tasks.

[x] Upvote System: Implement a simple upvote/downvote button for each community task.

[x] Connect to real Firestore for persistence (DONE - community tasks can be persisted)

[x] 2. Advanced Game Modes:

[x] Team vs. Team: Add an option during game creation to sort players into teams.

[x] Secret Individual Tasks: Randomly assign one player a secret side-mission (17 secret tasks implemented).

[x] 3. Task Modifiers:

[x] Before each task begins, randomly apply a "modifier" from a predefined list (18 modifiers implemented).

[x] 4. Geo-Located Tasks:

[x] Integrate a Flutter location package (geolocator).

[x] Create a new task type for physical location-based challenges (12 location types).

[ ] Enable actual GPS functionality (requires permissions setup)

[x] 5. Autograded Puzzle Tasks:

[x] Add a new task type ("puzzle") that accepts a text input instead of a video link.

[x] Implement logic to automatically check the submission against a stored answer and award points.

✅ Phase 7: V3 - Monetization & Revenue (The Business Model)
Introduce revenue streams once the app has a stable, engaged user base.

[x] 1. Implement In-App Advertising (MOCK ONLY):

[x] Created AdService interface with mock implementation

[x] Placeholder ad spaces in UI (ready for AdMob integration)

[ ] Integrate the actual Google AdMob SDK for Flutter (production)

[ ] Configure real ad unit IDs (requires AdMob account)

[x] 2. Create "Taskmaster Pro" (UI ONLY):

[x] Store screen with Pro version UI

[x] Mock purchase flow for testing

[ ] Implement actual in-app purchases (requires store accounts)

[ ] Configure products in Google Play / App Store

[x] 3. Curated "Task Packs" (UI ONLY):

[x] Task pack cards in store interface

[x] Mock purchase buttons

[ ] Actual IAP implementation with real products

[ ] 4. Paid Judge Marketplace:

[ ] Allow a game creator to post a request for a paid, anonymous judge.

[ ] Create an interface for verified "Pro Judges" to browse and accept these gigs.

[ ] Integrate a payment provider (like Stripe) to handle the transactions.

✅ Phase 8: V4 - Advanced Engagement Features (Novel & Harder)
Features that require more complex implementation but create unique, shareable moments.

[ ] 1. Manual "Episode" Creation Tool:

[ ] Timestamp Bookmarking: Allow the judge to save video timestamps.

[ ] Highlight Reel: Present an ordered, shareable list of all bookmarked video links.

[ ] 2. Augmented Reality (AR) Tasks:

[ ] Integrate an AR plugin for Flutter for unique 3D tasks.

✅ Phase 9: V5 - The Future (AI & Automation)
Ambitious, "moonshot" features that would require significant R&D and likely move beyond the zero-cost model by requiring paid APIs.

[ ] 1. AI-Generated Tasks:

[ ] Integrate with a generative AI API (like Gemini) to create tasks on the fly.

[ ] 2. Automated Video Splicing (The "Episode" Maker):

[ ] Explore using a cloud-based video intelligence API to analyze video links for key moments.

[ ] A server-side process could then automatically stitch these clips together into a highlight reel.

[ ] 3. Task Icons/Images System:

[ ] Add visual icons or images to each task to make them more engaging

**Implementation Options:**
- **Option A: Icon Mapping** - Use Material Icons or emoji based on keywords
  - Regex/keyword detection: "cook" → 🍳, "run" → 🏃, "draw" → 🎨
  - Simple mapping in code: `taskIconMap = {"cooking": Icons.restaurant, ...}`

- **Option B: AI Image Generation** - Use DALL-E/Midjourney API
  - Generate unique image per task on creation
  - Store in Firebase Storage
  - More expensive but unique visuals

- **Option C: Icon Library** - Curated icon set from Noun Project/Flaticon
  - Download ~500 task-related icons
  - Store in assets, map by category
  - One-time cost, good performance

**Recommended:** Option A (keyword → emoji/icon) for MVP, then Option C for polish

[ ] 4. 3D Avatar Social System:

[ ] Create 3D animated avatars with user profile photos as heads that interact on the home screen.

---

## 🎮 Phase 10: 3D Avatar Social System (Advanced Feature)

**Goal:** Create an engaging social experience where users' profile photos become 3D animated characters that run, climb, and interact on the home screen.

### Overview
User profile photos are applied to 3D character bodies that:
- Run around the home screen with physics
- Climb up game cards and UI elements
- Push and interact with each other
- React to gravity and collisions
- Show who's currently online

### Technical Approach: 2.5D Isometric System

**Why 2.5D instead of full 3D:**
- ✅ Much better web performance
- ✅ Simpler implementation (proven Flame 2D)
- ✅ Still looks 3D with isometric projection
- ✅ Easier physics and collision detection
- ✅ More reliable across devices

**Technology Stack:**
```yaml
dependencies:
  flame: ^1.10.0           # Flutter game engine
  flame_forge2d: ^0.16.0   # 2D physics engine
```

### Implementation Phases

#### Phase 10.1: Foundation (Days 1-2)
**Setup Flame Engine Overlay**

[ ] Add Flame dependencies to pubspec.yaml
[ ] Create `AvatarWorld` game class extending FlameGame
[ ] Setup physics world with gravity
[ ] Create overlay stack on HomeScreen:
```dart
Stack(
  children: [
    HomeScreen(),              // Regular Flutter UI
    GameWidget<AvatarWorld>(), // Flame overlay
  ],
)
```

[ ] Test basic physics: dropping objects with gravity
[ ] Ensure 60 FPS on web

#### Phase 10.2: Avatar Bodies (Days 3-5)
**Create Character System**

[ ] Design isometric sprite sheets:
  - Idle animation (bobbing)
  - Walk cycle (4-8 frames)
  - Run cycle (6-10 frames)
  - Jump animation
  - Push/interact animation

[ ] Create `AvatarBody` component:
```dart
class AvatarBody extends SpriteAnimationComponent {
  final String userId;
  final String photoUrl;

  // Body parts
  late SpriteComponent head;    // User's circular photo
  late SpriteAnimationComponent body;  // Animated torso/legs

  // Physics
  late BodyComponent physicsBody;

  // State
  AvatarState state = AvatarState.idle;
  Vector2 targetPosition;
}
```

[ ] Implement head texture loading from Firebase Storage
[ ] Apply circular crop to user photos (profile pic style)
[ ] Attach photo to body sprite
[ ] Create fallback avatars for users without photos

[ ] Implement character controller:
  - Walk animation triggers on movement
  - Idle animation when stationary
  - Jump mechanics
  - Turn to face movement direction

#### Phase 10.3: UI Integration (Days 6-8)
**Make UI Elements Interactive Platforms**

[ ] Create physics colliders for UI elements:
```dart
class GameCardPlatform extends BodyComponent {
  final Vector2 position;
  final Vector2 size;

  @override
  void onMount() {
    final shape = RectangleShape()
      ..size = size
      ..isSensor = false;  // Solid platform
    addShape(shape);
  }
}
```

[ ] Map Flutter UI coordinates to game world:
  - Game cards → Platforms
  - Text elements → Platforms
  - Buttons → Platforms (avatars can stand on them!)

[ ] Implement climbing mechanics:
```dart
class ClimbingBehavior extends Component {
  void update(double dt) {
    if (isTouchingPlatform()) {
      if (inputUp) {
        applyClimbForce();
        setState(AvatarState.climbing);
      }
    }
  }
}
```

[ ] Add pathfinding (simple A* or Dijkstra):
  - Avatars navigate to clicked UI elements
  - Avoid obstacles
  - Find optimal climbing paths

[ ] Mouse/touch interaction:
  - Click on game card → Avatar runs there
  - Click on avatar → Show user menu
  - Hover over avatar → Show tooltip with username

#### Phase 10.4: Physics Interactions (Days 9-10)
**Social Behaviors & Competition**

[ ] Implement push mechanics:
```dart
void onCollisionStart(PositionComponent other) {
  if (other is AvatarBody) {
    // Calculate push force
    final direction = (other.position - position).normalized();
    final pushForce = direction * pushStrength;

    other.physicsBody.applyLinearImpulse(pushForce);
    setState(AvatarState.pushing);
  }
}
```

[ ] Add competitive behaviors:
  - Race to clicked location (first one there wins)
  - King of the Hill (stay on platform longest)
  - Push enemies off platforms
  - Territorial behavior (defend "home" area)

[ ] Implement personality traits:
```dart
enum AvatarPersonality {
  aggressive,  // Pushes others frequently
  friendly,    // Avoids collisions
  explorer,    // Climbs everywhere
  lazy,        // Moves slowly, sits often
}
```

[ ] Add reaction animations:
  - Get pushed → stumble animation
  - Fall off platform → flail animation
  - Successful push → victory pose
  - Meet friend → wave animation

#### Phase 10.5: Performance & Polish (Days 11-12)
**Optimization & UX**

[ ] Performance optimization:
  - Limit to 10-15 avatars max on screen
  - Use sprite batching for efficiency
  - Implement object pooling for avatars
  - Lazy load physics for off-screen avatars
  - Use LOD (Level of Detail) for distant avatars

[ ] Add device capability detection:
```dart
if (isLowEndDevice() || isMobile) {
  // Show static profile list
  return SimpleProfileList();
} else {
  // Show full 3D avatar system
  return AvatarWorldOverlay();
}
```

[ ] Polish features:
  - Particle effects (dust when landing)
  - Sound effects (footsteps, jumps, pushes)
  - Camera shake on collisions
  - Shadows under avatars
  - Ambient animations (breathing, looking around)

[ ] User settings:
  - Toggle 3D avatars on/off
  - Adjust avatar density (how many shown)
  - Mute sounds
  - "Focus mode" (hide all avatars)

### Data Model Changes

#### User Model Addition:
```dart
class User {
  // ... existing fields

  final String? photoUrl;           // Firebase Storage URL
  final DateTime? lastOnline;       // For presence detection
  final AvatarPersonality personality;  // Avatar behavior
  final AvatarCustomization customization;  // Body style, colors
}
```

#### Online Presence System:
```dart
// Firestore presence detection
class PresenceService {
  void trackUserPresence(String userId) {
    final presenceRef = _firestore
      .collection('presence')
      .doc(userId);

    // Set online
    presenceRef.set({
      'online': true,
      'lastSeen': FieldValue.serverTimestamp(),
    });

    // Set offline on disconnect
    presenceRef.onDisconnect().update({
      'online': false,
      'lastSeen': FieldValue.serverTimestamp(),
    });
  }
}
```

### Bundle Size & Performance Impact

**Expected Bundle Size Increase:**
- Flame engine: ~500KB
- forge2d physics: ~200KB
- Sprite sheets (per user): ~50KB
- **Total: ~1-2MB increase**

**Performance Targets:**
- 60 FPS on desktop web
- 30 FPS minimum on mobile web
- <100ms input latency
- Graceful fallback on low-end devices

### Testing Requirements

[ ] Unit tests for physics calculations
[ ] Integration tests for avatar spawning
[ ] Performance tests with 15 avatars
[ ] Cross-browser compatibility (Chrome, Firefox, Safari)
[ ] Mobile web testing (iOS Safari, Chrome Mobile)
[ ] Accessibility: Keyboard navigation option

### Fallback Strategy

**If 3D system is too complex/slow:**
1. **Static Profile List** (already implemented)
2. **2D Sprite Parade** (simple left-to-right walk)
3. **Profile Carousel** (rotating 3D cards with photos)

### Future Enhancements (Post-MVP)

[ ] Customizable avatar bodies (different styles)
[ ] Emote system (avatars do dances/reactions)
[ ] Voice chat integration (avatars' mouths move)
[ ] Mini-games between avatars
[ ] Seasonal costumes/themes
[ ] True 3D with Flame 3D (when stable)

---

### 📊 Development Priority

**Priority: MEDIUM-LOW**
- This is a "wow factor" feature, not core functionality
- Implement AFTER core game loop is solid
- Consider as V3-V4 feature
- Great for marketing/demos

**Estimated Timeline: 2-3 weeks**
**Risk Level: MEDIUM** (performance on web can be tricky)
**User Impact: HIGH** (very memorable and shareable)
