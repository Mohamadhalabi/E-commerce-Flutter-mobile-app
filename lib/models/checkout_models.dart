import 'package:shop/models/address_model.dart';
// Note: We removed ProductModel import because we are defining a specific QuoteItem class below
// to handle the checkout-specific fields (unit, line, etc.)

class Quote {
  final List<QuoteItem> products; // Changed from ProductModel to QuoteItem
  final List<AddressModel> addresses;
  final int? selectedAddressId;
  final QuoteShipping shipping;
  final QuoteSummary summary;
  final CheckoutBlock? checkoutBlock;
  final QuotePromotions? promotions;
  final QuoteCoupon? coupon;

  Quote({
    required this.products,
    required this.addresses,
    this.selectedAddressId,
    required this.shipping,
    required this.summary,
    this.checkoutBlock,
    this.promotions,
    this.coupon,
  });

  factory Quote.fromJson(Map<String, dynamic> json) {
    // Handle generic 'data' wrapper if present
    final data = json.containsKey('data') ? json['data'] : json;

    return Quote(
      products: (data['products'] as List?)
          ?.map((e) => QuoteItem.fromJson(e))
          .toList() ?? [],
      addresses: (data['addresses'] as List?)
          ?.map((e) => AddressModel.fromJson(e))
          .toList() ?? [],
      selectedAddressId: int.tryParse(data['selected_address_id'].toString()),

      shipping: data['shipping'] is Map<String, dynamic>
          ? QuoteShipping.fromJson(data['shipping'])
          : QuoteShipping(options: []),

      summary: data['summary'] is Map<String, dynamic>
          ? QuoteSummary.fromJson(data['summary'])
          : QuoteSummary.empty(),

      checkoutBlock: data['checkout_block'] is Map<String, dynamic>
          ? CheckoutBlock.fromJson(data['checkout_block'])
          : null,

      promotions: data['promotions'] is Map<String, dynamic>
          ? QuotePromotions.fromJson(data['promotions'])
          : null,

      coupon: data['coupon'] is Map<String, dynamic>
          ? QuoteCoupon.fromJson(data['coupon'])
          : null,
    );
  }
}

// ✅ NEW CLASS: Handles the specific structure of items in the Checkout Quote
class QuoteItem {
  final String productId;
  final String title;
  final String sku;
  final String image;
  final int quantity;
  final double price; // Unit price (mapped from 'unit')
  final double total; // Line total (mapped from 'line')

  QuoteItem({
    required this.productId,
    required this.title,
    required this.sku,
    required this.image,
    required this.quantity,
    required this.price,
    required this.total,
  });

  factory QuoteItem.fromJson(Map<String, dynamic> json) {
    // Helper to safely parse doubles
    double parseDouble(dynamic val) {
      if (val == null) return 0.0;
      return double.tryParse(val.toString()) ?? 0.0;
    }

    return QuoteItem(
      productId: json['product_id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      sku: json['sku']?.toString() ?? '',
      image: json['image']?.toString() ?? '',
      quantity: int.tryParse(json['quantity']?.toString() ?? '1') ?? 1,

      // ✅ VITAL FIX: Map 'unit' from API to 'price'
      price: json['unit'] != null ? parseDouble(json['unit']) : parseDouble(json['price']),

      // ✅ VITAL FIX: Map 'line' from API to 'total'
      total: json['line'] != null ? parseDouble(json['line']) : parseDouble(json['total']),
    );
  }
}

class QuoteShipping {
  final List<ShippingOption> options;
  final String? selected;

  QuoteShipping({required this.options, this.selected});

  factory QuoteShipping.fromJson(Map<String, dynamic> json) {
    return QuoteShipping(
      options: (json['options'] as List?)
          ?.map((e) => ShippingOption.fromJson(e))
          .toList() ?? [],
      selected: json['selected']?.toString(),
    );
  }
}

class ShippingOption {
  final String key;
  final String label;
  final double price;
  final bool disabled;

  ShippingOption({required this.key, required this.label, required this.price, this.disabled = false});

  factory ShippingOption.fromJson(Map<String, dynamic> json) {
    double safeParse(dynamic value) {
      if (value == null) return 0.0;
      String str = value.toString().replaceAll(RegExp(r'[$,]'), '');
      return double.tryParse(str) ?? 0.0;
    }

    double foundPrice = 0.0;
    if (json.containsKey('price')) foundPrice = safeParse(json['price']);
    else if (json.containsKey('cost')) foundPrice = safeParse(json['cost']);
    else if (json.containsKey('rate')) foundPrice = safeParse(json['rate']);
    else if (json.containsKey('amount')) foundPrice = safeParse(json['amount']);

    return ShippingOption(
      key: json['key']?.toString() ?? '',
      label: json['label']?.toString() ?? json['name']?.toString() ?? 'Shipping',
      price: foundPrice,
      disabled: json['disabled'] == true,
    );
  }
}

class QuoteSummary {
  final double subTotal;
  final double shipping;
  final double couponDiscount;
  final double promoDiscount;
  final double total;

  QuoteSummary({
    required this.subTotal,
    required this.shipping,
    required this.couponDiscount,
    required this.promoDiscount,
    required this.total,
  });

  factory QuoteSummary.empty() => QuoteSummary(subTotal: 0, shipping: 0, couponDiscount: 0, promoDiscount: 0, total: 0);

  factory QuoteSummary.fromJson(Map<String, dynamic> json) {
    return QuoteSummary(
      subTotal: double.tryParse(json['sub_total'].toString()) ?? 0.0,
      shipping: double.tryParse(json['shipping'].toString()) ?? 0.0,
      couponDiscount: double.tryParse(json['coupon_discount'].toString()) ?? 0.0,
      promoDiscount: double.tryParse(json['promo_discount'].toString()) ?? 0.0,
      total: double.tryParse(json['total'].toString()) ?? 0.0,
    );
  }
}

class CheckoutBlock {
  final bool isBlocked;
  final String? message;
  final String? countryName;

  CheckoutBlock({required this.isBlocked, this.message, this.countryName});

  factory CheckoutBlock.fromJson(Map<String, dynamic> json) {
    return CheckoutBlock(
      isBlocked: json['is_blocked'] == true,
      message: json['message']?.toString(),
      countryName: json['country_name']?.toString(),
    );
  }
}

class QuotePromotions {
  final Map<String, bool> eligible;
  final String selected;
  final Map<String, double> savings;
  final Map<String, String> notes;

  QuotePromotions({
    required this.eligible,
    required this.selected,
    required this.savings,
    required this.notes,
  });

  factory QuotePromotions.fromJson(Map<String, dynamic> json) {
    return QuotePromotions(
      eligible: Map<String, bool>.from(json['eligible'] ?? {}),
      selected: json['selected']?.toString() ?? 'none',
      savings: (json['savings'] as Map<String, dynamic>?)?.map((k, v) => MapEntry(k, double.tryParse(v.toString()) ?? 0.0)) ?? {},
      notes: Map<String, String>.from(json['notes'] ?? {}),
    );
  }
}

class QuoteCoupon {
  final String code;
  final bool applied;
  final String? message;
  final double discountValue;

  QuoteCoupon({required this.code, required this.applied, this.message, required this.discountValue});

  factory QuoteCoupon.fromJson(Map<String, dynamic> json) {
    return QuoteCoupon(
      code: json['code']?.toString() ?? '',
      applied: json['applied'] == true,
      message: json['message']?.toString(),
      discountValue: double.tryParse(json['discount_value'].toString()) ?? 0.0,
    );
  }
}