import 'package:flutter/material.dart';
import '../skeleton.dart';

class ProductCardSkeleton extends StatelessWidget {
  const ProductCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      // No fixed width here (parent controls it)
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFF0F0F0), width: 1),
        borderRadius: BorderRadius.circular(8), // Match new radius
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. IMAGE SECTION (Square 1.0)
          Padding(
            padding: EdgeInsets.all(8), // Reduced padding
            child: AspectRatio(
              aspectRatio: 1.0,
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
              padding: EdgeInsets.fromLTRB(6, 0, 6, 6), // Tighter padding
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // SKU (Small)
                  Skeleton(width: 60, height: 8),
                  SizedBox(height: 6),

                  // Title (Simulate 3 lines for the 4-line limit)
                  Skeleton(width: double.infinity, height: 10),
                  SizedBox(height: 4),
                  Skeleton(width: double.infinity, height: 10),
                  SizedBox(height: 4),
                  Skeleton(width: 80, height: 10),

                  Spacer(),

                  // Price
                  Skeleton(width: 70, height: 14),
                  SizedBox(height: 8),

                  // 3. BOTTOM ACTIONS
                  // Quantity Row (Height 26px to match real card)
                  SizedBox(
                    height: 26,
                    child: Row(
                      children: [
                        Skeleton(width: 24, height: 24), // Small btn
                        SizedBox(width: 4),
                        Expanded(child: Skeleton(width: double.infinity, height: 26)),
                        SizedBox(width: 4),
                        Skeleton(width: 24, height: 24), // Small btn
                      ],
                    ),
                  ),

                  SizedBox(height: 6),

                  // Add to Cart Button (Height 30px to match real card)
                  Skeleton(width: double.infinity, height: 30),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}