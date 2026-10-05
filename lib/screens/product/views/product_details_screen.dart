import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:shop/providers/cart_provider.dart';
import '../../../components/skleton/product_details_skeleton.dart';
import '../../../models/product_model.dart';
import '../../../route/route_constants.dart';
import '../../../constants.dart';

// --- COMPONENTS IMPORTS ---
import 'package:shop/screens/product/views/components/product_attributes.dart';
import '../../../components/common/drawer.dart';
import '../../../components/common/glass_bottom_nav.dart';
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
  final int _currentIndex = 0;
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

  /// [showSkeleton] is false for pull-to-refresh so the page doesn't blank out.
  Future<void> fetchProductDetails({bool showSkeleton = true}) async {
    if (_currentLocale == null) return;
    if (showSkeleton) setState(() => isLoading = true);

    try {
      final result = await ApiService.fetchProductDetails(
        widget.productId,
        _currentLocale!,
      );

      try {
        final pModel = ProductModel.fromJson(result);
        await LocalStorageService.addToRecentlyViewed(pModel);
      } catch (e) {
        debugPrint("Error saving recent view: $e");
      }

      if (!mounted) return;
      setState(() {
        product = result;
        isLoading = false;
      });
    } catch (e) {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _onBottomNavTap(int index) {
    if (index == 3) {
      Navigator.pushNamed(context, cartScreenRoute);
    } else {
      Navigator.pushNamedAndRemoveUntil(
        context,
        entryPointScreenRoute,
            (route) => false,
        arguments: index,
      );
    }
  }

  static int? _toInt(dynamic v) => v == null ? null : int.tryParse('$v');

  double _calculateUnitPrice(int qty) {
    if (product == null) return 0.0;

    double finalPrice = (product!['price'] as num).toDouble();

    if (product!['table_price'] is List &&
        (product!['table_price'] as List).isNotEmpty) {
      for (final tier in product!['table_price'] as List) {
        final min = _toInt(tier['min_qty'] ?? tier['from']) ?? 1;
        final max = _toInt(tier['max_qty'] ?? tier['to']);
        if (qty >= min && (max == null || qty <= max)) {
          finalPrice = (tier['price'] as num).toDouble();
          break;
        }
      }
    }

    if (product!['discount'] is Map) {
      final d = product!['discount'] as Map;
      if (d.isNotEmpty && d['value'] != null) {
        final val = (d['value'] as num).toDouble();
        if (d['type'] == 'percent') {
          finalPrice = finalPrice - (finalPrice * (val / 100));
        } else if (d['type'] == 'fixed') {
          finalPrice = finalPrice - val;
        }
      }
    }

    return finalPrice < 0 ? 0 : finalPrice;
  }

  bool _parseBool(dynamic value) {
    if (value == null) return false;
    if (value is bool) return value;
    if (value is int) return value == 1;
    if (value is String) return value == '1' || value.toLowerCase() == 'true';
    return false;
  }

  void _addToCart(double unitPrice) {
    final p = product!;
    final cart = Provider.of<CartProvider>(context, listen: false);

    String imgUrl = "";
    if (p['image'] != null) {
      imgUrl = p['image'];
    } else if (p['gallery'] is List && (p['gallery'] as List).isNotEmpty) {
      imgUrl = p['gallery'][0];
    }

    cart.addToCart(
      productId: widget.productId,
      title: p['title'] ?? 'Unknown',
      sku: p['sku'] ?? 'N/A',
      image: imgUrl,
      price: unitPrice,
      quantity: _quantity,
      stock: (p['quantity'] as num?)?.toInt() ?? 0,
      context: context,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) return const ProductDetailsSkeleton();
    if (product == null) {
      return _NotFound(onRetry: () => fetchProductDetails());
    }

    final p = product!;
    final isDark = AppPalette.isDark(context);
    final bg = Theme.of(context).scaffoldBackgroundColor;
    final cartCount =
    context.select<CartProvider, int>((c) => c.cartItems.length);

    final originalPrice = (p['price'] as num).toDouble();
    final baseUnitPrice = _calculateUnitPrice(1);
    final currentUnitPrice = _calculateUnitPrice(_quantity);
    final hidePrice = _parseBool(p['hide_price']);
    final hasDiscount = p['discount'] is Map && (p['discount'] as Map).isNotEmpty;
    final tiers = p['table_price'] is List && (p['table_price'] as List).isNotEmpty
        ? List<Map<String, dynamic>>.from(p['table_price'])
        : <Map<String, dynamic>>[];

    Widget divider() => SliverToBoxAdapter(
      child: Divider(
        height: 24,
        thickness: 1,
        indent: defaultPadding,
        endIndent: defaultPadding,
        color: AppPalette.border(context),
      ),
    );

    return Scaffold(
      extendBody: true,
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        automaticallyImplyLeading: false,
        leadingWidth: 64,
        leading: Padding(
          padding: const EdgeInsetsDirectional.only(start: defaultPadding),
          child: Center(
            child: _RoundIconButton(
              icon: Icons.arrow_back_ios_new_rounded,
              iconSize: 17,
              semanticLabel: 'Back',
              onTap: () {
                if (Navigator.canPop(context)) Navigator.pop(context);
              },
            ),
          ),
        ),
        actions: [
          _RoundIconButton(
            icon: Icons.shopping_bag_outlined,
            semanticLabel: 'Cart',
            badge: cartCount,
            onTap: () => Navigator.pushNamed(context, cartScreenRoute),
          ),
          const SizedBox(width: defaultPadding),
        ],
      ),
      drawer: CustomEndDrawer(
        onLocaleChange: widget.onLocaleChange,
        user: user,
        onTabChanged: (int _) {},
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(defaultPadding, 0, defaultPadding, 10),
            child: hidePrice
                ? BottomWhatsAppAction(
              sku: p['sku'] ?? 'N/A',
              title: p['title'] ?? 'Unknown Product',
            )
                : BottomCartAction(
              unitPrice: currentUnitPrice,
              quantity: _quantity,
              onQtyChanged: (val) => setState(() => _quantity = val),
              onAddToCart: () => _addToCart(currentUnitPrice),
            ),
          ),
          GlassBottomNav(
            currentIndex: _currentIndex,
            onTabChanged: _onBottomNavTap,
            cartCount: cartCount,
            reselectable: true,
          ),
        ],
      ),
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: () => fetchProductDetails(showSkeleton: false),
          color: primaryColor,
          backgroundColor: isDark ? darkCardColor : Colors.white,
          child: CustomScrollView(
            slivers: [
              // 1. IMAGES
              SliverToBoxAdapter(
                child: Stack(
                  children: [
                    ProductImages(
                      images: (p['gallery'] as List<dynamic>?)
                          ?.map((item) => item as String)
                          .toList() ??
                          [],
                      isBestSeller: p['is_best_seller'] == 1,
                    ),
                    if (hasDiscount)
                      PositionedDirectional(
                        top: 12,
                        end: defaultPadding,
                        child: DiscountTimerBanner(
                          discount: Map<String, dynamic>.from(p['discount']),
                          originalPrice: originalPrice,
                          isBadge: true,
                        ),
                      ),
                  ],
                ),
              ),

              // 2. COUNTDOWN
              if (hasDiscount)
                SliverToBoxAdapter(
                  child: DiscountTimerBanner(
                    discount: Map<String, dynamic>.from(p['discount']),
                    originalPrice: originalPrice,
                  ),
                ),

              // 3. TITLE / SKU / CATEGORY / RATING
              ProductInfo(
                category: p['category'] ?? "Unknown",
                sku: p['sku'] ?? "Unknown",
                title: p['title'] ?? "Unknown",
                summaryName: p['summary_name'] ?? "",
                rating: (p['rating'] is Map)
                    ? (p['rating']['average'] as num?)?.toDouble() ?? 0.0
                    : (p['rating'] as num?)?.toDouble() ?? 0.0,
                numOfReviews: (p['rating'] is Map)
                    ? (p['rating']['count'] as num?)?.toInt() ?? 0
                    : p['num_of_reviews'] ?? 0,
              ),

              // 4. PRICE
              SliverToBoxAdapter(
                child: _PriceBlock(price: baseUnitPrice, original: originalPrice),
              ),

              // 5. BULK SAVINGS
              if (tiers.isNotEmpty) ...[
                divider(),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: defaultPadding),
                    child: ModernTablePriceList(
                      tiers: tiers,
                      currentQty: hidePrice ? null : _quantity,
                      onSelect: hidePrice
                          ? null
                          : (minQty) => setState(() => _quantity = minQty),
                    ),
                  ),
                ),
              ],

              divider(),

              // 6. SPECIFICATIONS
              if (p['attributes'] != null) ...[
                ExpandableSection(
                  title: "Product Specifications",
                  initiallyExpanded: true,
                  leadingIcon: Icons.tune_outlined,
                  child: ProductAttributes(attributes: p['attributes']),
                ),
                divider(),
              ],

              // 7. DESCRIPTION
              ExpandableSection(
                title: "Description",
                leadingIcon: Icons.notes_outlined,
                child: Html(
                  data: p['description'] ?? "",
                  style: {
                    "body": Style(
                      fontSize: FontSize(14.0),
                      color: isDark ? Colors.white70 : blackColor80,
                      lineHeight: LineHeight(1.55),
                    ),
                  },
                ),
              ),

              // 8. RELATED
              SliverToBoxAdapter(
                child: Container(
                  margin: const EdgeInsets.only(top: 20),
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  color: isDark ? darkCardColor : lightSurfaceColor,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: defaultPadding),
                        child: Text(
                          "You might also like",
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: AppPalette.text(context),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      RelatedProducts(productId: widget.productId),
                    ],
                  ),
                ),
              ),

              // Builder gives a context INSIDE the Scaffold body, where the
              // bottom padding includes the action card + nav (extendBody).
              SliverToBoxAdapter(
                child: Builder(
                  builder: (ctx) => SizedBox(
                    height: MediaQuery.paddingOf(ctx).bottom + 24,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// PIECES
// =============================================================================
class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({
    required this.icon,
    required this.semanticLabel,
    this.onTap,
    this.iconSize = 20,
    this.badge = 0,
  });

  final IconData icon;
  final String semanticLabel;
  final VoidCallback? onTap;
  final double iconSize;
  final int badge;

  @override
  Widget build(BuildContext context) {
    final button = Material(
      color: AppPalette.cardElevated(context),
      shape: CircleBorder(side: BorderSide(color: AppPalette.border(context))),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 42,
          height: 42,
          child: Icon(icon, size: iconSize, color: AppPalette.text(context)),
        ),
      ),
    );

    return Semantics(
      button: true,
      label: badge > 0 ? '$semanticLabel, $badge items' : semanticLabel,
      // Badge sits outside the button so it's never clipped or squeezed
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          button,
          if (badge > 0)
            PositionedDirectional(
              top: -5,
              end: -5,
              child: IgnorePointer(
                child: Container(
                  height: 20,
                  constraints: const BoxConstraints(minWidth: 20),
                  padding: const EdgeInsets.symmetric(horizontal: 5),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: primaryColor,
                    borderRadius: BorderRadius.circular(10),
                    // ring in the page colour separates it from the button
                    border: Border.all(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: primaryColor.withOpacity(0.35),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    badge > 99 ? '99+' : '$badge',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      height: 1,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _PriceBlock extends StatelessWidget {
  const _PriceBlock({required this.price, required this.original});

  final double price;
  final double original;

  @override
  Widget build(BuildContext context) {
    final onSale = price < original && original > 0;
    final pct = onSale ? ((1 - price / original) * 100).round() : 0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(defaultPadding, 6, defaultPadding, 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            "\$${price.toStringAsFixed(2)}",
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w900,
              color: primaryColor,
              letterSpacing: -0.5,
            ),
          ),
          if (onSale) ...[
            const SizedBox(width: 10),
            Text(
              "\$${original.toStringAsFixed(2)}",
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey.shade500,
                decoration: TextDecoration.lineThrough,
                decorationColor: Colors.grey.shade500,
              ),
            ),
            if (pct > 0) ...[
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  "Save $pct%",
                  style: const TextStyle(
                    color: primaryColor,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _NotFound extends StatelessWidget {
  const _NotFound({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final muted = AppPalette.textMuted(context);
    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.inventory_2_outlined, size: 48, color: muted),
              const SizedBox(height: 12),
              Text(
                "This product isn't available",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppPalette.text(context),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                "It may have been removed, or the connection dropped.",
                textAlign: TextAlign.center,
                style: TextStyle(color: muted, fontSize: 13),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: onRetry,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: const StadiumBorder(),
                ),
                child: const Text("Try again"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Floating card that holds the bottom actions.
class _ActionCard extends StatelessWidget {
  const _ActionCard({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final isDark = AppPalette.isDark(context);
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppPalette.card(context),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppPalette.border(context)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.4 : 0.10),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}

class BottomWhatsAppAction extends StatelessWidget {
  final String sku;
  final String title;

  const BottomWhatsAppAction({
    super.key,
    required this.sku,
    required this.title,
  });

  Future<void> _launchWhatsApp(BuildContext context) async {
    final message = Uri.encodeComponent("Hi, I want to ask about $title\nSKU: $sku");
    final waUrl = Uri.parse('https://wa.me/971504429045?text=$message');

    if (!await launchUrl(waUrl, mode: LaunchMode.externalApplication)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open WhatsApp')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return _ActionCard(
      child: SizedBox(
        height: 48,
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () => _launchWhatsApp(context),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1DA851),
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          icon: const Icon(Icons.chat_bubble_outline_rounded,
              size: 18, color: Colors.white),
          label: const Text(
            "Contact on WhatsApp",
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}

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
    final muted = AppPalette.textMuted(context);

    Widget stepButton(IconData icon, VoidCallback? onTap) => InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: 40,
        height: 48,
        child: Icon(
          icon,
          size: 18,
          color: onTap == null ? muted.withOpacity(0.4) : AppPalette.text(context),
        ),
      ),
    );

    return _ActionCard(
      child: Row(
        children: [
          Container(
            height: 48,
            decoration: BoxDecoration(
              color: AppPalette.cardElevated(context),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                stepButton(
                  Icons.remove_rounded,
                  quantity > 1 ? () => onQtyChanged(quantity - 1) : null,
                ),
                SizedBox(
                  width: 32,
                  child: Text(
                    "$quantity",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                      color: AppPalette.text(context),
                    ),
                  ),
                ),
                stepButton(Icons.add_rounded, () => onQtyChanged(quantity + 1)),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Consumer<CartProvider>(
              builder: (context, cart, _) {
                return SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    onPressed: cart.isLoading ? null : onAddToCart,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      disabledBackgroundColor: primaryColor.withOpacity(0.7),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: cart.isLoading
                        ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                        : FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.add_shopping_cart_rounded,
                              size: 18, color: Colors.white),
                          const SizedBox(width: 8),
                          const Text(
                            "Add to cart",
                            style: TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            "\$${(unitPrice * quantity).toStringAsFixed(2)}",
                            style: TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w700,
                              color: Colors.white.withOpacity(0.85),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class DiscountTimerBanner extends StatefulWidget {
  final Map<String, dynamic> discount;
  final bool isBadge;

  /// Used to turn a fixed discount ($3.20) into a percentage (-8%).
  final double? originalPrice;

  const DiscountTimerBanner({
    super.key,
    required this.discount,
    this.isBadge = false,
    this.originalPrice,
  });

  @override
  State<DiscountTimerBanner> createState() => _DiscountTimerBannerState();
}

class _DiscountTimerBannerState extends State<DiscountTimerBanner> {
  Timer? _timer; // nullable: the old `late` timer crashed when there was no end date
  DateTime? _end;
  Duration _timeLeft = Duration.zero;

  @override
  void initState() {
    super.initState();
    final raw = widget.discount['end_date'];
    _end = raw == null ? null : DateTime.tryParse(raw.toString());
    _timeLeft = _remaining();
    if (_timeLeft > Duration.zero) {
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        final left = _remaining();
        if (left <= Duration.zero) _timer?.cancel();
        if (mounted) setState(() => _timeLeft = left);
      });
    }
  }

  Duration _remaining() {
    if (_end == null) return Duration.zero;
    final d = _end!.difference(DateTime.now());
    return d.isNegative ? Duration.zero : d;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String get _amountLabel {
    final value = (widget.discount['value'] as num?)?.toDouble() ?? 0;
    final original = widget.originalPrice ?? 0;

    double pct;
    if (widget.discount['type'] == 'percent') {
      pct = value;
    } else if (original > 0) {
      pct = value / original * 100;
    } else {
      return '\$${value.toStringAsFixed(2)}'; // no price to compare against
    }
    // At least 1% so tiny discounts don't read "-0%"
    return '${pct.round().clamp(1, 100)}%';
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isBadge) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: primaryColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: primaryColor.withOpacity(0.35),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Text(
          "-$_amountLabel",
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 12,
          ),
        ),
      );
    }

    // No end date, or already ended → no countdown strip
    if (_timeLeft <= Duration.zero) return const SizedBox.shrink();

    String two(int n) => n.toString().padLeft(2, '0');
    final parts = <String>[
      if (_timeLeft.inDays > 0) '${_timeLeft.inDays}d',
      '${two(_timeLeft.inHours.remainder(24))}h',
      '${two(_timeLeft.inMinutes.remainder(60))}m',
      '${two(_timeLeft.inSeconds.remainder(60))}s',
    ];

    return Container(
      margin: const EdgeInsets.fromLTRB(defaultPadding, 12, defaultPadding, 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [primaryColor, primaryDeepColor],
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.18),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.bolt_rounded, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Offer ends in",
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 5),
                Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: [
                    for (final part in parts)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.18),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          part,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            fontFeatures: [FontFeature.tabularFigures()],
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Bulk price tiers. The tier matching the current quantity is highlighted,
/// and tapping a tier sets the quantity to that tier's minimum.
class ModernTablePriceList extends StatelessWidget {
  final List<Map<String, dynamic>> tiers;
  final int? currentQty;
  final ValueChanged<int>? onSelect;

  const ModernTablePriceList({
    super.key,
    required this.tiers,
    this.currentQty,
    this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = AppPalette.isDark(context);
    final textColor = AppPalette.text(context);
    final muted = AppPalette.textMuted(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.local_offer_outlined, size: 18, color: primaryColor),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                "Bulk savings",
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                  color: textColor,
                ),
              ),
            ),
            if (onSelect != null)
              Text("Tap a tier to apply", style: TextStyle(fontSize: 11.5, color: muted)),
          ],
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: tiers.map((tier) {
              final min = int.tryParse('${tier['min_qty'] ?? tier['from']}') ?? 1;
              final maxRaw = tier['max_qty'] ?? tier['to'];
              final max = maxRaw == null ? null : int.tryParse('$maxRaw');
              final price = (tier['price'] as num).toDouble();
              final active = currentQty != null &&
                  currentQty! >= min &&
                  (max == null || currentQty! <= max);

              return Padding(
                padding: const EdgeInsetsDirectional.only(end: 10),
                child: Material(
                  color: active
                      ? primaryColor.withOpacity(isDark ? 0.18 : 0.06)
                      : AppPalette.card(context),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: BorderSide(
                      color: active ? primaryColor : AppPalette.border(context),
                      width: active ? 1.5 : 1,
                    ),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: onSelect == null ? null : () => onSelect!(min),
                    child: SizedBox(
                      width: 104,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
                        child: Column(
                          children: [
                            Text(
                              max != null ? "$min–$max pcs" : "$min+ pcs",
                              style: TextStyle(
                                fontSize: 11.5,
                                color: muted,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              "\$${price.toStringAsFixed(2)}",
                              style: TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 16,
                                color: active ? primaryColor : textColor,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text("per unit", style: TextStyle(fontSize: 10.5, color: muted)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}