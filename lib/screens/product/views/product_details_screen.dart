import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:provider/provider.dart';

import 'package:shop/providers/cart_provider.dart';
import '../../../components/skleton/product_details_skeleton.dart';
import '../../../models/product_model.dart';
import '../../../route/route_constants.dart';
import '../../../constants.dart';

// --- COMPONENTS IMPORTS ---
import 'package:shop/screens/product/views/components/product_attributes.dart';
import '../../../components/common/drawer.dart';
import '../../../components/common/CustomBottomNavigationBar.dart';
import '../../../components/product/related_products.dart';
import '../../../services/api_service.dart';
import '../../../services/local_storage_service.dart';
import 'components/expandable_section.dart';
import 'components/product_images.dart';
import 'components/product_info.dart';

class ProductDetailsScreen extends StatefulWidget {
  const ProductDetailsScreen({
    super.key,
    required this.productId,
    required this.onLocaleChange,
  });

  final Function(String) onLocaleChange;
  final int productId;

  @override
  State<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen> {
  Map<String, dynamic>? product;
  bool isLoading = true;
  String? _currentLocale;
  int _currentIndex = 0;
  int _quantity = 1;

  Map<String, dynamic>? user = {
    "name": "Guest User",
    "email": "guest@example.com",
  };

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final locale = Localizations.localeOf(context).languageCode;
    if (_currentLocale != locale) {
      _currentLocale = locale;
      fetchProductDetails();
    }
  }

