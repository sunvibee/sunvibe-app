import 'package:flutter/material.dart';
import 'screens/splash_screen.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'package:sunvibee_app/screens/login_screen.dart';
import 'package:sunvibee_app/utils/app_theme.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => AuthProvider(),
      child: const Sunvibee(),
    ),
  );
}

class Sunvibee extends StatelessWidget {
  const Sunvibee({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "Sunvibee",
      theme: AppTheme.lightTheme,

      //Splash Screen opens first 
      home: const SplashScreen(),
    );
  }
}