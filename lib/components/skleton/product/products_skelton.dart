import 'package:flutter/material.dart';
import '../../../constants.dart';
import 'product_card_skelton.dart';

class ProductsSkelton extends StatelessWidget {
  const ProductsSkelton({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      // FIXED: Increased height to 420 to match your real Product Card height.
      // 250 was too small, causing the "RenderFlex overflowed" error.
      height: 420,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 5,
        physics: const NeverScrollableScrollPhysics(), // Optional: disable scrolling while loading
        itemBuilder: (context, index) => Padding(
          padding: EdgeInsets.only(
            left: defaultPadding,
            right: index == 4 ? defaultPadding : 0,
          ),
          child: const ProductCardSkeleton(),
        ),
      ),
    );
  }
}