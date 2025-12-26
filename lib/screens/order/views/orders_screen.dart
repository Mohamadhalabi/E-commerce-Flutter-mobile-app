import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shop/constants.dart';
import 'package:shop/models/order_model.dart';
import 'package:shop/providers/auth_provider.dart';
import 'package:shop/services/api_service.dart';
import 'package:shop/screens/order/views/order_details_screen.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:shop/components/common/CustomBottomNavigationBar.dart';
import 'package:shop/route/route_constants.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  final ScrollController _scrollController = ScrollController();
  List<OrderModel> _orders = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  int _currentPage = 1;
  bool _hasMore = true;

  int _currentIndex = 4;

  @override
  void initState() {
    super.initState();
    _fetchOrders(page: 1);
    _scrollController.addListener(_onScroll);
  }

  // ✅ 2. Handle Bottom Nav Taps
  void _onBottomNavTap(int index) {
    if (_currentIndex == index) return;
    setState(() => _currentIndex = index);

    switch (index) {
      case 0: // Home
        Navigator.pushNamedAndRemoveUntil(context, entryPointScreenRoute, (route) => false);
        break;
      case 1: // Search
        Navigator.pushNamed(context, searchScreenRoute);
        break;
      case 2: // Shop (Optional: Add route if needed)
      // Navigator.pushNamed(context, shopScreenRoute);
        break;
      case 3: // Cart
        Navigator.pushNamed(context, cartScreenRoute);
        break;
      case 4: // Profile (We are already in a sub-page of profile)
        Navigator.popUntil(context, ModalRoute.withName(entryPointScreenRoute));
        break;
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200 &&
        !_isLoadingMore &&
        _hasMore) {
      _fetchOrders(page: _currentPage + 1);
    }
  }

  Future<void> _fetchOrders({required int page}) async {
    if (page > 1) setState(() => _isLoadingMore = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final newOrders = await ApiService.fetchOrders(authProvider.token ?? '', 'en', page: page);

      if (mounted) {
        setState(() {
          if (page == 1) _orders = newOrders;
          else _orders.addAll(newOrders);

          if (newOrders.length < 10) _hasMore = false;

          _currentPage = page;
          _isLoading = false;
          _isLoadingMore = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() { _isLoading = false; _isLoadingMore = false; });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final tr = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F5F7),
      appBar: AppBar(
        title: Text(tr?.myOrders ?? "My Orders"),
        backgroundColor: Colors.white,
        elevation: 0.5,
        centerTitle: true,
        titleTextStyle: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 18),
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      // ✅ 3. Add the Bottom Navigation Bar
      bottomNavigationBar: CustomBottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onBottomNavTap,
      ),
      body: _isLoading && _orders.isEmpty
          ? const Center(child: CircularProgressIndicator(color: primaryColor))
          : RefreshIndicator(
        onRefresh: () async {
          setState(() => _hasMore = true);
          await _fetchOrders(page: 1);
        },
        child: _orders.isEmpty
            ? _buildEmptyState(tr)
            : ListView.separated(
          controller: _scrollController,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          itemCount: _orders.length + (_isLoadingMore ? 1 : 0),
          separatorBuilder: (_, __) => const SizedBox(height: 16),
          itemBuilder: (context, index) {
            if (index == _orders.length) {
              return const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator()));
            }
            return _buildOrderCard(context, _orders[index], tr);
          },
        ),
      ),
    );
  }

  Widget _buildEmptyState(AppLocalizations? tr) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long_outlined, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(tr?.noOrdersFound ?? "No orders found",
              style: TextStyle(color: Colors.grey[600], fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildOrderCard(BuildContext context, OrderModel order, AppLocalizations? tr) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => OrderDetailsScreen(orderId: order.id)),
          ),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "${tr?.orderNumber ?? 'Order'} #${order.uuid.isNotEmpty ? (order.uuid.length > 8 ? order.uuid.substring(0, 8) : order.uuid) : order.id}",                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                    ),
                    _buildStatusBadge(order.status),
                  ],
                ),
                const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider(height: 1)),
                _buildInfoRow(Icons.calendar_today_outlined, tr?.orderDate ?? "Date", order.createdAt),
                const SizedBox(height: 8),
                _buildInfoRow(Icons.local_shipping_outlined, tr?.shippingMethod ?? "Shipping", order.shippingMethod),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(tr?.totalAmount ?? "Total Amount", style: const TextStyle(color: Colors.grey, fontSize: 14)),
                    Text("\$${order.total}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: primaryColor)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[400]),
        const SizedBox(width: 8),
        Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
        const Spacer(),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
      ],
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bgColor;
    Color textColor;

    switch (status.toLowerCase()) {
      case 'delivered':
      case 'completed':
        bgColor = const Color(0xFFE8F5E9);
        textColor = const Color(0xFF2E7D32);
        break;
      case 'cancelled':
        bgColor = const Color(0xFFFFEBEE);
        textColor = const Color(0xFFC62828);
        break;
      case 'processing':
        bgColor = const Color(0xFFE3F2FD);
        textColor = const Color(0xFF1565C0);
        break;
      case 'pending':
        bgColor = const Color(0xFFFFF3E0);
        textColor = const Color(0xFFEF6C00);
        break;
      default:
        bgColor = const Color(0xFFF5F5F5);
        textColor = const Color(0xFF616161);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(8)),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 11),
      ),
    );
  }
}