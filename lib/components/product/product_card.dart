import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shop/providers/cart_provider.dart';
import '../../constants.dart';
import '../../models/product_model.dart';

class ProductCard extends StatefulWidget {
  const ProductCard({
    super.key,
    required this.product,
    required this.press,
  });

  final ProductModel product;
  final VoidCallback press;

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard> {
  late TextEditingController _qtyController;

  // State for dynamic pricing
  late double _currentUnitPrice;
  late double _regularPrice;

  @override
  void initState() {
    super.initState();
    _qtyController = TextEditingController(text: "1");
    // Default to the regular price from model
    _regularPrice = widget.product.regularPrice;
    _calculatePrice(1);
  }

  @override
  void dispose() {
    _qtyController.dispose();
    super.dispose();
  }

  void _calculatePrice(int qty) {
    double finalPrice = widget.product.effectivePrice;

    // Check table pricing
    if (widget.product.tablePrices.isNotEmpty) {
      for (var tier in widget.product.tablePrices) {
        if (qty >= tier.minQty && (tier.maxQty == null || qty <= tier.maxQty!)) {
          finalPrice = tier.price;
          break;
        }
      }
    }

    if (mounted) {
      setState(() {
        _currentUnitPrice = finalPrice;
      });
    }
  }

  void _incrementQuantity() {
    int current = int.tryParse(_qtyController.text) ?? 1;
    int newQty = current + 1;
    _qtyController.text = newQty.toString();
    _calculatePrice(newQty);
  }

  void _decrementQuantity() {
    int current = int.tryParse(_qtyController.text) ?? 1;
    if (current > 1) {
      int newQty = current - 1;
      _qtyController.text = newQty.toString();
      _calculatePrice(newQty);
    }
  }

  void _handleManualInput(String value) {
    if (value.isEmpty) return;
    int? val = int.tryParse(value);
    if (val != null && val >= 1) {
      _calculatePrice(val);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final Color cardBg = isDark ? const Color(0xFF1E1E2C) : Colors.white;
    final Color textColor = isDark ? Colors.white : const Color(0xFF333333);
    final Color inputBg = isDark ? const Color(0xFF2C2C38) : const Color(0xFFF5F5F5);
    final Color borderColor = isDark ? Colors.white10 : Colors.grey.shade200;

    bool isDiscounted = _currentUnitPrice < _regularPrice;

    return Container(
      // Margin allows shadow to be visible
      margin: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.08),
            offset: const Offset(0, 4),
            blurRadius: 8,
          ),
        ],
        border: isDark ? Border.all(color: Colors.white10) : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. IMAGE & TIMER
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(bottom: BorderSide(color: borderColor, width: 1)),
              ),
              child: Stack(
                children: [
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: widget.press,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        child: AspectRatio(
                          aspectRatio: 1.0,
                          child: Hero(
                            tag: "product_${widget.product.id}",
                            child: Image.network(
                              widget.product.image,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) =>
                                  Icon(Icons.image_not_supported, color: Colors.grey.shade300, size: 40),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (widget.product.discount != null &&
                      widget.product.discount!['end_date'] != null)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: DiscountTimer(endDate: widget.product.discount!['end_date']),
                    ),
                ],
              ),
            ),

