import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // ✅ Added for input formatters
import 'package:provider/provider.dart';
import 'package:shop/providers/auth_provider.dart';
import 'package:shop/providers/cart_provider.dart';
import 'package:shop/constants.dart';
import 'package:shop/route/route_constants.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../../../../components/common/CustomBottomNavigationBar.dart';

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
      _initCart();
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
    if (index == 3) return;
    if (index == 0) {
      Navigator.popUntil(context, (route) => route.isFirst);
    } else {
      String? routeName;
      switch (index) {
        case 1: routeName = searchScreenRoute; break;
        case 2: routeName = discoverScreenRoute; break;
        case 4: routeName = profileScreenRoute; break;
      }
      if (routeName != null) {
        Navigator.pushNamed(context, routeName);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final tr = AppLocalizations.of(context)!;

    // ✅ Dark Mode Colors
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final Color scaffoldBg = Theme.of(context).scaffoldBackgroundColor;
    final Color appBarBg = isDark ? const Color(0xFF1C1C23) : Colors.white;
    final Color textColor = isDark ? Colors.white : const Color(0xFF1A1A1A);
    final Color subTextColor = isDark ? Colors.white54 : Colors.grey[600]!;
    final Color warningBg = isDark ? const Color(0xFF2A1010) : const Color(0xFFFFF5F5);
    final Color dividerColor = isDark ? Colors.white12 : Colors.grey.withOpacity(0.1);

    return Scaffold(
      backgroundColor: scaffoldBg,

      // ✅ UPDATED PROFESSIONAL HEADER
      appBar: AppBar(
        backgroundColor: appBarBg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        // Adds a subtle separator line at the bottom of the AppBar
        shape: Border(bottom: BorderSide(color: dividerColor, width: 1)),

        leading: Padding(
          padding: const EdgeInsets.only(left: 8.0),
          child: IconButton(
            icon: Icon(Icons.arrow_back_ios_new, size: 20, color: textColor),
            onPressed: () {
              if (Navigator.canPop(context)) {
                Navigator.pop(context);
              } else {
                Navigator.pushReplacementNamed(context, entryPointScreenRoute);
              }
            },
          ),
        ),

        title: Column(
          children: [
            Text(
              tr.myCart,
              style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.w700,
                  fontSize: 17,
                  letterSpacing: 0.5
              ),
            ),
            const SizedBox(height: 2),
            Consumer<CartProvider>(
              builder: (context, cart, child) => Text(
                "${cart.cartItems.length} ${tr.items}",
                style: TextStyle(
                    color: subTextColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w400
                ),
              ),
            ),
          ],
        ),
      ),

      bottomNavigationBar: widget.isStandalone
          ? CustomBottomNavigationBar(currentIndex: 3, onTap: _onBottomNavTap)
          : null,

      body: Consumer<CartProvider>(
        builder: (context, cart, child) {
          if (cart.isLoading && cart.cartItems.isEmpty) {
            return const Center(child: CircularProgressIndicator(color: primaryColor));
          }

          if (cart.cartItems.isEmpty) {
            return const _EmptyCartState();
          }

          List<String> unavailableSkus = cart.cartItems
              .where((item) => item.quantity > item.stock)
              .map((item) => item.sku)
              .toList();

          return Column(
            children: [
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _onRefresh,
                  color: primaryColor,
                  backgroundColor: appBarBg,
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                    children: [
                      // ✅ GLOBAL WARNING BANNER
                      if (unavailableSkus.isNotEmpty)
                        Container(
                          margin: const EdgeInsets.only(bottom: 20),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: warningBg,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.red.withOpacity(0.5), width: 1.0),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.info_outline, color: Colors.red, size: 20),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      "Attention Needed",
                                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red, fontSize: 13),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      tr.stockLimitWarning(unavailableSkus.join(", ")),
                                      style: const TextStyle(color: Colors.red, fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                      // Cart Items
                      ...cart.cartItems.map((item) => Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: _CartItemTile(item: item),
                      )).toList(),
                    ],
                  ),
                ),
              ),
              _CheckoutBar(cart: cart),
            ],
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// SUB-COMPONENTS
// ---------------------------------------------------------------------------

