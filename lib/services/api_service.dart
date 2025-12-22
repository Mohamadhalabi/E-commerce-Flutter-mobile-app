import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shop/models/brand_model.dart';
import 'package:shop/models/manufacturer_model.dart';
import '../models/product_model.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/category_model.dart';

class ApiService {

  static Map<String, String> _buildHeaders(String locale, String apiKey, String secretKey, {String? token}) {
    final headers = {
      'Accept-Language': locale,
      'Content-Type': 'application/json',
      'currency': 'USD',
      'Accept': 'application/json',
      'secret-key': secretKey,
      'api-key': apiKey,
    };
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
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
        headers: _buildHeaders(locale, apiKey, secretKey),
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
        headers: _buildHeaders(locale, apiKey, secretKey),
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
        headers: _buildHeaders(locale, apiKey, secretKey),
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
        headers: _buildHeaders(locale, apiKey, secretKey),
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
        headers: _buildHeaders(locale, apiKey, secretKey),
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
        headers: _buildHeaders(locale, apiKey, secretKey),
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
        headers: _buildHeaders(locale, apiKey, secretKey),
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
// lib/services/api_service.dart

  static Future<Map<String, dynamic>> fetchProductDetails(int id, String locale) async {
    try {
      await dotenv.load();
      String apiBaseUrl = dotenv.env['API_BASE_URL'] ?? '';
      String apiKey = dotenv.env['API_KEY'] ?? '';
      String secretKey = dotenv.env['SECRET_KEY'] ?? '';

      // ✅ CRITICAL FIX: Added 'table_price' to the list
      String queryParams = '?include=description,images,attributes,faq,categories,manufacturers,discount,table_price';

      String url = '$apiBaseUrl/product/$id$queryParams';

      final response = await http.get(
        Uri.parse(url),
        headers: {
          ..._buildHeaders(locale, apiKey, secretKey),
          'Accept-Language': locale,
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = jsonDecode(response.body);
        final Map<String, dynamic> data = jsonResponse['data'];

        // ... (Keep your existing image gallery transformation logic here) ...
        List<String> galleryUrls = [];
        if (data['images'] != null) {
          for (var img in data['images']) {
            if (img['src'] != null) {
              galleryUrls.add(img['src']);
            }
          }
        }
        if (galleryUrls.isEmpty && data['image'] != null) {
          galleryUrls.add(data['image']);
        }
        data['gallery'] = galleryUrls;

        // Fix Category Name
        if (data['categories'] != null && (data['categories'] as List).isNotEmpty) {
          data['category'] = data['categories'][0]['name'];
        } else {
          data['category'] = "Unknown";
        }

        return data;
      } else {
        throw Exception('Failed to load product: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception("Error fetching details: $e");
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
        headers: _buildHeaders(locale, apiKey, secretKey),
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
        headers: _buildHeaders('en', apiKey, secretKey),
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
      headers: _buildHeaders(locale, apiKey, secretKey),
    );

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((item) => ProductModel.fromJson(item)).toList();
    } else {
      throw Exception('Failed to fetch search results: ${response.statusCode}');
    }
  }

  // ==================================================
  // AUTH ROUTES
  // ==================================================

  // API for login
  static Future<Map<String, dynamic>> login(String email, String password) async {
    await dotenv.load();
    String apiBaseUrl = dotenv.env['API_BASE_URL'] ?? '';
    String apiKey = dotenv.env['API_KEY'] ?? ''; // Load API key
    String secretKey = dotenv.env['SECRET_KEY'] ?? ''; // Load Secret key

    // Assuming the Laravel route is set up as 'api-mobile/auth/login'
    String url = '$apiBaseUrl/auth/login';

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: _buildHeaders('en', apiKey, secretKey),
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      final Map<String, dynamic> responseData = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {'success': true, ...responseData};
      } else {
        String message = responseData['message'] ?? 'Invalid credentials or login failed';
        return {'success': false, 'message': message};
      }
    } catch (e) {
      return {'success': false, 'message': 'Network or server error: $e'};
    }
  }

  // API for Register
  static Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    await dotenv.load();
    String apiBaseUrl = dotenv.env['API_BASE_URL'] ?? '';
    String apiKey = dotenv.env['API_KEY'] ?? '';
    String secretKey = dotenv.env['SECRET_KEY'] ?? '';

    String url = '$apiBaseUrl/auth/register';

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: _buildHeaders('en', apiKey, secretKey),
        body: jsonEncode({
          'name': name,
          'email': email,
          'phone': phone,
          'password': password,
        }),
      );

