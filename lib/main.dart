import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const PanaderiaApp());
}

class PanaderiaApp extends StatelessWidget {
  const PanaderiaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Panadería App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: const Color(0xFFD4A574),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFD4A574),
          primary: const Color(0xFFD4A574),
          secondary: const Color(0xFF8B4513),
        ),
        scaffoldBackgroundColor: const Color(0xFFFFF8E7),
        useMaterial3: true,
      ),
      home: const SplashScreen(),
    );
  }
}