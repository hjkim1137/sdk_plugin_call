import 'package:flutter/material.dart';

import 'screens/home_screen.dart';

void main() {
  runApp(const CaresensApp());
}

class CaresensApp extends StatelessWidget {
  const CaresensApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CareSens Air',
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFF1565C0),
        useMaterial3: true,
      ),
      debugShowCheckedModeBanner: false,
      home: const HomeScreen(),
    );
  }
}
