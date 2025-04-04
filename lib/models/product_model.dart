// For demo only
import 'package:shop/constants.dart';

class ProductModel {
  final String image, brandName, title;
  final double price;
  final double? priceAfterDiscount;
  final int? discountPercent;

  ProductModel({
    required this.image,
    required this.brandName,
    required this.title,
    required this.price,
    this.priceAfterDiscount,
    this.discountPercent,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      image: json['image'] ?? "",
      brandName: json['brand_name'] ?? "Unknown Brand",
      title: json['title'] ?? "No Title",
      price: (json['price'] as num).toDouble(),
      priceAfterDiscount: json['price_after_discount'] != null
          ? (json['price_after_discount'] as num).toDouble()
          : null,
      discountPercent: json['discount_percent'],
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
  ),
  ProductModel(
    image: productDemoImg4,
    title: "Mountain Beta Warehouse",
    brandName: "Lipsy london",
    price: 800,
  ),
  ProductModel(
    image: productDemoImg5,
    title: "FS - Nike Air Max 270 Really React",
    brandName: "Lipsy london",
    price: 650.62,
    priceAfterDiscount: 390.36,
    discountPercent: 40,
  ),
  ProductModel(
    image: productDemoImg6,
    title: "Green Poplin Ruched Front",
    brandName: "Lipsy london",
    price: 1264,
    priceAfterDiscount: 1200.8,
    discountPercent: 5,
  ),
  ProductModel(
    image: "",
    title: "Green Poplin Ruched Front",
    brandName: "Lipsy london",
    price: 650.62,
    priceAfterDiscount: 390.36,
    discountPercent: 40,
  ),
  ProductModel(
    image: "",
    title: "white satin corset top",
    brandName: "Lipsy london",
    price: 1264,
    priceAfterDiscount: 1200.8,
    discountPercent: 5,
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
  ),
  ProductModel(
    image: productDemoImg6,
    title: "Green Poplin Ruched Front",
    brandName: "Lipsy london",
    price: 1264,
    priceAfterDiscount: 1200.8,
    discountPercent: 5,
  ),
  ProductModel(
    image: productDemoImg4,
    title: "Mountain Beta Warehouse",
    brandName: "Lipsy london",
    price: 800,
    priceAfterDiscount: 680,
    discountPercent: 15,
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
  ),
  ProductModel(
    image: "",
    title: "white satin corset top",
    brandName: "Lipsy london",
    price: 1264,
    priceAfterDiscount: 1200.8,
    discountPercent: 5,
  ),
  ProductModel(
    image: productDemoImg4,
    title: "Mountain Beta Warehouse",
    brandName: "Lipsy london",
    price: 800,
    priceAfterDiscount: 680,
    discountPercent: 15,
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
  ),
  ProductModel(
    image: "",
    title: "Printed Sleeveless Tiered Swing Dress",
    brandName: "Lipsy london",
    price: 650.62,
  ),
  ProductModel(
    image: "",
    title: "Ruffle-Sleeve Ponte-Knit Sheath ",
    brandName: "Lipsy london",
    price: 400,
  ),
  ProductModel(
    image: "",
    title: "Green Mountain Beta Warehouse",
    brandName: "Lipsy london",
    price: 400,
    priceAfterDiscount: 360,
    discountPercent: 20,
  ),
  ProductModel(
    image: "",
    title: "Printed Sleeveless Tiered Swing Dress",
    brandName: "Lipsy london",
    price: 654,
  ),
  ProductModel(
    image: "",
    title: "Mountain Beta Warehouse",
    brandName: "Lipsy london",
    price: 250,
  ),
];
