import 'package:flutter/material.dart';
import '../../../constants.dart';
import 'product_card_skelton.dart';

class ProductsSkelton extends StatelessWidget {
  const ProductsSkelton({super.key});

  @override
  Widget build(BuildContext context) {
    // Calculate width to match the real product card (2.5 items per row)
    double cardWidth = (MediaQuery.of(context).size.width / 2.5) - 16;

    return SizedBox(
      // FIXED: Height reduced to 330 to match the new compact design
      height: 330,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 5,
        physics: const NeverScrollableScrollPhysics(),
        itemBuilder: (context, index) => Padding(
          padding: EdgeInsets.only(
            left: defaultPadding,
            right: index == 4 ? defaultPadding : 0,
          ),
          child: SizedBox(
            width: cardWidth, // Force the skeleton to the correct width
            child: const ProductCardSkeleton(),
          ),
        ),
      ),
    );
  }
}