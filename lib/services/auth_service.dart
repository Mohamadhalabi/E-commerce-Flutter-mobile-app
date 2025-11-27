import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AuthService {
  static final String baseUrl = dotenv.env['API_BASE_URL']!;
  static final String apiKey = dotenv.env['API_KEY']!;
  static final String secretKey = dotenv.env['SECRET_KEY']!;

  static Map<String, String> _baseHeaders = {
    'Accept': 'application/json',
    'API-KEY': apiKey,
    'SECRET-KEY': secretKey,
  };

  // Get stored token
  static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token'); // Make sure you store token on login
  }

  // Get user profile from Laravel backend
  static Future<Map<String, dynamic>?> getUserProfile() async {
    try {
      final token = await _getToken();
      if (token == null) return null; // Not logged in

      final headers = {
        ..._baseHeaders,
        'Authorization': 'Bearer $token',
      };

      final response = await http.get(
        Uri.parse('$baseUrl/user'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      } else if (response.statusCode == 401) {
        // Token expired or invalid
        return null;
      }
    } catch (e) {
      print("getUserProfile error: $e");
    }
    return null;
  }

  // Logout user
  static Future<bool> logoutUser() async {
    try {
      final token = await _getToken();
      if (token == null) return false;

      final headers = {
        ..._baseHeaders,
        'Authorization': 'Bearer $token',
      };

      final response = await http.post(
        Uri.parse('$baseUrl/logout'),
        headers: headers,
      );

      // Clear local token
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('auth_token');

      return response.statusCode == 200;
    } catch (e) {
      print("logoutUser error: $e");
      return false;
    }
  }
}