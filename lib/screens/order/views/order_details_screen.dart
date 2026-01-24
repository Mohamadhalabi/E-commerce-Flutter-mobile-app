import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:provider/provider.dart';
import 'package:shop/constants.dart';
import 'package:shop/models/order_model.dart';
import 'package:shop/providers/auth_provider.dart';
import 'package:shop/route/route_constants.dart';
import 'package:shop/services/api_service.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shop/components/common/CustomBottomNavigationBar.dart';

class OrderDetailsScreen extends StatefulWidget {
  final int orderId;

  const OrderDetailsScreen({super.key, required this.orderId});

  @override
  State<OrderDetailsScreen> createState() => _OrderDetailsScreenState();
}

class _OrderDetailsScreenState extends State<OrderDetailsScreen> {
  bool _isDownloading = false;
  late Future<OrderModel> _orderFuture;

  int _currentIndex = 4;

  @override
  void initState() {
    super.initState();
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    _orderFuture = ApiService.fetchOrderDetails(widget.orderId, authProvider.token ?? '', 'en');
  }

  void _onBottomNavTap(int index) {
    if (_currentIndex == index) return;
    setState(() => _currentIndex = index);

    switch (index) {
      case 0:
        Navigator.pushNamedAndRemoveUntil(context, entryPointScreenRoute, (route) => false);
        break;
      case 1:
        Navigator.pushNamed(context, searchScreenRoute);
        break;
      case 3:
        Navigator.pushNamed(context, cartScreenRoute);
        break;
      case 4:
        Navigator.popUntil(context, ModalRoute.withName(entryPointScreenRoute));
        break;
    }
  }

