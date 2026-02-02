import 'package:flutter/material.dart';
import '../../../constants.dart';

class ProductsSkelton extends StatelessWidget {
  const ProductsSkelton({super.key});

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    bool isTablet = size.width > 600;
    double cardWidth = isTablet ? size.width / 4.5 : size.width / 2.6;
    double listHeight = cardWidth + 180;

    return SizedBox(
      height: listHeight,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 5,
        physics: const NeverScrollableScrollPhysics(),
        itemBuilder: (context, index) => Padding(
          padding: EdgeInsets.only(
            left: index == 0 ? defaultPadding : defaultPadding / 2,
            right: index == 4 ? defaultPadding : 0,
          ),
          child: SizedBox(
            width: cardWidth,
            child: const ProductCardSkeleton(),
          ),
        ),
      ),
    );
  }
}

class ProductCardSkeleton extends StatelessWidget {
  const ProductCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    // 1. Detect Dark Mode
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    // 2. Define Colors
    // Card Background
    final Color cardBg = isDark ? const Color(0xFF1C1C23) : Colors.white;
    // Border Color
    final Color borderColor = isDark ? Colors.white10 : const Color(0xFFF0F0F0);
    // Skeleton (Bone) Color - subtle grey for dark mode, light grey for light mode
    final Color skeletonColor = isDark ? const Color(0xFF2C2C36) : const Color(0xFFF4F4F4);

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        border: Border.all(color: borderColor, width: 1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. IMAGE SECTION
          Padding(
            padding: const EdgeInsets.all(12),
            child: AspectRatio(
              aspectRatio: 1.0,
              child: Container(
                width: double.infinity,
                height: double.infinity,
                decoration: BoxDecoration(
                  color: skeletonColor,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),

          // 2. CONTENT SECTION
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // SKU
                  _SkeletonBox(width: 50, height: 8, color: skeletonColor),
                  const SizedBox(height: 6),

                  // Title (2 lines)
                  _SkeletonBox(width: double.infinity, height: 10, color: skeletonColor),
                  const SizedBox(height: 6),
                  _SkeletonBox(width: double.infinity, height: 10, color: skeletonColor),
                  const SizedBox(height: 6),

                  // Manufacturer
                  _SkeletonBox(width: 80, height: 10, color: skeletonColor),

                  const Spacer(),

                  // Price
                  _SkeletonBox(width: 60, height: 16, color: skeletonColor),
                  const SizedBox(height: 10),

                  // 3. BOTTOM ACTIONS
                  Row(
                    children: [
                      // Quantity Box
                      _SkeletonBox(width: 80, height: 28, color: skeletonColor),
                      const SizedBox(width: 8),

                      // Add Button
                      Expanded(
                        child: Container(
                          height: 28,
                          decoration: BoxDecoration(
                            color: skeletonColor,
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Helper Widget to create consistent bones
class _SkeletonBox extends StatelessWidget {
  final double width;
  final double height;
  final Color color;

  const _SkeletonBox({
    required this.width,
    required this.height,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}