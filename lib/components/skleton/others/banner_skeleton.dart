import 'package:flutter/material.dart';
import '../skeleton.dart'; // Make sure this points to your shared Skeleton file

class BannerSkeleton extends StatelessWidget {
  const BannerSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      // Matches the padding in your BannerFetcher
      padding: const EdgeInsets.only(top: 20, left: 15, right: 15, bottom: 0),
      child: AspectRatio(
        aspectRatio: 2.0, // Adjust this ratio to match your real banner size
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: const Skeleton(
            width: double.infinity,
            height: double.infinity,
            layer: 1,
          ),
        ),
      ),
    );
  }
}