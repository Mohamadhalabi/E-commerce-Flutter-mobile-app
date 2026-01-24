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
    this.stock = 9999,
    required this.press,
  });

  final String image, category, title, sku;
  final double price, rating;
  final double? salePrice;
  final Map<String, dynamic>? discount;
  final int? id;
  final bool? freeShipping;
  final int stock;
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
    // 1. Detect Dark Mode
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // 2. Define Dynamic Colors
    final Color cardBg = isDark ? const Color(0xFF1C1C23) : Colors.white;
    final Color borderColor = isDark ? Colors.white10 : const Color(0xFFF0F0F0);
    final Color textColor = isDark ? Colors.white : Colors.black87;
    // Light Green for Dark Mode visibility, Dark Green for Light Mode
    final Color skuColor = isDark ? Colors.greenAccent.shade100 : Colors.green.shade900;

    // Inputs
    final Color inputBg = isDark ? const Color(0xFF2A2A35) : const Color(0xFFFAFAFA);
    final Color inputBorder = isDark ? Colors.white12 : Colors.grey.shade200;
    final Color btnBg = isDark ? const Color(0xFF2A2A35) : Colors.white;
    final Color btnIconColor = isDark ? Colors.white70 : Colors.black54;

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        border: Border.all(color: borderColor, width: 1),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            offset: const Offset(0, 2),
            blurRadius: 4,
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
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white, // Keep image bg white for consistency
                borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
              ),
              child: AspectRatio(
                aspectRatio: 1.0,
                child: Image.network(
                  widget.image,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) =>
                  const Icon(Icons.image_not_supported, color: Colors.grey, size: 30),
                ),
              ),
            ),
          ),

          // ------------------------------------------
          // 2. CONTENT SECTION
          // ------------------------------------------
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(6, 6, 6, 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // SKU
                  Text(
                    "SKU: ${widget.sku}",
                    style: TextStyle(
                      color: skuColor, // Dynamic SKU Color
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 2),

                  // TITLE
                  Text(
                    widget.title,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: textColor, // Dynamic Title Color
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      height: 1.5,
                    ),
                  ),

                  const Spacer(),
                  const SizedBox(height: 4),

                  // PRICE
                  Text(
                    "\$${widget.price.toStringAsFixed(2)}",
                    style: const TextStyle(
                      color: primaryColor,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 6),

                  // ------------------------------------------
                  // 3. COMPACT BOTTOM ACTIONS
                  // ------------------------------------------
                  // Quantity Row
                  SizedBox(
                    height: 26,
                    child: Row(
                      children: [
                        _buildQtyBtn(Icons.remove, _decrementQuantity, btnBg, inputBorder, btnIconColor),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Container(
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              border: Border.all(color: inputBorder),
                              borderRadius: BorderRadius.circular(4),
                              color: inputBg,
                            ),
                            child: TextField(
                              controller: _qtyController,
                              keyboardType: TextInputType.number,
                              textAlign: TextAlign.center,
                              textAlignVertical: TextAlignVertical.center,
                              onChanged: _handleManualInput,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                LengthLimitingTextInputFormatter(3),
                              ],
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                                color: textColor, // Dynamic Input Text
                              ),
                              decoration: const InputDecoration(
                                isCollapsed: true,
                                border: InputBorder.none,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        _buildQtyBtn(Icons.add, _incrementQuantity, btnBg, inputBorder, btnIconColor),
                      ],
                    ),
                  ),

                  const SizedBox(height: 6),

                  // Add to Cart Button
                  SizedBox(
                    width: double.infinity,
                    height: 30,
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
                                stock: widget.stock,
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
                              borderRadius: BorderRadius.circular(4),
                            ),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: cartProvider.isLoading
                              ? const SizedBox(
                            height: 14,
                            width: 14,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                              : const Text(
                            "Add",
                            style: TextStyle(
                              fontSize: 11,
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

  Widget _buildQtyBtn(IconData icon, VoidCallback onTap, Color bg, Color border, Color iconColor) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: bg,
          border: Border.all(color: border),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Icon(
          icon,
          size: 14,
          color: iconColor,
        ),
      ),
    );
  }
}