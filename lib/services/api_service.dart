import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/product_model.dart';

class ApiService {
  static const String baseUrl = "https://your-api.com"; // Replace with actual API

  static Future<List<ProductModel>> fetchLatestProducts() async {
    try {
      final response = await http.get(Uri.parse("$baseUrl/products/latest"));

      if (response.statusCode == 200) {
        List<dynamic> jsonData = json.decode(response.body);
        return jsonData.map((item) => ProductModel.fromJson(item)).toList();
      } else {
        throw Exception("Failed to load latest products");
      }
    } catch (e) {
      throw Exception("Error: $e");
    }
  }
}