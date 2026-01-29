import 'package:flutter/material.dart';
import '../skeleton.dart';

class ProductCardSkeleton extends StatelessWidget {
  const ProductCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFF0F0F0), width: 1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. IMAGE SECTION
          Padding(
            padding: EdgeInsets.all(12),
            child: AspectRatio(
              aspectRatio: 1.0,
              child: Skeleton(
                width: double.infinity,
                height: double.infinity,
              ),
            ),
          ),

          // 2. CONTENT SECTION
          Expanded(
            child: Padding(
              padding: EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // SKU
                  Skeleton(width: 50, height: 8),
                  SizedBox(height: 6),

                  // Title
                  Skeleton(width: double.infinity, height: 10),
                  SizedBox(height: 6),
                  Skeleton(width: double.infinity, height: 10),
                  SizedBox(height: 6),
                  Skeleton(width: 80, height: 10),

                  Spacer(),

                  // Price
                  Skeleton(width: 60, height: 16),
                  SizedBox(height: 10),

                  // 3. BOTTOM ACTIONS
                  Row(
                    children: [
                      // Quantity Box
                      Skeleton(width: 80, height: 28),
                      SizedBox(width: 8),

                      // Add Button (The Error was here)
                      Expanded(
                        child: Skeleton(
                          width: double.infinity, // [FIX] Added required width
                          height: 28,
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