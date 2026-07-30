// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sunvibee_app/main.dart';
import 'package:sunvibee_app/providers/auth_provider.dart';
import 'package:sunvibee_app/screens/login_screen.dart';

void main() {
  testWidgets('Login screen shows welcome text', (WidgetTester tester) async {
    // Build the login screen
    await tester.pumpWidget(
      const MaterialApp(
        home: LoginScreen(),
        debugShowCheckedModeBanner: false,
      ),
    );

    // Verify that the login screen shows "Welcome"
    expect(find.text('Welcome'), findsOneWidget);
    expect(find.text('Robot ID'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(find.text('Login'), findsOneWidget);
  });

  testWidgets('App starts with login screen when not authenticated', 
      (WidgetTester tester) async {
    // Build the app with auth provider
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AuthProvider()),
        ],
        child: const MyApp(),
      ),
    );

    // Wait for the app to build
    await tester.pumpAndSettle();

    // Verify login screen is shown
    expect(find.text('Welcome'), findsOneWidget);
  });

  testWidgets('Login button is present', (WidgetTester tester) async {
    // Build the login screen
    await tester.pumpWidget(
      const MaterialApp(
        home: LoginScreen(),
        debugShowCheckedModeBanner: false,
      ),
    );

    // Find the login button
    expect(find.text('Login'), findsOneWidget);
    
    // Verify it's a button
    final loginButton = find.byType(ElevatedButton);
    expect(loginButton, findsOneWidget);
  });
}