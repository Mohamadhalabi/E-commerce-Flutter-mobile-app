import 'package:flutter/material.dart';
import 'components/offer_carousel_and_categories.dart';
import 'components/new_arrival_products.dart';
import 'components/slider_carousel.dart';
import 'components/flash_sale.dart';
import 'components/free_shipping_products.dart';
import 'components/banners.dart';
import 'components/bundle_products.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const SafeArea(
      child: ColoredBox(
        color: Colors.white, // ⬅️ This ensures the background is white
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: OffersCarouselAndCategories()),
            SliverToBoxAdapter(child: NewArrivalProducts()),
            SliverToBoxAdapter(child: SliderCarousel()),
            SliverToBoxAdapter(child: FlashSaleProducts()),
            SliverToBoxAdapter(child: FreeShippingProducts()),
            SliverToBoxAdapter(child: BannerFetcher()),
            SliverToBoxAdapter(child: BundleProducts()),
          ],
        ),
      ),
    );
  }
}

