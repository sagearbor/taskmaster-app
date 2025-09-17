Taskmaster App: Full Development & Deployment Checklist
This checklist outlines every step required to build and launch your Taskmaster-style app using Flutter and Firebase, with a focus on simplicity and zero ongoing costs for the initial versions.

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

[ ] Configure Firebase using flutterfire CLI tools (requires Firebase project)

[x] 2. Implement Mocking & Service Layers:

[x] Create abstract service classes for Database and Authentication.

[x] Create mock service implementations that return hard-coded data for offline UI development and testing.

[x] 3. Build User Authentication:

[x] Create a "Login/Register" screen.

[x] Implement sign-in logic with mock auth service

[x] Create a "wrapper" widget that shows the Login screen if logged out, and the Home screen if logged in.

[ ] Connect to real Firebase Auth (requires Firebase setup)

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

[ ] Connect to real Firestore (requires Firebase setup)

[x] 6. Implement Testing:

[x] Write Unit Tests for all business logic (e.g., score calculation).

[x] Write Widget Tests for every screen and component, using your mock services.

✅ Phase 3-4: Deployment & Launch
Follow the original Phase 3 (Web) and Phase 4 (Mobile) deployment steps to get the MVP live.

✅ Phase 5: V1.5 - Post-Launch Polish & Feedback
[ ] Monitor Usage: Keep an eye on the free-tier usage quotas in the Firebase console.

[ ] Gather Feedback: Actively ask your first users (friends) for feedback on bugs and features.

[ ] Basic Task Library: Instead of the game creator writing all tasks, create a simple, built-in list of 50-100 generic tasks the app can pull from.

✅ Phase 6: V2 - Enhancing Gameplay & Community (Novel & Easy)
Focus on features that dramatically increase fun and replayability with minimal code complexity.

[x] 1. User-Generated Content (UGC) Tasks:

[x] Task Submission: Add a screen where any user can write and submit a task idea to a central community_tasks collection.

[x] Community Task Browser: Create a "Community" tab in the app where users can browse all submitted tasks.

[x] Upvote System: Implement a simple upvote/downvote button for each community task.

[ ] Connect to real Firestore for persistence (requires Firebase setup)

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
