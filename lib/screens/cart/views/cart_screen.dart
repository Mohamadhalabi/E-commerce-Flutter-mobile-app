import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shop/providers/auth_provider.dart';
import 'package:shop/providers/cart_provider.dart';
import 'package:shop/constants.dart';
import 'package:shop/route/route_constants.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

// ✅ Import your Custom Bottom Bar
import '../../../../components/common/CustomBottomNavigationBar.dart';

class CartScreen extends StatefulWidget {
  // ✅ Flag to decide if we show the bottom bar manually (pushed screen vs main tab)
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

  // ✅ Navigation Logic for the Bottom Bar
  void _onBottomNavTap(int index) {
    // 0: Home, 1: Search, 2: Shop, 3: Cart, 4: Profile
    if (index == 3) return; // Already on Cart

    if (index == 0) {
      // Go back to the very start (Home)
      Navigator.popUntil(context, (route) => route.isFirst);
    } else {
      // Navigate to other screens based on your route constants
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
      backgroundColor: const Color(0xFFF9FAFB), // Clean off-white background
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

      // ✅ CONDITIONAL BOTTOM BAR: Only show if 'isStandalone' is true
      bottomNavigationBar: widget.isStandalone
          ? CustomBottomNavigationBar(
        currentIndex: 3, // Cart is typically index 3
        onTap: _onBottomNavTap,
      )
          : null,

      body: Consumer<CartProvider>(
        builder: (context, cart, child) {
          if (cart.isLoading && cart.cartItems.isEmpty) {
            return const Center(child: CircularProgressIndicator(color: primaryColor));
          }

          if (cart.cartItems.isEmpty) {
            return const _EmptyCartState();
          }

          // ✅ CHECK FOR ITEMS WITH LIMITED STOCK
          // Collect SKUs where quantity > stock
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
                      // ✅ GLOBAL WARNING BANNER (Top of list)
                      if (unavailableSkus.isNotEmpty)
                        Container(
                          margin: const EdgeInsets.only(bottom: 20),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF5F5), // Light Red background
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.red.withOpacity(0.3)),
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
                                      // Uses the translation key: "The selected quantity for product {sku}..."
                                      // We join multiple SKUs with a comma if necessary
                                      tr.stockLimitWarning(unavailableSkus.join(", ")),
                                      style: const TextStyle(color: Colors.red, fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                      // Cart Items List
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

// ==============================================================================
// 1. CART ITEM TILE
// ==============================================================================
class _CartItemTile extends StatelessWidget {
  final CartItem item;

  const _CartItemTile({required this.item});

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context, listen: false);
    final tr = AppLocalizations.of(context)!;

    final double rowTotal = item.price * item.quantity;

    // We check availability to determine border color
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
      onDismissed: (_) => cart.removeItem(item.id),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          // ✅ Red Border if Out Of Stock
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
            // IMAGE
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

            // DETAILS
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title & Close
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          item.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF2D2D2D),
                            height: 1.3,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      InkWell(
                        onTap: () => cart.removeItem(item.id),
                        child: Icon(Icons.close, size: 18, color: Colors.grey[400]),
                      )
                    ],
                  ),
                  const SizedBox(height: 8),

                  // ✅ PRICE SECTION: Display Old & New Prices
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        "${tr.unitPrice} ",
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      // Current Price (Red)
                      Text(
                        "\$${item.price.toStringAsFixed(2)}",
                        style: const TextStyle(
                            fontSize: 13,
                            color: primaryColor,
                            fontWeight: FontWeight.bold
                        ),
                      ),
                      // Regular Price (Strikethrough - only if higher)
                      if (item.regularPrice > item.price) ...[
                        const SizedBox(width: 6),
                        Text(
                          "\$${item.regularPrice.toStringAsFixed(2)}",
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.grey,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                      ],
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Footer (Quantity & Row Total)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _QuantityCounter(
                        qty: item.quantity,
                        onAdd: () => cart.updateQuantity(item.id, item.quantity + 1),
                        onRemove: () => cart.updateQuantity(item.id, item.quantity - 1),
                      ),

                      Text(
                        "\$${rowTotal.toStringAsFixed(2)}",
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: primaryColor,
                        ),
                      ),
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

// ==============================================================================
// 2. QUANTITY COUNTER
// ==============================================================================
class _QuantityCounter extends StatelessWidget {
  final int qty;
  final VoidCallback onAdd;
  final VoidCallback onRemove;

  const _QuantityCounter({
    required this.qty,
    required this.onAdd,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF7F7F7),
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          InkWell(
            onTap: onRemove,
            child: const Padding(
              padding: EdgeInsets.all(4.0),
              child: Icon(Icons.remove, size: 16, color: Colors.black87),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            "$qty",
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
          const SizedBox(width: 8),
          InkWell(
            onTap: onAdd,
            child: const Padding(
              padding: EdgeInsets.all(4.0),
              child: Icon(Icons.add, size: 16, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }
}

// ==============================================================================
// 3. CHECKOUT BAR
// ==============================================================================
class _CheckoutBar extends StatelessWidget {
  final CartProvider cart;

  const _CheckoutBar({required this.cart});

  @override
  Widget build(BuildContext context) {
    final tr = AppLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            offset: const Offset(0, -4),
            blurRadius: 20,
            color: Colors.black.withOpacity(0.05),
          )
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  tr.total,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.grey),
                ),
                Text(
                  "\$${cart.totalPrice.toStringAsFixed(2)}",
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: primaryColor),
                ),
              ],
            ),
            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: () {
                  // Navigate to Checkout
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: Text(
                  tr.checkout,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==============================================================================
// 4. EMPTY STATE
// ==============================================================================
class _EmptyCartState extends StatelessWidget {
  const _EmptyCartState();

  @override
  Widget build(BuildContext context) {
    final tr = AppLocalizations.of(context)!;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            height: 100,
            width: 100,
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.shopping_bag_outlined, size: 48, color: primaryColor),
          ),
          const SizedBox(height: 24),
          Text(
            tr.yourCartIsEmpty,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black),
          ),
          const SizedBox(height: 8),
          Text(
            tr.emptyCartSubtitle,
            style: const TextStyle(fontSize: 14, color: Colors.grey),
          ),
          const SizedBox(height: 32),
          SizedBox(
            height: 48,
            width: 180,
            child: OutlinedButton(
              onPressed: () {
                if (Navigator.canPop(context)) {
                  Navigator.pop(context);
                } else {
                  Navigator.pushReplacementNamed(context, entryPointScreenRoute);
                }
              },
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: primaryColor),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(
                tr.startShopping,
                style: const TextStyle(color: primaryColor, fontWeight: FontWeight.bold),
              ),
            ),
          )
        ],
      ),
    );
  }
}