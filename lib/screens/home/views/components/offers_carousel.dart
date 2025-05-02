import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../components/skleton/others/offers_skelton.dart';
import '../../../../constants.dart';
import 'package:shop/components/dot_indicators.dart';
import '../../../../services/api_initializer.dart';
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

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
    _fetchSliders();
  }

  Future<void> _fetchSliders() async {
    try {
      final data = await apiClient.get('/get-sliders?type=main'); // assume it's List<dynamic>

      if (data is List) {
        setState(() {
          offers = data.map<Map<String, String>>((item) {
            return {
              'image': item['image'].toString(),
              'link': item['link'].toString(),
            };
          }).toList();
          isLoading = false;
        });

        _startAutoSlide();
      } else {
        // if not a list, treat it as empty
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
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
    if (isLoading) {
      return const Center(child: OffersSkelton());
    }

    if (offers.isEmpty) {
      return const Center(child: Text("No sliders available"));
    }

    return AspectRatio(
      aspectRatio: 1.87,
      child: Stack(
        alignment: Alignment.bottomRight,
        children: [
          PageView.builder(
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
          FittedBox(
            child: Padding(
              padding: const EdgeInsets.all(defaultPadding),
              child: SizedBox(
                height: 16,
                child: Row(
                  children: List.generate(
                    offers.length,
                        (index) => Padding(
                      padding: const EdgeInsets.only(left: defaultPadding / 4),
                      child: DotIndicator(
                        isActive: index == _selectedIndex,
                        activeColor: Colors.white70,
                        inActiveColor: Colors.white54,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          )
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
    return AspectRatio(
      aspectRatio: 1.00,
      child: GestureDetector(
        onTap: press,
        child: Stack(
          children: [
            Image.network(
              image,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => const Center(child: Icon(Icons.broken_image)),
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return const Center(child: OffersSkelton());
              },
            ),
            ...children,
          ],
        ),
      ),
    );
  }
}