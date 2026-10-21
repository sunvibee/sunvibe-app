import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sunvibee_app/services/robot_timer_service.dart';
import 'package:sunvibee_app/services/notification_service.dart';
import 'package:sunvibee_app/models/notification_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await NotificationService().init();
    await NotificationService().clearAllNotifications();
    await RobotTimerService().init();
    RobotTimerService().reset();
    await RobotTimerService().clearHistory();
  });

  test('RobotTimerService starts, stops, records session in history', () async {
    final timer = RobotTimerService();
    expect(timer.isRunning, isFalse);
    expect(timer.formattedElapsed, '00:00:00');
    expect(timer.history.length, 0);

    timer.start();
    expect(timer.isRunning, isTrue);
    expect(timer.startTime, isNotNull);
    expect(timer.formattedStartTime.contains(RegExp(r'AM|PM')), isTrue);
    expect(timer.formattedStopTime, 'Running...');

    // Wait a brief moment and stop
    await Future.delayed(const Duration(milliseconds: 10));
    final duration = timer.stop();
    expect(timer.isRunning, isFalse);
    expect(timer.stopTime, isNotNull);
    expect(timer.formattedStopTime.contains(RegExp(r'AM|PM')), isTrue);
    expect(duration.inMilliseconds, greaterThanOrEqualTo(0));

    // Verify session recorded in history
    expect(timer.history.length, 1);
    final session = timer.history.first;
    expect(session.status, 'Completed');
    expect(session.formattedDuration, isNotEmpty);
    expect(session.formattedTimeRange.contains(RegExp(r'AM|PM')), isTrue);
    expect(session.formattedDate, 'Today');
  });

  test('Notification sequence logs only Robot Started and Robot Stopped', () async {
    final notificationService = NotificationService();
    final timer = RobotTimerService();

    // 1. Start Robot
    timer.start();
    final startTimeStr = timer.formattedStartTime;
    final startTimestamp = timer.startTime ?? DateTime.now();
    await notificationService.addNotification(
      title: 'Robot Started',
      message: 'Robot cleaning operation started at $startTimeStr.',
      type: NotificationType.success,
      timestamp: startTimestamp,
      showSystemNotification: false,
    );

    expect(notificationService.notifications.length, 1);
    expect(notificationService.notifications.first.title, 'Robot Started');

    // 2. Stop Robot after brief duration
    await Future.delayed(const Duration(milliseconds: 10));
    timer.stop();
    final stopTimeStr = timer.formattedStopTime;

    var stopTimestamp = timer.stopTime ?? DateTime.now();
    if (!stopTimestamp.isAfter(startTimestamp.add(const Duration(milliseconds: 2)))) {
      stopTimestamp = startTimestamp.add(const Duration(milliseconds: 2));
    }

    // Notification: Robot Stopped
    await notificationService.addNotification(
      title: 'Robot Stopped',
      message: 'Robot cleaning operation stopped at $stopTimeStr.',
      type: NotificationType.warning,
      timestamp: stopTimestamp,
      showSystemNotification: false,
    );

    // 3. Verify exactly 2 notifications (Start and Stop only)
    final list = notificationService.notifications;
    expect(list.length, 2);

    // Sorted descending by timestamp:
    // list[0] = Robot Stopped (newest)
    // list[1] = Robot Started (oldest)
    expect(list[0].title, 'Robot Stopped');
    expect(list[1].title, 'Robot Started');
    expect(list[0].message.contains(stopTimeStr), isTrue);
    expect(list[1].message.contains(startTimeStr), isTrue);
  });
}
