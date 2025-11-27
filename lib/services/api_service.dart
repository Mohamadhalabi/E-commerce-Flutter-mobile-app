import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shop/models/brand_model.dart';
import 'package:shop/models/manufacturer_model.dart';
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
      await dotenv.load();
      String apiBaseUrl = dotenv.env['API_BASE_URL'] ?? '';
      String apiKey = dotenv.env['API_KEY'] ?? '';
      String secretKey = dotenv.env['SECRET_KEY'] ?? '';
      String url = '$apiBaseUrl/get-category';

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
        throw Exception("Failed to load category");
      }
    } catch (e) {
      throw Exception("Error: $e");
    }
  }
  static Future<List<BrandModel>> fetchBrands(String locale) async {
    try {
      await dotenv.load();
      String apiBaseUrl = dotenv.env['API_BASE_URL'] ?? '';
      String apiKey = dotenv.env['API_KEY'] ?? '';
      String secretKey = dotenv.env['SECRET_KEY'] ?? '';
      String url = '$apiBaseUrl/get-brands';

      print('📡 Calling: $url');
      print('📥 Headers: Accept-Language=$locale, api-key=$apiKey, secret-key=$secretKey');

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
        final List data = jsonResponse['brands'] ?? [];

        return data.map((item) => BrandModel.fromJson(item)).toList();
      } else {
        throw Exception("Failed to load brands");
      }
    } catch (e) {
      throw Exception("Error: $e");
    }
  }

  static Future<List<ManufacturerModel>> fetchManufacturers(String locale) async {
    try {
      await dotenv.load();
      String apiBaseUrl = dotenv.env['API_BASE_URL'] ?? '';
      String apiKey = dotenv.env['API_KEY'] ?? '';
      String secretKey = dotenv.env['SECRET_KEY'] ?? '';
      String url = '$apiBaseUrl/get-manufacturers';

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
        final List data = jsonResponse['manufacturers'] ?? [];

        return data.map((item) => ManufacturerModel.fromJson(item)).toList();
      } else {
        throw Exception("Failed to load manufacturers");
      }
    } catch (e) {
      throw Exception("Error: $e");
    }
  }

  static Future<List<ProductModel>> fetchLatestProducts(String locale) async {
    try {
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
  // fetch subcategories (using the id of the category)
  static Future<List<dynamic>> fetchSubcategories(int parentId) async {
    try {
      await dotenv.load();
      String apiBaseUrl = dotenv.env['API_BASE_URL'] ?? '';
      String apiKey = dotenv.env['API_KEY'] ?? '';
      String secretKey = dotenv.env['SECRET_KEY'] ?? '';

      final response = await http.get(
        Uri.parse('$apiBaseUrl/categories/$parentId/subcategories'),
        headers: {
          'Accept-Language': 'en', // You can pass locale dynamically if needed
          'Content-Type': 'application/json',
          'currency': 'USD',
          'Accept': 'application/json',
          'secret-key': secretKey,
          'api-key': apiKey,
        },
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        return body['data'];
      } else {
        throw Exception('Failed to load subcategories: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching subcategories: $e');
      return [];
    }
  }

  // fetch sub category products
  static Future<Map<String, dynamic>> fetchProductsBySubcategory(int subCategoryId, String locale, {int page = 1}) async {
    await dotenv.load();
    String apiBaseUrl = dotenv.env['API_BASE_URL'] ?? '';
    String apiKey = dotenv.env['API_KEY'] ?? '';
    String secretKey = dotenv.env['SECRET_KEY'] ?? '';
    String url = '$apiBaseUrl/products/by-subcategory/$subCategoryId?page=$page';

    final response = await http.get(
      Uri.parse(url),
      headers: _buildHeaders(locale, apiKey, secretKey),
    );
    if (response.statusCode == 200) {
      final jsonBody = jsonDecode(response.body);
      print("⚙️ Full API Response Page $page: $jsonBody");

      return {
        'products': (jsonBody['products'] as List).map((item) => ProductModel.fromJson(item)).toList(),
        'current_page': jsonBody['current_page'],
        'last_page': jsonBody['last_page'],
      };
    } else {
      throw Exception("Failed to load paginated products");
    }
  }

  //search by category

  static Future<List<ProductModel>> searchSubCategoryProducts(
      int subCategoryId,
      String query,
      String locale,
      ) async {
    await dotenv.load();

    final String baseUrl = dotenv.env['API_BASE_URL'] ?? '';
    final String apiKey = dotenv.env['API_KEY'] ?? '';
    final String secretKey = dotenv.env['SECRET_KEY'] ?? '';

    final Uri url = Uri.parse(
      '$baseUrl/subcategories/$subCategoryId/search?q=$query',
    );

    final response = await http.get(
      url,
      headers: {
        'Accept-Language': locale,
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'currency': 'USD',
        'api-key': apiKey,
        'secret-key': secretKey,
      },
    );

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((item) => ProductModel.fromJson(item)).toList();
    } else {
      throw Exception('Failed to fetch search results: ${response.statusCode}');
    }
  }
}