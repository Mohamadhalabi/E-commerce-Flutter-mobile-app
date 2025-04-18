import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiClient {
  final String baseUrl;
  final String apiKey;
  final String secretKey;

  String _language = 'en';
  String _currency = 'USD';

  ApiClient({
    required this.baseUrl,
    required this.apiKey,
    required this.secretKey,
  });

  /// Update locale settings globally
  void setLocale({required String language, required String currency}) {
    _language = language;
    _currency = currency;
  }

  /// GET request
  Future<dynamic> get(String endpoint) async {
    final url = Uri.parse('$baseUrl$endpoint');
    final response = await http.get(
      url,
      headers: _buildHeaders(),
    );
    return _handleResponse(response);
  }

  /// POST request (optional - if needed later)
  Future<dynamic> post(String endpoint, Map<String, dynamic> body) async {
    final url = Uri.parse('$baseUrl$endpoint');
    final response = await http.post(
      url,
      headers: _buildHeaders(),
      body: jsonEncode(body),
    );
    return _handleResponse(response);
  }

  /// Common headers
  Map<String, String> _buildHeaders() {
    return {
      'Accept-Language': _language,
      'Content-Type': 'application/json',
      'currency': _currency,
      'Accept': 'application/json',
      'secret-key': secretKey,
      'api-key': apiKey,
    };
  }

  /// Handle response and decode JSON
  dynamic _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return json.decode(response.body);
    } else {
      throw Exception(
        'Request failed: ${response.statusCode} - ${response.reasonPhrase}\n${response.body}',
      );
    }
  }

  /// Factory method to load from .env (if needed globally)
  static Future<ApiClient> fromEnv() async {
    await dotenv.load();

    final baseUrl = dotenv.env['API_BASE_URL'] ?? '';
    final apiKey = dotenv.env['API_KEY'] ?? '';
    final secretKey = dotenv.env['SECRET_KEY'] ?? '';

    if (baseUrl.isEmpty || apiKey.isEmpty || secretKey.isEmpty) {
      throw Exception('Missing environment variables for API client.');
    }

    return ApiClient(
      baseUrl: baseUrl,
      apiKey: apiKey,
      secretKey: secretKey,
    );
  }
}