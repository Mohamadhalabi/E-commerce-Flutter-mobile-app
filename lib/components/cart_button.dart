import 'package:flutter/material.dart';
import '../constants.dart';

class CartButton extends StatelessWidget {
  const CartButton({
    super.key,
    required this.price,
    this.salePrice,
    required this.onAddToCart,
    required this.onBuyNow,
  });

  final double price;
  final double? salePrice;
  final VoidCallback onAddToCart;
  final VoidCallback onBuyNow;

  @override
  Widget build(BuildContext context) {
    final isOnSale = salePrice != null && salePrice! < price;

    return SafeArea(
      child: Container(
        padding: const EdgeInsets.all(12),
        color: const Color(0xFFE5E5E5),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Price Info
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isOnSale)
                    Row(
                      children: [
                        Text(
                          "\$${salePrice!.toStringAsFixed(2)}",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          "\$${price.toStringAsFixed(2)}",
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                      ],
                    )
                  else
                    Text(
                      "\$${price.toStringAsFixed(2)}",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  const Text(
                    "Unit price",
                    style: TextStyle(color: Colors.white60, fontSize: 12),
                  ),
                ],
              ),
            ),

            // Add to Cart Button
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: ElevatedButton(
                  onPressed: onAddToCart,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text("Add to Cart"),
                ),
              ),
            ),

            // Buy Now Button
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.only(left: 4),
                child: ElevatedButton(
                  onPressed: onBuyNow,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text("Buy Now"),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}