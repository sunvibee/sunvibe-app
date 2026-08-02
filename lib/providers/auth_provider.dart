import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../models/user_model.dart';

class AuthProvider extends ChangeNotifier {
  bool _isLoggedIn = false;
  bool _isLoading = true;
  String? _token;
  UserModel? _user;

  bool get isLoggedIn => _isLoggedIn;
  bool get isLoading => _isLoading;
  String? get token => _token;
  UserModel? get user => _user;
  String? get userName => _user?.username;
  int? get userId => _user?.id;
  // Keep robotId for backward compatibility
  String? get robotId => null;

  AuthProvider() {
    _loadSession();
  }

  Future<void> _loadSession() async {
    _isLoading = true;
    try {
      final prefs = await SharedPreferences.getInstance();
<<<<<<< HEAD
      _isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
      _robotId = prefs.getString('robotId');
      _userName = prefs.getString('userName');
      print('🔵 Session loaded: isLoggedIn=$_isLoggedIn');
=======
      _token = prefs.getString('authToken');
      final storedUserId = prefs.getInt('userId');
      final storedUsername = prefs.getString('userName');

      if (_token != null && storedUserId != null && storedUsername != null) {
        _user = UserModel(
          id: storedUserId,
          username: storedUsername,
          createdAt: DateTime.now(),
        );
        _isLoggedIn = true;
      }
>>>>>>> 04a289a6ec324868af7862c6edf577ce122cb349
    } catch (e) {
      _isLoggedIn = false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

<<<<<<< HEAD
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
=======
  Future<void> login({required String username, required String password}) async {
    final result = await ApiService().login(username: username, password: password);
    await _saveSession(result);
  }

  Future<void> register({
    required String username,
    required String password,
    String? wifiSsid,
    String? wifiPassword,
  }) async {
    final result = await ApiService().register(
      username: username,
      password: password,
      wifiSsid: wifiSsid,
      wifiPassword: wifiPassword,
    );
    await _saveSession(result);
  }

  Future<void> _saveSession(Map<String, dynamic> result) async {
    final token = result['token'] as String;
    final user = UserModel.fromJson(result['user'] as Map<String, dynamic>);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('authToken', token);
    await prefs.setInt('userId', user.id);
    await prefs.setString('userName', user.username);
    await prefs.setBool('isLoggedIn', true);

    _token = token;
    _user = user;
    _isLoggedIn = true;
    notifyListeners();
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('authToken');
    await prefs.remove('userId');
    await prefs.remove('userName');
    await prefs.remove('isLoggedIn');

    _token = null;
    _user = null;
    _isLoggedIn = false;
    notifyListeners();
  }

  Future<bool> checkSession() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('isLoggedIn') ?? false;
>>>>>>> 04a289a6ec324868af7862c6edf577ce122cb349
  }

  Future<void> refreshSession() async {
    await _loadSession();
  }
}