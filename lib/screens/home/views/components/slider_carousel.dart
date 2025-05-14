import 'dart:async';
import 'package:flutter/material.dart';
import 'package:visibility_detector/visibility_detector.dart';
import '../../../../components/skleton/others/offers_skelton.dart';
import '../../../../constants.dart';
import 'package:shop/components/dot_indicators.dart';
import '../../../../services/api_service.dart';

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
      final data = await ApiService.fetchSliders(locale);
      setState(() {
        offers = data;
        isLoading = false;
      });
      _startAutoSlide();
    } catch (e) {
      setState(() => isLoading = false);
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
      key: Key('slider-carousel-section'), // Unique key for this section
      onVisibilityChanged: (visibilityInfo) {
        // Trigger fetch only if more than 50% of the widget is visible
        if (visibilityInfo.visibleFraction > 0.5 && !isSectionVisible) {
          setState(() {
            isSectionVisible = true;
          });
          _fetchSliders();  // Fetch sliders only when the section becomes visible
        }
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isLoading)
            const Center(child: OffersSkelton())
          else if (offers.isEmpty)
            const Center(child: Text("No sliders available"))
          else
            Center(
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 20.0),
                child: ClipRRect(
                  child: AspectRatio(
                    aspectRatio: 0.75, // Adjust this to tighten/widen image box
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
                        press: () {
                          print("Redirecting to: ${offers[index]['link']}");
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ),
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