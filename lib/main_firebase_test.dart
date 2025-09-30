/// Firebase connection test
/// Run with: flutter run -d chrome -t lib/main_firebase_test.dart

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const FirebaseTestApp());
}

class FirebaseTestApp extends StatelessWidget {
  const FirebaseTestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Firebase Test',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const FirebaseTestScreen(),
    );
  }
}

class FirebaseTestScreen extends StatefulWidget {
  const FirebaseTestScreen({super.key});

  @override
  State<FirebaseTestScreen> createState() => _FirebaseTestScreenState();
}

class _FirebaseTestScreenState extends State<FirebaseTestScreen> {
  String _status = 'Checking Firebase connection...';
  String? _userId;
  Color _statusColor = Colors.orange;

  final _emailController = TextEditingController(text: 'test@example.com');
  final _passwordController = TextEditingController(text: 'password123');

  @override
  void initState() {
    super.initState();
    _checkFirebaseConnection();
  }

  Future<void> _checkFirebaseConnection() async {
    try {
      // Check if Firebase is initialized
      final app = Firebase.app();
      setState(() {
        _status = '✅ Firebase Connected!\nProject: ${app.options.projectId}';
        _statusColor = Colors.green;
      });
    } catch (e) {
      setState(() {
        _status = '❌ Firebase Error: $e';
        _statusColor = Colors.red;
      });
    }
  }

  Future<void> _testSignUp() async {
    setState(() {
      _status = 'Creating account...';
      _statusColor = Colors.orange;
    });

    try {
      final credential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text,
        password: _passwordController.text,
      );

      setState(() {
        _userId = credential.user?.uid;
        _status = '✅ Sign Up Successful!\nUser ID: $_userId';
        _statusColor = Colors.green;
      });
    } on FirebaseAuthException catch (e) {
      setState(() {
        if (e.code == 'email-already-in-use') {
          _status = '⚠️ Email already registered. Try signing in instead.';
          _statusColor = Colors.orange;
        } else if (e.code == 'weak-password') {
          _status = '❌ Password too weak';
          _statusColor = Colors.red;
        } else {
          _status = '❌ Sign Up Error: ${e.message}';
          _statusColor = Colors.red;
        }
      });
    }
  }

  Future<void> _testSignIn() async {
    setState(() {
      _status = 'Signing in...';
      _statusColor = Colors.orange;
    });

    try {
      final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text,
        password: _passwordController.text,
      );

      setState(() {
        _userId = credential.user?.uid;
        _status = '✅ Sign In Successful!\nUser ID: $_userId';
        _statusColor = Colors.green;
      });
    } on FirebaseAuthException catch (e) {
      setState(() {
        if (e.code == 'user-not-found') {
          _status = '❌ No user found for that email';
          _statusColor = Colors.red;
        } else if (e.code == 'wrong-password') {
          _status = '❌ Wrong password';
          _statusColor = Colors.red;
        } else {
          _status = '❌ Sign In Error: ${e.message}';
          _statusColor = Colors.red;
        }
      });
    }
  }

  Future<void> _testSignOut() async {
    await FirebaseAuth.instance.signOut();
    setState(() {
      _userId = null;
      _status = '✅ Signed out successfully';
      _statusColor = Colors.green;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Firebase Connection Test'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _statusColor.withOpacity(0.1),
                border: Border.all(color: _statusColor, width: 2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _status,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: _statusColor,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 40),
            const Text(
              'Test Authentication',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _testSignUp,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                padding: const EdgeInsets.all(16),
              ),
              child: const Text(
                'Test Sign Up',
                style: TextStyle(fontSize: 16),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _testSignIn,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: const EdgeInsets.all(16),
              ),
              child: const Text(
                'Test Sign In',
                style: TextStyle(fontSize: 16),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _testSignOut,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey,
                padding: const EdgeInsets.all(16),
              ),
              child: const Text(
                'Test Sign Out',
                style: TextStyle(fontSize: 16),
              ),
            ),
            const SizedBox(height: 40),
            const Divider(),
            const SizedBox(height: 20),
            const Text(
              'Firebase Configuration:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('Project ID: ${Firebase.app().options.projectId}'),
            Text('Auth Domain: ${Firebase.app().options.authDomain}'),
            const SizedBox(height: 20),
            const Text(
              'Instructions:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              '1. If you see "Firebase Connected", Firebase is working!\n'
              '2. Click "Test Sign Up" to create a new account\n'
              '3. Check Firebase Console > Authentication to see the user\n'
              '4. Click "Test Sign In" to sign in with that account\n'
              '5. If it works, your app is ready to use Firebase!',
              style: TextStyle(fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}