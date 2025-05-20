import 'package:shop/constants.dart';

class ProductModel {
  final String image, brandName, title, category, sku;
  final double price, rating;
  final double? salePrice;
  final int? discountPercent, id;
  final bool? freeShipping;
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
    this.freeShipping,
    this.salePrice,
    this.discountPercent,
    this.discount,
    required this.faq, // Add this line
  });


  factory ProductModel.fromJson(Map<String, dynamic> json) {
    // Safely parse price
    double parsePrice(dynamic priceJson) {
      if (priceJson is Map && priceJson['value'] != null) {
        return double.tryParse(priceJson['value'].toString()) ?? 0.0;
      }
      return 0.0;
    }

    return ProductModel(
      id: json['id'],
      image: json['image'] ?? "",
      sku: json['sku'] ?? "",
      brandName: json['brand_name'] ?? "Unknown Brand",
      title: json['title'] ?? "No Title",
      price: parsePrice(json['price']),
      salePrice: json['sale_price'] != null
          ? parsePrice(json['sale_price'])
          : null,
      discountPercent: json['discount_percent'],
      category: json['category'] ?? "",
      rating: json['avg_rating'] ?? 0,
      discount: json['discount'] is Map
          ? Map<String, dynamic>.from(json['discount'])
          : (json['discount'] is List && json['discount'].isNotEmpty)
          ? Map<String, dynamic>.from(json['discount'][0])
          : null,
      freeShipping: json['free_shipping'] == 1 ? true : false,
      faq: json['faq'] != null
          ? List<List<String>>.from(
        (json['faq'] as List).map(
              (item) => List<String>.from(item),
        ),
      ) : [],
    );
  }
}