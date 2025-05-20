import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/product_model.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/category_model.dart';

class ApiService {
  static Map<String, String> _buildHeaders(String locale, String apiKey, String secretKey) {
    return {
      'Accept-Language': locale,
      'Content-Type': 'application/json',
      'currency': 'USD',
      'Accept': 'application/json',
      'secret-key': secretKey,
      'api-key': apiKey,
    };
  }
  // Home Page API
  static Future<List<CategoryModel>> fetchCategories(String locale) async {
    try {
      print("categories language");
      print(locale);
      await dotenv.load();
      String apiBaseUrl = dotenv.env['API_BASE_URL'] ?? '';
      String apiKey = dotenv.env['API_KEY'] ?? '';
      String secretKey = dotenv.env['SECRET_KEY'] ?? '';
      String url = '$apiBaseUrl/get-categories';

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Accept-Language': locale,
          'Content-Type': 'application/json',
          'currency': 'USD',
          'Accept': 'application/json',
          'secret-key': secretKey,
          'api-key': apiKey,
        },
      );

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        final List data = jsonResponse['categories'] ?? [];

        return data.map((item) => CategoryModel.fromJson(item)).toList();
      } else {
        throw Exception("Failed to load categories");
      }
    } catch (e) {
      throw Exception("Error: $e");
    }
  }

  static Future<List<ProductModel>> fetchLatestProducts(String locale) async {
    try {
      print("hello it is moe");
      print(locale);
      await dotenv.load();
      String apiBaseUrl = dotenv.env['API_BASE_URL'] ?? '';
      String apiKey = dotenv.env['API_KEY'] ?? '';
      String secretKey = dotenv.env['SECRET_KEY'] ?? '';
      String url = '$apiBaseUrl/products/latest-products';

      final response = await http.get(
        Uri.parse(url),
        headers: _buildHeaders(locale, apiKey, secretKey),
      );

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);

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

  static Future<List<Map<String, String>>> fetchSliders(String locale) async {
    try {
      await dotenv.load();
      String apiBaseUrl = dotenv.env['API_BASE_URL'] ?? '';
      String apiKey = dotenv.env['API_KEY'] ?? '';
      String secretKey = dotenv.env['SECRET_KEY'] ?? '';
      String url = '$apiBaseUrl/get-sliders?type=banner';

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Accept-Language': locale,
          'Content-Type': 'application/json',
          'currency': 'USD',
          'Accept': 'application/json',
          'secret-key': secretKey,
          'api-key': apiKey,
        },
      );

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        if (jsonResponse is List) {
          return jsonResponse.map<Map<String, String>>((item) {
            return {
              'image': item['image'].toString(),
              'link': item['link'].toString(),
            };
          }).toList();
        } else {
          throw Exception("Unexpected response format");
        }
      } else {
        throw Exception("Failed to load sliders");
      }
    } catch (e) {
      throw Exception("Error: $e");
    }
  }


  static Future<List<ProductModel>> fetchFlashSaleProducts(String locale) async {
    try {
      await dotenv.load();
      String apiBaseUrl = dotenv.env['API_BASE_URL'] ?? '';
      String apiKey = dotenv.env['API_KEY'] ?? '';
      String secretKey = dotenv.env['SECRET_KEY'] ?? '';
      String url = '$apiBaseUrl/products/offer-products';

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Accept-Language': locale,
          'Content-Type': 'application/json',
          'currency': 'USD',
          'Accept': 'application/json',
          'secret-key': secretKey,
          'api-key': apiKey,
        },
      );

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        if (jsonResponse['offer_products'] != null &&
            jsonResponse['offer_products'] is List) {
          return (jsonResponse['offer_products'] as List)
              .map((item) => ProductModel.fromJson(item))
              .toList();
        } else {
          throw Exception("Invalid API response format for offer_products");
        }
      } else {
        throw Exception("Failed to load offer products");
      }
    } catch (e) {
      throw Exception("Error: $e");
    }
  }



  static Future<List<ProductModel>> fetchFreeShippingProducts(String locale) async {
    try {
      await dotenv.load();
      String apiBaseUrl = dotenv.env['API_BASE_URL'] ?? '';
      String apiKey = dotenv.env['API_KEY'] ?? '';
      String secretKey = dotenv.env['SECRET_KEY'] ?? '';
      String url = '$apiBaseUrl/products/free-shipping';

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Accept-Language': locale,
          'Content-Type': 'application/json',
          'currency': 'USD',
          'Accept': 'application/json',
          'secret-key': secretKey,
          'api-key': apiKey,
        },
      );

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        if (jsonResponse['free_shipping'] != null && jsonResponse['free_shipping'] is List) {
          return (jsonResponse['free_shipping'] as List)
              .map((item) => ProductModel.fromJson(item))
              .toList();
        } else {
          throw Exception("Invalid API response format for free_shipping");
        }
      } else {
        throw Exception("Failed to load free shipping products");
      }
    } catch (e) {
      throw Exception("Error: $e");
    }
  }


  static Future<List<ProductModel>> fetchBundleProducts(String locale) async {
    try {
      await dotenv.load();
      String apiBaseUrl = dotenv.env['API_BASE_URL'] ?? '';
      String apiKey = dotenv.env['API_KEY'] ?? '';
      String secretKey = dotenv.env['SECRET_KEY'] ?? '';
      String url = '$apiBaseUrl/products/bundle-products';

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Accept-Language': locale,
          'Content-Type': 'application/json',
          'currency': 'USD',
          'Accept': 'application/json',
          'secret-key': secretKey,
          'api-key': apiKey,
        },
      );

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        if (jsonResponse['bundle_products'] != null &&
            jsonResponse['bundle_products'] is List) {
          return (jsonResponse['bundle_products'] as List)
              .map((item) => ProductModel.fromJson(item))
              .toList();
        } else {
          throw Exception("Invalid API response format for bundle_products");
        }
      } else {
        throw Exception("Failed to load Bundle products");
      }
    } catch (e) {
      throw Exception("Error: $e");
    }
  }
  // product details
  static Future<Map<String, dynamic>> fetchProductDetails(int id, String locale) async {
    try {
      await dotenv.load();
      String apiBaseUrl = dotenv.env['API_BASE_URL'] ?? '';
      String apiKey = dotenv.env['API_KEY'] ?? '';
      String secretKey = dotenv.env['SECRET_KEY'] ?? '';
      String url = '$apiBaseUrl/product/$id';

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Accept-Language': locale,
          'Content-Type': 'application/json',
          'currency': 'USD',
          'Accept': 'application/json',
          'secret-key': secretKey,
          'api-key': apiKey,
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        return responseData['product_data'];
      } else {
        throw Exception('Failed to load product');
      }
    } catch (e) {
      throw Exception("Error: $e");
    }
  }
  // fetch Related Products
  static Future<List<ProductModel>> fetchRelatedProducts(String locale, int productId) async {
    try {
      await dotenv.load();
      String apiBaseUrl = dotenv.env['API_BASE_URL'] ?? '';
      String apiKey = dotenv.env['API_KEY'] ?? '';
      String secretKey = dotenv.env['SECRET_KEY'] ?? '';
      String url = '$apiBaseUrl/products/related-products?product_id=$productId';

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Accept-Language': locale,
          'Content-Type': 'application/json',
          'currency': 'USD',
          'Accept': 'application/json',
          'secret-key': secretKey,
          'api-key': apiKey,
        },
      );

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        if (jsonResponse['related_products'] != null &&
            jsonResponse['related_products'] is List) {
          return (jsonResponse['related_products'] as List)
              .map((item) => ProductModel.fromJson(item))
              .toList();
        } else {
          throw Exception("Invalid API response format for related_products");
        }
      } else {
        throw Exception("Failed to load related products");
      }
    } catch (e) {
      throw Exception("Error: $e");
    }
  }
}