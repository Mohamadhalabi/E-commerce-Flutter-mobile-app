import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../components/skleton/others/banner_skeleton.dart'; // ADD THIS
import '../../../../components/skleton/skeleton.dart';
import '../../../../constants.dart';
import '../../../../services/api_initializer.dart';
import 'package:visibility_detector/visibility_detector.dart';

class BannerFetcher extends StatefulWidget {
  const BannerFetcher({super.key});

  @override
  _BannerFetcherState createState() => _BannerFetcherState();
}

class _BannerFetcherState extends State<BannerFetcher> {
  bool isSectionVisible = false;
  Future<Map<String, String>?>? _bannerFuture;

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
      print(e);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return VisibilityDetector(
      key: const Key('banner-section'),
      onVisibilityChanged: (visibilityInfo) {
        if (visibilityInfo.visibleFraction > 0.5 && !isSectionVisible) {
          setState(() {
            isSectionVisible = true;
            _bannerFuture = _fetchBanner();
          });
        }
      },
      child: FutureBuilder<Map<String, String>?>(
        future: _bannerFuture,
        builder: (context, snapshot) {
          // 1. API LOADING STATE: Show BannerSkeleton
          if (snapshot.connectionState == ConnectionState.waiting || !isSectionVisible) {
            return const BannerSkeleton();
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
        // 1. Force the container to hold the 2.0 ratio CONSTANTLY.
        // This prevents layout jumps when switching from Skeleton to Image.
        child: AspectRatio(
          aspectRatio: 2.0,
          child: Stack(
            fit: StackFit.expand, // Ensures children fill the box
            children: [
              // 2. LAYER 0: THE SKELETON
              // This sits behind the image. If the image is loading (transparent),
              // the user sees this skeleton.
              const ClipRRect(
                borderRadius: BorderRadius.all(Radius.circular(10)),
                child: Skeleton(width: double.infinity, height: double.infinity),
              ),

              // 3. LAYER 1: THE IMAGE
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(
                  image,
                  fit: BoxFit.cover,

                  // We use frameBuilder to smoothly fade the image in over the skeleton
                  frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
                    if (wasSynchronouslyLoaded) return child;

                    // While frame is null, opacity is 0 (invisible), showing the Skeleton below.
                    // When frame arrives, opacity becomes 1, covering the Skeleton.
                    return AnimatedOpacity(
                      opacity: frame == null ? 0 : 1,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOut,
                      child: child,
                    );
                  },

                  // NOTE: We don't need loadingBuilder anymore because the
                  // Skeleton is already in the Stack behind the image!

                  errorBuilder: (context, error, stackTrace) =>
                      Container(
                        color: Colors.grey[200],
                        child: const Center(child: Icon(Icons.broken_image, color: Colors.grey)),
                      ),
                ),
              ),

              // 4. LAYER 2: OVERLAY CHILDREN (Text, etc.)
              ...children,
            ],
          ),
        ),
      ),
    );
  }
}