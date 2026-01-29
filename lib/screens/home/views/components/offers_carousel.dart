import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../../components/Banner/M/banner_m_style_1.dart';
import '../../../../components/skleton/others/offers_skelton.dart';
import '../../../../constants.dart';
import '../../../../services/api_initializer.dart';
import '../../../../route/route_constants.dart';

class OffersCarousel extends StatefulWidget {
  const OffersCarousel({super.key});

  @override
  State<OffersCarousel> createState() => _OffersCarouselState();
}

class _OffersCarouselState extends State<OffersCarousel> {
  int _selectedIndex = 0;
  bool isLoading = true;
  late PageController _pageController;
  Timer? _timer;
  List<Map<String, String>> offers = [];
  bool _isTimerStarted = false;

  final double imgWidth = 1800;
  final double imgHeight = 454;
  final double viewPortFraction = 0.92;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0, viewportFraction: viewPortFraction);
    _fetchSliders();
  }

  Future<void> _fetchSliders() async {
    try {
      final data = await apiClient.get('/get-sliders?type=main');
      if (data is List) {
        if (mounted) {
          setState(() {
            offers = data.map<Map<String, String>>((item) {
              return {
                'image': item['image'].toString(),
                'link': (item['link'] ?? '').toString(),
                'keyword': (item['keyword'] ?? '').toString(),
              };
            }).toList();
            isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) setState(() => isLoading = false);
    }
  }

  // ---------------------------------------------------------------------------
  // [FIXED] Navigate Directly to Results Screen
  // ---------------------------------------------------------------------------
  void _onBannerTapped(Map<String, String> bannerData) {

    // 1. Check for KEYWORD -> Go to SubCategoryProductsScreen (Results)
    final String keyword = bannerData['keyword'] ?? '';

    if (keyword.isNotEmpty && keyword != "null") {
      print("DEBUG: Keyword found ($keyword). Navigating to results...");

      Navigator.pushNamed(
          context,
          "sub_category_products_screen", // [CORRECT ROUTE NAME]
          arguments: {
            'searchQuery': keyword,       // Pass keyword here
            'title': keyword,             // Title of the screen
            'categorySlug': '',           // Empty because it's a search
            'currentIndex': 0,
            'user': null,
            'onTabChanged': (int i) {},   // Dummy callback
            'onLocaleChange': (String s) {}, // Dummy callback
          }
      );
      return;
    }

    // 2. Fallback: Parse LINK (Product Details)
    final String linkRaw = bannerData['link'] ?? '';
    if (linkRaw.isEmpty || linkRaw == "null") return;

    String url = "";
    if (linkRaw.trim().startsWith('{')) {
      try {
        final Map<String, dynamic> links = jsonDecode(linkRaw);
        final String currentLang = Localizations.localeOf(context).languageCode;
        url = links[currentLang] ?? links['en'] ?? "";
      } catch (e) {
        return;
      }
    } else {
      url = linkRaw;
    }

    if (url.isEmpty || url == "null") return;

    // Extract ID logic
    int? productId;
    if (int.tryParse(url) != null) {
      productId = int.parse(url);
    }
    else if (url.contains('/products/') || url.contains('product')) {
      try {
        final RegExp idRegex = RegExp(r'(\d+)$');
        final Match? match = idRegex.firstMatch(url);
        if (match != null) {
          productId = int.parse(match.group(0)!);
        }
      } catch (e) {
        // ignore
      }
    }

    if (productId != null) {
      Navigator.pushNamed(
        context,
        productDetailsScreenRoute,
        arguments: productId,
      );
    }
  }

  void _startAutoSlide() {
    if (offers.isEmpty || _timer != null) return;
    _timer = Timer.periodic(const Duration(seconds: 4), (Timer timer) {
      if (!mounted) return;
      setState(() {
        _selectedIndex = (_selectedIndex + 1) % offers.length;
        _pageController.animateToPage(
          _selectedIndex,
          duration: const Duration(milliseconds: 800),
          curve: Curves.fastOutSlowIn,
        );
      });
    });
  }

  void _onImageLoaded() {
    if (!_isTimerStarted) {
      _isTimerStarted = true;
      _startAutoSlide();
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) return const OffersSkelton();
    if (offers.isEmpty) return const SizedBox.shrink();

    final double computedAspectRatio = (imgWidth / imgHeight) / viewPortFraction;

    return Padding(
      padding: const EdgeInsets.only(top: defaultPadding),
      child: AspectRatio(
        aspectRatio: computedAspectRatio,
        child: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            PageView.builder(
              controller: _pageController,
              itemCount: offers.length,
              onPageChanged: (index) => setState(() => _selectedIndex = index),
              itemBuilder: (context, index) => BannerMStyle1(
                image: offers[index]['image']!,
                press: () => _onBannerTapped(offers[index]),
                onLoaded: index == 0 ? _onImageLoaded : null,
              ),
            ),
            Positioned(
              bottom: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    offers.length,
                        (index) => AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      height: 6,
                      width: 6,
                      decoration: BoxDecoration(
                        color: index == _selectedIndex
                            ? primaryColor
                            : Colors.white.withOpacity(0.5),
                        shape: BoxShape.circle,
                      ),
                    ),
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