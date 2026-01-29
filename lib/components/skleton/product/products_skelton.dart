import 'package:flutter/material.dart';
import '../../../constants.dart';
import 'product_card_skelton.dart';

class ProductsSkelton extends StatelessWidget {
  const ProductsSkelton({super.key});

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;

    // ---------------------------------------------------------
    // 📱 RESPONSIVE CALCULATIONS (Same as Real Product List)
    // ---------------------------------------------------------
    // 1. Tablet Check
    bool isTablet = size.width > 600;

    // 2. Card Width
    // Mobile: / 2.3
    // Tablet: / 4.5
    double cardWidth = isTablet ? size.width / 4.5 : size.width / 2.3;

    // 3. List Height
    // Image (square) + Content (~190px)
    double listHeight = cardWidth + 190;
    // ---------------------------------------------------------

    return SizedBox(
      height: listHeight, // Dynamic Height
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
            width: cardWidth, // Dynamic Width
            child: const ProductCardSkeleton(),
          ),
        ),
      ),
    );
  }
}