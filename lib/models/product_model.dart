import 'package:shop/constants.dart';

class ProductModel {
  final String image, brandName, title, category, sku;
  final double price, rating;
  final double? salePrice;
  final int? discountPercent, id;
  final bool? freeShipping;
  final Map<String, dynamic>? discount;

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
    );
  }
}

List<ProductModel> demoPopularProducts = [
  ProductModel(
    id: 11,
    image: productDemoImg1,
    title: "Mountain Warehouse for Women",
    brandName: "Lipsy london",
    price: 540,
    salePrice: 420,
    discountPercent: 20,
    category: "",
    sku: "Sku HERE",
    rating: 4.5,
  ),
  ProductModel(
    id: 11,
    image: productDemoImg4,
    title: "Mountain Beta Warehouse",
    brandName: "Lipsy london",
    price: 800,
    category: "",
    sku: "Sku HERE",
    rating: 4.5,
  ),
  ProductModel(
    id: 11,
    image: productDemoImg5,
    title: "FS - Nike Air Max 270 Really React",
    brandName: "Lipsy london",
    price: 650.62,
    salePrice: 390.36,
    discountPercent: 40,
    category: "",
    sku: "Sku HERE",
    rating: 4.5,
  ),
  ProductModel(
    id: 11,
    image: productDemoImg6,
    title: "Green Poplin Ruched Front",
    brandName: "Lipsy london",
    price: 1264,
    salePrice: 1200.8,
    discountPercent: 5,
    category: "",
    sku: "Sku HERE",
    rating: 4.5,
  ),
  ProductModel(
    id: 11,
    image: "",
    title: "Green Poplin Ruched Front",
    brandName: "Lipsy london",
    price: 650.62,
    salePrice: 390.36,
    discountPercent: 40,
    category: "",
    sku: "Sku HERE",
    rating: 4.5,
  ),
  ProductModel(
    id: 11,
    image: "",
    title: "white satin corset top",
    brandName: "Lipsy london",
    price: 1264,
    salePrice: 1200.8,
    discountPercent: 5,
    category: "",
    sku: "Sku HERE",
    rating: 4.5,
  ),
];
List<ProductModel> demoFlashSaleProducts = [
  ProductModel(
    id: 11,
    image: productDemoImg5,
    title: "FS - Nike Air Max 270 Really React",
    brandName: "Lipsy london",
    price: 650.62,
    salePrice: 390.36,
    discountPercent: 40,
    category: "",
    sku: "Sku HERE",
    rating: 4.5,
  ),
  ProductModel(
    id: 11,
    image: productDemoImg6,
    title: "Green Poplin Ruched Front",
    brandName: "Lipsy london",
    price: 1264,
    salePrice: 1200.8,
    discountPercent: 5,
    category: "",
    sku: "Sku HERE",
    rating: 4.5,
  ),
  ProductModel(
    id: 11,
    image: productDemoImg4,
    title: "Mountain Beta Warehouse",
    brandName: "Lipsy london",
    price: 800,
    salePrice: 680,
    discountPercent: 15,
    category: "",
    sku: "Sku HERE",
    rating: 4.5,
  ),
];
List<ProductModel> demoBestSellersProducts = [
  ProductModel(
    id: 11,
    image: "",
    title: "Green Poplin Ruched Front",
    brandName: "Lipsy london",
    price: 650.62,
    salePrice: 390.36,
    discountPercent: 40,
    category: "",
    sku: "Sku HERE",
    rating: 4.5,
  ),
  ProductModel(
    id: 11,
    image: "",
    title: "white satin corset top",
    brandName: "Lipsy london",
    price: 1264,
    salePrice: 1200.8,
    discountPercent: 5,
    category: "",
    sku: "Sku HERE",
    rating: 4.5,
  ),
  ProductModel(
    id: 11,
    image: productDemoImg4,
    title: "Mountain Beta Warehouse",
    brandName: "Lipsy london",
    price: 800,
    salePrice: 680,
    discountPercent: 15,
    category: "",
    sku: "Sku HERE",
    rating: 4.5,
  ),
];
List<ProductModel> kidsProducts = [
  ProductModel(
    id: 11,
    image: "",
    title: "Green Poplin Ruched Front",
    brandName: "Lipsy london",
    price: 650.62,
    salePrice: 590.36,
    discountPercent: 24,
    category: "",
    sku: "Sku HERE",
    rating: 4.5,
  ),
  ProductModel(
    id: 11,
    image: "",
    title: "Printed Sleeveless Tiered Swing Dress",
    brandName: "Lipsy london",
    price: 650.62,
    category: "",
    sku: "Sku HERE",
    rating: 4.5,
  ),
  ProductModel(
    id: 11,
    image: "",
    title: "Ruffle-Sleeve Ponte-Knit Sheath ",
    brandName: "Lipsy london",
    price: 400,
    category: "",
    sku: "Sku HERE",
    rating: 4.5,
  ),
  ProductModel(
    id: 11,
    image: "",
    title: "Green Mountain Beta Warehouse",
    brandName: "Lipsy london",
    price: 400,
    salePrice: 360,
    discountPercent: 20,
    category: "",
    sku: "Sku HERE",
    rating: 4.5,
  ),
  ProductModel(
    id: 11,
    image: "",
    title: "Printed Sleeveless Tiered Swing Dress",
    brandName: "Lipsy london",
    price: 654,
    category: "",
    sku: "Sku HERE",
    rating: 4.5,
  ),
  ProductModel(
    id: 11,
    image: "",
    title: "Mountain Beta Warehouse",
    brandName: "Lipsy london",
    price: 250,
    category: "",
    sku: "Sku HERE",
    rating: 4.5,
  ),
];
