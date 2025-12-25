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
import 'package:shop/components/common/CustomBottomNavigationBar.dart'; // ✅ Import

class OrderDetailsScreen extends StatefulWidget {
  final int orderId;

  const OrderDetailsScreen({super.key, required this.orderId});

  @override
  State<OrderDetailsScreen> createState() => _OrderDetailsScreenState();
}

class _OrderDetailsScreenState extends State<OrderDetailsScreen> {
  bool _isDownloading = false;
  late Future<OrderModel> _orderFuture;

  // ✅ 1. Current Tab Index
  int _currentIndex = 4;

  @override
  void initState() {
    super.initState();
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    _orderFuture = ApiService.fetchOrderDetails(widget.orderId, authProvider.token ?? '', 'en');
  }

  // ✅ 2. Handle Taps
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
      case 2:
      // Navigator.pushNamed(context, shopScreenRoute);
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

    return Scaffold(
      backgroundColor: const Color(0xFFF4F5F7),
      // ✅ 3. Add Bottom Bar
      bottomNavigationBar: CustomBottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onBottomNavTap,
      ),
      appBar: AppBar(
        // ... (Keep AppBar code exactly as before)
        title: Text(tr?.orderDetails ?? 'Order Details', style: const TextStyle(fontSize: 16)),
        backgroundColor: Colors.white,
        elevation: 0.5,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black87),
        titleTextStyle: const TextStyle(color: Colors.black87, fontSize: 18, fontWeight: FontWeight.bold),
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
            return Center(child: Text(tr?.errorLoadingDetails ?? "Failed to load details"));
          }

          final order = snapshot.data!;
          final String displayId = order.uuid.isNotEmpty ? order.uuid : "#${order.id}";

          // We update the AppBar title with the loaded ID using a micro-hack or just accept generic title in loading
          // Actually, since the AppBar is OUTSIDE FutureBuilder, we can't update it dynamically easily without state.
          // For now, let's keep the body logic simple.

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with ID (Since we can't easily update AppBar from here without prop drilling)
                Text("${tr?.orderDetails ?? 'Order'} #$displayId", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),

                _buildSection(
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(tr?.orderStatus ?? "Order Status", style: TextStyle(color: Colors.grey[600], fontSize: 14)),
                          _buildStatusBadge(order.status),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("Payment Status", style: TextStyle(color: Colors.grey[600], fontSize: 14)),
                          _buildPaymentStatusBadge(order.paymentStatus),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Divider(),
                      const SizedBox(height: 8),
                      Text("${tr?.placedOn ?? 'Placed on'} ${order.createdAt}", style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                    ],
                  ),
                ),

                // ... (Keep the rest of your body UI code: Items list, shipping, summary etc.)
                const SizedBox(height: 20),
                Text("${tr?.items ?? 'Items'} (${order.items.length})", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
                const SizedBox(height: 10),
                ...order.items.map((item) => _buildProductCard(context, item)),

                const SizedBox(height: 20),
                // Shipping
                _buildSection(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionHeader(Icons.local_shipping_outlined, tr?.shippingDetails ?? "Shipping Details"),
                      const Divider(height: 24),
                      _buildDetailRow(tr?.shippingMethod ?? "Method", order.shippingMethod),
                      const SizedBox(height: 12),
                      _buildDetailRow("Payment Method", order.paymentMethod),
                      const SizedBox(height: 12),
                      if (order.address != null)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(tr?.shippingAddress ?? "Address", style: TextStyle(color: Colors.grey[600], fontSize: 14)),
                            const SizedBox(height: 4),
                            Text("${order.address!.address}, ${order.address!.city}", style: const TextStyle(fontWeight: FontWeight.w500, height: 1.4)),
                            const SizedBox(height: 4),
                            Text(order.address!.phone, style: TextStyle(color: Colors.grey[500], fontSize: 13)),
                          ],
                        )
                    ],
                  ),
                ),

                const SizedBox(height: 20),
                // Payment Summary
                _buildSection(
                  child: Column(
                    children: [
                      _buildSectionHeader(Icons.receipt_outlined, tr?.paymentSummary ?? "Payment Summary"),
                      const Divider(height: 24),
                      _buildSummaryRow(tr?.subtotal ?? "Subtotal", "\$${(double.tryParse(order.total)! - double.tryParse(order.shippingAmount)!).toStringAsFixed(2)}"),
                      const SizedBox(height: 12),
                      _buildSummaryRow(tr?.shippingFee ?? "Shipping Fee", "\$${order.shippingAmount}"),
                      const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider()),
                      _buildSummaryRow(tr?.totalAmount ?? "Total Amount", "\$${order.total}", isTotal: true),
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

  // --- Helper Widgets (Paste the same helper widgets as before) ---
  Widget _buildSection({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: child,
    );
  }

  // ... Paste other helpers (_buildSectionHeader, _buildProductCard, etc.)
  Widget _buildSectionHeader(IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, size: 20, color: primaryColor),
        const SizedBox(width: 10),
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
      ],
    );
  }

  Widget _buildProductCard(BuildContext context, OrderItemModel item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade100),
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
                    color: Colors.grey[50],
                    image: item.image.isNotEmpty ? DecorationImage(image: NetworkImage(item.image), fit: BoxFit.contain) : null,
                  ),
                  child: item.image.isEmpty ? const Icon(Icons.image_not_supported, color: Colors.grey) : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.productName, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, height: 1.2)),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(4)),
                        child: Text("Qty: ${item.quantity}", style: TextStyle(color: Colors.grey[700], fontSize: 12)),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text("\$${item.price}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black87)),
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

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 14)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
      ],
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(
          color: isTotal ? Colors.black : Colors.grey[600],
          fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
          fontSize: isTotal ? 16 : 14,
        )),
        Text(value, style: TextStyle(
          color: isTotal ? primaryColor : Colors.black87,
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
    switch (status.toLowerCase()) {
      case 'paid': color = Colors.green[800]!; bg = Colors.green[50]!; break;
      case 'unpaid': color = Colors.red[800]!; bg = Colors.red[50]!; break;
      case 'pending': color = Colors.orange[800]!; bg = Colors.orange[50]!; break;
      default: color = Colors.grey[800]!; bg = Colors.grey[200]!;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
      child: Text(status.toUpperCase(), style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
    );
  }
}