import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:shop/components/product/product_card.dart';
import 'package:shop/components/skleton/product/products_skelton.dart';
import 'package:shop/constants.dart';
import 'package:shop/models/product_model.dart';
import 'package:shop/route/route_constants.dart';
import 'package:shop/screens/discover/views/view_all_products_screen.dart';

enum ProductSectionStyle { plain, highlighted }

typedef ProductFetcher = Future<List<ProductModel>> Function(String locale);

/// One horizontal product rail. Replaces NewArrivalProducts, FlashSaleProducts,
/// FreeShippingProducts and BundleProducts.
class ProductSection extends StatefulWidget {
  const ProductSection({
    super.key,
    required this.sectionId,
    required this.title,
    required this.listType,
    required this.fetcher,
    this.icon,
    this.style = ProductSectionStyle.plain,
    this.lazy = false,
  });

  final String sectionId;
  final String title;
  final ProductListType listType;
  final ProductFetcher fetcher;
  final IconData? icon;
  final ProductSectionStyle style;

  /// When true, products load only once the section scrolls into view.
  final bool lazy;

  @override
  State<ProductSection> createState() => _ProductSectionState();
}

class _ProductSectionState extends State<ProductSection> {
  static const double _headerHeight = 56;

  List<ProductModel> _products = const [];
  bool _isLoading = true;
  String? _error;
  String? _locale;
  bool _hasBeenVisible = false;
  int _requestId = 0; // ignores responses from outdated requests

  bool get _highlighted => widget.style == ProductSectionStyle.highlighted;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Only refetch when the language actually changes
    final locale = Localizations.localeOf(context).languageCode;
    if (locale == _locale) return;
    _locale = locale;
    if (!widget.lazy || _hasBeenVisible) {
      _isLoading = true;
      _error = null;
      _load();
    }
  }

  void _reload() {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    _load();
  }

  Future<void> _load() async {
    final locale = _locale;
    if (locale == null) return;
    final requestId = ++_requestId;
    try {
      final result = await widget.fetcher(locale);
      if (!mounted || requestId != _requestId) return;
      setState(() {
        _products = result;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('ProductSection(${widget.sectionId}) failed: $e');
      if (!mounted || requestId != _requestId) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _handleVisibility(VisibilityInfo info) {
    if (_hasBeenVisible || !mounted || info.visibleFraction < 0.1) return;
    _hasBeenVisible = true;
    _reload();
  }

  void _openViewAll() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ViewAllProductsScreen(
          title: widget.title,
          type: widget.listType,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Nothing to show → take no space instead of an empty strip
    if (!_isLoading && _error == null && _products.isEmpty) {
      return const SizedBox.shrink();
    }

    final width = MediaQuery.sizeOf(context).width;
    final isTablet = width > 600;
    final cardWidth = isTablet ? width / 4.5 : width / 2.6;
    final listHeight = cardWidth + 180;
    final inset = _highlighted ? 12.0 : 0.0;

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(
          title: widget.title,
          icon: widget.icon,
          highlighted: _highlighted,
          inset: inset,
          height: _headerHeight,
          onViewAll: _openViewAll,
        ),
        _buildBody(cardWidth, listHeight, inset),
      ],
    );

    Widget section = _highlighted
        ? Stack(
            children: [
              // Red band is shorter than the cards, so they "pop out" below it
              Positioned(
                top: 0,
                left: inset,
                right: inset,
                height: _headerHeight + cardWidth * 0.62,
                child: const _HighlightBackground(),
              ),
              content,
            ],
          )
        : content;

    section = Padding(
      padding: const EdgeInsets.only(top: defaultPadding / 2),
      child: section,
    );

    if (!widget.lazy) return section;
    return VisibilityDetector(
      key: Key('product-section-${widget.sectionId}'),
      onVisibilityChanged: _handleVisibility,
      child: section,
    );
  }

  Widget _buildBody(double cardWidth, double listHeight, double inset) {
    if (_isLoading) {
      return const Center(child: ProductsSkelton());
    }
    if (_error != null) {
      return _SectionError(
        highlighted: _highlighted,
        inset: inset,
        onRetry: _reload,
      );
    }
    return SizedBox(
      height: listHeight,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        // Cards have a 6px margin, so this lines their edge up with the header
        padding: EdgeInsets.symmetric(horizontal: defaultPadding - 6 + inset),
        itemCount: _products.length,
        itemBuilder: (context, index) {
          final product = _products[index];
          return SizedBox(
            width: cardWidth,
            child: ProductCard(
              key: ValueKey(product.id),
              product: product,
              press: () => Navigator.pushNamed(
                context,
                productDetailsScreenRoute,
                arguments: product.id,
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.icon,
    required this.highlighted,
    required this.inset,
    required this.height,
    required this.onViewAll,
  });

  final String title;
  final IconData? icon;
  final bool highlighted;
  final double inset;
  final double height;
  final VoidCallback onViewAll;

  @override
  Widget build(BuildContext context) {
    final isDark = AppPalette.isDark(context);
    final titleColor = highlighted ? Colors.white : AppPalette.text(context);
    final accent = highlighted ? Colors.white : primaryColor;
    final chipBg = highlighted
        ? Colors.white.withOpacity(0.16)
        : primaryColor.withOpacity(isDark ? 0.18 : 0.08);

    return SizedBox(
      height: height,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          defaultPadding + inset,
          12,
          defaultPadding - 4 + inset,
          4,
        ),
        child: Row(
          children: [
            if (icon != null) ...[
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: chipBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 18, color: accent),
              ),
              const SizedBox(width: 10),
            ],
            Expanded(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: titleColor,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.2,
                ),
              ),
            ),
            Material(
              color: chipBg,
              shape: const StadiumBorder(),
              child: InkWell(
                customBorder: const StadiumBorder(),
                onTap: onViewAll,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 6, 6, 6),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        AppLocalizations.of(context)!.viewAll,
                        style: TextStyle(
                          color: accent,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Icon(Icons.chevron_right_rounded, size: 18, color: accent),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HighlightBackground extends StatelessWidget {
  const _HighlightBackground();

  @override
  Widget build(BuildContext context) {
    Widget circle(double size, double opacity) => Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withOpacity(opacity),
          ),
        );

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [primaryColor, primaryDeepColor],
        ),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.25),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Positioned(top: -40, right: -30, child: circle(140, 0.08)),
            Positioned(top: 34, right: 90, child: circle(46, 0.06)),
            Positioned(bottom: -60, left: -30, child: circle(130, 0.05)),
          ],
        ),
      ),
    );
  }
}

class _SectionError extends StatelessWidget {
  const _SectionError({
    required this.highlighted,
    required this.inset,
    required this.onRetry,
  });

  final bool highlighted;
  final double inset;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final color = highlighted ? Colors.white : AppPalette.textMuted(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(
        defaultPadding + inset,
        8,
        defaultPadding + inset,
        defaultPadding,
      ),
      child: Row(
        children: [
          Icon(Icons.wifi_off_rounded, size: 18, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              "Products didn't load. Check your connection.",
              style: TextStyle(color: color, fontSize: 12.5),
            ),
          ),
          TextButton(
            onPressed: onRetry,
            style: TextButton.styleFrom(
              foregroundColor: highlighted ? Colors.white : primaryColor,
            ),
            child: const Text('Try again'),
          ),
        ],
      ),
    );
  }
}
