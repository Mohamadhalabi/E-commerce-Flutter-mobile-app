class ProductModel {
  final int id;
  final String title;
  final String sku;
  final String image;
  final String category;
  final String brandName;

  // Pricing
  final double regularPrice;
  final double? salePrice;
  final double effectivePrice;

  // Logic
  final int stock;
  final Map<String, dynamic>? discount;
  final List<TablePriceItem> tablePrices;
  final bool freeShipping;
  final bool hidePrice;
  final double rating;

  ProductModel({
    required this.id,
    required this.title,
    required this.sku,
    required this.image,
    this.category = "General",
    this.brandName = "",
    required this.regularPrice,
    this.salePrice,
    required this.effectivePrice,
    required this.stock,
    this.discount,
    required this.tablePrices,
    this.freeShipping = false,
    this.hidePrice = false,
    this.rating = 0.0,
  });

  // =========================================================
  // BACKWARD COMPATIBILITY
  // =========================================================
  double get price => effectivePrice;
  int get quantity => stock;

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    // --- HELPER: Safe Double Parser ---
    double parseDouble(dynamic value) {
      if (value == null) return 0.0;
      if (value is num) return value.toDouble();
      if (value is String) {
        String clean = value.replaceAll(RegExp(r'[^0-9.]'), '');
        return double.tryParse(clean) ?? 0.0;
      }
      return 0.0;
    }

    // --- HELPER: Safe Int Parser ---
    int parseInt(dynamic value) {
      if (value == null) return 0;
      if (value is int) return value;
      if (value is String) {
        String clean = value.replaceAll(RegExp(r'[^0-9]'), '');
        return int.tryParse(clean) ?? 0;
      }
      return 0;
    }

    // --- HELPER: Safe Bool Parser ---
    bool parseBool(dynamic value) {
      if (value == null) return false;
      if (value is bool) return value;
      if (value is int) return value == 1;
      if (value is String) return value == '1' || value.toLowerCase() == 'true';
      return false;
    }

    // 1. Parse Base Values from API
    double regular = parseDouble(json['regular_price']);
    double effective = parseDouble(json['price']);
    double? sale = json['sale_price'] != null ? parseDouble(json['sale_price']) : null;

    // 2. APPLY DISCOUNT MATH
    if (json['discount'] != null && json['discount'] is Map) {
      Map<String, dynamic> d = json['discount'];
      String type = d['type']?.toString().toLowerCase() ?? '';
      double value = parseDouble(d['value']);

      if (value > 0) {
        double calculatedPrice = effective;

        if (type == 'fixed') {
          calculatedPrice = effective - value;
        } else if (type == 'percent') {
          calculatedPrice = effective - (effective * (value / 100));
        }

        if (calculatedPrice < effective && calculatedPrice > 0) {
          if (regular <= 0 || regular == calculatedPrice) {
            regular = effective;
          }
          effective = calculatedPrice;
          sale = calculatedPrice;
        }
      }
    }

    // 3. Fallback Logic
    if (regular <= 0.0 && sale != null && sale > 0) {
      regular = effective > sale ? effective : sale + 10;
      effective = sale;
    } else if (effective <= 0.0 && regular > 0) {
      effective = regular;
    }

    return ProductModel(
      id: json['id'] ?? 0,
      title: json['title'] ?? "No Title",
      sku: json['sku'] ?? "",
      image: json['image'] ?? "",
      category: json['category'] ?? "General",
      brandName: json['brand_name'] ?? "",

      // Pricing
      regularPrice: regular,
      salePrice: sale,
      effectivePrice: effective,

      // Logic
      stock: parseInt(json['quantity']),
      rating: parseDouble(json['rating'] ?? json['avg_rating']),
      discount: json['discount'] is Map ? Map<String, dynamic>.from(json['discount']) : null,
      tablePrices: (json['table_price'] != null && json['table_price'] is List)
          ? (json['table_price'] as List).map((e) => TablePriceItem.fromJson(e)).toList()
          : [],
      freeShipping: parseBool(json['is_free_shipping']),

      // Parse hide_price flag safely
      hidePrice: parseBool(json['hide_price']),
    );
  }
}

class TablePriceItem {
  final int minQty;
  final int? maxQty;
  final double price;

  TablePriceItem({required this.minQty, this.maxQty, required this.price});

  factory TablePriceItem.fromJson(Map<String, dynamic> json) {
    double parseDouble(dynamic value) {
      if (value == null) return 0.0;
      if (value is num) return value.toDouble();
      if (value is String) {
        String clean = value.replaceAll(RegExp(r'[^0-9.]'), '');
        return double.tryParse(clean) ?? 0.0;
      }
      return 0.0;
    }

    return TablePriceItem(
      minQty: json['min_qty'] is int ? json['min_qty'] : (int.tryParse(json['min_qty']?.toString() ?? "1") ?? 1),
      maxQty: json['max_qty'] != null ? int.tryParse(json['max_qty'].toString()) : null,
      price: json['sale_price'] != null
          ? parseDouble(json['sale_price'])
          : parseDouble(json['price']),
    );
  }
}