import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz;
import '../models/notification_model.dart';
import '../utils/app_colors.dart';

class NotificationService extends ChangeNotifier {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  List<NotificationItem> _notifications = [];
  bool _initialized = false;

  List<NotificationItem> get notifications => List.unmodifiable(_notifications);

  int get unreadCount => _notifications.where((n) => !n.isRead).length;
  int get readCount => _notifications.where((n) => n.isRead).length;
  int get totalCount => _notifications.length;

  List<NotificationItem> get unreadNotifications =>
      _notifications.where((n) => !n.isRead).toList();

  List<NotificationItem> get readNotifications =>
      _notifications.where((n) => n.isRead).toList();

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    try {
      tz.initializeTimeZones();

      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      const DarwinInitializationSettings initializationSettingsIOS =
          DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const InitializationSettings initializationSettings =
          InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: initializationSettingsIOS,
      );

      await flutterLocalNotificationsPlugin.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: (response) {
          debugPrint('Notification tapped: ${response.payload}');
        },
      );
    } catch (e) {
      debugPrint('Local notifications plugin init warning (normal in tests): $e');
    }

    await _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String>? jsonList = prefs.getStringList('notifications');

      if (jsonList != null && jsonList.isNotEmpty) {
        _notifications = jsonList
            .map((item) => NotificationItem.fromJson(jsonDecode(item)))
            .toList();
        _notifications.sort((a, b) => b.timestamp.compareTo(a.timestamp));
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading notifications: $e');
      _notifications = [];
    }
  }

  Future<void> _saveNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String> jsonList =
          _notifications.map((n) => jsonEncode(n.toJson())).toList();
      await prefs.setStringList('notifications', jsonList);
    } catch (e) {
      debugPrint('Error saving notifications: $e');
    }
  }

  Future<void> addNotification({
    required String title,
    required String message,
    NotificationType type = NotificationType.info,
    String? robotId,
    bool showSystemNotification = true,
  }) async {
    // Debounce duplicate notifications within 3 seconds
    if (_notifications.isNotEmpty) {
      final latest = _notifications.first;
      if (latest.title == title &&
          latest.message == message &&
          DateTime.now().difference(latest.timestamp).inSeconds < 3) {
        return;
      }
    }

    final item = NotificationItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      message: message,
      timestamp: DateTime.now(),
      isRead: false,
      type: type,
      robotId: robotId,
    );

    _notifications.insert(0, item);
    await _saveNotifications();
    notifyListeners();

    if (showSystemNotification) {
      _showSystemNotification(item);
    }
  }

  Future<void> _showSystemNotification(NotificationItem item) async {
    try {
      final color = _getNotificationColor(item.type);
      final androidDetails = AndroidNotificationDetails(
        'sunvibee_channel',
        'SunVibee Notifications',
        channelDescription: 'Real-time notifications from SunVibee app',
        importance: Importance.high,
        priority: Priority.high,
        showWhen: true,
        enableVibration: true,
        playSound: true,
        icon: '@mipmap/ic_launcher',
        color: color,
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      final details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await flutterLocalNotificationsPlugin.show(
        item.id.hashCode,
        item.title,
        item.message,
        details,
      );
    } catch (e) {
      debugPrint('System notification display warning: $e');
    }
  }

  Color _getNotificationColor(NotificationType type) {
    switch (type) {
      case NotificationType.info:
        return AppColors.blue;
      case NotificationType.warning:
        return AppColors.orange;
      case NotificationType.error:
        return AppColors.red;
      case NotificationType.success:
        return AppColors.green;
    }
  }

  Future<void> markAsRead(String id) async {
    final idx = _notifications.indexWhere((n) => n.id == id);
    if (idx != -1 && !_notifications[idx].isRead) {
      _notifications[idx].isRead = true;
      await _saveNotifications();
      notifyListeners();
    }
  }

  Future<void> toggleReadStatus(String id) async {
    final idx = _notifications.indexWhere((n) => n.id == id);
    if (idx != -1) {
      _notifications[idx].isRead = !_notifications[idx].isRead;
      await _saveNotifications();
      notifyListeners();
    }
  }

  Future<void> markAllAsRead() async {
    bool changed = false;
    for (final n in _notifications) {
      if (!n.isRead) {
        n.isRead = true;
        changed = true;
      }
    }
    if (changed) {
      await _saveNotifications();
      notifyListeners();
    }
  }

  Future<void> removeNotification(String id) async {
    final initialCount = _notifications.length;
    _notifications.removeWhere((n) => n.id == id);
    if (_notifications.length != initialCount) {
      await _saveNotifications();
      notifyListeners();
    }
  }

  Future<void> removeMultiple(List<String> ids) async {
    final initialCount = _notifications.length;
    _notifications.removeWhere((n) => ids.contains(n.id));
    if (_notifications.length != initialCount) {
      await _saveNotifications();
      notifyListeners();
    }
  }

  Future<void> clearAllNotifications() async {
    if (_notifications.isNotEmpty) {
      _notifications.clear();
      await _saveNotifications();
      notifyListeners();
    }
  }

  // Backward compatibility methods
  void clearAllNotificationsSync() => clearAllNotifications();
  void removeNotificationSync(int index) {
    if (index >= 0 && index < _notifications.length) {
      removeNotification(_notifications[index].id);
    }
  }
  void markAllAsReadSync() => markAllAsRead();
  void markAsReadSync(int index) {
    if (index >= 0 && index < _notifications.length) {
      markAsRead(_notifications[index].id);
    }
  }
}
