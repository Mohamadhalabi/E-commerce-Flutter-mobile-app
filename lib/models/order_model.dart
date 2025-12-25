import 'package:shop/models/product_model.dart';

class OrderModel {
  final int id;
  final String uuid;
  final String status;
  final String paymentStatus;
  final String paymentMethod;
  final String shippingMethod;
  final String shippingAmount;
  final String total;
  final String createdAt;
  final List<OrderItemModel> items;
  final OrderAddressModel? address;

  OrderModel({
    required this.id,
    required this.uuid,
    required this.status,
    required this.paymentStatus,
    required this.paymentMethod,
    required this.shippingMethod,
    required this.shippingAmount,
    required this.total,
    required this.createdAt,
    this.items = const [],
    this.address,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      id: json['id'],
      uuid: json['uuid'] ?? '',
      status: json['status'] ?? 'pending',
      paymentStatus: json['payment_status'] ?? '',
      paymentMethod: json['payment_method'] ?? '',
      shippingMethod: json['shipping_method'] ?? '',
      shippingAmount: json['shipping_amount']?.toString() ?? '0.00',
      total: json['total']?.toString() ?? '0.00',
      createdAt: json['created_at'] ?? '',
      items: (json['items'] as List<dynamic>?)
          ?.map((item) => OrderItemModel.fromJson(item))
          .toList() ??
          [],
      address: json['address'] != null ? OrderAddressModel.fromJson(json['address']) : null,
    );
  }
}

class OrderItemModel {
  final int id;
  final int productId; // <--- ADD THIS
  final String productName;
  final String price;
  final int quantity;
  final String image;

  OrderItemModel({
    required this.id,
    required this.productId, // <--- ADD THIS
    required this.productName,
    required this.price,
    required this.quantity,
    required this.image,
  });

  factory OrderItemModel.fromJson(Map<String, dynamic> json) {
    return OrderItemModel(
      id: json['id'],
      // Ensure your backend OrderResource sends 'product_id' inside the items array
      productId: json['product_id'] ?? 0,
      productName: json['product_name'] ?? 'Unknown',
      price: json['price']?.toString() ?? '0.00',
      quantity: json['quantity'] ?? 1,
      image: json['image'] ?? '',
    );
  }
}

class OrderAddressModel {
  final String address;
  final String city;
  final String phone;

  OrderAddressModel({required this.address, required this.city, required this.phone});

  factory OrderAddressModel.fromJson(Map<String, dynamic> json) {
    return OrderAddressModel(
      address: json['address'] ?? '',
      city: json['city'] ?? '',
      phone: json['phone'] ?? '',
    );
  }
}