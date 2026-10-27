import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/cleaning_session_model.dart';

class RobotTimerService extends ChangeNotifier {
  static final RobotTimerService _instance = RobotTimerService._internal();
  factory RobotTimerService() => _instance;
  RobotTimerService._internal();

  Timer? _ticker;
  DateTime? _startTime;
  DateTime? _stopTime;
  Duration _elapsed = Duration.zero;
  bool _isRunning = false;

  List<CleaningSession> _history = [];

  bool get isRunning => _isRunning;
  DateTime? get startTime => _startTime;
  DateTime? get stopTime => _stopTime;
  Duration get elapsed => _elapsed;
  List<CleaningSession> get history => List.unmodifiable(_history);

  int get totalSessions => _history.length;

  Duration get totalCleanTime {
    return _history.fold<Duration>(
      Duration.zero,
      (prev, s) => prev + s.duration,
    );
  }

  String get formattedTotalCleanTime {
    final total = totalCleanTime;
    final hours = total.inHours;
    final minutes = total.inMinutes % 60;
    final seconds = total.inSeconds % 60;
    if (hours > 0) {
      return "${hours}h ${minutes}m ${seconds}s";
    } else if (minutes > 0) {
      return "${minutes}m ${seconds}s";
    } else {
      return "${seconds}s";
    }
  }

  /// Returns the elapsed time in HH:MM:SS format
  String get formattedElapsed {
    final hours = _elapsed.inHours.toString().padLeft(2, '0');
    final minutes = (_elapsed.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (_elapsed.inSeconds % 60).toString().padLeft(2, '0');
    return "$hours:$minutes:$seconds";
  }

  /// Hours component as 2 digits
  String get hoursStr => _elapsed.inHours.toString().padLeft(2, '0');

  /// Minutes component as 2 digits
  String get minutesStr => (_elapsed.inMinutes % 60).toString().padLeft(2, '0');

  /// Seconds component as 2 digits
  String get secondsStr => (_elapsed.inSeconds % 60).toString().padLeft(2, '0');

  /// Formatted mobile start time in AM/PM (e.g. "10:30 AM")
  String get formattedStartTime {
    if (_startTime == null) return "--:--";
    return DateFormat('h:mm a').format(_startTime!);
  }

  /// Formatted mobile stop time in AM/PM (e.g. "11:15 AM")
  String get formattedStopTime {
    if (_isRunning) return "Running...";
    if (_stopTime == null) return "--:--";
    return DateFormat('h:mm a').format(_stopTime!);
  }

  /// Combined session time range in AM/PM (e.g. "10:30 AM - 11:15 AM")
  String get formattedTimeRange {
    if (_startTime == null) return "No active session";
    if (_isRunning) {
      return "$formattedStartTime - Present (Running)";
    }
    return "$formattedStartTime - $formattedStopTime";
  }

  /// Initialize and restore any active or previously saved session and history
  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final startMillis = prefs.getInt('robot_timer_start_millis');
      final stopMillis = prefs.getInt('robot_timer_stop_millis');
      final running = prefs.getBool('robot_timer_is_running') ?? false;

      if (startMillis != null) {
        _startTime = DateTime.fromMillisecondsSinceEpoch(startMillis);
      }
      if (stopMillis != null) {
        _stopTime = DateTime.fromMillisecondsSinceEpoch(stopMillis);
      }
      _isRunning = running;

      if (_isRunning && _startTime != null) {
        _elapsed = DateTime.now().difference(_startTime!);
        _startTicker();
      } else if (_startTime != null && _stopTime != null) {
        _elapsed = _stopTime!.difference(_startTime!);
        if (_elapsed.isNegative) _elapsed = Duration.zero;
      }

      // Load History
      final rawHistory = prefs.getStringList('robot_cleaning_history');
      if (rawHistory != null && rawHistory.isNotEmpty) {
        _history = rawHistory
            .map((e) => CleaningSession.fromJson(jsonDecode(e)))
            .toList();
        _history.sort((a, b) => b.stopTime.compareTo(a.stopTime));
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Error restoring robot timer & history: $e');
    }
  }

  /// Start the stopwatch synchronized with mobile clock
  void start() {
    _startTime = DateTime.now();
    _stopTime = null;
    _elapsed = Duration.zero;
    _isRunning = true;
    _startTicker();
    _persistTimer();
    notifyListeners();
  }

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_startTime != null) {
        _elapsed = DateTime.now().difference(_startTime!);
        notifyListeners();
      }
    });
  }

  /// Stop the stopwatch, record cleaning session to history, and return final duration
  Duration stop() {
    _ticker?.cancel();
    _ticker = null;
    _stopTime = DateTime.now();
    _isRunning = false;
    if (_startTime != null) {
      _elapsed = _stopTime!.difference(_startTime!);
      if (_elapsed.isNegative) _elapsed = Duration.zero;

      // Add to cleaning history
      final session = CleaningSession(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        startTime: _startTime!,
        stopTime: _stopTime!,
        duration: _elapsed,
        status: 'Completed',
      );
      _history.insert(0, session);
      _persistHistory();
    }
    _persistTimer();
    notifyListeners();
    return _elapsed;
  }

  /// Reset the stopwatch
  void reset() {
    _ticker?.cancel();
    _ticker = null;
    _isRunning = false;
    _startTime = null;
    _stopTime = null;
    _elapsed = Duration.zero;
    _persistTimer();
    notifyListeners();
  }

  /// Clear all cleaning history
  Future<void> clearHistory() async {
    _history.clear();
    await _persistHistory();
    notifyListeners();
  }

  /// Delete a single cleaning session from history
  Future<void> deleteSession(String id) async {
    _history.removeWhere((s) => s.id == id);
    await _persistHistory();
    notifyListeners();
  }

  Future<void> _persistTimer() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_startTime != null) {
        await prefs.setInt(
          'robot_timer_start_millis',
          _startTime!.millisecondsSinceEpoch,
        );
      } else {
        await prefs.remove('robot_timer_start_millis');
      }

      if (_stopTime != null) {
        await prefs.setInt(
          'robot_timer_stop_millis',
          _stopTime!.millisecondsSinceEpoch,
        );
      } else {
        await prefs.remove('robot_timer_stop_millis');
      }

      await prefs.setBool('robot_timer_is_running', _isRunning);
    } catch (e) {
      debugPrint('Error persisting robot timer: $e');
    }
  }

  Future<void> _persistHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded = _history.map((s) => jsonEncode(s.toJson())).toList();
      await prefs.setStringList('robot_cleaning_history', encoded);
    } catch (e) {
      debugPrint('Error persisting cleaning history: $e');
    }
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }
}