  Future<void> fetchProductDetails() async {
    if (_currentLocale == null) return;
    setState(() => isLoading = true);

    try {
      final result = await ApiService.fetchProductDetails(
        widget.productId,
        _currentLocale!,
      );

      try {
        ProductModel pModel = ProductModel.fromJson(result);
        await LocalStorageService.addToRecentlyViewed(pModel);
      } catch (e) {
        print("Error saving recent view: $e");
      }

      setState(() {
        product = result;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  // Navigation Logic
  void _onBottomNavTap(int index) {
    if (index == 0) {
      Navigator.popUntil(context, (route) => route.isFirst);
    } else if (index == 3) {
      Navigator.pushNamed(context, cartScreenRoute);
    } else {
      setState(() => _currentIndex = index);
    }
  }

  double _calculateUnitPrice(int qty) {
    if (product == null) return 0.0;

    double finalPrice = (product!['price'] as num).toDouble();

    if (product!['table_price'] is List && (product!['table_price'] as List).isNotEmpty) {
      List tiers = product!['table_price'];
      for (var tier in tiers) {
        int min = tier['min_qty'] ?? tier['from'];
        int? max = tier['max_qty'] ?? tier['to'];
        if (qty >= min && (max == null || qty <= max)) {
          finalPrice = (tier['price'] as num).toDouble();
          break;
        }
      }
    }

    if (product!['discount'] != null && product!['discount'] is Map) {
      var d = product!['discount'];
      if (d.isNotEmpty) {
        double val = (d['value'] as num).toDouble();
        if (d['type'] == 'percent') {
          finalPrice = finalPrice - (finalPrice * (val / 100));
        } else if (d['type'] == 'fixed') {
          finalPrice = finalPrice - val;
        }
      }
    }

    return finalPrice < 0 ? 0 : finalPrice;
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) return const ProductDetailsSkeleton();

    if (product == null) {
      return Scaffold(
        appBar: AppBar(leading: const BackButton()),
        body: const Center(child: Text("Product not found.")),
      );
    }

    double currentUnitPrice = _calculateUnitPrice(_quantity);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent, // Keeps header white on scroll
        elevation: 0,

        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black),
          onPressed: () => Navigator.canPop(context) ? Navigator.pop(context) : null,
        ),
        title: Text(
          product?['title'] ?? "",
          style: const TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.w600),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_bag_outlined, color: Colors.black),
            onPressed: () => Navigator.pushNamed(context, cartScreenRoute),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4.0),
          child: Container(
            // ERROR WAS HERE: "color: Colors.white," -> REMOVED
            height: 1.0,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white, // Color must be inside decoration
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.4),
                  offset: const Offset(0, 2),
                  blurRadius: 4.0,
                ),
              ],
            ),
          ),
        ),
      ),
      drawer: CustomEndDrawer(
        onLocaleChange: widget.onLocaleChange,
        user: user,
        onTabChanged: (int _) {},
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          BottomCartAction(
            unitPrice: currentUnitPrice,
            quantity: _quantity,
            onQtyChanged: (val) => setState(() => _quantity = val),
            onAddToCart: () {
              final cart = Provider.of<CartProvider>(context, listen: false);

              String imgUrl = "";
              if (product!['image'] != null) {
                imgUrl = product!['image'];
              } else if (product!['gallery'] != null && (product!['gallery'] as List).isNotEmpty) {
                imgUrl = product!['gallery'][0];
              }

              String sku = product!['sku'] ?? 'N/A';
              int stock = (product!['quantity'] as num?)?.toInt() ?? 0;

              cart.addToCart(
                productId: widget.productId,
                title: product!['title'] ?? 'Unknown',
                sku: sku,
                image: imgUrl,
                price: currentUnitPrice,
                quantity: _quantity,
                stock: stock,
                context: context,
              );
            },
          ),
          CustomBottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: _onBottomNavTap,
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: fetchProductDetails,
          color: primaryColor,
          child: CustomScrollView(
            slivers: [
              // 1. PRODUCT IMAGES (With Bottom Border)
              SliverToBoxAdapter(
                child: Container(
                  decoration: const BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Color(0xFFF0F0F0), width: 1),
                    ),
                  ),
                  child: Stack(
                    children: [
                      ProductImages(
                        images: (product?['gallery'] as List<dynamic>?)
                            ?.map((item) => item as String)
                            .toList() ?? [],
                        isBestSeller: product?['is_best_seller'] == 1,
                      ),
                      if (product!['discount'] is Map && (product!['discount'] as Map).isNotEmpty)
                        Positioned(
                          top: 16,
                          right: 16,
                          child: DiscountTimerBanner(discount: product!['discount'], isBadge: true),
                        ),
                    ],
                  ),
                ),
              ),

              // 2. PRODUCT INFO
              ProductInfo(
                category: product!['category'] ?? "Unknown",
                sku: product!['sku'] ?? "Unknown",
                title: product!['title'] ?? "Unknown",
                summaryName: product!['summary_name'] ?? "",
                rating: (product!['rating'] is Map)
                    ? (product!['rating']['average'] as num?)?.toDouble() ?? 0.0
                    : (product!['rating'] as num?)?.toDouble() ?? 0.0,
                numOfReviews: (product!['rating'] is Map)
                    ? (product!['rating']['count'] as num?)?.toInt() ?? 0
                    : product!['num_of_reviews'] ?? 0,
              ),

              const SliverToBoxAdapter(child: Divider(thickness: 1, color: Color(0xFFF0F0F0))),

              // 3. BULK SAVINGS TABLE
              if (product!['table_price'] is List && (product!['table_price'] as List).isNotEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: ModernTablePriceList(tiers: List<Map<String, dynamic>>.from(product!['table_price'])),
                  ),
                ),

              // 4. DISCOUNT TIMER
              if (product!['discount'] is Map && (product!['discount'] as Map).isNotEmpty)
                SliverToBoxAdapter(
                  child: DiscountTimerBanner(discount: product!['discount'], isBadge: false),
                ),

              // 5. ATTRIBUTES
              if (product!['attributes'] != null)
                ExpandableSection(
                  title: "Product Specifications",
                  initiallyExpanded: true,
                  leadingIcon: Icons.tune_outlined,
                  child: ProductAttributes(attributes: product!['attributes']),
                ),

              const SliverToBoxAdapter(child: Divider(thickness: 1, color: Color(0xFFF0F0F0))),

              // 6. DESCRIPTION
              ExpandableSection(
                title: "Description",
                leadingIcon: Icons.notes_outlined,
                child: Html(
                  data: product!['description'] ?? "",
                  style: {
                    "body": Style(
                      fontSize: FontSize(14.0),
                      color: Colors.black87,
                      lineHeight: LineHeight(1.5),
                    ),
                  },
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 16)),

              // 7. RELATED PRODUCTS
              SliverToBoxAdapter(
                child: Container(
                  color: const Color(0xFFF9F9F9),
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          "You might also like",
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(height: 16),
                      RelatedProducts(productId: widget.productId),
                    ],
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 30)),
            ],
          ),
        ),
      ),
    );
  }
}

