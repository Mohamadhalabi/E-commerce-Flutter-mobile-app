import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
    this.discount,
    this.freeShipping,
    required this.press,
  });

  final String image, category, title, sku;
  final double price, rating;
  final double? salePrice;
  final Map<String, dynamic>? discount;
  final int? id;
  final bool? freeShipping;
  final VoidCallback press;

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard> {
  late TextEditingController _qtyController;

  @override
  void initState() {
    super.initState();
    _qtyController = TextEditingController(text: "1");
  }

  @override
  void dispose() {
    _qtyController.dispose();
    super.dispose();
  }

  void _incrementQuantity() {
    int current = int.tryParse(_qtyController.text) ?? 1;
    setState(() {
      _qtyController.text = (current + 1).toString();
    });
  }

  void _decrementQuantity() {
    int current = int.tryParse(_qtyController.text) ?? 1;
    if (current > 1) {
      setState(() {
        _qtyController.text = (current - 1).toString();
      });
    }
  }

  void _handleManualInput(String value) {
    if (value.isEmpty) return;
    int? val = int.tryParse(value);
    if (val != null && val < 1) {
      _qtyController.text = "1";
      _qtyController.selection = TextSelection.fromPosition(
        TextPosition(offset: _qtyController.text.length),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      decoration: BoxDecoration(
        color: whiteColor,
        borderRadius: BorderRadius.circular(defaultBorderRadious),
        border: Border.all(color: blackColor10),
        boxShadow: [
          BoxShadow(
            color: blackColor.withOpacity(0.05),
            offset: const Offset(0, 4),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, // Align everything to left
        children: [
          // 1. Image Section
          GestureDetector(
            onTap: widget.press,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(defaultPadding / 2),
              decoration: const BoxDecoration(
                color: whiteColor,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(defaultBorderRadious),
                ),
                border: Border(
                  bottom: BorderSide(color: blackColor10, width: 1),
                ),
              ),
              child: AspectRatio(
                aspectRatio: 1.1,
                child: Image.network(
                  widget.image,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),

          // 2. Details Section
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(defaultPadding / 2),
              child: Column(
                // CHANGED: Aligned to start (Left)
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // CHANGED: Category and SKU in same row
                  Row(
                    children: [
                      const SizedBox(width: 6),
                      // SKU
                      Text(
                        widget.sku,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: greenColor, // Green for SKU
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 4),

                  // CHANGED: Title Left Aligned & Increased Height
                  Text(
                    widget.title,
                    textAlign: TextAlign.left,
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: blackColor,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      height: 1.7, // Increased line height for better spacing
                    ),
                  ),

                  const Spacer(),

                  // Price
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Text(
                      "\$${widget.price.toStringAsFixed(2)}",
                      style: const TextStyle(
                        color: primaryColor,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),

                  // Quantity Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildQuantityButton(
                        icon: Icons.remove,
                        onTap: _decrementQuantity,
                      ),

                      // Manual Input Field
                      Container(
                        width: 90,
                        height: 40,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: whiteColor,
                          border: Border.all(color: blackColor10),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: TextField(
                          controller: _qtyController,
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          onChanged: _handleManualInput,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(3),
                          ],
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: blackColor,
                          ),
                          decoration: const InputDecoration(
                            contentPadding: EdgeInsets.only(bottom: 8),
                            border: InputBorder.none,
                            isDense: true,
                          ),
                        ),
                      ),

                      _buildQuantityButton(
                        icon: Icons.add,
                        onTap: _incrementQuantity,
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Add to Cart Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        int qty = int.tryParse(_qtyController.text) ?? 1;
                        print("Added $qty of ${widget.title} to cart");
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: whiteColor,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        "Add to Cart",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
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

  Widget _buildQuantityButton({required IconData icon, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: whiteColor,
          border: Border.all(color: blackColor10),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Icon(
          icon,
          size: 20,
          color: blackColor60,
        ),
      ),
    );
  }
}