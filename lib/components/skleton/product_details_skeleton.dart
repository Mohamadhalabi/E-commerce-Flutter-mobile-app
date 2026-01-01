import 'package:flutter/material.dart';
import 'package:shop/components/skleton/skeleton.dart';
import '../../../../constants.dart';

class ProductDetailsSkeleton extends StatelessWidget {
  const ProductDetailsSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const Icon(Icons.arrow_back_ios_new, color: Colors.grey),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16),
            child: Icon(Icons.shopping_bag_outlined, color: Colors.grey),
          )
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. IMAGE SLIDER SKELETON
            const AspectRatio(
              aspectRatio: 1.1,
              child: Skeleton(width: double.infinity, height: double.infinity),
            ),

            // Thumbnails
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Row(
                children: List.generate(4, (index) => const Padding(
                  padding: EdgeInsets.only(right: 12),
                  child: Skeleton(width: 60, height: 60),
                )),
              ),
            ),

            // 2. PRODUCT INFO SKELETON
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Skeleton(width: 80, height: 12), // Category
                  SizedBox(height: 8),
                  Skeleton(width: 120, height: 14), // SKU
                  SizedBox(height: 12),
                  Skeleton(width: double.infinity, height: 20), // Title line 1
                  SizedBox(height: 6),
                  Skeleton(width: 200, height: 20), // Title line 2

                  SizedBox(height: 16),

                  // Rating Row
                  Row(
                    children: [
                      Skeleton(width: 20, height: 20),
                      SizedBox(width: 8),
                      Skeleton(width: 40, height: 16),
                      SizedBox(width: 8),
                      Skeleton(width: 80, height: 16),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
            const Divider(color: Color(0xFFF0F0F0), thickness: 1),
            const SizedBox(height: 16),

            // 3. TABLE PRICE SKELETON
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Skeleton(width: 120, height: 16), // "Bulk Savings"
                  const SizedBox(height: 12),
                  Row(
                    children: List.generate(3, (index) => const Padding(
                      padding: EdgeInsets.only(right: 10),
                      child: Skeleton(width: 100, height: 80),
                    )),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // 4. ATTRIBUTES / EXPANDABLE SKELETON
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  Skeleton(width: double.infinity, height: 50), // Header
                  SizedBox(height: 10),
                  Skeleton(width: double.infinity, height: 20),
                  SizedBox(height: 10),
                  Skeleton(width: double.infinity, height: 20),
                  SizedBox(height: 10),
                  Skeleton(width: double.infinity, height: 20),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // 5. DESCRIPTION SKELETON
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Skeleton(width: 150, height: 18), // "Description" Header
                  SizedBox(height: 16),
                  Skeleton(width: double.infinity, height: 14),
                  SizedBox(height: 8),
                  Skeleton(width: double.infinity, height: 14),
                  SizedBox(height: 8),
                  Skeleton(width: 300, height: 14),
                ],
              ),
            ),
          ],
        ),
      ),
      // Bottom Bar Skeleton
      bottomNavigationBar: Container(
        height: 80,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
        ),
        child: const Row(
          children: [
            Skeleton(width: 120, height: 50), // Qty
            SizedBox(width: 16),
            Expanded(child: Skeleton(width: double.infinity, height: 50)), // Add btn
          ],
        ),
      ),
    );
  }
}