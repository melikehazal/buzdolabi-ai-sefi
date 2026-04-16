import 'package:flutter/material.dart';
import 'package:frontend/screens/home_screen.dart';
//import 'package:frontend/screens/home_screen2.dart';
import 'package:frontend/theme.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Buzdolabı AI Şefi',
      theme: AppTheme.theme,
      home: const HomeScreen(),
    );
  }
}
