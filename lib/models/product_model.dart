// For demo only
import 'package:shop/constants.dart';

class ProductModel {
  final String image, brandName, title, category, sku;
  final double price, rating;
  final double? priceAfterDiscount;
  final int? discountPercent;

  ProductModel({
    required this.image,
    required this.brandName,
    required this.title,
    required this.price,
    required this.category,
    required this.sku,
    required this.rating,
    this.priceAfterDiscount,
    this.discountPercent,
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
      image: json['image'] ?? "",
      sku: json['sku'] ?? "",
      brandName: json['brand_name'] ?? "Unknown Brand",
      title: json['title'] ?? "No Title",
      price: parsePrice(json['price']),
      priceAfterDiscount: json['sale_price'] != null
          ? parsePrice(json['sale_price'])
          : null,
      discountPercent: json['discount_percent'],
      category: json['category'] ?? "",
      rating: json['avg_rating'] ?? 0,
    );
  }
}

List<ProductModel> demoPopularProducts = [
  ProductModel(
    image: productDemoImg1,
    title: "Mountain Warehouse for Women",
    brandName: "Lipsy london",
    price: 540,
    priceAfterDiscount: 420,
    discountPercent: 20,
    category: "",
    sku: "Sku HERE",
    rating: 4.5,
  ),
  ProductModel(
    image: productDemoImg4,
    title: "Mountain Beta Warehouse",
    brandName: "Lipsy london",
    price: 800,
    category: "",
    sku: "Sku HERE",
    rating: 4.5,
  ),
  ProductModel(
    image: productDemoImg5,
    title: "FS - Nike Air Max 270 Really React",
    brandName: "Lipsy london",
    price: 650.62,
    priceAfterDiscount: 390.36,
    discountPercent: 40,
    category: "",
    sku: "Sku HERE",
    rating: 4.5,
  ),
  ProductModel(
    image: productDemoImg6,
    title: "Green Poplin Ruched Front",
    brandName: "Lipsy london",
    price: 1264,
    priceAfterDiscount: 1200.8,
    discountPercent: 5,
    category: "",
    sku: "Sku HERE",
    rating: 4.5,
  ),
  ProductModel(
    image: "",
    title: "Green Poplin Ruched Front",
    brandName: "Lipsy london",
    price: 650.62,
    priceAfterDiscount: 390.36,
    discountPercent: 40,
    category: "",
    sku: "Sku HERE",
    rating: 4.5,
  ),
  ProductModel(
    image: "",
    title: "white satin corset top",
    brandName: "Lipsy london",
    price: 1264,
    priceAfterDiscount: 1200.8,
    discountPercent: 5,
    category: "",
    sku: "Sku HERE",
    rating: 4.5,
  ),
];
List<ProductModel> demoFlashSaleProducts = [
  ProductModel(
    image: productDemoImg5,
    title: "FS - Nike Air Max 270 Really React",
    brandName: "Lipsy london",
    price: 650.62,
    priceAfterDiscount: 390.36,
    discountPercent: 40,
    category: "",
    sku: "Sku HERE",
    rating: 4.5,
  ),
  ProductModel(
    image: productDemoImg6,
    title: "Green Poplin Ruched Front",
    brandName: "Lipsy london",
    price: 1264,
    priceAfterDiscount: 1200.8,
    discountPercent: 5,
    category: "",
    sku: "Sku HERE",
    rating: 4.5,
  ),
  ProductModel(
    image: productDemoImg4,
    title: "Mountain Beta Warehouse",
    brandName: "Lipsy london",
    price: 800,
    priceAfterDiscount: 680,
    discountPercent: 15,
    category: "",
    sku: "Sku HERE",
    rating: 4.5,
  ),
];
List<ProductModel> demoBestSellersProducts = [
  ProductModel(
    image: "",
    title: "Green Poplin Ruched Front",
    brandName: "Lipsy london",
    price: 650.62,
    priceAfterDiscount: 390.36,
    discountPercent: 40,
    category: "",
    sku: "Sku HERE",
    rating: 4.5,
  ),
  ProductModel(
    image: "",
    title: "white satin corset top",
    brandName: "Lipsy london",
    price: 1264,
    priceAfterDiscount: 1200.8,
    discountPercent: 5,
    category: "",
    sku: "Sku HERE",
    rating: 4.5,
  ),
  ProductModel(
    image: productDemoImg4,
    title: "Mountain Beta Warehouse",
    brandName: "Lipsy london",
    price: 800,
    priceAfterDiscount: 680,
    discountPercent: 15,
    category: "",
    sku: "Sku HERE",
    rating: 4.5,
  ),
];
List<ProductModel> kidsProducts = [
  ProductModel(
    image: "",
    title: "Green Poplin Ruched Front",
    brandName: "Lipsy london",
    price: 650.62,
    priceAfterDiscount: 590.36,
    discountPercent: 24,
    category: "",
    sku: "Sku HERE",
    rating: 4.5,
  ),
  ProductModel(
    image: "",
    title: "Printed Sleeveless Tiered Swing Dress",
    brandName: "Lipsy london",
    price: 650.62,
    category: "",
    sku: "Sku HERE",
    rating: 4.5,
  ),
  ProductModel(
    image: "",
    title: "Ruffle-Sleeve Ponte-Knit Sheath ",
    brandName: "Lipsy london",
    price: 400,
    category: "",
    sku: "Sku HERE",
    rating: 4.5,
  ),
  ProductModel(
    image: "",
    title: "Green Mountain Beta Warehouse",
    brandName: "Lipsy london",
    price: 400,
    priceAfterDiscount: 360,
    discountPercent: 20,
    category: "",
    sku: "Sku HERE",
    rating: 4.5,
  ),
  ProductModel(
    image: "",
    title: "Printed Sleeveless Tiered Swing Dress",
    brandName: "Lipsy london",
    price: 654,
    category: "",
    sku: "Sku HERE",
    rating: 4.5,
  ),
  ProductModel(
    image: "",
    title: "Mountain Beta Warehouse",
    brandName: "Lipsy london",
    price: 250,
    category: "",
    sku: "Sku HERE",
    rating: 4.5,
  ),
];
