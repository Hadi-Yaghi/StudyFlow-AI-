import 'package:flutter/material.dart';
import 'screens/login_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'StudyFlow',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFFF9FAFB),
        primaryColor: const Color(0xFF3525CD),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF3525CD),
          primary: const Color(0xFF3525CD),
        ),
        useMaterial3: true,
      ),
      home: const LoginScreen(),
    );
  }
}
