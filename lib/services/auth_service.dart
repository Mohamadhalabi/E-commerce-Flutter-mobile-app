import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AuthService {
  // Ensure this is loaded in main.dart
  static final String baseUrl = dotenv.env['API_BASE_URL'] ?? '';
  static final String apiKey = dotenv.env['API_KEY'] ?? '';
  static final String secretKey = dotenv.env['SECRET_KEY'] ?? '';

  static Map<String, String> _buildHeaders(String? token) {
    final headers = {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      // Ensure these match your Laravel Middleware expectations (lowercase is standard)
      'api-key': apiKey,
      'secret-key': secretKey,
    };

    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }

    return headers;
  }

  // Get stored token
  static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    // FIX 1: Changed 'auth_token' to 'authToken' to match your AuthProvider
    return prefs.getString('authToken');
  }

  // Get user profile from Laravel backend
  static Future<Map<String, dynamic>?> getUserProfile() async {
    try {
      final token = await _getToken();
      if (token == null) return null; // Not logged in locally

      // FIX 2: Correct URL to match Laravel 'routes/api.php'
      // Route: api-mobile/auth/me
      // If baseUrl is ".../api", we append "api-mobile/auth/me"
      final String url = '$baseUrl/api-mobile/auth/me';

      final response = await http.get(
        Uri.parse(url),
        headers: _buildHeaders(token),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      } else {
        // 401 or 404 means the token is invalid or route is wrong
        return null;
      }
    } catch (e) {
      print("getUserProfile error: $e");
      return null;
    }
  }

  // Logout user
  static Future<bool> logoutUser() async {
    try {
      final token = await _getToken();
      if (token == null) return false;

      // FIX 3: Correct URL to match Laravel 'routes/api.php'
      final String url = '$baseUrl/api-mobile/auth/logout';

      final response = await http.post(
        Uri.parse(url),
        headers: _buildHeaders(token),
      );

      // Clear local token regardless of server response
      final prefs = await SharedPreferences.getInstance();
      // FIX 4: Use the correct key 'authToken'
      await prefs.remove('authToken');
      await prefs.remove('userData'); // Optional: clear user data if you store it

      return response.statusCode == 200;
    } catch (e) {
      print("logoutUser error: $e");
      // Even if API fails, clear local storage so the user is logged out in the UI
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('authToken');
      return false;
    }
  }
}