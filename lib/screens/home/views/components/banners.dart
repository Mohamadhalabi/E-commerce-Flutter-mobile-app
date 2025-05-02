import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../components/skleton/others/offers_skelton.dart';
import '../../../../constants.dart';
import '../../../../services/api_initializer.dart';
import 'package:visibility_detector/visibility_detector.dart'; // Import VisibilityDetector

class BannerFetcher extends StatefulWidget {
  const BannerFetcher({super.key});

  @override
  _BannerFetcherState createState() => _BannerFetcherState();
}

class _BannerFetcherState extends State<BannerFetcher> {
  bool isSectionVisible = false; // Track if the section is visible
  Future<Map<String, String>?>? _bannerFuture;

  // Fetch banner only when the section is visible
  Future<Map<String, String>?> _fetchBanner() async {
    try {
      final data = await apiClient.get('/get-banners?image=bottom_big_banner_image&link=bottom_big_banner_link');

      if (data is Map && data.containsKey('image') && data.containsKey('link')) {
        return {
          'image': data['image'].toString(),
          'link': data['link'].toString(),
        };
      }
    } catch (e) {
      print(e); // Handle error accordingly
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return VisibilityDetector(
      key: Key('banner-section'),
      onVisibilityChanged: (visibilityInfo) {
        // Check if the section is at least 50% visible before fetching
        if (visibilityInfo.visibleFraction > 0.5 && !isSectionVisible) {
          setState(() {
            isSectionVisible = true;
            _bannerFuture = _fetchBanner(); // Trigger fetch when section is visible
          });
        }
      },
      child: FutureBuilder<Map<String, String>?>(
        future: _bannerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting || !isSectionVisible) {
            return const OffersSkelton();
          }

          if (!snapshot.hasData || snapshot.data == null) {
            return const Center(child: Text("No banner available"));
          }

          final banner = snapshot.data!;

          return Padding(
            padding: const EdgeInsets.only(top: 20, left: 15, right: 15, bottom: 0),
            child: BannerMStyle1(
              image: banner['image']!,
              press: () {
                print("Redirecting to: ${banner['link']}");
              },
            ),
          );
        },
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
              borderRadius: BorderRadius.circular(10),
              child: Image.network(
                image,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                const Center(child: Icon(Icons.broken_image)),
                loadingBuilder: (context, child, loadingProgress) => child,
              ),
            ),
            ...children,
          ],
        ),
      ),
    );
  }
}