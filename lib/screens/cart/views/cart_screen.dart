import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shop/providers/auth_provider.dart';
import 'package:shop/providers/cart_provider.dart';
import 'package:shop/constants.dart';
import 'package:shop/route/route_constants.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:shop/components/common/CustomBottomNavigationBar.dart';

class CartScreen extends StatefulWidget {
  final bool isStandalone;

  const CartScreen({super.key, this.isStandalone = false});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _initCart();
    });
  }

  void _initCart() {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final cart = Provider.of<CartProvider>(context, listen: false);

    if (auth.isAuthenticated && !cart.isLoggedIn) {
      cart.setAuthToken(auth.token);
    } else if (cart.isLoggedIn) {
      cart.fetchServerCart();
    } else {
      cart.loadCart();
    }
  }

  Future<void> _onRefresh() async {
    final cart = Provider.of<CartProvider>(context, listen: false);
    if (cart.isLoggedIn) {
      await cart.fetchServerCart();
    } else {
      await cart.loadCart();
    }
  }

  void _onBottomNavTap(int index) {
    if (index == 3) return; // already on the cart
    // Go back to the main app on the chosen tab, like every other screen does
    Navigator.pushNamedAndRemoveUntil(
      context,
      entryPointScreenRoute,
          (route) => false,
      arguments: index,
    );
  }

  void _goBack() {
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    } else {
      Navigator.pushReplacementNamed(context, entryPointScreenRoute);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tr = AppLocalizations.of(context)!;
    final bg = Theme.of(context).scaffoldBackgroundColor;
    // As a bottom tab there's nothing to go back to
    final showBack = widget.isStandalone || Navigator.canPop(context);

    return Scaffold(
      backgroundColor: bg,
      extendBody: widget.isStandalone,
      appBar: AppBar(
        backgroundColor: bg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
        leadingWidth: 64,
        leading: showBack
            ? Padding(
          padding: const EdgeInsetsDirectional.only(start: defaultPadding),
          child: Center(
            child: _RoundButton(
              icon: Icons.arrow_back_ios_new_rounded,
              semanticLabel: 'Back',
              onTap: _goBack,
            ),
          ),
        )
            : null,
        title: Consumer<CartProvider>(
          builder: (context, cart, _) => Column(
            children: [
              Text(
                tr.myCart,
                style: TextStyle(
                  color: AppPalette.text(context),
                  fontWeight: FontWeight.w800,
                  fontSize: 17,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                "${cart.cartItems.length} ${tr.items}",
                style: TextStyle(
                  color: AppPalette.textMuted(context),
                  fontSize: 12.5,
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: widget.isStandalone
          ? CustomBottomNavigationBar(currentIndex: 3, onTap: _onBottomNavTap)
          : null,
      body: Consumer<CartProvider>(
        builder: (context, cart, _) {
          if (cart.isLoading && cart.cartItems.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(color: primaryColor),
            );
          }

          // Includes the floating nav height when it overlaps this screen
          final bottomInset = MediaQuery.paddingOf(context).bottom;

          if (cart.cartItems.isEmpty) {
            return Padding(
              padding: EdgeInsets.only(bottom: bottomInset),
              child: _EmptyCartState(onStartShopping: _goBack),
            );
          }

          final unavailableSkus = cart.cartItems
              .where((item) => item.quantity > item.stock)
              .map((item) => item.sku)
              .toList();

          return Column(
            children: [
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _onRefresh,
                  color: primaryColor,
                  backgroundColor: AppPalette.card(context),
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(defaultPadding, 8, defaultPadding, 12),
                    children: [
                      if (unavailableSkus.isNotEmpty)
                        _StockWarning(
                          message: tr.stockLimitWarning(unavailableSkus.join(", ")),
                        ),
                      for (final item in cart.cartItems)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _CartItemTile(item: item),
                        ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(
                  defaultPadding,
                  4,
                  defaultPadding,
                  bottomInset + 10,
                ),
                child: _CheckoutCard(cart: cart),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// SHARED
// ---------------------------------------------------------------------------
class _RoundButton extends StatelessWidget {
  const _RoundButton({
    required this.icon,
    required this.semanticLabel,
    required this.onTap,
    this.size = 42,
    this.iconSize = 17,
  });

  final IconData icon;
  final String semanticLabel;
  final VoidCallback onTap;
  final double size;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticLabel,
      child: Material(
        color: AppPalette.cardElevated(context),
        shape: CircleBorder(side: BorderSide(color: AppPalette.border(context))),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox(
            width: size,
            height: size,
            child: Icon(icon, size: iconSize, color: AppPalette.text(context)),
          ),
        ),
      ),
    );
  }
}

Future<bool> _confirmRemove(BuildContext context) async {
  final tr = AppLocalizations.of(context)!;
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: AppPalette.card(context),
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(
        tr.removeItem,
        style: TextStyle(
          color: AppPalette.text(context),
          fontWeight: FontWeight.w800,
          fontSize: 18,
        ),
      ),
      content: Text(
        tr.removeItemConfirmation,
        style: TextStyle(color: AppPalette.textMuted(context), fontSize: 14),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          style: TextButton.styleFrom(foregroundColor: AppPalette.text(context)),
          child: Text(tr.cancel),
        ),
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          style: TextButton.styleFrom(foregroundColor: primaryColor),
          child: Text(
            tr.remove,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    ),
  );
  return result ?? false;
}

// ---------------------------------------------------------------------------
// PIECES
// ---------------------------------------------------------------------------
class _StockWarning extends StatelessWidget {
  const _StockWarning({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    final isDark = AppPalette.isDark(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: primaryColor.withOpacity(isDark ? 0.14 : 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: primaryColor.withOpacity(0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: const BoxDecoration(
              color: primaryColor,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.priority_high_rounded,
                color: Colors.white, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Some items exceed available stock",
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: primaryColor,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  message,
                  style: TextStyle(
                    color: isDark ? Colors.red.shade200 : primaryDarkColor,
                    fontSize: 12,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CartItemTile extends StatelessWidget {
  final CartItem item;
  const _CartItemTile({required this.item});

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context, listen: false);
    final isDark = AppPalette.isDark(context);
    final textColor = AppPalette.text(context);

    final rowTotal = item.price * item.quantity;
    final isOverStock = item.quantity > item.stock;

    return Dismissible(
      key: Key(item.id.toString()),
      direction: DismissDirection.endToStart,
      background: Container(
        padding: const EdgeInsetsDirectional.only(end: 24),
        alignment: AlignmentDirectional.centerEnd,
        decoration: BoxDecoration(
          color: primaryColor.withOpacity(isDark ? 0.2 : 0.1),
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Icon(Icons.delete_outline_rounded, color: primaryColor, size: 26),
      ),
      confirmDismiss: (_) => _confirmRemove(context),
      onDismissed: (_) => cart.removeItem(item.id, context),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppPalette.card(context),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isOverStock ? primaryColor : AppPalette.border(context),
            width: isOverStock ? 1.4 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.3 : 0.04),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 84,
              height: 84,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppPalette.border(context)),
              ),
              child: item.image.isNotEmpty
                  ? Image.network(
                item.image,
                fit: BoxFit.contain,
                errorBuilder: (c, e, s) => const Icon(
                  Icons.image_not_supported_outlined,
                  color: blackColor20,
                ),
              )
                  : const Icon(Icons.image_outlined, color: blackColor20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (item.sku.isNotEmpty)
                              Text(
                                "SKU: ${item.sku}",
                                style: TextStyle(
                                  color: isDark ? Colors.green.shade400 : greenColor,
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            const SizedBox(height: 2),
                            Text(
                              item.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w600,
                                color: textColor,
                                height: 1.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      _RoundButton(
                        icon: Icons.close_rounded,
                        semanticLabel: 'Remove item',
                        size: 28,
                        iconSize: 15,
                        onTap: () async {
                          if (await _confirmRemove(context) && context.mounted) {
                            cart.removeItem(item.id, context);
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 6,
                    children: [
                      Text(
                        "\$${item.price.toStringAsFixed(2)}",
                        style: const TextStyle(
                          fontSize: 14,
                          color: primaryColor,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      if (item.regularPrice > item.price)
                        Text(
                          "\$${item.regularPrice.toStringAsFixed(2)}",
                          style: TextStyle(
                            fontSize: 11.5,
                            color: Colors.grey.shade500,
                            decoration: TextDecoration.lineThrough,
                            decorationColor: Colors.grey.shade500,
                          ),
                        ),
                    ],
                  ),
                  if (isOverStock) ...[
                    const SizedBox(height: 4),
                    Text(
                      item.stock > 0 ? "Only ${item.stock} in stock" : "Out of stock",
                      style: const TextStyle(
                        color: primaryColor,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _QuantityCounter(
                        qty: item.quantity,
                        onAdd: () => cart.updateQuantity(item.id, item.quantity + 1),
                        onRemove: () => cart.updateQuantity(item.id, item.quantity - 1),
                        onUpdate: (newQty) => cart.updateQuantity(item.id, newQty),
                      ),
                      const Spacer(),
                      Text(
                        "\$${rowTotal.toStringAsFixed(2)}",
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: textColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuantityCounter extends StatefulWidget {
  final int qty;
  final VoidCallback onAdd;
  final VoidCallback onRemove;
  final Function(int) onUpdate;

  const _QuantityCounter({
    required this.qty,
    required this.onAdd,
    required this.onRemove,
    required this.onUpdate,
  });

  @override
  State<_QuantityCounter> createState() => _QuantityCounterState();
}

class _QuantityCounterState extends State<_QuantityCounter> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.qty.toString());
    _focusNode = FocusNode();
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus) _submit();
    });
  }

  @override
  void didUpdateWidget(covariant _QuantityCounter oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.qty != widget.qty && !_focusNode.hasFocus) {
      _controller.text = widget.qty.toString();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _submit() {
    final newQty = int.tryParse(_controller.text);
    if (newQty != null && newQty > 0) {
      if (newQty != widget.qty) widget.onUpdate(newQty);
    } else {
      _controller.text = widget.qty.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    final iconColor = AppPalette.text(context);
    final muted = AppPalette.textMuted(context);

    Widget button(IconData icon, VoidCallback? onTap) => InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: SizedBox(
        width: 32,
        height: 34,
        child: Icon(
          icon,
          size: 16,
          color: onTap == null ? muted.withOpacity(0.4) : iconColor,
        ),
      ),
    );

    return Container(
      height: 34,
      decoration: BoxDecoration(
        color: AppPalette.cardElevated(context),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          button(Icons.remove_rounded, widget.qty > 1 ? widget.onRemove : null),
          SizedBox(
            width: 34,
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              textAlign: TextAlign.center,
              cursorColor: primaryColor,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 13.5,
                color: iconColor,
              ),
              decoration: const InputDecoration(
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
              onSubmitted: (_) => _submit(),
            ),
          ),
          button(Icons.add_rounded, widget.onAdd),
        ],
      ),
    );
  }
}

class _CheckoutCard extends StatelessWidget {
  final CartProvider cart;
  const _CheckoutCard({required this.cart});

  @override
  Widget build(BuildContext context) {
    final tr = AppLocalizations.of(context)!;
    final isDark = AppPalette.isDark(context);
    final isRtl = Directionality.of(context) == TextDirection.rtl;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      decoration: BoxDecoration(
        color: AppPalette.card(context),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppPalette.border(context)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.4 : 0.10),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  tr.total,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppPalette.textMuted(context),
                  ),
                ),
              ),
              Text(
                "\$${cart.totalPrice.toStringAsFixed(2)}",
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: primaryColor,
                  letterSpacing: -0.4,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: () {
                final auth = Provider.of<AuthProvider>(context, listen: false);
                Navigator.pushNamed(
                  context,
                  auth.isAuthenticated ? checkoutScreenRoute : logInScreenRoute,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    tr.checkout,
                    style: const TextStyle(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(
                    isRtl ? Icons.arrow_back_rounded : Icons.arrow_forward_rounded,
                    size: 18,
                    color: Colors.white,
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

class _EmptyCartState extends StatelessWidget {
  const _EmptyCartState({required this.onStartShopping});
  final VoidCallback onStartShopping;

  @override
  Widget build(BuildContext context) {
    final tr = AppLocalizations.of(context)!;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 96,
              width: 96,
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.shopping_cart_outlined, size: 40, color: primaryColor),
            ),
            const SizedBox(height: 20),
            Text(
              tr.yourCartIsEmpty,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppPalette.text(context),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              tr.emptyCartSubtitle,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: AppPalette.textMuted(context)),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: onStartShopping,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  shape: const StadiumBorder(),
                ),
                child: Text(
                  tr.startShopping,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}