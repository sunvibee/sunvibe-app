import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sunvibee_app/main.dart';
import 'package:sunvibee_app/providers/auth_provider.dart';

import 'package:sunvibee_app/screens/support_screen.dart';
import 'package:sunvibee_app/screens/home_screen.dart';
import 'package:sunvibee_app/screens/notification_screen.dart';
import 'package:sunvibee_app/services/notification_service.dart';
import 'package:sunvibee_app/services/mqtt_service.dart';
import 'package:sunvibee_app/models/notification_model.dart';
import 'package:sunvibee_app/widgets/bottom_nav_bar.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  testWidgets('BottomNavBar displays 3 centralized tabs without Reports and preserves body height', (WidgetTester tester) async {
    int tappedIndex = -1;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: const SizedBox.expand(
            child: Center(child: Text('Body Content')),
          ),
          bottomNavigationBar: BottomNavBar(
            currentIndex: 0,
            onTap: (index) => tappedIndex = index,
          ),
        ),
      ),
    );

    final bodySize = tester.getSize(find.text('Body Content'));
    expect(bodySize.height, greaterThan(0));
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Robot'), findsOneWidget);
    expect(find.text('Support'), findsOneWidget);
    expect(find.text('Reports'), findsNothing);

    await tester.tap(find.text('Robot'));
    expect(tappedIndex, 1);

    await tester.tap(find.text('Support'));
    expect(tappedIndex, 2);
  });

  group('Real-time Notifications and Dynamic Red Dot Tests', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      await NotificationService().clearAllNotifications();
    });

    test('NotificationService manages notifications, unread counts, and persistence', () async {
      final service = NotificationService();
      expect(service.totalCount, 0);
      expect(service.unreadCount, 0);

      await service.addNotification(
        title: 'Robot Started',
        message: 'Robot cleaning operation has been started.',
        type: NotificationType.success,
        showSystemNotification: false,
      );

      expect(service.totalCount, 1);
      expect(service.unreadCount, 1);
      expect(service.readCount, 0);
      expect(service.notifications.first.title, 'Robot Started');

      final notifId = service.notifications.first.id;
      await service.markAsRead(notifId);
      expect(service.unreadCount, 0);
      expect(service.readCount, 1);

      await service.toggleReadStatus(notifId);
      expect(service.unreadCount, 1);

      await service.clearAllNotifications();
      expect(service.totalCount, 0);
    });

    testWidgets('HomeScreen notification bell has NO red dot when unreadCount is 0, and SHOWS red dot when unreadCount > 0', (WidgetTester tester) async {
      final service = NotificationService();
      await service.clearAllNotifications();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => AuthProvider()),
            ChangeNotifierProvider.value(value: service),
          ],
          child: const MaterialApp(
            home: HomeScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // No unread notification: bell icon is notifications_none and no red dot
      expect(find.byIcon(Icons.notifications_none), findsOneWidget);
      expect(find.byIcon(Icons.notifications_active_outlined), findsNothing);

      // Now add a real-time notification
      await service.addNotification(
        title: 'Robot Started',
        message: 'Robot cleaning operation has been started.',
        type: NotificationType.success,
        showSystemNotification: false,
      );

      // Pump to trigger ListenableBuilder
      await tester.pumpAndSettle();

      // Unread notification exists: bell icon changes and red dot appears
      expect(find.byIcon(Icons.notifications_active_outlined), findsOneWidget);
      expect(find.byIcon(Icons.notifications_none), findsNothing);

      // Mark as read
      await service.markAllAsRead();
      await tester.pumpAndSettle();

      // Red dot disappears again
      expect(find.byIcon(Icons.notifications_none), findsOneWidget);
      expect(find.byIcon(Icons.notifications_active_outlined), findsNothing);
    });

    testWidgets('NotificationsScreen displays filter tabs (All, Unread, Read) and filters items properly', (WidgetTester tester) async {
      final service = NotificationService();
      await service.clearAllNotifications();

      await service.addNotification(
        title: 'Robot Started',
        message: 'Robot operation started.',
        type: NotificationType.success,
        showSystemNotification: false,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: const NotificationsScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // Check header and filter tabs
      expect(find.text('Notifications'), findsOneWidget);
      expect(find.text('All'), findsOneWidget);
      expect(find.text('Unread'), findsOneWidget);
      expect(find.text('Read'), findsOneWidget);

      // Item should be visible under All
      expect(find.text('Robot Started'), findsOneWidget);
      expect(find.text('UNREAD'), findsOneWidget);

      // Tap on Read filter
      await tester.tap(find.text('Read'));
      await tester.pumpAndSettle();

      // Should show empty state for Read filter
      expect(find.text('No Read Notifications'), findsOneWidget);
      expect(find.text('Robot Started'), findsNothing);

      // Tap on Unread filter
      await tester.tap(find.text('Unread'));
      await tester.pumpAndSettle();

      // Should show Robot Started again
      expect(find.text('Robot Started'), findsOneWidget);

      // Tap on the notification card to toggle to Read
      await tester.tap(find.text('Robot Started'));
      await tester.pumpAndSettle();

      // Under Unread tab, it now moves to Read so Unread shows empty
      expect(find.text('All Caught Up!'), findsOneWidget);
    });

    testWidgets('Tapping Start Cleaning and Stop Cleaning on HomeScreen creates live notifications when online', (WidgetTester tester) async {
      MQTTService.instance.setMockState(isConnected: true, isRobotOnline: true);
      final service = NotificationService();
      await service.clearAllNotifications();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => AuthProvider()),
            ChangeNotifierProvider.value(value: service),
          ],
          child: const MaterialApp(
            home: HomeScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Ensure Start Cleaning is visible in test viewport and tap
      await tester.ensureVisible(find.text('Start Cleaning'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Start Cleaning'));
      // Clock animation controller repeats while running, so pump frame with duration
      await tester.pump(const Duration(milliseconds: 300));

      expect(service.totalCount, 1);
      expect(service.notifications.first.title, 'Robot Started');

      // Ensure Stop Cleaning is visible and tap
      await tester.ensureVisible(find.text('Stop Cleaning'));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.tap(find.text('Stop Cleaning'));
      await tester.pumpAndSettle();

      // On stop, exactly 2 notifications exist: Robot Stopped and Robot Started
      expect(service.totalCount, 2);
      expect(service.notifications[0].title, 'Robot Stopped');
      expect(service.notifications[1].title, 'Robot Started');
    });

    testWidgets('Tapping Start Cleaning when robot is offline blocks operation and shows professional error', (WidgetTester tester) async {
      MQTTService.instance.setMockState(isConnected: true, isRobotOnline: false);
      final service = NotificationService();
      await service.clearAllNotifications();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => AuthProvider()),
            ChangeNotifierProvider.value(value: service),
          ],
          child: const MaterialApp(
            home: HomeScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap Start Cleaning while robot is offline
      await tester.ensureVisible(find.text('Start Cleaning'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Start Cleaning'));
      await tester.pump();

      // Expect professional error snackbar with action
      expect(find.text('Robot is Offline'), findsOneWidget);
      expect(find.text('Check Robot'), findsOneWidget);
      // No start notification should be recorded
      expect(service.totalCount, 0);
    });

    testWidgets('Tapping Start Cleaning when MQTT is disconnected shows Server Disconnected error', (WidgetTester tester) async {
      MQTTService.instance.setMockState(isConnected: false, isRobotOnline: false);
      final service = NotificationService();
      await service.clearAllNotifications();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => AuthProvider()),
            ChangeNotifierProvider.value(value: service),
          ],
          child: const MaterialApp(
            home: HomeScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap Start Cleaning while MQTT is disconnected
      await tester.ensureVisible(find.text('Start Cleaning'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Start Cleaning'));
      await tester.pump();

      expect(find.text('Server Disconnected'), findsOneWidget);
      expect(service.totalCount, 0);
    });
  });
}