import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'config/theme.dart';
import 'screens/home_screen.dart';
import 'screens/admin/admin_login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  if (kIsWeb) {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: "AIzaSyAUPE1oNQc_CtLiNR77xgwZtV4zydteJwE",
        appId: "1:203345627146:web:2d0767bfd9502d12c2b7f3",
        messagingSenderId: "203345627146",
        projectId: "minimarket-b6655",
        authDomain: "minimarket-b6655.firebaseapp.com",
        storageBucket: "minimarket-b6655.firebasestorage.app",
        measurementId: "G-QGX2HW9RS9",
      ),
    );
  } else {
    await Firebase.initializeApp();
  }
  
  runApp(const MinimarketApp());
}

class MinimarketApp extends StatelessWidget {
  const MinimarketApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: kIsWeb ? 'Wisa Admin' : 'Minimarket',
      debugShowCheckedModeBanner: false,
      theme: MinimarketTheme.themeData,
      home: kIsWeb ? const AdminLoginScreen() : HomeScreen(),
    );
  }
}