      final Map<String, dynamic> responseData = jsonDecode(response.body);
      if (response.statusCode == 201) {
        return {'success': true, ...responseData};
      } else {
        String message = responseData['message'] ?? 'Registration failed';
        return {
          'success': false,
          'message': message,
          'errors': responseData['errors']
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

// In lib/services/api_service.dart

// API to fetch logged-in user profile
  static Future<Map<String, dynamic>?> getUserProfile(String token) async {
    await dotenv.load();
    String apiBaseUrl = dotenv.env['API_BASE_URL'] ?? '';
    String apiKey = dotenv.env['API_KEY'] ?? '';
    String secretKey = dotenv.env['SECRET_KEY'] ?? '';

    // URL: .../api/api-mobile/auth/me
    String url = '$apiBaseUrl/auth/me';

    print(">>> Fetching Profile from: $url");

    try {
      final response = await http.get(
        Uri.parse(url),
        // FIX: Use _buildHeaders to include API Key & Secret Key
        headers: _buildHeaders('en', apiKey, secretKey, token: token),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        print("Profile Error: ${response.statusCode}");
        return null;
      }
    } catch (e) {
      print("Profile Fetch Exception: $e");
      return null;
    }
  }
  // ==================================================
  // CART ROUTES
  // ==================================================

  // Fetch Server Cart
// ... inside ApiService class

  // ==================================================
  // CART ROUTES (Updated for api-mobile)
  // ==================================================
// ... inside ApiService class

  // ==================================================
  // CART ROUTES (Updated for api-mobile)
  // ==================================================

  // 1. Fetch Cart
  static Future<List<dynamic>> fetchCart(String token, String locale) async {
    await dotenv.load();
    String apiBaseUrl = dotenv.env['API_BASE_URL'] ?? '';
    String apiKey = dotenv.env['API_KEY'] ?? '';
    String secretKey = dotenv.env['SECRET_KEY'] ?? '';

    // FIX: Removed '/v2', used '/cart' which maps to 'api-mobile/cart'
    String url = '$apiBaseUrl/cart';

    print(">>> Fetching Cart from: $url"); // DEBUG LOG

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: _buildHeaders(locale, apiKey, secretKey, token: token),
      );

      print(">>> Cart Status: ${response.statusCode}"); // DEBUG LOG
      print(">>> Cart Body: ${response.body}"); // DEBUG LOG

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data'] ?? [];
      }
    } catch (e) {
      print("Fetch Cart Error: $e");
    }
    return [];
  }

  // 2. Add Item
  static Future<bool> addToCart(int productId, int quantity, String token, String locale) async {
    await dotenv.load();
    String apiBaseUrl = dotenv.env['API_BASE_URL'] ?? '';
    String apiKey = dotenv.env['API_KEY'] ?? '';
    String secretKey = dotenv.env['SECRET_KEY'] ?? '';

    // FIX: Removed '/v2'
    String url = '$apiBaseUrl/cart/add';

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: _buildHeaders(locale, apiKey, secretKey, token: token),
        body: jsonEncode({
          'product_id': productId,
          'quantity': quantity,
        }),
      );
      print("Add Cart Status: ${response.statusCode}"); // DEBUG
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }

  // 3. Sync Guest Cart
  static Future<bool> syncGuestCart(List<Map<String, dynamic>> localCartItems, String token) async {
    await dotenv.load();
    String apiBaseUrl = dotenv.env['API_BASE_URL'] ?? '';
    String apiKey = dotenv.env['API_KEY'] ?? '';
    String secretKey = dotenv.env['SECRET_KEY'] ?? '';

    // FIX: Removed '/v2'
    String url = '$apiBaseUrl/cart/sync';

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: _buildHeaders('en', apiKey, secretKey, token: token),
        body: jsonEncode({
          'cart_items': localCartItems,
        }),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // 4. Remove Item
  static Future<bool> removeFromCart(int productId, String token) async {
    await dotenv.load();
    String apiBaseUrl = dotenv.env['API_BASE_URL'] ?? '';
    String apiKey = dotenv.env['API_KEY'] ?? '';
    String secretKey = dotenv.env['SECRET_KEY'] ?? '';

    // FIX: Removed '/v2'
    String url = '$apiBaseUrl/cart/$productId';

    try {
      final response = await http.delete(
        Uri.parse(url),
        headers: _buildHeaders('en', apiKey, secretKey, token: token),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // 5. Update Quantity
// 5. Update Quantity
  // ✅ Changed return type from Future<bool> to Future<double?>
  static Future<double?> updateCartQuantity(int productId, int quantity, String token) async {
    await dotenv.load();
    String apiBaseUrl = dotenv.env['API_BASE_URL'] ?? '';
    String apiKey = dotenv.env['API_KEY'] ?? '';
    String secretKey = dotenv.env['SECRET_KEY'] ?? '';

    String url = '$apiBaseUrl/cart/$productId';

    try {
      final response = await http.patch(
        Uri.parse(url),
        headers: _buildHeaders('en', apiKey, secretKey, token: token),
        body: jsonEncode({'quantity': quantity}),
      );

      if (response.statusCode == 200) {
        // ✅ FIX: Parse the new unit price from the server response
        final data = jsonDecode(response.body);
        if (data['unit_price'] != null) {
          return (data['unit_price'] as num).toDouble();
        }
        return -1.0; // Signal success but no price returned (fallback)
      }
    } catch (e) {
      print("Update Qty Error: $e");
    }
    return null; // Signal failure
  }
}