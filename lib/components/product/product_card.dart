import 'package:flutter/material.dart';

import '../../constants.dart';
class ProductCard extends StatefulWidget {
  const ProductCard({
    super.key,
    required this.id,
    required this.image,
    required this.category,
    required this.title,
    required this.price,
    required this.rating,
    required this.sku,
    this.salePrice,
    this.dicountpercent,
    this.discount,
    this.freeShipping,
    required this.press,
  });

  final String image, category, title, sku;
  final double price, rating;
  final double? salePrice;
  final Map<String, dynamic>? discount;
  final int? dicountpercent, id;
  final bool? freeShipping;
  final VoidCallback press;

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final discount = widget.discount;
    return OutlinedButton(
      onPressed: widget.press,
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
                      child: Image.network(
                        widget.image,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),

                if (discount != null &&
                    discount['type'] != null &&
                    discount['value'] != null)
                  Positioned(
                    right: defaultPadding / 2,
                    top: defaultPadding / 2,
                    child: ScaleTransition(
                      scale: _scaleAnimation,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: defaultPadding / 2),
                        height: 16,
                        decoration: const BoxDecoration(
                          color: errorColor,
                          borderRadius: BorderRadius.all(Radius.circular(defaultBorderRadious)),
                        ),
                        child: Builder(
                          builder: (context) {
                            String label = '';
                            final String? discountType = discount['type'];
                            final dynamic discountValue = discount['value'];

                            if (discountType == 'percent') {
                              double percent = double.tryParse(discountValue.toString()) ?? 0;
                              label = '${percent.toStringAsFixed(0)}% OFF';
                            } else if (discountType == 'fixed') {
                              double fixed = double.tryParse(discountValue.toString()) ?? 0;
                              label = '\$${fixed.toStringAsFixed(0)} OFF';
                            }

                            return Text(
                              label,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
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
                      widget.category,
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
                    widget.sku,
                    style: const TextStyle(
                      fontSize: 12,
                      color: greenColor,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  Text(
                    widget.title,
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
                      if (index < widget.rating.floor()) {
                        return const Icon(Icons.star, color: Colors.amber, size: 14);
                      } else if (index < widget.rating && widget.rating - index >= 0.5) {
                        return const Icon(Icons.star_half, color: Colors.amber, size: 14);
                      } else {
                        return const Icon(Icons.star_border, color: Colors.amber, size: 14);
                      }
                    }),
                  ),
                  const SizedBox(height: defaultPadding / 2),
                  // ... price section continues here
                  Builder(
                    builder: (context) {
                      double finalPrice = widget.price;
                      String? discountType = discount?['type'];
                      dynamic discountValue = discount?['value'];

                      if (discount != null && discountType != null && discountValue != null) {
                        if (discountType == 'fixed') {
                          finalPrice = widget.price - double.tryParse(discountValue.toString())!;
                        } else if (discountType == 'percent') {
                          finalPrice = widget.price - (widget.price * (double.tryParse(discountValue.toString())! / 100));
                        }
                      }

                      bool isStandardDiscount = discountType == 'fixed' || discountType == 'percent';
                      bool showSalePriceInstead = !isStandardDiscount && widget.salePrice != null;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (isStandardDiscount)
                            Row(
                              children: [
                                Text(
                                  "\$${finalPrice.toStringAsFixed(2)}",
                                  style: const TextStyle(
                                    color: Color(0xFFF52020),
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(width: defaultPadding / 4),
                                Text(
                                  "\$${widget.price.toStringAsFixed(2)}",
                                  style: TextStyle(
                                    color: Theme.of(context).textTheme.bodyMedium!.color,
                                    fontSize: 14,
                                    decoration: TextDecoration.lineThrough,
                                  ),
                                ),
                              ],
                            )
                          else if (showSalePriceInstead)
                            Row(
                              children: [
                                Text(
                                  "\$${widget.salePrice!.toStringAsFixed(2)}",
                                  style: const TextStyle(
                                    color: Color(0xFFF52020),
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(width: defaultPadding / 4),
                                Text(
                                  "\$${widget.price.toStringAsFixed(2)}",
                                  style: TextStyle(
                                    color: Theme.of(context).textTheme.bodyMedium!.color,
                                    fontSize: 14,
                                    decoration: TextDecoration.lineThrough,
                                  ),
                                ),
                              ],
                            )
                          else
                            Text(
                              "\$${widget.price.toStringAsFixed(2)}",
                              style: const TextStyle(
                                color: Color(0xFFF52020),
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                        ],
                      );
                    },
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
