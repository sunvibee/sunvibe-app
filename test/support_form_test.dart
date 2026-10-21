import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sunvibee_app/providers/auth_provider.dart';
import 'package:sunvibee_app/screens/support_form_screen.dart';
import 'package:sunvibee_app/screens/support_screen.dart';
import 'package:sunvibee_app/services/notification_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await NotificationService().init();
    await NotificationService().clearAllNotifications();
  });

  Widget buildTestableWidget(Widget child) {
    return ChangeNotifierProvider(
      create: (_) => AuthProvider(),
      child: MaterialApp(
        home: child,
      ),
    );
  }

  testWidgets('SupportScreen displays Support Form card along with Email Support and FAQ', (WidgetTester tester) async {
    await tester.pumpWidget(buildTestableWidget(const SupportScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Support Options'), findsOneWidget);
    expect(find.text('Support Form'), findsOneWidget);
    expect(find.text('Report Issue'), findsOneWidget);
    expect(find.text('Email Support'), findsOneWidget);
    expect(find.text('FAQ'), findsOneWidget);
    expect(find.byIcon(Icons.assignment_late_outlined), findsOneWidget);
  });

  testWidgets('SupportFormScreen renders all required fields, dropdown, and submit button', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(buildTestableWidget(const SupportFormScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Product Support Form'), findsOneWidget);
    expect(find.text('Personal & Contact Details'), findsOneWidget);
    expect(find.text('Full Name'), findsOneWidget);
    expect(find.text('Contact Number'), findsOneWidget);
    expect(find.text('Email Address'), findsOneWidget);
    expect(find.text('Installation / Site Address'), findsOneWidget);
    expect(find.text('Product Issue & Problem Category'), findsOneWidget);
    expect(find.text('Any Other / Additional Details'), findsOneWidget);
    expect(find.text('Submit Support Request'), findsOneWidget);
  });

  testWidgets('SupportFormScreen triggers validation errors when submitting empty form', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(buildTestableWidget(const SupportFormScreen()));
    await tester.pumpAndSettle();

    // Scroll to submit button and tap
    final submitButton = find.text('Submit Support Request');
    await tester.ensureVisible(submitButton);
    await tester.pumpAndSettle();
    await tester.tap(submitButton);
    await tester.pumpAndSettle();

    // Verify error messages for required fields
    expect(find.text('Full name is required'), findsOneWidget);
    expect(find.text('Contact number is required'), findsOneWidget);
    expect(find.text('Email address is required'), findsOneWidget);
    expect(find.text('Address is required for product on-site inspection'), findsOneWidget);
  });

  testWidgets('SupportFormScreen fills valid data, submits and logs notification', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final notificationService = NotificationService();
    await notificationService.clearAllNotifications();

    await tester.pumpWidget(buildTestableWidget(const SupportFormScreen()));
    await tester.pumpAndSettle();

    // Fill form fields
    await tester.enterText(find.byType(TextFormField).at(0), 'John Doe');
    await tester.enterText(find.byType(TextFormField).at(1), '+91 9876543210');
    await tester.enterText(find.byType(TextFormField).at(2), 'john.doe@example.com');
    await tester.enterText(find.byType(TextFormField).at(3), '123 Solar Park Avenue, Sector 5');
    await tester.enterText(find.byType(TextFormField).at(4), 'Robot brushes are making a clicking noise');

    // Tap submit
    final submitButton = find.text('Submit Support Request');
    await tester.ensureVisible(submitButton);
    await tester.pumpAndSettle();
    await tester.tap(submitButton);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();

    // Verify confirmation dialog
    expect(find.text('Support Ticket Prepared'), findsOneWidget);
    expect(find.textContaining('Ticket ID: SVB-'), findsOneWidget);
    expect(find.text('Copy Ticket'), findsOneWidget);
    expect(find.text('Done'), findsOneWidget);

    // Verify notification was created
    expect(notificationService.totalCount, 1);
    expect(notificationService.notifications.first.title.contains('Support Ticket #SVB-'), isTrue);
  });

  testWidgets('SupportScreen navigates to SupportFormScreen when tapping Support Form card', (WidgetTester tester) async {
    await tester.pumpWidget(buildTestableWidget(const SupportScreen()));
    await tester.pumpAndSettle();

    final supportFormCard = find.text('Support Form');
    await tester.ensureVisible(supportFormCard);
    await tester.pumpAndSettle();
    await tester.tap(supportFormCard);
    await tester.pumpAndSettle();

    expect(find.byType(SupportFormScreen), findsOneWidget);
    expect(find.text('Product Support Form'), findsOneWidget);
  });
}
