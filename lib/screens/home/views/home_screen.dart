import 'package:flutter/material.dart';
import 'components/offer_carousel_and_categories.dart';
import 'components/new_arrival_products.dart';
import 'components/slider_carousel.dart';
import 'components/flash_sale.dart';
import 'components/free_shipping_products.dart';
import 'components/banners.dart';
import 'components/bundle_products.dart';

class HomeScreen extends StatefulWidget {
  final int currentIndex;
  final Map<String, dynamic>? user;
  final Function(int) onTabChanged;
  final Function(String) onLocaleChange;

  const HomeScreen({
    super.key,
    required this.currentIndex,
    required this.user,
    required this.onTabChanged,
    required this.onLocaleChange,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // This key controls the lifecycle of the ScrollView.
  // When we change this key, everything inside destroys and rebuilds (reloading data).
  Key _refreshKey = UniqueKey();

  Future<void> _onRefresh() async {
    // 1. Simulate a small network delay so the user sees the spinner
    await Future.delayed(const Duration(milliseconds: 1500));

    // 2. Change the key to force a complete rebuild of the scroll view content
    setState(() {
      _refreshKey = UniqueKey();
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ColoredBox(
        color: Colors.white,
        child: RefreshIndicator(
          // Triggered when user pulls down
          onRefresh: _onRefresh,
          color: const Color(0xFF7B61FF), // Use your primary color here
          backgroundColor: Colors.white,
          child: CustomScrollView(
            // The Key ensures that when _onRefresh is called,
            // this entire widget tree is reset.
            key: _refreshKey,
            slivers: [
              SliverToBoxAdapter(
                child: OffersCarouselAndCategories(
                  currentIndex: widget.currentIndex,
                  user: widget.user,
                  onTabChanged: widget.onTabChanged,
                  onLocaleChange: widget.onLocaleChange,
                ),
              ),
              const SliverToBoxAdapter(child: NewArrivalProducts()),
              const SliverToBoxAdapter(child: SliderCarousel()),
              const SliverToBoxAdapter(child: FlashSaleProducts()),
              const SliverToBoxAdapter(child: FreeShippingProducts()),
              const SliverToBoxAdapter(child: BannerFetcher()),
              const SliverToBoxAdapter(child: BundleProducts()),
            ],
          ),
        ),
      ),
    );
  }
}