  Future<void> _downloadAndOpenInvoice(String token) async {
    setState(() => _isDownloading = true);
    try {
      final path = await ApiService.downloadInvoice(widget.orderId, token);
      if (path != null) {
        await OpenFilex.open(path);
      } else {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Could not download invoice")));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if (mounted) setState(() => _isDownloading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final tr = AppLocalizations.of(context);

    // ✅ Dark Mode Colors
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final Color scaffoldBg = Theme.of(context).scaffoldBackgroundColor;
    final Color appBarBg = isDark ? const Color(0xFF1C1C23) : Colors.white;
    final Color textColor = isDark ? Colors.white : Colors.black87;
    final Color iconColor = isDark ? Colors.white : Colors.black87;
    final Color sectionBg = isDark ? const Color(0xFF1C1C23) : Colors.white;
    final Color subTextColor = isDark ? Colors.white60 : Colors.grey[600]!;

    return Scaffold(
      backgroundColor: scaffoldBg,
      bottomNavigationBar: CustomBottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onBottomNavTap,
      ),
      appBar: AppBar(
        title: Text(tr?.orderDetails ?? 'Order Details', style: const TextStyle(fontSize: 16)),
        backgroundColor: appBarBg,
        elevation: 0.5,
        centerTitle: true,
        surfaceTintColor: Colors.transparent,
        iconTheme: IconThemeData(color: iconColor),
        titleTextStyle: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.bold),
        actions: [
          _isDownloading
              ? const Padding(
            padding: EdgeInsets.all(12.0),
            child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: primaryColor)),
          )
              : IconButton(
            icon: SvgPicture.asset(
              "assets/icons/pdf.svg",
              width: 32,
              height: 32,
              // Keep PDF icon colored or tint if necessary, usually colorful icons are fine
            ),
            tooltip: "Download Invoice",
            onPressed: () => _downloadAndOpenInvoice(authProvider.token ?? ''),
          ),
        ],
      ),
      body: FutureBuilder<OrderModel>(
        future: _orderFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: primaryColor));
          }
          if (snapshot.hasError) {
            return Center(child: Text(tr?.errorLoadingDetails ?? "Failed to load details", style: TextStyle(color: textColor)));
          }

          final order = snapshot.data!;
          final String displayId = order.uuid.isNotEmpty ? order.uuid : "#${order.id}";

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("${tr?.orderDetails ?? 'Order'} #$displayId", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textColor)),
                const SizedBox(height: 20),

                _buildSection(
                  color: sectionBg,
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(tr?.orderStatus ?? "Order Status", style: TextStyle(color: subTextColor, fontSize: 14)),
                          _buildStatusBadge(order.status),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("Payment Status", style: TextStyle(color: subTextColor, fontSize: 14)),
                          _buildPaymentStatusBadge(order.paymentStatus),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Divider(color: isDark ? Colors.white12 : Colors.grey[300]),
                      const SizedBox(height: 8),
                      Text("${tr?.placedOn ?? 'Placed on'} ${order.createdAt}", style: TextStyle(color: subTextColor, fontSize: 12)),
                    ],
                  ),
                ),

                const SizedBox(height: 20),
                Text("${tr?.items ?? 'Items'} (${order.items.length})", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor)),
                const SizedBox(height: 10),
                ...order.items.map((item) => _buildProductCard(context, item, sectionBg, textColor)),

                const SizedBox(height: 20),
                // Shipping
                _buildSection(
                  color: sectionBg,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionHeader(Icons.local_shipping_outlined, tr?.shippingDetails ?? "Shipping Details", textColor),
                      Divider(height: 24, color: isDark ? Colors.white12 : Colors.grey[300]),
                      _buildDetailRow(tr?.shippingMethod ?? "Method", order.shippingMethod, textColor, subTextColor),
                      const SizedBox(height: 12),
                      _buildDetailRow("Payment Method", order.paymentMethod, textColor, subTextColor),
                      const SizedBox(height: 12),
                      if (order.address != null)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(tr?.shippingAddress ?? "Address", style: TextStyle(color: subTextColor, fontSize: 14)),
                            const SizedBox(height: 4),
                            Text("${order.address!.address}, ${order.address!.city}", style: TextStyle(fontWeight: FontWeight.w500, height: 1.4, color: textColor)),
                            const SizedBox(height: 4),
                            Text(order.address!.phone, style: TextStyle(color: subTextColor, fontSize: 13)),
                          ],
                        )
                    ],
                  ),
                ),

                const SizedBox(height: 20),
                // Payment Summary
                _buildSection(
                  color: sectionBg,
                  child: Column(
                    children: [
                      _buildSectionHeader(Icons.receipt_outlined, tr?.paymentSummary ?? "Payment Summary", textColor),
                      Divider(height: 24, color: isDark ? Colors.white12 : Colors.grey[300]),
                      _buildSummaryRow(tr?.subtotal ?? "Subtotal", "\$${(double.tryParse(order.total)! - double.tryParse(order.shippingAmount)!).toStringAsFixed(2)}", textColor, subTextColor),
                      const SizedBox(height: 12),
                      _buildSummaryRow(tr?.shippingFee ?? "Shipping Fee", "\$${order.shippingAmount}", textColor, subTextColor),
                      Padding(padding: const EdgeInsets.symmetric(vertical: 12), child: Divider(color: isDark ? Colors.white12 : Colors.grey[300])),
                      _buildSummaryRow(tr?.totalAmount ?? "Total Amount", "\$${order.total}", textColor, subTextColor, isTotal: true),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          );
        },
      ),
    );
  }

  // --- Helper Widgets ---
  Widget _buildSection({required Widget child, required Color color}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          if (color == Colors.white) // Only shadow in light mode
            BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))
        ],
      ),
      child: child,
    );
  }

  Widget _buildSectionHeader(IconData icon, String title, Color textColor) {
    return Row(
      children: [
        Icon(icon, size: 20, color: primaryColor),
        const SizedBox(width: 10),
        Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: textColor)),
      ],
    );
  }

  Widget _buildProductCard(BuildContext context, OrderItemModel item, Color bg, Color textColor) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? Colors.white12 : Colors.grey.shade100),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            Navigator.pushNamed(context, productDetailsScreenRoute, arguments: item.productId);
          },
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 70, height: 70,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.white, // Keep white for product visibility
                    image: item.image.isNotEmpty ? DecorationImage(image: NetworkImage(item.image), fit: BoxFit.contain) : null,
                  ),
                  child: item.image.isEmpty ? const Icon(Icons.image_not_supported, color: Colors.grey) : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.productName, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, height: 1.2, color: textColor)),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                            color: isDark ? Colors.white10 : Colors.grey[100],
                            borderRadius: BorderRadius.circular(4)
                        ),
                        child: Text("Qty: ${item.quantity}", style: TextStyle(color: isDark ? Colors.white70 : Colors.grey[700], fontSize: 12)),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text("\$${item.price}", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: textColor)),
                    const SizedBox(height: 8),
                    const Icon(Icons.arrow_forward_ios, size: 12, color: primaryColor)
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, Color textColor, Color subTextColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: subTextColor, fontSize: 14)),
        Text(value, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: textColor)),
      ],
    );
  }

  Widget _buildSummaryRow(String label, String value, Color textColor, Color subTextColor, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(
          color: isTotal ? textColor : subTextColor,
          fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
          fontSize: isTotal ? 16 : 14,
        )),
        Text(value, style: TextStyle(
          color: isTotal ? primaryColor : textColor,
          fontWeight: isTotal ? FontWeight.bold : FontWeight.w600,
          fontSize: isTotal ? 18 : 14,
        )),
      ],
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    switch (status.toLowerCase()) {
      case 'delivered': color = Colors.green; break;
      case 'cancelled': color = Colors.red; break;
      case 'processing': color = Colors.blue; break;
      default: color = primaryColor;
    }
    return Text(status.toUpperCase(), style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 14));
  }

  Widget _buildPaymentStatusBadge(String status) {
    Color color;
    Color bg;
    // For Dark Mode compatibility, make bg slightly transparent or generic
    switch (status.toLowerCase()) {
      case 'paid': color = Colors.green; bg = Colors.green.withOpacity(0.1); break;
      case 'unpaid': color = Colors.red; bg = Colors.red.withOpacity(0.1); break;
      case 'pending': color = Colors.orange; bg = Colors.orange.withOpacity(0.1); break;
      default: color = Colors.grey; bg = Colors.grey.withOpacity(0.1);
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
      child: Text(status.toUpperCase(), style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
    );
  }
}