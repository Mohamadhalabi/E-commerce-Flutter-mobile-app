import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/product_model.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiService {

  static Future<List<ProductModel>> fetchLatestProducts() async {
    try {
      await dotenv.load();
      String apiBaseUrl = dotenv.env['API_BASE_URL'] ?? '';
      String apiKey = dotenv.env['API_KEY'] ?? '';
      String secretKey = dotenv.env['SECRET_KEY'] ?? '';
      String url = '$apiBaseUrl/products/latest-products';

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Accept-Language': 'en',
          'Content-Type': 'application/json',
          'currency': 'USD',
          'Accept': 'application/json',
          'secret-key': secretKey,
          'api-key': apiKey,
        },
      );

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);

        // Replace 'products' with the correct key based on your response
        if (jsonResponse['new_arrival'] != null && jsonResponse['new_arrival'] is List) {
          return (jsonResponse['new_arrival'] as List)
              .map((item) => ProductModel.fromJson(item))
              .toList();
        } else {
          throw Exception("Invalid API response format");
        }
      } else {
        throw Exception("Failed to load latest products");
      }
    } catch (e) {
      throw Exception("Error: $e");
    }
  }
}