// --- SUPPORTING WIDGETS ---

class BottomCartAction extends StatelessWidget {
  final double unitPrice;
  final int quantity;
  final Function(int) onQtyChanged;
  final VoidCallback onAddToCart;

  const BottomCartAction({
    super.key,
    required this.unitPrice,
    required this.quantity,
    required this.onQtyChanged,
    required this.onAddToCart,
  });

  @override
  Widget build(BuildContext context) {
    double total = unitPrice * quantity;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(0, -2),
            blurRadius: 10,
          )
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => quantity > 1 ? onQtyChanged(quantity - 1) : null,
                    icon: const Icon(Icons.remove, size: 20, color: Colors.black54),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                  ),
                  Text("$quantity", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  IconButton(
                    onPressed: () => onQtyChanged(quantity + 1),
                    icon: const Icon(Icons.add, size: 20, color: Colors.black54),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Consumer<CartProvider>(
                builder: (context, cart, child) {
                  return ElevatedButton(
                    onPressed: cart.isLoading ? null : onAddToCart,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: cart.isLoading
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.shopping_cart_outlined, size: 20, color: Colors.white),
                        const SizedBox(width: 8),
                        Text(
                          "Add \$${total.toStringAsFixed(2)}",
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DiscountTimerBanner extends StatefulWidget {
  final Map<String, dynamic> discount;
  final bool isBadge;
  const DiscountTimerBanner({super.key, required this.discount, this.isBadge = false});

  @override
  State<DiscountTimerBanner> createState() => _DiscountTimerBannerState();
}

class _DiscountTimerBannerState extends State<DiscountTimerBanner> {
  late Timer _timer;
  Duration _timeLeft = Duration.zero;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    if (widget.discount['end_date'] == null) return;
    try {
      DateTime end = DateTime.parse(widget.discount['end_date']);
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (!mounted) {
          timer.cancel();
          return;
        }
        final now = DateTime.now();
        if (end.isAfter(now)) {
          setState(() {
            _timeLeft = end.difference(now);
          });
        } else {
          timer.cancel();
          setState(() => _timeLeft = Duration.zero);
        }
      });
    } catch (e) {}
  }

  @override
  void dispose() {
    if (mounted && _timer.isActive) _timer.cancel();
    super.dispose();
  }

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    return "${d.inDays}d ${twoDigits(d.inHours.remainder(24))}h ${twoDigits(d.inMinutes.remainder(60))}m ${twoDigits(d.inSeconds.remainder(60))}s";
  }

  @override
  Widget build(BuildContext context) {
    final value = widget.discount['value'];
    final type = widget.discount['type'];

    if (widget.isBadge) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
            color: const Color(0xFFFF3B30),
            borderRadius: BorderRadius.circular(4),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 4, offset: const Offset(0, 2))
            ]
        ),
        child: Text(
          type == 'percent' ? "$value% OFF" : "\$$value OFF",
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF0F0),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.red.shade100, width: 1),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
            child: const Icon(Icons.local_fire_department, color: Colors.red, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Hurry up! Offer ends in:", style: TextStyle(color: Colors.red.shade700, fontSize: 11, fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
                Text(_formatDuration(_timeLeft), style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 16, fontFamily: 'monospace')),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(6)),
            child: Text("- ${type == 'percent' ? '$value%' : '\$$value'}", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

class ModernTablePriceList extends StatelessWidget {
  final List<Map<String, dynamic>> tiers;
  const ModernTablePriceList({super.key, required this.tiers});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.inventory_2_outlined, size: 18, color: Colors.black87),
            SizedBox(width: 8),
            Text("Bulk Savings", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          ],
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: tiers.map((tier) {
              final min = tier['min_qty'] ?? tier['from'];
              final max = tier['max_qty'] ?? tier['to'];
              final price = tier['price'];
              return Container(
                width: 100,
                margin: const EdgeInsets.only(right: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  children: [
                    Text(max != null ? "$min-$max" : "$min+", style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 6),
                    Text("\$${(price as num).toStringAsFixed(2)}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87)),
                    const SizedBox(height: 4),
                    const Text("per unit", style: TextStyle(fontSize: 10, color: Colors.grey)),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}