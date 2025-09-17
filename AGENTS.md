AGENTS.md: Technical Brief for AI Development Team
1. Project Objective
Your primary directive is to build a cross-platform (iOS, Android, Web) party game application called "Taskmaster Party App" using the Flutter framework. The app facilitates Taskmaster-style games where users receive tasks, submit video links of their attempts, and have a designated judge score them. The core architecture must be serverless, using Firebase for all backend services to ensure zero maintenance and cost scalability.

2. Technology Stack
Core Framework: Flutter (latest stable version)

Programming Language: Dart

Backend: Google Firebase

Authentication: Firebase Authentication (Google Sign-In, Email/Password)

Database: Cloud Firestore (NoSQL, real-time)

Web Hosting: Firebase Hosting

State Management: Start with provider or flutter_bloc. Be consistent.

CI/CD: Codemagic (for mobile deployment)

3. Firestore Data Models
Implement the following Firestore data structures. All development should be against these models.

Collection: games

Document ID: (auto-generated)

Fields:

gameName: String (e.g., "Saturday Night Shenanigans")

creatorId: String (UID of the user who created it)

judgeId: String (UID of the designated judge)

status: String ("lobby", "in-progress", "completed")

inviteCode: String (a short, unique, shareable code)

createdAt: Timestamp

players: Array of Maps

userId: String

displayName: String

totalScore: Number

tasks: Array of Maps

title: String (e.g., "Make the most magnificent sandwich")

description: String (detailed instructions)

taskType: String ("video", "puzzle")

puzzleAnswer: String (optional, for autograded tasks)

submissions: Array of Maps

userId: String

videoUrl: String (link to user's video)

textAnswer: String (for puzzle submissions)

score: Number

isJudged: Boolean

Collection: users

Document ID: (user's UID from Firebase Auth)

Fields:

displayName: String

email: String

createdAt: Timestamp

Collection: community_tasks

Document ID: (auto-generated)

Fields:

title: String

description: String

submittedBy: String (user's UID)

upvotes: Number

4. Development Workflow & Best Practices
A. Mock-Driven Development:
Your immediate priority is to decouple the UI from Firebase. Do not call Firebase directly from your UI widgets.

Create a services directory. Inside, create an abstract DatabaseService class defining all required methods (e.g., Future<Game> createGame(...), Stream<Game> getGameStream(...)).

Create a FirebaseDataService that implements this abstract class and contains the actual Firebase logic.

Create a MockDataService that also implements the abstract class but returns hard-coded, fake data. It should mimic real-world delays using Future.delayed.

Use a service locator or dependency injection (like the provider package) to provide either the FirebaseDataService or MockDataService to the UI. Default to the mock service for all initial UI development. This allows the UI to be built and tested completely offline.

Example Mock Game Object:

// in mock_data_service.dart
final mockGame = {
    "gameName": "Mock Game Night",
    "creatorId": "mockUser123",
    "judgeId": "mockUser456",
    // ... other fields
};

B. Unit & Widget Testing:
All new features must be accompanied by tests. Use the built-in flutter_test framework.

Unit Tests: Test your business logic (e.g., functions in your BLoCs or ViewModels). Mock your service dependencies.

Widget Tests: Test each screen and component individually.

Verify that UI elements are rendered correctly based on state.

Simulate user interaction (tapping buttons, entering text) using tester.tap() and tester.enterText().

Always use the MockDataService for widget tests.

Example Widget Test:

// in game_lobby_screen_test.dart
testWidgets('GameLobbyScreen shows player names from mock data', (WidgetTester tester) async {
  // Setup: Provide the MockDataService to the widget tree.
  await tester.pumpWidget(MaterialApp(home: GameLobbyScreen()));

  // Verify: Find player names that exist in your mock data.
  expect(find.text('Mock Player Alice'), findsOneWidget);
  expect(find.text('Mock Player Bob'), findsOneWidget);
});

5. Agent Task Breakdown
Execute development according to the phases in taskmaster_app_checklist.md.

Agent 1 (Backend/Services):

Implement the full FirebaseDataService based on the data models.

Implement the MockDataService in parallel.

Agent 2 (UI/UX):

Develop all UI screens and widgets as defined in Phase 2.

You MUST develop against the MockDataService initially.

Write widget tests for all UI components.

Agent 3 (Integration/Testing):

Integrate the UI with the real FirebaseDataService.

Write integration tests using the integration_test package to verify end-to-end flows.

Fix bugs that arise during integration.
