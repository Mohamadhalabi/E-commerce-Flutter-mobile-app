import 'package:flutter/material.dart';
import 'components/offer_carousel_and_categories.dart';
import 'components/new_arrival_products.dart';
// import 'components/slider_carousel.dart';
import 'components/flash_sale.dart';
import 'components/free_shipping_products.dart';
import 'components/bundle_products.dart';

class HomeScreen extends StatefulWidget {
  final int currentIndex;
  final Map<String, dynamic>? user;
  final Function(int) onTabChanged;
  final Function(String) onLocaleChange;

  final GlobalKey? categoryKey;

  const HomeScreen({
    super.key,
    required this.currentIndex,
    required this.user,
    required this.onTabChanged,
    required this.onLocaleChange,
    this.categoryKey,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Key _refreshKey = UniqueKey();

  Future<void> _onRefresh() async {
    await Future.delayed(const Duration(milliseconds: 1500));
    setState(() {
      _refreshKey = UniqueKey();
    });
  }

  @override
  Widget build(BuildContext context) {
    final backgroundColor = Theme.of(context).scaffoldBackgroundColor;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SafeArea(
      child: ColoredBox(
        color: backgroundColor, // ✅ Changed from Colors.white
        child: RefreshIndicator(
          onRefresh: _onRefresh,
          color: const Color(0xFF7B61FF),
          backgroundColor: isDark ? const Color(0xFF1C1C23) : Colors.white, // ✅ Dynamic loading bg
          child: CustomScrollView(
            key: _refreshKey,
            slivers: [
              SliverToBoxAdapter(
                child: OffersCarouselAndCategories(
                  currentIndex: widget.currentIndex,
                  user: widget.user,
                  onTabChanged: widget.onTabChanged,
                  onLocaleChange: widget.onLocaleChange,
                  // ✅ ADDED: Pass the key down to the next widget
                  categoryKey: widget.categoryKey,
                ),
              ),
              const SliverToBoxAdapter(child: NewArrivalProducts()),
              // const SliverToBoxAdapter(child: SliderCarousel()),
              const SliverToBoxAdapter(child: FlashSaleProducts()),
              const SliverToBoxAdapter(child: FreeShippingProducts()),
              // const SliverToBoxAdapter(child: BannerFetcher()),
              const SliverToBoxAdapter(child: BundleProducts()),
            ],
          ),
        ),
      ),
    );
  }
}