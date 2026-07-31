import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthProvider extends ChangeNotifier {
  bool _isLoggedIn = false;
  String? _robotId;
  String? _userName;
  bool _isLoading = true;

  bool get isLoggedIn => _isLoggedIn;
  String? get robotId => _robotId;
  String? get userName => _userName;
  bool get isLoading => _isLoading;

  AuthProvider() {
    print('🔵 AuthProvider created - Loading session...');
    _loadSession();
  }

  Future<void> _loadSession() async {
    _isLoading = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      _isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
      _robotId = prefs.getString('robotId');
      _userName = prefs.getString('userName');
      print('🔵 Session loaded: isLoggedIn=$_isLoggedIn');
    } catch (e) {
      print('🔴 Error loading session: $e');
      _isLoggedIn = false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> login({
    required String robotId,
    required String userName,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', true);
      await prefs.setString('robotId', robotId);
      await prefs.setString('userName', userName);
      
      _isLoggedIn = true;
      _robotId = robotId;
      _userName = userName;
      print('🟢 Login successful: isLoggedIn=$_isLoggedIn');
      notifyListeners();
    } catch (e) {
      print('🔴 Error during login: $e');
      throw e;
    }
  }

  Future<void> logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('isLoggedIn');
      await prefs.remove('robotId');
      await prefs.remove('userName');
      
      _isLoggedIn = false;
      _robotId = null;
      _userName = null;
      print('🔴 Logout successful');
      notifyListeners();
    } catch (e) {
      print('🔴 Error during logout: $e');
      throw e;
    }
  }

  Future<bool> checkSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
      _isLoggedIn = isLoggedIn;
      _robotId = prefs.getString('robotId');
      _userName = prefs.getString('userName');
      notifyListeners();
      print('🔵 Session check: isLoggedIn=$isLoggedIn');
      return isLoggedIn;
    } catch (e) {
      print('🔴 Error checking session: $e');
      return false;
    }
  }

  Future<void> refreshSession() async {
    await _loadSession();
  }
}