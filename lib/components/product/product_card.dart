import 'package:flutter/material.dart';

import '../../constants.dart';
import '../network_image_with_loader.dart';

class ProductCard extends StatelessWidget {
  const ProductCard({
    super.key,
    required this.image,
    required this.category,
    required this.title,
    required this.price,
    required this.rating,
    required this.sku,
    this.priceAfetDiscount,
    this.dicountpercent,
    required this.press,
  });
  final String image, category, title, sku;
  final double price, rating;
  final double? priceAfetDiscount;
  final int? dicountpercent;
  final VoidCallback press;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: press,
      style: OutlinedButton.styleFrom(
          minimumSize: const Size(160, 160),
          maximumSize: const Size(160, 160),
          padding: const EdgeInsets.all(0.2)),
      child: Column(
        children: [
          AspectRatio(
            aspectRatio: 1,
            child: Stack(
              children: [
                Center(
                  child: Container(
                    decoration: BoxDecoration(
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          offset: const Offset(0, 8), // Only bottom shadow
                          blurRadius: 15,
                          spreadRadius: 0,
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(defaultBorderRadious),
                      child: NetworkImageWithLoader(
                        image,
                        radius: defaultBorderRadious,
                      ),
                    ),
                  ),
                ),

                if (dicountpercent != null)
                  Positioned(
                    right: defaultPadding / 2,
                    top: defaultPadding / 2,
                    child: Container(
                      padding:
                      const EdgeInsets.symmetric(horizontal: defaultPadding / 2),
                      height: 16,
                      decoration: const BoxDecoration(
                        color: errorColor,
                        borderRadius: BorderRadius.all(
                            Radius.circular(defaultBorderRadious)),
                      ),
                      child: Text(
                        "$dicountpercent% off",
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w500),
                      ),
                    ),
                  )
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: defaultPadding / 2, vertical: defaultPadding / 2),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: defaultPadding / 2),
                  Center(
                    child: Text(
                      category,
                      maxLines: 1,
                      style: const TextStyle(
                        fontSize: 12,
                        color: whileColor60,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: defaultPadding / 2),
                  Text(
                    sku,
                    style: const TextStyle(
                      fontSize: 12,
                      color: greenColor,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall!
                        .copyWith(fontSize: 12),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: List.generate(5, (index) {
                      if (index < rating.floor()) {
                        return const Icon(Icons.star, color: Colors.amber, size: 14);
                      } else if (index < rating && rating - index >= 0.5) {
                        return const Icon(Icons.star_half, color: Colors.amber, size: 14);
                      } else {
                        return const Icon(Icons.star_border, color: Colors.amber, size: 14);
                      }
                    }),
                  ),
                  const SizedBox(height: defaultPadding / 2),
                  // ... price section continues here
                  priceAfetDiscount != null
                      ? Row(
                    children: [
                      Text(
                        "\$$priceAfetDiscount",
                        style: const TextStyle(
                          color: Color(0xFFF52020),
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(width: defaultPadding / 4),
                      Text(
                        "\$$price",
                        style: TextStyle(
                          color: Theme.of(context).textTheme.bodyMedium!.color,
                          fontSize: 14,
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                    ],
                  )
                      : Text(
                    "\$$price",
                    style: const TextStyle(
                      color: Color(0xFFF52020),
                      fontWeight: FontWeight.w500,
                      fontSize: 12,
                    ),
                  ),
                  const Spacer(),
                  /// 🛒 Add to Cart button here
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        // Add your add to cart logic here
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: redColor, // Or your theme color
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        "Add to Cart",
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ),
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
