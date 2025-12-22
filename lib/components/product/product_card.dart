import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shop/providers/cart_provider.dart';
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
    this.stock = 9999, // ✅ Added stock parameter (default to high if unknown)
    required this.press,
  });

  final String image, category, title, sku;
  final double price, rating;
  final double? salePrice;
  final Map<String, dynamic>? discount;
  final int? id;
  final bool? freeShipping;
  final int stock; // ✅ Field for stock
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
        color: Colors.white,
        border: Border.all(color: const Color(0xFFEEEEEE), width: 1),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(0, 3),
            blurRadius: 6,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ------------------------------------------
          // 1. IMAGE SECTION
          // ------------------------------------------
          GestureDetector(
            onTap: widget.press,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
              ),
              child: AspectRatio(
                aspectRatio: 1.1,
                child: Image.network(
                  widget.image,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) =>
                  const Icon(Icons.image_not_supported, color: Colors.grey),
                ),
              ),
            ),
          ),

          // ------------------------------------------
          // 2. CONTENT SECTION
          // ------------------------------------------
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // SKU
                  Text(
                    "SKU: ${widget.sku}",
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),

                  const SizedBox(height: 4),

                  // TITLE
                  Text(
                    widget.title,
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.black87,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      height: 1.5,
                    ),
                  ),

                  const Spacer(),
                  const SizedBox(height: 6),

                  // PRICE
                  Text(
                    "\$${widget.price.toStringAsFixed(2)}",
                    style: const TextStyle(
                      color: primaryColor,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),

                  const SizedBox(height: 8),

                  // ------------------------------------------
                  // 3. BOTTOM ACTIONS
                  // ------------------------------------------
                  Row(
                    children: [
                      _buildQtyBtn(Icons.remove, _decrementQuantity),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Container(
                          height: 32,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade200),
                            borderRadius: BorderRadius.circular(4),
                            color: const Color(0xFFF9F9F9),
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
                              fontSize: 13,
                              color: Colors.black87,
                            ),
                            decoration: const InputDecoration(
                              contentPadding: EdgeInsets.only(bottom: 14),
                              border: InputBorder.none,
                              isDense: true,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      _buildQtyBtn(Icons.add, _incrementQuantity),
                    ],
                  ),

                  const SizedBox(height: 10),

                  // Add to Cart Button
                  SizedBox(
                    width: double.infinity,
                    height: 38,
                    child: Consumer<CartProvider>(
                      builder: (context, cartProvider, child) {
                        return ElevatedButton(
                          onPressed: () {
                            int qty = int.tryParse(_qtyController.text) ?? 1;
                            if (widget.id != null) {
                              cartProvider.addToCart(
                                productId: widget.id!,
                                title: widget.title,
                                image: widget.image,
                                sku: widget.sku,
                                price: widget.salePrice ?? widget.price,
                                quantity: qty,
                                stock: widget.stock, // ✅ Pass Stock Here
                                context: context,
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: EdgeInsets.zero,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                          child: cartProvider.isLoading
                              ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                              : const Text(
                            "Add to Cart",
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        );
                      },
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

  Widget _buildQtyBtn(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Icon(
          icon,
          size: 16,
          color: Colors.black54,
        ),
      ),
    );
  }
}