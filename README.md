# Taskmaster Party App 
An unofficial, fan-made mobile and web application for playing Taskmaster-style party games with friends, whether you're in the same room or across the globe.

🚀 Project Goal
The core idea is to create a simple, fun, and zero-cost platform for friends to compete in creative challenges. The app provides tasks, manages players, and keeps score, but cleverly avoids storage and hosting costs by having users share links to videos they've hosted on their own cloud services (like Google Photos, unlisted YouTube videos, etc.).

This project is built with a "single codebase" philosophy, targeting iOS, Android, and the Web simultaneously.

✨ Features (Planned)
Game Creation & Management: Create private game rooms for you and your friends.

Real-time Gameplay: Receive tasks, submit your attempts, and see scores update in real-time.

Remote Judging: A designated "Taskmaster" can view submissions (via links) and award points from anywhere.

Cross-Platform: Play on your iPhone, Android device, or in a web browser.

🛠️ Technology Stack
Frontend & App Logic: Flutter - For a single codebase across all platforms.

Backend Services: Firebase

Authentication: For secure user login (Google Sign-In, Email/Password).

Firestore: As the real-time NoSQL database for game state, tasks, scores, and video links.

Hosting: For deploying the web version of the app.

CI/CD & Deployment: Codemagic - To automate the build and release process for the iOS and Android app stores.

⚙️ Setup & Installation
(This section will be updated with instructions on how to run the project locally.)

Clone the repository: git clone <your-repo-url>

Install dependencies: flutter pub get

Run the app: flutter run

This is an independent project created by a fan and is not affiliated with the official Taskmaster show or its creators.
