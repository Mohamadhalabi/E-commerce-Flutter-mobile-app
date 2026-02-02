import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import '../services/api_service.dart';

class AuthProvider with ChangeNotifier {
  String? _token;
  Map<String, dynamic>? _user;
  bool _isLoading = false;

  final GoogleSignIn _googleSignIn = GoogleSignIn();

  String? get token => _token;
  Map<String, dynamic>? get user => _user;
  bool get isAuthenticated => _token != null;
  bool get isLoading => _isLoading;

  // Alias for isAuthenticated
  bool get isLoggedIn => _token != null;

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

  // ✅ STANDARD LOGIN
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

  // ✅ STANDARD REGISTER
  Future<bool> register({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    _setLoading(true);

    try {
      final response = await ApiService.register(
        name: name,
        email: email,
        phone: phone,
        password: password,
      );

      if (response['success'] == true && response['token'] != null && response['user'] != null) {
        await _saveAuthData(response['token'], response['user']);
        _setLoading(false);
        return true;
      } else {
        print("Register Failed: ${response['message']}");
        _setLoading(false);
        return false;
      }
    } catch (e) {
      print("Register Exception: $e");
      _setLoading(false);
      return false;
    }
  }

  // ✅ GOOGLE LOGIN
  Future<bool> signInWithGoogle() async {
    _setLoading(true);
    try {
      // 1. Trigger Native Google Sign In
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        _setLoading(false);
        return false; // User canceled
      }

      // 2. Send data to Laravel Backend
      final response = await ApiService.socialLogin(
        provider: 'google',
        providerId: googleUser.id,
        email: googleUser.email,
        name: googleUser.displayName,
        avatar: googleUser.photoUrl,
      );

      // 3. Handle Backend Response
      if (response['success'] == true && response['token'] != null) {
        await _saveAuthData(response['token'], response['user']);
        _setLoading(false);
        return true;
      } else {
        print("Google Backend Login Failed: ${response['message']}");
        _setLoading(false);
        _googleSignIn.signOut();
        return false;
      }
    } catch (e) {
      print("Google Login Error: $e");
      _setLoading(false);
      return false;
    }
  }

  // ✅ FACEBOOK LOGIN
  Future<bool> signInWithFacebook() async {
    _setLoading(true);
    try {
      // 1. Trigger Native Facebook Login
      final LoginResult result = await FacebookAuth.instance.login(
        permissions: ['public_profile', 'email'],
      );

      if (result.status == LoginStatus.success) {
        // 2. Get User Data
        final userData = await FacebookAuth.instance.getUserData();

        // 3. Send to Laravel Backend
        final response = await ApiService.socialLogin(
          provider: 'facebook',
          providerId: userData['id'],
          email: userData['email'],
          name: userData['name'],
          avatar: userData['picture']?['data']?['url'],
        );

        // 4. Handle Backend Response
        if (response['success'] == true && response['token'] != null) {
          await _saveAuthData(response['token'], response['user']);
          _setLoading(false);
          return true;
        } else {
          print("Facebook Backend Login Failed: ${response['message']}");
          _setLoading(false);
          FacebookAuth.instance.logOut();
          return false;
        }
      } else {
        _setLoading(false);
        return false;
      }
    } catch (e) {
      print("Facebook Login Error: $e");
      _setLoading(false);
      return false;
    }
  }

  Future<void> logout() async {
    // 1. Clear Local Data FIRST (Most Important)
    await _clearAuthData();

    // 2. Safely try to sign out of Google (Ignore errors)
    try {
      await _googleSignIn.signOut();
    } catch (e) {
      print("⚠️ Google Logout Failed (Safe to ignore): $e");
    }

    // 3. Safely try to log out of Facebook (Ignore errors)
    try {
      await FacebookAuth.instance.logOut();
    } catch (e) {
      print("⚠️ Facebook Logout Failed (Safe to ignore): $e");
    }
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
        await logout();
      }
    }
  }
  Future<bool> deleteAccount() async {
    if (_token == null) return false;

    _setLoading(true);

    try {
      // 1. Call Backend
      bool success = await ApiService.deleteAccount(_token!);

      // 2. Clear Local Data regardless of server response
      if (success) {
        await _clearAuthData();

        // 3. Safe Social Logout
        try {
          await _googleSignIn.signOut();
        } catch (_) {}

        try {
          await FacebookAuth.instance.logOut();
        } catch (_) {}
      }

      _setLoading(false);
      return success;
    } catch (e) {
      print("Delete Account Error: $e");
      _setLoading(false);
      return false;
    }
  }
}