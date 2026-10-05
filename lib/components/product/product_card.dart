import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
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
  late final TextEditingController _qtyController;
  late double _currentUnitPrice;
  late double _regularPrice;

  // Only THIS card shows a spinner, not every card on screen
  bool _isAdding = false;

  @override
  void initState() {
    super.initState();
    _qtyController = TextEditingController(text: '1');
    _resetPricing();
  }

  @override
  void didUpdateWidget(covariant ProductCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Lists recycle states — reset when a different product lands here
    if (oldWidget.product.id != widget.product.id) {
      _qtyController.text = '1';
      _resetPricing();
    }
  }

  @override
  void dispose() {
    _qtyController.dispose();
    super.dispose();
  }

  void _resetPricing() {
    _regularPrice = widget.product.regularPrice;
    _currentUnitPrice = _priceForQty(1);
  }

  double _priceForQty(int qty) {
    for (final tier in widget.product.tablePrices) {
      if (qty >= tier.minQty && (tier.maxQty == null || qty <= tier.maxQty!)) {
        return tier.price;
      }
    }
    return widget.product.effectivePrice;
  }

  int get _qty => int.tryParse(_qtyController.text) ?? 1;

  void _setQty(int qty) {
    final q = qty < 1 ? 1 : (qty > 999 ? 999 : qty);
    _qtyController.text = '$q';
    setState(() => _currentUnitPrice = _priceForQty(q));
  }

  void _onQtyTyped(String value) {
    final q = int.tryParse(value);
    if (q != null && q >= 1) {
      setState(() => _currentUnitPrice = _priceForQty(q));
    }
  }

  void _addToCart(CartProvider cart) {
    FocusScope.of(context).unfocus();
    HapticFeedback.lightImpact();
    setState(() => _isAdding = true);
    cart.addToCart(
      productId: widget.product.id,
      title: widget.product.title,
      image: widget.product.image,
      sku: widget.product.sku,
      price: _currentUnitPrice,
      quantity: _qty,
      stock: widget.product.stock,
      context: context,
    );
  }

  Future<void> _launchWhatsApp() async {
    final message = Uri.encodeComponent(
        "Hi, I want to ask about ${widget.product.title}\nSKU: ${widget.product.sku}");
    final waUrl = Uri.parse('https://wa.me/971504429045?text=$message');
    if (!await launchUrl(waUrl, mode: LaunchMode.externalApplication)) {
      debugPrint('Could not launch WhatsApp');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppPalette.isDark(context);
    final textColor = AppPalette.text(context);
    final mutedColor = AppPalette.textMuted(context);

    final isDiscounted = _currentUnitPrice < _regularPrice;
    final discountPct = isDiscounted && _regularPrice > 0
        ? ((1 - _currentUnitPrice / _regularPrice) * 100).round()
        : 0;

    return Container(
      margin: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: AppPalette.card(context),
        borderRadius: BorderRadius.circular(cardRadius),
        border: Border.all(color: AppPalette.border(context)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.35 : 0.06),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(cardRadius),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: widget.press, // whole card opens the product now
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildImage(discountPct),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(10, 6, 10, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "SKU: ${widget.product.sku}",
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: isDark ? Colors.green.shade400 : greenColor,
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
                          height: 1.55,
                        ),
                      ),
                      const Spacer(),
                      _buildPriceRow(isDiscounted, textColor, mutedColor),
                      const SizedBox(height: 8),
                      if (widget.product.hidePrice)
                        _buildWhatsAppButton()
                      else
                        _buildActions(textColor),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImage(int discountPct) {
    final endDate = widget.product.discount?['end_date'];

    return Padding(
      padding: const EdgeInsets.all(6),
      child: AspectRatio(
        aspectRatio: 1,
        child: Container(
          // Product photos have white backgrounds — an inset white tile
          // looks intentional in dark mode instead of a harsh white block.
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(cardRadius - 4),
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Padding(
                padding: const EdgeInsets.all(10),
                child: Hero(
                  tag: "product_${widget.product.id}",
                  child: Image.network(
                    widget.product.image,
                    fit: BoxFit.contain,
                    loadingBuilder: (context, child, progress) =>
                    progress == null
                        ? child
                        : Center(
                      child: SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: primaryColor.withOpacity(0.5),
                        ),
                      ),
                    ),
                    errorBuilder: (context, error, stackTrace) => Icon(
                      Icons.image_not_supported_outlined,
                      color: blackColor20,
                      size: 36,
                    ),
                  ),
                ),
              ),
              if (discountPct > 0)
                Positioned(
                  top: 6,
                  left: 6,
                  child: Container(
                    padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: primaryColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '-$discountPct%',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              if (endDate != null)
                Positioned(
                  left: 6,
                  right: 6,
                  bottom: 6,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: DiscountTimer(endDate: endDate.toString()),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPriceRow(bool isDiscounted, Color textColor, Color mutedColor) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Flexible(
          child: Text(
            "\$${_currentUnitPrice.toStringAsFixed(2)}",
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: primaryColor, // price is always red
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        if (isDiscounted) ...[
          const SizedBox(width: 6),
          Padding(
            padding: const EdgeInsets.only(bottom: 2),
            child: Text(
              "\$${_regularPrice.toStringAsFixed(2)}",
              style: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 11,
                fontWeight: FontWeight.w500,
                decoration: TextDecoration.lineThrough,
                decorationColor: Colors.grey.shade500,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildActions(Color textColor) {
    final iconColor = AppPalette.textMuted(context);

    return Row(
      children: [
        Container(
          height: 32,
          decoration: BoxDecoration(
            color: AppPalette.cardElevated(context),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _qtyButton(Icons.remove_rounded, () => _setQty(_qty - 1), iconColor),
              SizedBox(
                width: 26,
                child: TextField(
                  controller: _qtyController,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  onChanged: _onQtyTyped,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 12.5,
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
              _qtyButton(Icons.add_rounded, () => _setQty(_qty + 1), iconColor),
            ],
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Consumer<CartProvider>(
            builder: (context, cart, _) {
              // Clear our flag once the provider finishes
              if (_isAdding && !cart.isLoading) _isAdding = false;
              final busy = _isAdding && cart.isLoading;

              return SizedBox(
                height: 32,
                child: ElevatedButton(
                  onPressed: busy ? null : () => _addToCart(cart),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    disabledBackgroundColor: primaryColor.withOpacity(0.7),
                    padding: EdgeInsets.zero,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: busy
                      ? const SizedBox(
                    height: 14,
                    width: 14,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                      : const Icon(
                    Icons.add_shopping_cart_rounded,
                    size: 17,
                    color: Colors.white,
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildWhatsAppButton() {
    return SizedBox(
      height: 32,
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _launchWhatsApp,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1DA851),
          padding: const EdgeInsets.symmetric(horizontal: 6),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: const FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.chat_bubble_outline_rounded,
                  size: 14, color: Colors.white),
              SizedBox(width: 5),
              Text(
                "Contact on WhatsApp",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _qtyButton(IconData icon, VoidCallback onTap, Color color) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        width: 24,
        height: 32,
        child: Icon(icon, size: 16, color: color),
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
  Timer? _timer;
  Duration _timeLeft = Duration.zero;

  @override
  void initState() {
    super.initState();
    _start();
  }

  @override
  void didUpdateWidget(covariant DiscountTimer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.endDate != widget.endDate) {
      _timer?.cancel();
      _start();
    }
  }

  // Fixes a crash: the old version could call _timer.cancel() before
  // _timer was assigned when the sale had already ended.
  void _start() {
    final end = DateTime.tryParse(widget.endDate);
    if (end == null) {
      _timeLeft = Duration.zero;
      return;
    }
    _timeLeft = _remaining(end);
    if (_timeLeft > Duration.zero) {
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        final left = _remaining(end);
        if (left <= Duration.zero) _timer?.cancel();
        if (mounted) setState(() => _timeLeft = left);
      });
    }
  }

  Duration _remaining(DateTime end) {
    final diff = end.difference(DateTime.now());
    return diff.isNegative ? Duration.zero : diff;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_timeLeft <= Duration.zero) return const SizedBox.shrink();

    String two(int n) => n.toString().padLeft(2, '0');
    final d = _timeLeft.inDays;
    final h = _timeLeft.inHours.remainder(24);
    final m = _timeLeft.inMinutes.remainder(60);
    final s = _timeLeft.inSeconds.remainder(60);
    final text = d > 0
        ? '${d}d ${two(h)}:${two(m)}:${two(s)}'
        : '${two(h)}:${two(m)}:${two(s)}';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: blackColor.withOpacity(0.78),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.bolt_rounded, color: warningColor, size: 12),
          const SizedBox(width: 3),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 9.5,
              fontWeight: FontWeight.w700,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}