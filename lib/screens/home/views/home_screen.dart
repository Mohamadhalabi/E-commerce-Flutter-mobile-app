import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:shop/components/product/product_section.dart';
import 'package:shop/constants.dart';
import 'package:shop/screens/discover/views/view_all_products_screen.dart';
import 'package:shop/services/api_service.dart';
import 'components/offer_carousel_and_categories.dart';

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
    // New key → every section rebuilds and refetches
    setState(() => _refreshKey = UniqueKey());
    await Future.delayed(const Duration(milliseconds: 700));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = AppPalette.isDark(context);

    // With Scaffold.extendBody = true this includes the floating nav's height,
    // so the last section can scroll fully above the glass bar.
    final bottomSpacing = MediaQuery.paddingOf(context).bottom + defaultPadding;

    return SafeArea(
      bottom: false, // let content slide under the translucent nav
      child: ColoredBox(
        color: Theme.of(context).scaffoldBackgroundColor,
        child: RefreshIndicator(
          onRefresh: _onRefresh,
          color: primaryColor,
          backgroundColor: isDark ? darkCardColor : Colors.white,
          child: CustomScrollView(
            key: _refreshKey,
            slivers: [
              SliverToBoxAdapter(
                child: OffersCarouselAndCategories(
                  currentIndex: widget.currentIndex,
                  user: widget.user,
                  onTabChanged: widget.onTabChanged,
                  onLocaleChange: widget.onLocaleChange,
                  categoryKey: widget.categoryKey,
                ),
              ),
              SliverToBoxAdapter(
                child: ProductSection(
                  sectionId: 'new-arrival',
                  title: l10n.newArrival,
                  icon: Icons.auto_awesome_rounded,
                  listType: ProductListType.newArrival,
                  fetcher: ApiService.fetchLatestProducts,
                  style: ProductSectionStyle.highlighted,
                ),
              ),
              SliverToBoxAdapter(
                child: ProductSection(
                  sectionId: 'flash-sale',
                  title: l10n.specialOffer,
                  icon: Icons.local_fire_department_rounded,
                  listType: ProductListType.flashSale,
                  fetcher: ApiService.fetchFlashSaleProducts,
                ),
              ),
              SliverToBoxAdapter(
                child: ProductSection(
                  sectionId: 'free-shipping',
                  title: l10n.freeShipping,
                  icon: Icons.local_shipping_rounded,
                  listType: ProductListType.freeShipping,
                  fetcher: ApiService.fetchFreeShippingProducts,
                  lazy: true,
                ),
              ),
              SliverToBoxAdapter(
                child: ProductSection(
                  sectionId: 'bundle',
                  title: l10n.bundleProducts,
                  icon: Icons.inventory_2_rounded,
                  listType: ProductListType.bundle,
                  fetcher: ApiService.fetchBundleProducts,
                  lazy: true,
                ),
              ),
              SliverToBoxAdapter(child: SizedBox(height: bottomSpacing)),
            ],
          ),
        ),
      ),
    );
  }
}