class _CartItemTile extends StatelessWidget {
  final CartItem item;

  const _CartItemTile({required this.item});

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context, listen: false);
    final tr = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final Color cardBg = isDark ? const Color(0xFF1C1C23) : Colors.white;
    final Color textColor = isDark ? Colors.white : const Color(0xFF2D2D2D);
    final Color borderColor = isDark ? Colors.transparent : Colors.grey.withOpacity(0.1);

    final double rowTotal = item.price * item.quantity;
    final bool isOutOfStock = item.quantity > item.stock;

    return Dismissible(
      key: Key(item.id.toString()),
      direction: DismissDirection.endToStart,
      background: Container(
        padding: const EdgeInsets.only(right: 20),
        alignment: Alignment.centerRight,
        decoration: BoxDecoration(
          color: const Color(0xFFFFE5E5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.red, size: 28),
      ),
      confirmDismiss: (direction) async {
        return await showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: isDark ? const Color(0xFF1C1C23) : Colors.white,
            title: Text(tr.removeItem, style: TextStyle(color: textColor)),
            content: Text(tr.removeItemConfirmation, style: TextStyle(color: textColor)),
            actions: [
              TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: Text(tr.cancel)),
              TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: Text(tr.remove, style: const TextStyle(color: Colors.red))),
            ],
          ),
        );
      },
      onDismissed: (_) => cart.removeItem(item.id, context),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(12),
          border: isOutOfStock
              ? Border.all(color: Colors.red, width: 1)
              : Border.all(color: borderColor),
          boxShadow: [
            if (!isDark)
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                offset: const Offset(0, 2),
                blurRadius: 10,
              )
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 80,
              height: 80,
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.withOpacity(0.1)),
              ),
              child: item.image.isNotEmpty
                  ? Image.network(
                item.image,
                fit: BoxFit.contain,
                errorBuilder: (c, e, s) => const Icon(Icons.broken_image, color: Colors.grey),
              )
                  : const Icon(Icons.image, color: Colors.grey),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          item.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: textColor, height: 1.3),
                        ),
                      ),
                      InkWell(
                        onTap: () => cart.removeItem(item.id, context),
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.all(4.0),
                          child: Icon(Icons.close, size: 16, color: Colors.grey[400]),
                        ),
                      )
                    ],
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text("\$${item.price.toStringAsFixed(2)}", style: const TextStyle(fontSize: 14, color: primaryColor, fontWeight: FontWeight.w700)),
                      if (item.regularPrice > item.price) ...[
                        const SizedBox(width: 8),
                        Text("\$${item.regularPrice.toStringAsFixed(2)}", style: const TextStyle(fontSize: 12, color: Colors.grey, decoration: TextDecoration.lineThrough)),
                      ],
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _QuantityCounter(
                        qty: item.quantity,
                        onAdd: () => cart.updateQuantity(item.id, item.quantity + 1),
                        onRemove: () => cart.updateQuantity(item.id, item.quantity - 1),
                        // ✅ Added manual update trigger
                        onUpdate: (newQty) => cart.updateQuantity(item.id, newQty),
                      ),
                      Text("\$${rowTotal.toStringAsFixed(2)}", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: textColor)),
                    ],
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ✅ CHANGED: Upgraded from StatelessWidget to StatefulWidget to handle typing
class _QuantityCounter extends StatefulWidget {
  final int qty;
  final VoidCallback onAdd;
  final VoidCallback onRemove;
  final Function(int) onUpdate; // ✅ Custom input callback

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
  late TextEditingController _controller;
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.qty.toString());
    _focusNode = FocusNode();

    // Listen for when the user clicks out of the text field
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus) {
        _submit();
      }
    });
  }

  @override
  void didUpdateWidget(covariant _QuantityCounter oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If quantity changes from the outside (like server sync or +/- buttons), update the field
    if (oldWidget.qty != widget.qty) {
      if (!_focusNode.hasFocus) { // Don't interrupt them if they are currently typing
        _controller.text = widget.qty.toString();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _submit() {
    final text = _controller.text;
    final newQty = int.tryParse(text);

    // If valid number and greater than 0, push the update
    if (newQty != null && newQty > 0) {
      if (newQty != widget.qty) {
        widget.onUpdate(newQty);
      }
    } else {
      // Revert to original quantity if input is invalid (e.g., empty or 0)
      _controller.text = widget.qty.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final Color bg = isDark ? const Color(0xFF2A2A35) : const Color(0xFFF5F5F5);
    final Color iconColor = isDark ? Colors.white70 : Colors.black87;
    final Color textColor = isDark ? Colors.white : Colors.black;

    return Container(
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
              onTap: widget.onRemove,
              child: Padding(padding: const EdgeInsets.all(6.0), child: Icon(Icons.remove, size: 16, color: iconColor))
          ),
          SizedBox(
            width: 36, // Slightly wider to give typing room
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly], // Prevents decimals/letters
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: textColor),
              decoration: const InputDecoration(
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
              onSubmitted: (_) => _submit(), // Triggered when they press "Enter/Done" on keyboard
            ),
          ),
          InkWell(
              onTap: widget.onAdd,
              child: Padding(padding: const EdgeInsets.all(6.0), child: Icon(Icons.add, size: 16, color: iconColor))
          ),
        ],
      ),
    );
  }
}

