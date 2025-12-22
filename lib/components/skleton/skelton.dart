import 'package:flutter/material.dart';

class Skeleton extends StatelessWidget {
  const Skeleton({
    super.key,
    this.height,
    this.width,
    double? radius,
    double? radious, // 👈 backward compatible
  }) : radius = radius ?? radious ?? 12;

  final double? height;
  final double? width;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final baseColor = Colors.grey.shade300; // soft neutral

    return Container(
      height: height ?? 16,
      width: width ?? double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: baseColor.withOpacity(0.35),
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

class CircleSkeleton extends StatelessWidget {
  const CircleSkeleton({
    super.key,
    this.size = 40,
  });

  final double size;

  @override
  Widget build(BuildContext context) {
    final baseColor = Colors.grey.shade300;

    return Container(
      height: size,
      width: size,
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: baseColor.withOpacity(0.35),
        shape: BoxShape.circle,
      ),
    );
  }
}
