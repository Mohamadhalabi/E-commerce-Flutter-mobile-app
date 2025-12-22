import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';

class AuthProvider with ChangeNotifier {
  String? _token;
  Map<String, dynamic>? _user;
  bool _isLoading = false;

  String? get token => _token;
  Map<String, dynamic>? get user => _user;
  bool get isAuthenticated => _token != null;
  bool get isLoading => _isLoading;

  // FIX: Added the missing getter 'isLoggedIn' to resolve the error.
  bool get isLoggedIn => _token != null; // Alias for isAuthenticated

  static const _tokenKey = 'authToken';
  static const _userKey = 'userData';

  // Constructor runs immediately to load previous state
  AuthProvider() {
    _loadAuthData();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  // Handles loading state from SharedPreferences
  Future<void> _loadAuthData() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString(_tokenKey);
    final userJson = prefs.getString(_userKey);
    if (userJson != null) {
      _user = jsonDecode(userJson);
    }
    notifyListeners();
  }

  Future<void> _saveAuthData(String token, Map<String, dynamic> userData) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    await prefs.setString(_userKey, jsonEncode(userData));
    _token = token;
    _user = userData;
    notifyListeners();
  }

  Future<void> _clearAuthData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userKey);
    _token = null;
    _user = null;
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    _setLoading(true);
    try {
      final response = await ApiService.login(email, password);

      if (response['success'] == true && response['token'] != null && response['user'] != null) {
        await _saveAuthData(response['token'], response['user']);
        _setLoading(false);
        return true;
      } else {
        print('Login Failed: ${response['message']}');
        _setLoading(false);
        return false;
      }
    } catch (e) {
      print('Login Error: $e');
      _setLoading(false);
      return false;
    }
  }

  Future<void> logout() async {
    await _clearAuthData();
  }

  Future<void> fetchUserProfile() async {
    if (_token != null) {
      final userData = await ApiService.getUserProfile(_token!);
      if (userData != null) {
        _user = userData;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_userKey, jsonEncode(userData));
        notifyListeners();
      } else {
        // Token might be invalid/expired, force logout
        await logout();
      }
    }
  }
}