            // 2. CONTENT
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "SKU: ${widget.product.sku}",
                      style: const TextStyle(
                        color: greenColor,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.product.title,
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: textColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        height: 1.6,
                      ),
                    ),

                    const Spacer(),

                    // Price Row
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          "\$${_currentUnitPrice.toStringAsFixed(2)}",
                          style: const TextStyle(
                            color: primaryColor,
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(width: 6),
                        if (isDiscounted)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 2),
                            child: Text(
                              "\$${_regularPrice.toStringAsFixed(2)}",
                              style: TextStyle(
                                color: Colors.grey.shade400,
                                fontSize: 11,
                                decoration: TextDecoration.lineThrough,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    // Actions Row
                    Row(
                      children: [
                        Container(
                          height: 28,
                          decoration: BoxDecoration(
                            color: inputBg,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: borderColor),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _buildQtyBtn(Icons.remove, _decrementQuantity, isDark),
                              Container(
                                width: 28,
                                alignment: Alignment.center,
                                child: TextField(
                                  controller: _qtyController,
                                  keyboardType: TextInputType.number,
                                  textAlign: TextAlign.center,
                                  onChanged: _handleManualInput,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                    color: textColor,
                                  ),
                                  decoration: const InputDecoration(
                                    isCollapsed: true,
                                    border: InputBorder.none,
                                  ),
                                  inputFormatters: [
                                    LengthLimitingTextInputFormatter(3),
                                    FilteringTextInputFormatter.digitsOnly,
                                  ],
                                ),
                              ),
                              _buildQtyBtn(Icons.add, _incrementQuantity, isDark),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Consumer<CartProvider>(
                            builder: (context, cart, child) {
                              return SizedBox(
                                height: 28,
                                child: ElevatedButton(
                                  onPressed: () {
                                    int qty = int.tryParse(_qtyController.text) ?? 1;
                                    cart.addToCart(
                                      productId: widget.product.id,
                                      title: widget.product.title,
                                      image: widget.product.image,
                                      sku: widget.product.sku,
                                      price: _currentUnitPrice,
                                      quantity: qty,
                                      stock: widget.product.stock,
                                      context: context,
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: primaryColor,
                                    padding: EdgeInsets.zero,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    elevation: 0,
                                  ),
                                  child: cart.isLoading
                                      ? const SizedBox(
                                    height: 14,
                                    width: 14,
                                    child: CircularProgressIndicator(
                                        color: Colors.white, strokeWidth: 2),
                                  )
                                      : const Icon(Icons.shopping_cart_outlined,
                                      size: 16, color: Colors.white),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQtyBtn(IconData icon, VoidCallback onTap, bool isDark) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          child: Icon(icon, size: 14, color: isDark ? Colors.white70 : Colors.black54),
        ),
      ),
    );
  }
}

class DiscountTimer extends StatefulWidget {
  final String endDate;
  const DiscountTimer({super.key, required this.endDate});

  @override
  State<DiscountTimer> createState() => _DiscountTimerState();
}

class _DiscountTimerState extends State<DiscountTimer> {
  late Timer _timer;
  Duration _timeLeft = Duration.zero;

  @override
  void initState() {
    super.initState();
    _calculateTimeLeft();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _calculateTimeLeft());
  }

  void _calculateTimeLeft() {
    final end = DateTime.tryParse(widget.endDate);
    if (end != null) {
      final now = DateTime.now();
      final diff = end.difference(now);
      if (diff.isNegative) {
        _timer.cancel();
        setState(() => _timeLeft = Duration.zero);
      } else {
        setState(() => _timeLeft = diff);
      }
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_timeLeft.inSeconds <= 0) return const SizedBox.shrink();

    String twoDigits(int n) => n.toString().padLeft(2, "0");
    final days = _timeLeft.inDays;
    final hours = _timeLeft.inHours.remainder(24);
    final minutes = _timeLeft.inMinutes.remainder(60);
    final seconds = _timeLeft.inSeconds.remainder(60);

    String timerText;
    if (days > 0) {
      timerText = "${days}d ${twoDigits(hours)}h ${twoDigits(minutes)}m ${twoDigits(seconds)}s";
    } else {
      timerText = "${twoDigits(hours)}h ${twoDigits(minutes)}m ${twoDigits(seconds)}s";
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
          color: Colors.red.shade600,
          borderRadius: BorderRadius.circular(4),
          boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 2, offset: Offset(0, 1))]
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.access_time_filled, color: Colors.white, size: 10),
          const SizedBox(width: 4),
          Text(
            timerText,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 9,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}