class _CheckoutBar extends StatelessWidget {
  final CartProvider cart;
  const _CheckoutBar({required this.cart});

  @override
  Widget build(BuildContext context) {
    final tr = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final Color bg = isDark ? const Color(0xFF1C1C23) : Colors.white;
    final Color labelColor = isDark ? Colors.white70 : Colors.grey[600]!;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: bg,
          border: Border(top: BorderSide(color: isDark ? Colors.white12 : Colors.grey.shade100)),
          boxShadow: [
            if(!isDark)
              BoxShadow(
                  offset: const Offset(0, -4),
                  blurRadius: 16,
                  color: Colors.black.withOpacity(0.04)
              )
          ]
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(tr.total, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: labelColor)),
                  Text("\$${cart.totalPrice.toStringAsFixed(2)}", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: primaryColor))
                ]
            ),
            const SizedBox(height: 16),
            SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                    onPressed: () {
                      final auth = Provider.of<AuthProvider>(context, listen: false);
                      if (auth.isAuthenticated) {
                        Navigator.pushNamed(context, checkoutScreenRoute);
                      } else {
                        Navigator.pushNamed(context, logInScreenRoute);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                    ),
                    child: Text(
                        tr.checkout,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)
                    )
                )
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyCartState extends StatelessWidget {
  const _EmptyCartState();
  @override
  Widget build(BuildContext context) {
    final tr = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final Color textColor = isDark ? Colors.white : Colors.black;

    return Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(
              height: 100,
              width: 100,
              decoration: BoxDecoration(color: primaryColor.withOpacity(0.08), shape: BoxShape.circle),
              child: const Icon(Icons.shopping_cart_outlined, size: 40, color: primaryColor)
          ),
          const SizedBox(height: 24),
          Text(tr.yourCartIsEmpty, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
          const SizedBox(height: 8),
          Text(tr.emptyCartSubtitle, style: TextStyle(fontSize: 14, color: isDark ? Colors.white54 : Colors.grey)),
          const SizedBox(height: 32),
          SizedBox(
              height: 46,
              width: 160,
              child: OutlinedButton(
                  onPressed: () {
                    if (Navigator.canPop(context)) {
                      Navigator.pop(context);
                    } else {
                      Navigator.pushReplacementNamed(context, entryPointScreenRoute);
                    }
                  },
                  style: OutlinedButton.styleFrom(side: const BorderSide(color: primaryColor), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                  child: Text(tr.startShopping, style: const TextStyle(color: primaryColor, fontWeight: FontWeight.w600))
              )
          )
        ])
    );
  }
}