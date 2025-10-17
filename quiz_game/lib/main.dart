import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'services/auth_service.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home/home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Quiz Game',
      home: StreamBuilder<User?>(
        stream: authService.authStateChanges,
        builder: (context, snap) {
          // đang kiểm tra trạng thái
          if (snap.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          // đã đăng nhập → vào Home
          if (snap.data != null) {
            return const HomeScreen();
          }
          // chưa đăng nhập → vào Login
          return const LoginScreen();
        },
      ),
    );
  }
}
