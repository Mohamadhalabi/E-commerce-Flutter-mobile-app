import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:visibility_detector/visibility_detector.dart';
import '../../../../components/skleton/others/offers_skelton.dart';
import '../../../../constants.dart';
import 'package:shop/components/dot_indicators.dart';
import '../../../../services/api_service.dart';
import '../../../../route/route_constants.dart';

class SliderCarousel extends StatefulWidget {
  const SliderCarousel({super.key});

  @override
  State<SliderCarousel> createState() => _SliderCarouselState();
}

class _SliderCarouselState extends State<SliderCarousel> {
  int _selectedIndex = 0;
  bool isLoading = true;
  late PageController _pageController;
  Timer? _timer;
  List<Map<String, String>> offers = [];
  bool isSectionVisible = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
  }

  Future<void> _fetchSliders() async {
    final locale = Localizations.localeOf(context).languageCode;

    try {
      final dynamic response = await ApiService.fetchSliders(locale);

      // DEBUG PRINT: See exactly what the API returns
      print("DEBUG: API Response for Sliders: $response");

      if (mounted) {
        setState(() {
          // Robust mapping to handle potential nulls or different types
          offers = (response as List).map<Map<String, String>>((item) {
            return {
              'image': item['image']?.toString() ?? '',
              'link': item['link']?.toString() ?? '',
              // Check for 'keyword' or 'search_keyword'
              'keyword': (item['keyword'] ?? item['search_keyword'] ?? '').toString(),
            };
          }).toList();
          isLoading = false;
        });
        _startAutoSlide();
      }
    } catch (e) {
      print("DEBUG: Error fetching sliders: $e");
      if (mounted) setState(() => isLoading = false);
    }
  }

  // ---------------------------------------------------------------------------
  // [FIXED] Smart Navigation Logic
  // ---------------------------------------------------------------------------
  void _onBannerTapped(Map<String, String> bannerData) {
    print("DEBUG: Banner Tapped. Data: $bannerData");

    // 1. TRY EXPLICIT KEYWORD
    String keyword = bannerData['keyword'] ?? '';

    // 2. IF KEYWORD IS EMPTY, TRY TO EXTRACT FROM LINK
    // Example: link is "/rolls-royce" -> we convert it to keyword "rolls royce"
    final String linkRaw = bannerData['link'] ?? '';

    // Check if it's a product link (has numbers at the end)
    bool isProductLink = false;
    if (linkRaw.isNotEmpty) {
      // This regex looks for --12345 or just digits at the end
      if (RegExp(r'(\d+)$').hasMatch(linkRaw) || linkRaw.contains('/products/')) {
        isProductLink = true;
      }
    }

    // If we have no keyword AND it's not a product ID link, treat the link as a keyword!
    if ((keyword.isEmpty || keyword == "null") && !isProductLink && linkRaw.isNotEmpty) {
      // Clean the link: remove '/', replace '-' with space
      // "/rolls-royce" becomes "rolls royce"
      keyword = linkRaw.replaceAll('/', '').replaceAll('-', ' ').trim();
      print("DEBUG: Extracted keyword from link: $keyword");
    }

    // ---------------------------------------------------------
    // ACTION 1: PERFORM SEARCH (SubCategoryProductsScreen)
    // ---------------------------------------------------------
    if (keyword.isNotEmpty && keyword != "null") {
      print("DEBUG: Navigating to Results with keyword: '$keyword'");

      Navigator.pushNamed(
          context,
          "sub_category_products_screen",
          arguments: {
            'searchQuery': keyword,
            'title': keyword.toUpperCase(),
            'categorySlug': '',
            'currentIndex': 0,
            'user': null,
            'onTabChanged': (int i) {},
            'onLocaleChange': (String s) {},
          }
      );
      return; // STOP HERE
    }

    // ---------------------------------------------------------
    // ACTION 2: GO TO PRODUCT DETAILS (Only if it's a product link)
    // ---------------------------------------------------------
    if (isProductLink) {
      String url = linkRaw;
      // Handle JSON if needed
      if (url.trim().startsWith('{')) {
        try {
          final Map<String, dynamic> links = jsonDecode(url);
          final String currentLang = Localizations.localeOf(context).languageCode;
          url = links[currentLang] ?? links['en'] ?? "";
        } catch (e) {
          print("DEBUG: Error parsing JSON link: $e");
        }
      }

      int? productId;
      try {
        final RegExp idRegex = RegExp(r'(\d+)$');
        final Match? match = idRegex.firstMatch(url);
        if (match != null) {
          productId = int.parse(match.group(0)!);
        }
      } catch (e) {
        print("DEBUG: Error parsing ID: $e");
      }

      if (productId != null) {
        print("DEBUG: Product ID found: $productId");
        Navigator.pushNamed(
          context,
          productDetailsScreenRoute,
          arguments: productId,
        );
      } else {
        print("DEBUG: Could not extract Product ID from URL: $url");
      }
    }
  }

  void _startAutoSlide() {
    if (offers.isEmpty) return;

    _timer = Timer.periodic(const Duration(seconds: 4), (Timer timer) {
      if (!mounted) return;
      setState(() {
        _selectedIndex = (_selectedIndex + 1) % offers.length;
        _pageController.animateToPage(
          _selectedIndex,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOutCubic,
        );
      });
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return VisibilityDetector(
      key: const Key('slider-carousel-section'),
      onVisibilityChanged: (visibilityInfo) {
        if (visibilityInfo.visibleFraction > 0.5 && !isSectionVisible) {
          setState(() {
            isSectionVisible = true;
          });
          _fetchSliders();
        }
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isLoading)
            const Center(child: OffersSkelton())
          else if (offers.isEmpty)
            const SizedBox.shrink()
          else
            Center(
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 20.0),
                child: ClipRRect(
                  child: AspectRatio(
                    aspectRatio: 0.75,
                    child: PageView.builder(
                      controller: _pageController,
                      itemCount: offers.length,
                      onPageChanged: (int index) {
                        setState(() {
                          _selectedIndex = index;
                        });
                      },
                      itemBuilder: (context, index) => BannerMStyle1(
                        image: offers[index]['image']!,
                        press: () => _onBannerTapped(offers[index]),
                      ),
                    ),
                  ),
                ),
              ),
            ),

          if (!isLoading && offers.isNotEmpty)
            SizedBox(
              height: 20,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  offers.length,
                      (index) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: DotIndicator(
                      isActive: index == _selectedIndex,
                      activeColor: Colors.orange.shade700,
                      inActiveColor: Colors.orange.shade200,
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

class BannerMStyle1 extends StatelessWidget {
  const BannerMStyle1({super.key, required this.image, required this.press});

  final String image;
  final VoidCallback press;

  @override
  Widget build(BuildContext context) {
    return BannerM(
      image: image,
      press: press,
      children: const [
        Padding(
          padding: EdgeInsets.all(defaultPadding),
          child: SizedBox.shrink(),
        ),
      ],
    );
  }
}

class BannerM extends StatelessWidget {
  const BannerM({super.key, required this.image, required this.press, required this.children});

  final String image;
  final VoidCallback press;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: GestureDetector(
        onTap: press,
        child: Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.network(
                image,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => const Center(child: Icon(Icons.broken_image)),
                loadingBuilder: (context, child, loadingProgress) {
                  return child;
                },
              ),
            ),
            ...children,
          ],
        ),
      ),
    );
  }
}