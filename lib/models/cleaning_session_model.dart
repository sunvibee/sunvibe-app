import 'package:intl/intl.dart';

class CleaningSession {
  final String id;
  final DateTime startTime;
  final DateTime stopTime;
  final Duration duration;
  final String status;
  final String robotName;

  CleaningSession({
    required this.id,
    required this.startTime,
    required this.stopTime,
    required this.duration,
    this.status = 'Completed',
    this.robotName = 'Solar Cleaner',
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'startTime': startTime.toIso8601String(),
      'stopTime': stopTime.toIso8601String(),
      'durationSeconds': duration.inSeconds,
      'status': status,
      'robotName': robotName,
    };
  }

  factory CleaningSession.fromJson(Map<String, dynamic> json) {
    return CleaningSession(
      id: json['id'] as String,
      startTime: DateTime.parse(json['startTime'] as String),
      stopTime: DateTime.parse(json['stopTime'] as String),
      duration: Duration(seconds: json['durationSeconds'] as int? ?? 0),
      status: json['status'] as String? ?? 'Completed',
      robotName: json['robotName'] as String? ?? 'Solar Cleaner',
    );
  }

  /// Returns the duration formatted as HH:MM:SS
  String get formattedDuration {
    final hours = duration.inHours.toString().padLeft(2, '0');
    final minutes = (duration.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return "$hours:$minutes:$seconds";
  }

  /// Returns human-readable duration e.g. "45m 12s" or "1h 15m"
  String get readableDuration {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    final seconds = duration.inSeconds % 60;

    if (hours > 0) {
      return "${hours}h ${minutes}m ${seconds}s";
    } else if (minutes > 0) {
      return "${minutes}m ${seconds}s";
    } else {
      return "${seconds}s";
    }
  }

  /// Formatted time range in AM/PM (e.g. "10:30 AM - 11:15 AM")
  String get formattedTimeRange {
    final startStr = DateFormat('h:mm a').format(startTime);
    final stopStr = DateFormat('h:mm a').format(stopTime);
    return "$startStr - $stopStr";
  }

  /// Formatted date (e.g. "Today", "Yesterday", "Oct 19, 2026")
  String get formattedDate {
    final now = DateTime.now();
    if (startTime.year == now.year &&
        startTime.month == now.month &&
        startTime.day == now.day) {
      return "Today";
    }
    final yesterday = now.subtract(const Duration(days: 1));
    if (startTime.year == yesterday.year &&
        startTime.month == yesterday.month &&
        startTime.day == yesterday.day) {
      return "Yesterday";
    }
    return DateFormat('MMM d, yyyy').format(startTime);
  }
}
