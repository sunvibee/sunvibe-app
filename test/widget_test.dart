import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sunvibee_app/main.dart';
import 'package:sunvibee_app/providers/auth_provider.dart';

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
    expect(find.byType(RichText), findsOneWidget);
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
}