import 'package:flutter/material.dart';
import '../../skleton/skeleton.dart'; // Make sure this path points to your Skeleton widget
import '../../../constants.dart';      // Make sure this points to your constants

class BannerMStyle1 extends StatelessWidget {
  const BannerMStyle1({
    super.key,
    required this.image,
    required this.press,
    this.onLoaded, // [ADDED] Defined the parameter here
  });

  final String image;
  final VoidCallback press;
  final VoidCallback? onLoaded; // [ADDED]

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

            // [ADDED] Loading Builder for Skeleton
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return const Skeleton(
                width: double.infinity,
                height: double.infinity,
              );
            },

            // [ADDED] Frame Builder to trigger auto-slide when loaded
            frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
              if (frame != null) {
                // If the image has a frame (is loaded), call the callback
                if (onLoaded != null) {
                  WidgetsBinding.instance.addPostFrameCallback((_) => onLoaded!());
                }
                return child;
              }
              // While waiting for the first frame, show Skeleton
              return const Skeleton(width: double.infinity, height: double.infinity);
            },

            errorBuilder: (context, error, stackTrace) => Container(
              color: Colors.grey[200],
              child: const Icon(Icons.broken_image, color: Colors.grey),
            ),
          ),
        ),
      ),
    );
  }
}