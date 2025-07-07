import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AuthService {
  static final String baseUrl = dotenv.env['API_BASE_URL']!;
  static final String apiKey = dotenv.env['API_KEY']!;
  static final String secretKey = dotenv.env['SECRET_KEY']!;

  static Map<String, String> get _headers => {
    'Accept': 'application/json',
    'API-KEY': apiKey,
    'SECRET-KEY': secretKey,
  };

  /// LOGIN USER
  static Future<bool> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/user/auth/login'),
      headers: _headers,
      body: {
        'email': email,
        'password': password,
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final token = data['token'];

      if (token != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', token);

        // Fetch and save user profile
        final userResponse = await http.post(
          Uri.parse('$baseUrl/me'),
          headers: {
            ..._headers,
            'Authorization': 'Bearer $token',
          },
        );

        if (userResponse.statusCode == 200) {
          final userData = json.decode(userResponse.body);
          await prefs.setString('user', jsonEncode(userData));
          return true;
        }
      }
    }

    return false;
  }

  /// REGISTER USER
  static Future<bool> register(String name, String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/user/auth/register'),
      headers: _headers,
      body: {
        'name': name,
        'email': email,
        'password': password,
        'password_confirmation': password,
      },
    );

    return response.statusCode == 200 || response.statusCode == 201;
  }

  /// FETCH USER (fresh from API)
  static Future<Map<String, dynamic>?> fetchUser() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) return null;

    final response = await http.post(
      Uri.parse('$baseUrl/me'),
      headers: {
        ..._headers,
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final userData = json.decode(response.body);
      await prefs.setString('user', jsonEncode(userData));
      return userData;
    }

    return null;
  }

  /// GET USER FROM CACHE
  static Future<Map<String, dynamic>?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString('user');
    if (userJson == null) return null;
    return json.decode(userJson);
  }

  /// CHECK IF USER IS LOGGED IN
  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token') != null;
  }

  /// LOGOUT USER
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token != null) {
      await http.post(
        Uri.parse('$baseUrl/user/auth/logout'),
        headers: {
          ..._headers,
          'Authorization': 'Bearer $token',
        },
      );
    }

    await prefs.remove('token');
    await prefs.remove('user');
  }
}