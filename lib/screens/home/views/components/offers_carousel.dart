import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../components/skleton/others/offers_skelton.dart';
import '../../../../components/skleton/skeleton.dart';
import '../../../../constants.dart';
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
                'link': item['link'].toString(),
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
                press: () {},
                onLoaded: index == 0 ? _onImageLoaded : null,
              ),
            ),

            // --- UPDATED DOTS ---
            Positioned(
              bottom: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.2), // Slightly darker background for contrast
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    offers.length,
                        (index) => AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      height: 6, // Small size
                      width: 6,  // Small size (Circle)
                      decoration: BoxDecoration(
                        color: index == _selectedIndex
                            ? primaryColor // Active color
                            : Colors.white.withOpacity(0.5), // Inactive color
                        shape: BoxShape.circle, // Ensures it is rounded
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

class BannerMStyle1 extends StatelessWidget {
  const BannerMStyle1({
    super.key,
    required this.image,
    required this.press,
    this.onLoaded,
  });

  final String image;
  final VoidCallback press;
  final VoidCallback? onLoaded;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: press,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(defaultBorderRadius),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(defaultBorderRadius),
          child: Image.network(
            image,
            fit: BoxFit.cover,
            width: double.infinity,

            // --- HERE IS THE FIX ---
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;

              // PREVIOUSLY: return Container(color: Colors.grey[100]);
              // NOW: returns the animated Skeleton
              return const Skeleton(
                width: double.infinity,
                height: double.infinity,
                layer: 1, // Optional: makes it slightly darker if needed
              );
            },
            // -----------------------

            frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
              if (frame != null) {
                if (onLoaded != null) {
                  WidgetsBinding.instance.addPostFrameCallback((_) => onLoaded!());
                }
                return child;
              }
              // While waiting for the first frame, also show Skeleton
              return const Skeleton(width: double.infinity, height: double.infinity);
            },

            errorBuilder: (context, error, stackTrace) =>
                Container(
                    color: Colors.grey[200],
                    child: const Icon(Icons.broken_image, color: Colors.grey)
                ),
          ),
        ),
      ),
    );
  }
}