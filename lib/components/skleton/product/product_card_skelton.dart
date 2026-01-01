import 'package:flutter/material.dart';
import '../skeleton.dart'; // Adjust if needed

class ProductCardSkeleton extends StatelessWidget {
  const ProductCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFEEEEEE), width: 1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. IMAGE SECTION (Keep aspect ratio 1.1)
          Padding(
            padding: EdgeInsets.all(12),
            child: AspectRatio(
              aspectRatio: 1.1,
              child: Skeleton(
                width: double.infinity,
                height: double.infinity,
                layer: 1,
              ),
            ),
          ),

          // 2. CONTENT SECTION
          Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // SKU
                  Skeleton(width: 80, height: 10),
                  SizedBox(height: 12),

                  // Title (2 longer lines for realistic feel)
                  Skeleton(width: double.infinity, height: 12),
                  SizedBox(height: 8),
                  Skeleton(width: 140, height: 12),

                  Spacer(),

                  // Price
                  Skeleton(width: 100, height: 20),
                  SizedBox(height: 12),

                  // 3. BOTTOM ACTIONS
                  // Quantity Row
                  Row(
                    children: [
                      Skeleton(width: 32, height: 32),
                      SizedBox(width: 8),
                      Expanded(child: Skeleton(width: double.infinity, height: 32)),
                      SizedBox(width: 8),
                      Skeleton(width: 32, height: 32),
                    ],
                  ),

                  SizedBox(height: 10),

                  // Add to Cart Button
                  Skeleton(width: double.infinity, height: 38),

                  // Extra padding at bottom to match real card container
                  SizedBox(height: 4),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}