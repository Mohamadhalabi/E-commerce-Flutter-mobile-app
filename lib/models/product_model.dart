class ProductModel {
  final int id;
  final String image;
  final String brandName;
  final String title;
  final String category;
  final String sku;
  final double price;
  final double? salePrice;
  final double rating;
  final bool freeShipping;
  final Map<String, dynamic>? discount;
  final List<List<String>> faq;

  // 1. ADD FIELD HERE
  final int quantity;

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
    // 2. ADD TO CONSTRUCTOR (Default to 0 or 1)
    this.quantity = 0,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {

    // ... (Your existing parseDouble logic) ...
    double parseDouble(dynamic value) {
      if (value == null) return 0.0;
      if (value is Map && value.containsKey('value')) {
        return parseDouble(value['value']);
      }
      if (value is int) return value.toDouble();
      if (value is double) return value;
      if (value is String) return double.tryParse(value) ?? 0.0;
      return 0.0;
    }

    // ... (Your existing brand/category logic) ...
    String extractBrand(Map<String, dynamic> data) {
      if (data['brands'] != null && (data['brands'] as List).isNotEmpty) {
        return data['brands'][0]['name'] ?? "Unknown Brand";
      }
      return data['brand_name'] ?? "Unknown Brand";
    }

    String extractCategory(Map<String, dynamic> data) {
      if (data['categories'] != null && (data['categories'] as List).isNotEmpty) {
        return data['categories'][0]['name'] ?? "General";
      }
      return data['category'] ?? "General";
    }

    // 3. HELPER FOR QUANTITY (Optional but recommended for safety)
    int parseInt(dynamic value) {
      if (value == null) return 0;
      if (value is int) return value;
      if (value is String) return int.tryParse(value) ?? 0;
      if (value is double) return value.toInt();
      return 0;
    }

    return ProductModel(
      id: json['id'] ?? 0,
      title: json['title'] ?? "No Title",
      sku: json['sku'] ?? "",
      image: json['image'] ?? "",
      brandName: extractBrand(json),
      category: extractCategory(json),
      price: parseDouble(json['unit'] ?? json['regular_price'] ?? json['price']),
      salePrice: json['sale_price'] != null ? parseDouble(json['sale_price']) : null,
      rating: parseDouble(json['rating'] ?? json['avg_rating']),
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

      // 4. MAP THE JSON
      // If the API calls it 'stock', 'qty', or 'quantity', change the string key below accordingly.
      quantity: parseInt(json['quantity'] ?? json['stock_quantity']),
    );
  }
}