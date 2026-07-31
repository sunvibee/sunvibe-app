// lib/services/notification_service.dart
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/notification_model.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = 
      FlutterLocalNotificationsPlugin();
  
  // List to store all notifications
  List<NotificationItem> _notifications = [];
  
  // Getter for notifications
  List<NotificationItem> get notifications => _notifications;

  Future<void> init() async {
    tz.initializeTimeZones();
    
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    
    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );
    
    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: onDidReceiveNotificationResponse,
    );
    
    // Load saved notifications
    await _loadNotifications();
  }

  void onDidReceiveNotificationResponse(NotificationResponse response) {
    print('Notification tapped: ${response.payload}');
  }

  Future<void> _saveNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String> notificationJsonList = _notifications.map((n) => jsonEncode(n.toJson())).toList();
      await prefs.setStringList('notifications', notificationJsonList);
    } catch (e) {
      print('Error saving notifications: $e');
    }
  }

  Future<void> _loadNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String>? notificationJsonList = prefs.getStringList('notifications');
      
      if (notificationJsonList != null) {
        _notifications = notificationJsonList
            .map((jsonString) => NotificationItem.fromJson(jsonDecode(jsonString)))
            .toList();
        // Sort by timestamp (newest first)
        _notifications.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      }
    } catch (e) {
      print('Error loading notifications: $e');
      _notifications = [];
    }
  }

  Future<void> showNotification({
    required String title,
    required String body,
    String? payload,
    NotificationType type = NotificationType.info,
  }) async {
    // Add to local list
    final notification = NotificationItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      message: body,
      timestamp: DateTime.now(),
      isRead: false,
      type: type,
    );
    _notifications.insert(0, notification);
    
    // Save to SharedPreferences
    await _saveNotifications();

    // Get color based on type
    final color = _getNotificationColor(type);

    // Build notification details with color
    final androidPlatformChannelSpecifics = AndroidNotificationDetails(
      'sunvibee_channel',
      'SunVibee Notifications',
      channelDescription: 'Notifications from SunVibee app',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      enableVibration: true,
      playSound: true,
      icon: '@mipmap/ic_launcher',
      color: color,
    );

    const DarwinNotificationDetails iosPlatformChannelSpecifics =
        DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iosPlatformChannelSpecifics,
    );

    await flutterLocalNotificationsPlugin.show(
      _notifications.length,
      title,
      body,
      platformChannelSpecifics,
      payload: payload,
    );
  }

  Color _getNotificationColor(NotificationType type) {
    switch (type) {
      case NotificationType.info:
        return Colors.blue;
      case NotificationType.warning:
        return Colors.orange;
      case NotificationType.error:
        return Colors.red;
      case NotificationType.success:
        return Colors.green;
    }
  }

  Future<void> clearAllNotifications() async {
    _notifications.clear();
    await _saveNotifications();
  }

  Future<void> removeNotification(int index) async {
    if (index < _notifications.length) {
      _notifications.removeAt(index);
      await _saveNotifications();
    }
  }

  Future<void> markAllAsRead() async {
    for (var notification in _notifications) {
      notification.isRead = true;
    }
    await _saveNotifications();
  }

  Future<void> markAsRead(int index) async {
    if (index < _notifications.length) {
      _notifications[index].isRead = true;
      await _saveNotifications();
    }
  }

  // For backward compatibility with existing code
  void clearAllNotificationsSync() {
    _notifications.clear();
    _saveNotifications();
  }

  void removeNotificationSync(int index) {
    if (index < _notifications.length) {
      _notifications.removeAt(index);
      _saveNotifications();
    }
  }

  void markAllAsReadSync() {
    for (var notification in _notifications) {
      notification.isRead = true;
    }
    _saveNotifications();
  }
}