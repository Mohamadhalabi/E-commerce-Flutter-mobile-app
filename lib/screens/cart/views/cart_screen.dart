import 'package:flutter/material.dart';
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

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: Column(
          children: [
            Text(
              tr.myCart,
              style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18),
            ),
            Consumer<CartProvider>(
              builder: (context, cart, child) => Text(
                "${cart.cartItems.length} ${tr.items}",
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ),
          ],
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20, color: Colors.black),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              Navigator.pushReplacementNamed(context, entryPointScreenRoute);
            }
          },
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
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                    children: [
                      // ✅ GLOBAL WARNING BANNER with Red Border
                      if (unavailableSkus.isNotEmpty)
                        Container(
                          margin: const EdgeInsets.only(bottom: 20),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF5F5),
                            borderRadius: BorderRadius.circular(8),
                            // ✅ Solid Red Border
                            border: Border.all(color: Colors.red, width: 1.0),
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
                                      "Some items have limited availability",
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

class _CartItemTile extends StatelessWidget {
  final CartItem item;

  const _CartItemTile({required this.item});

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context, listen: false);
    final tr = AppLocalizations.of(context)!;

    final double rowTotal = item.price * item.quantity;
    final bool isOutOfStock = item.quantity > item.stock;

    return Dismissible(
      key: Key(item.id.toString()),
      direction: DismissDirection.endToStart,
      background: Container(
        padding: const EdgeInsets.only(right: 20),
        alignment: Alignment.centerRight,
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.white, size: 28),
      ),
      confirmDismiss: (direction) async {
        return await showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(tr.removeItem),
            content: Text(tr.removeItemConfirmation),
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
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          // ✅ Red Border if Out of Stock
          border: isOutOfStock
              ? Border.all(color: Colors.red, width: 1.5)
              : Border.all(color: Colors.transparent),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              offset: const Offset(0, 4),
              blurRadius: 12,
            )
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 90,
              height: 90,
              padding: const EdgeInsets.all(4),
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
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF2D2D2D), height: 1.3),
                        ),
                      ),
                      const SizedBox(width: 8),
                      InkWell(
                        onTap: () => cart.removeItem(item.id, context),
                        child: Icon(Icons.close, size: 18, color: Colors.grey[400]),
                      )
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text("${tr.unitPrice} ", style: const TextStyle(fontSize: 12, color: Colors.grey)),
                      Text("\$${item.price.toStringAsFixed(2)}", style: const TextStyle(fontSize: 13, color: primaryColor, fontWeight: FontWeight.bold)),
                      if (item.regularPrice > item.price) ...[
                        const SizedBox(width: 6),
                        Text("\$${item.regularPrice.toStringAsFixed(2)}", style: const TextStyle(fontSize: 11, color: Colors.grey, decoration: TextDecoration.lineThrough)),
                      ],
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _QuantityCounter(
                        qty: item.quantity,
                        onAdd: () => cart.updateQuantity(item.id, item.quantity + 1),
                        onRemove: () => cart.updateQuantity(item.id, item.quantity - 1),
                      ),
                      Text("\$${rowTotal.toStringAsFixed(2)}", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: primaryColor)),
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

// ... (Keep _QuantityCounter, _CheckoutBar, and _EmptyCartState as they are)
class _QuantityCounter extends StatelessWidget {
  final int qty;
  final VoidCallback onAdd;
  final VoidCallback onRemove;
  const _QuantityCounter({required this.qty, required this.onAdd, required this.onRemove});
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: const Color(0xFFF7F7F7), borderRadius: BorderRadius.circular(8)),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          InkWell(onTap: onRemove, child: const Padding(padding: EdgeInsets.all(4.0), child: Icon(Icons.remove, size: 16, color: Colors.black87))),
          const SizedBox(width: 8),
          Text("$qty", style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
          const SizedBox(width: 8),
          InkWell(onTap: onAdd, child: const Padding(padding: EdgeInsets.all(4.0), child: Icon(Icons.add, size: 16, color: Colors.black87))),
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
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: const BorderRadius.vertical(top: Radius.circular(24)), boxShadow: [BoxShadow(offset: const Offset(0, -4), blurRadius: 20, color: Colors.black.withOpacity(0.05))]),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(tr.total, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.grey)), Text("\$${cart.totalPrice.toStringAsFixed(2)}", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: primaryColor))]),
            const SizedBox(height: 20),
            SizedBox(width: double.infinity, height: 54, child: ElevatedButton(onPressed: () {}, style: ElevatedButton.styleFrom(backgroundColor: primaryColor, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))), child: Text(tr.checkout, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)))),
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
    return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Container(height: 100, width: 100, decoration: BoxDecoration(color: primaryColor.withOpacity(0.1), shape: BoxShape.circle), child: const Icon(Icons.shopping_bag_outlined, size: 48, color: primaryColor)), const SizedBox(height: 24), Text(tr.yourCartIsEmpty, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black)), const SizedBox(height: 8), Text(tr.emptyCartSubtitle, style: const TextStyle(fontSize: 14, color: Colors.grey)), const SizedBox(height: 32), SizedBox(height: 48, width: 180, child: OutlinedButton(onPressed: () {if (Navigator.canPop(context)) {Navigator.pop(context);} else {Navigator.pushReplacementNamed(context, entryPointScreenRoute);}}, style: OutlinedButton.styleFrom(side: const BorderSide(color: primaryColor), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), child: Text(tr.startShopping, style: const TextStyle(color: primaryColor, fontWeight: FontWeight.bold))))]));
  }
}