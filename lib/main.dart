import 'package:flutter/material.dart';
import 'package:sunvibee_app/screens/home_screen.dart';
import 'package:sunvibee_app/screens/login_screen.dart';
import 'package:sunvibee_app/utils/app_theme.dart';

void main() {
  runApp(const Sunvibee());
}

class Sunvibee extends StatelessWidget {
  const Sunvibee({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "Sunvibee",
      theme: AppTheme.lightTheme,
      home: const LoginScreen(),
    );
  }
}