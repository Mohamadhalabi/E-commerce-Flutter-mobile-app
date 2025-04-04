import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/product_model.dart';
import '../../../../constants.dart';

class ApiService {

  static Future<List<ProductModel>> fetchLatestProducts() async {
    try {
      final response = await http.get(Uri.parse("${AppConstants.baseUrl}/products/latest-products"),
        headers: {
          'Accept-Language': 'en',
          'Content-Type': 'application/json',
          'currency': 'USD',
          'Accept': 'application/json',
          'secret-key': AppConstants.secretKey,
          'api-key': AppConstants.apiKey,
        },
      );

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