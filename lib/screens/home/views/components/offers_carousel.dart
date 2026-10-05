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
  static const double _bannerRatio = 1800 / 600;
  static const double _viewportFraction = 1.0; // full width, no side slivers
  static const double _gap = 0; // true edge-to-edge
  static const int _maxDots = 8; // above this, show "3 / 25" instead

  final PageController _pageController =
  PageController(viewportFraction: _viewportFraction);
  Timer? _timer;
  List<Map<String, String>> _offers = [];
  bool _isLoading = true;
  int _selectedIndex = 0;
  bool _autoSlideStarted = false;

  @override
  void initState() {
    super.initState();
    _fetchSliders();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _fetchSliders() async {
    List<Map<String, String>> result = [];
    try {
      final data = await apiClient.get('/get-sliders?type=main');
      if (data is List) {
        result = data.map<Map<String, String>>((item) {
          return {
            'image': item['image'].toString(),
            'link': (item['link'] ?? '').toString(),
            'keyword': (item['keyword'] ?? '').toString(),
          };
        }).toList();
      }
    } catch (e) {
      debugPrint('Sliders failed: $e');
    }
    // Always leave the loading state (old code stayed on the skeleton
    // forever if the API returned something other than a list)
    if (!mounted) return;
    setState(() {
      _offers = result;
      _isLoading = false;
    });
    // Fallback in case the first image never reports it loaded
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) _startAutoSlide();
    });
  }

  void _startAutoSlide() {
    if (_autoSlideStarted) return;
    _autoSlideStarted = true;
    _restartTimer();
  }

  void _restartTimer() {
    _timer?.cancel();
    if (_offers.length < 2) return;
    _timer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted || !_pageController.hasClients) return;
      _pageController.animateToPage(
        (_selectedIndex + 1) % _offers.length,
        duration: const Duration(milliseconds: 800),
        curve: Curves.fastOutSlowIn,
      );
    });
  }

  // Pause auto-slide while the user swipes, resume afterwards
  bool _handleScroll(ScrollNotification n) {
    if (n is ScrollStartNotification && n.dragDetails != null) {
      _timer?.cancel();
    } else if (n is ScrollEndNotification && _autoSlideStarted) {
      _restartTimer();
    }
    return false;
  }

  void _onBannerTapped(Map<String, String> bannerData) {
    final String keyword = bannerData['keyword'] ?? '';

    if (keyword.isNotEmpty && keyword != "null") {
      Navigator.pushNamed(
        context,
        "sub_category_products_screen",
        arguments: {
          'searchQuery': keyword,
          'title': keyword,
          'categorySlug': '',
          'currentIndex': 0,
          'user': null,
          'onTabChanged': (int i) {},
          'onLocaleChange': (String s) {},
        },
      );
      return;
    }

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

    int? productId = int.tryParse(url);
    if (productId == null && url.contains('product')) {
      final match = RegExp(r'(\d+)$').firstMatch(url);
      if (match != null) productId = int.parse(match.group(0)!);
    }

    if (productId != null) {
      Navigator.pushNamed(
        context,
        productDetailsScreenRoute,
        arguments: productId,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const OffersSkelton();
    if (_offers.isEmpty) return const SizedBox.shrink();

    final useCounter = _offers.length > _maxDots;

    return Padding(
      padding: const EdgeInsets.only(top: defaultPadding),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final bannerHeight =
              (constraints.maxWidth - _gap * 2) / _bannerRatio;

          return Column(
            children: [
              SizedBox(
                height: bannerHeight,
                child: NotificationListener<ScrollNotification>(
                  onNotification: _handleScroll,
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: _offers.length,
                    onPageChanged: (index) =>
                        setState(() => _selectedIndex = index),
                    itemBuilder: (context, index) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: _gap),
                      child: ClipRect(
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            BannerMStyle1(
                              image: _offers[index]['image']!,
                              press: () => _onBannerTapped(_offers[index]),
                              onLoaded: index == 0 ? _startAutoSlide : null,
                            ),
                            if (useCounter)
                              Positioned(
                                right: 10,
                                bottom: 8,
                                child: _PageCounter(
                                  current: _selectedIndex + 1,
                                  total: _offers.length,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              if (!useCounter && _offers.length > 1) ...[
                const SizedBox(height: 10),
                _Dots(count: _offers.length, selected: _selectedIndex),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _Dots extends StatelessWidget {
  const _Dots({required this.count, required this.selected});

  final int count;
  final int selected;

  @override
  Widget build(BuildContext context) {
    final inactive = AppPalette.textMuted(context).withOpacity(0.3);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        final active = i == selected;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
          margin: const EdgeInsets.symmetric(horizontal: 3),
          height: 6,
          width: active ? 20 : 6,
          decoration: BoxDecoration(
            color: active ? primaryColor : inactive,
            borderRadius: BorderRadius.circular(3),
          ),
        );
      }),
    );
  }
}

class _PageCounter extends StatelessWidget {
  const _PageCounter({required this.current, required this.total});

  final int current;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.45),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '$current / $total',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
          fontFeatures: [FontFeature.tabularFigures()],
        ),
      ),
    );
  }
}