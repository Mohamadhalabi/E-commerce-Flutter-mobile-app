class ProductModel {
  final int id;
  final String image;
  final String brandName;
  final String title;
  final String category;
  final String sku;
  final double price; // Represents Regular Price
  final double? salePrice; // Represents Sale Price
  final double rating;
  final bool freeShipping;
  final Map<String, dynamic>? discount;
  final List<List<String>> faq;

  ProductModel({
    required this.id,
    required this.image,
    required this.brandName,
    required this.title,
    required this.price,
    required this.category,
    required this.sku,
    required this.rating,
    this.freeShipping = false,
    this.salePrice,
    this.discount,
    required this.faq,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    // 1. ROBUST NUMBER PARSER
    // Handles: 10, 10.5, "10.5", and {"value": 10.5}
    double parseDouble(dynamic value) {
      if (value == null) return 0.0;

      // Handle legacy nested object structure: {"value": 50.0}
      if (value is Map && value.containsKey('value')) {
        return parseDouble(value['value']);
      }

      if (value is int) return value.toDouble();
      if (value is double) return value;
      if (value is String) return double.tryParse(value) ?? 0.0;

      return 0.0;
    }

    // 2. BRAND EXTRACTION LOGIC
    String extractBrand(Map<String, dynamic> data) {
      if (data['brands'] != null && (data['brands'] as List).isNotEmpty) {
        return data['brands'][0]['name'] ?? "Unknown Brand";
      }
      return data['brand_name'] ?? "Unknown Brand";
    }

    // 3. CATEGORY EXTRACTION LOGIC
    String extractCategory(Map<String, dynamic> data) {
      if (data['categories'] != null && (data['categories'] as List).isNotEmpty) {
        return data['categories'][0]['name'] ?? "General";
      }
      return data['category'] ?? "General";
    }

    return ProductModel(
      id: json['id'] ?? 0,
      title: json['title'] ?? "No Title",
      sku: json['sku'] ?? "",
      image: json['image'] ?? "",

      brandName: extractBrand(json),
      category: extractCategory(json),

      // Checks 'regular_price' first (New API), then 'price' (Old API)
      price: parseDouble(json['regular_price'] ?? json['price']),

      // Correctly parses sale_price if it exists
      salePrice: json['sale_price'] != null ? parseDouble(json['sale_price']) : null,

      // Handles 'rating' or 'avg_rating'
      rating: parseDouble(json['rating'] ?? json['avg_rating']),

      // Flexible boolean check for shipping
      freeShipping: json['is_free_shipping'] == true ||
          json['is_free_shipping'] == 1 ||
          json['free_shipping'] == 1,

      discount: json['discount'] is Map
          ? Map<String, dynamic>.from(json['discount'])
          : null,

      faq: json['faq'] != null
          ? List<List<String>>.from(
          (json['faq'] as List).map((item) => List<String>.from(item)))
          : [],
    );
  }
}