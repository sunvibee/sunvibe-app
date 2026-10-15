import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sunvibee_app/main.dart';
import 'package:sunvibee_app/providers/auth_provider.dart';

import 'package:sunvibee_app/screens/support_screen.dart';
import 'package:sunvibee_app/widgets/bottom_nav_bar.dart';

void main() {
  testWidgets('App builds without errors', (WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AuthProvider(),
        child: const MyApp(),
      ),
    );
    
    await tester.pump();
    expect(find.byType(MaterialApp), findsOneWidget);
  });

  testWidgets('Splash screen shows SUNVIBEE text', (WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AuthProvider(),
        child: const MyApp(),
      ),
    );
    
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1200));

    expect(find.text('SUNVIBEE'), findsOneWidget);
    expect(find.text('CONNECTING TO ROBOT...'), findsOneWidget);
    expect(find.byType(RichText), findsWidgets);
  });

  testWidgets('Splash screen shows loading indicator', (WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AuthProvider(),
        child: const MyApp(),
      ),
    );
    
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1200));

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('SupportScreen displays Email Support option', (WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AuthProvider(),
        child: const MaterialApp(
          home: SupportScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Email Support'), findsOneWidget);
    expect(find.text('Call Support'), findsNothing);
    expect(find.text('FAQ'), findsOneWidget);
    expect(find.byIcon(Icons.email_outlined), findsOneWidget);
  });

  testWidgets('BottomNavBar displays 3 centralized tabs without Reports', (WidgetTester tester) async {
    int tappedIndex = -1;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          bottomNavigationBar: BottomNavBar(
            currentIndex: 0,
            onTap: (index) => tappedIndex = index,
          ),
        ),
      ),
    );

    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Robot'), findsOneWidget);
    expect(find.text('Support'), findsOneWidget);
    expect(find.text('Reports'), findsNothing);

    await tester.tap(find.text('Robot'));
    expect(tappedIndex, 1);

    await tester.tap(find.text('Support'));
    expect(tappedIndex, 2);
  });
}