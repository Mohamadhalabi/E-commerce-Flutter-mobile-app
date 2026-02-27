import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shop/models/checkout_models.dart';
import 'package:shop/models/country_model.dart';
import 'package:shop/providers/auth_provider.dart';
import 'package:shop/services/api_service.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';

// Ensure this points to your skeleton widget
import '../../../components/skleton/skeleton.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final Color _navyBlue = const Color(0xFF0C1E4E);

  Quote? _quote;
  bool _isLoading = true;
  bool _isCreatingOrder = false;
  String? _errorMessage;

  int? _selectedAddressId;
  String? _selectedShippingKey;
  String? _paymentMethod = 'card';
  bool _acceptTerms = false;
  bool _showAllItems = false;

  final TextEditingController _couponCtrl = TextEditingController();
  final TextEditingController _noteCtrl = TextEditingController();
  final TextEditingController _shipmentValueCtrl = TextEditingController();

  // ✅ PROMO STATE
  String _selectedPromo = 'none';

  bool _showAddressForm = false;
  final _addressFormKey = GlobalKey<FormState>();
  final Map<String, dynamic> _addressFormData = {};
  List<CountryModel> _countries = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchInitialData();
    });
  }

  @override
  void dispose() {
    _couponCtrl.dispose();
    _noteCtrl.dispose();
    _shipmentValueCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchInitialData() async {
    final token = Provider.of<AuthProvider>(context, listen: false).token;
    if (token == null) {
      if (mounted) setState(() { _isLoading = false; _errorMessage = "User not logged in"; });
      return;
    }

    try {
      _countries = await ApiService.fetchCountries(token);
      await _fetchQuote(initialLoad: true);
    } catch (e) {
      if (mounted) setState(() { _isLoading = false; _errorMessage = "Failed to load data: $e"; });
    }
  }

  Future<void> _fetchQuote({bool initialLoad = false}) async {
    final token = Provider.of<AuthProvider>(context, listen: false).token;
    if (token == null) return;

    if (mounted) setState(() { _isLoading = true; _errorMessage = null; });
    final locale = Localizations.localeOf(context).languageCode;

    Map<String, dynamic> params = {};
    if (initialLoad) params['skip_shipping'] = '1';
    if (_selectedAddressId != null) params['address_id'] = _selectedAddressId;
    if (_selectedShippingKey != null) params['shipping_method'] = _selectedShippingKey;
    if (_couponCtrl.text.isNotEmpty) params['coupon'] = _couponCtrl.text;

    params['promo'] = _selectedPromo;

    try {
      final json = await ApiService.fetchCheckoutQuote(params, locale, token);
      final newQuote = Quote.fromJson(json);

      if (mounted) {
        setState(() {
          _quote = newQuote;

          if (_selectedAddressId == null && newQuote.selectedAddressId != null) {
            _selectedAddressId = newQuote.selectedAddressId;
          }

          if (_selectedAddressId != null && _selectedShippingKey == null && newQuote.shipping.selected != null) {
            _selectedShippingKey = newQuote.shipping.selected;
          }

          if (_shipmentValueCtrl.text.isEmpty && newQuote.summary.subTotal > 0) {
            _shipmentValueCtrl.text = newQuote.summary.subTotal.toString();
          }

          if (newQuote.promotions != null) {
            _selectedPromo = newQuote.promotions!.selected;
          }
        });

        if (initialLoad && newQuote.selectedAddressId != null) {
          _fetchQuote(initialLoad: false);
        }
      }
    } catch (e) {
      if (mounted) {
        if (_quote == null) {
          setState(() => _errorMessage = "Failed to load quote.");
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
        }
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _onAddressSelected(int? id) {
    if (id == null) return;
    setState(() {
      _selectedAddressId = id;
      _selectedShippingKey = null;
    });
    _fetchQuote();
  }

  void _onShippingSelected(String key) {
    setState(() => _selectedShippingKey = key);
    _fetchQuote();
  }

  void _onPromoSelected(String? value) {
    if (value != null && value != _selectedPromo) {
      setState(() => _selectedPromo = value);
      _fetchQuote();
    }
  }

  // ✅ FIX 1: Make Save Address automatically select the newly created address
  Future<void> _saveAddress() async {
    if (!_addressFormKey.currentState!.validate()) return;
    _addressFormKey.currentState!.save();

    final token = Provider.of<AuthProvider>(context, listen: false).token;
    if (token == null) return;

    setState(() => _isLoading = true);
    bool success = await ApiService.addAddress(_addressFormData, token);

    if (success) {
      setState(() {
        _showAddressForm = false;
        _addressFormData.clear();
        _selectedAddressId = null; // Clear so we can grab the fresh ones
      });

      // 1. Fetch the newly updated list of addresses from the server
      await _fetchQuote();

      // 2. Find the newest address (highest ID) and select it
      if (_quote?.addresses != null && _quote!.addresses.isNotEmpty) {
        final newestId = _quote!.addresses.map((a) => a.id).reduce((a, b) => a > b ? a : b);

        if (_selectedAddressId != newestId) {
          setState(() {
            _selectedAddressId = newestId;
            _selectedShippingKey = null; // Reset shipping so it recalculates for this new address
          });
          // 3. Fetch quote one more time to calculate shipping rates for the new selected address
          await _fetchQuote();
        }
      }
    } else {
      setState(() => _isLoading = false);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Failed to save address")));
    }
  }

  Future<void> _createOrder() async {
    if (_quote?.checkoutBlock?.isBlocked == true) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_quote?.checkoutBlock?.message ?? "Checkout Blocked")));
      return;
    }
    if (!_acceptTerms) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please accept Terms & Conditions")));
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token;

    if (token == null || token.isEmpty) {
      _handleSessionExpired();
      return;
    }

    setState(() => _isCreatingOrder = true);
    final locale = Localizations.localeOf(context).languageCode;

    String apiPaymentMethod = 'ccavenue';
    if (_paymentMethod == 'paypal') apiPaymentMethod = 'paypal';
    if (_paymentMethod == 'transfer') apiPaymentMethod = 'transfer_online';

    final body = {
      'address': _selectedAddressId,
      'shipping_method': _selectedShippingKey,
      'payment_method': apiPaymentMethod,
      'coupon_code': _quote?.coupon?.applied == true ? _quote?.coupon?.code : null,
      'promo': _selectedPromo,
      'free_ship': _selectedPromo == 'free_ship' ? 1 : 0,
      'note': _noteCtrl.text,
      'shipment_value': _shipmentValueCtrl.text,
    };

    final result = await ApiService.createOrder(body, locale, token);

    if (mounted) setState(() => _isCreatingOrder = false);

    if (result['success']) {
      final data = result['data'];
      final innerData = (data['data'] != null && data['data'] is Map) ? data['data'] : data;

      String? redirectUrl = innerData['paypal_url'];
      if (redirectUrl == null) redirectUrl = innerData['card_url'];
      if (redirectUrl == null) redirectUrl = innerData['url'];
      if (redirectUrl == null) redirectUrl = innerData['payment_link'];

      if (redirectUrl != null && redirectUrl.toString().isNotEmpty && redirectUrl != "null") {
        _launchUrl(redirectUrl);
        return;
      }

      final orderInfo = innerData['order'];
      final orderId = orderInfo != null ? orderInfo['order_id']?.toString() : "Confirmed";
      _showSuccessDialog(orderId ?? "Confirmed");

    } else {
      if (mounted) {
        String msg = result['message'].toString().toLowerCase();
        if (msg.contains('unauthorized') || msg.contains('unauthenticated')) {
          _handleSessionExpired();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(result['message'] ?? "Order Failed"), backgroundColor: Colors.red)
          );
        }
      }
    }
  }

  void _handleSessionExpired() {
    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Session expired. Redirecting to login..."),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        )
    );

    Provider.of<AuthProvider>(context, listen: false).logout();

    Future.delayed(const Duration(seconds: 1), () {
      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
    });
  }

  Future<void> _launchUrl(String urlString) async {
    String cleanUrl = urlString.trim();
    if (!cleanUrl.startsWith('http://') && !cleanUrl.startsWith('https://')) {
      cleanUrl = 'https://$cleanUrl';
    }

    final Uri url = Uri.parse(cleanUrl);

    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        await launchUrl(url, mode: LaunchMode.platformDefault);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Could not open payment link: $cleanUrl"))
        );
      }
    }
  }

  void _showSuccessDialog(String orderId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.all(24),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_rounded, color: Colors.green, size: 48),
            ),
            const SizedBox(height: 20),
            const Text("Order Received!", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
            const SizedBox(height: 12),
            Text("Order ID: #$orderId", style: TextStyle(color: _navyBlue, fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            const Text(
              "We have received your order. We will contact you soon.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, height: 1.5),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: _navyBlue,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0
                ),
                onPressed: () {
                  Navigator.of(ctx).pop();
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
                child: const Text("Continue Shopping", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tr = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final Color scaffoldBg = Theme.of(context).scaffoldBackgroundColor;
    final Color appBarBg = isDark ? const Color(0xFF1C1C23) : Colors.white;
    final Color dividerColor = isDark ? Colors.white12 : Colors.grey.shade200;
    final Color textColor = isDark ? Colors.white : Colors.black;

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        title: Text(tr?.checkout ?? "Checkout", style: TextStyle(fontWeight: FontWeight.bold, color: textColor)),
        backgroundColor: appBarBg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, size: 20, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
        shape: Border(bottom: BorderSide(color: dividerColor, width: 1)),
      ),

      bottomNavigationBar: _isLoading && _quote == null ? null : _buildStickyFooter(isDark, textColor, tr),

      body: _isLoading && _quote == null
          ? const CheckoutPageSkeleton()
          : _errorMessage != null
          ? _buildErrorState(textColor)
          : RefreshIndicator(
        onRefresh: () async {
          await _fetchQuote();
        },
        color: _navyBlue,
        backgroundColor: isDark ? const Color(0xFF2A2A35) : Colors.white,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_quote?.checkoutBlock?.isBlocked == true)
                _buildBlockedAlert(),

              _buildSectionTitle("Items in Order", textColor),
              const SizedBox(height: 12),
              _buildExpandableOrderItems(isDark, textColor, dividerColor),
              const SizedBox(height: 24),

              _buildPromotionsSection(isDark, textColor, dividerColor),
              const SizedBox(height: 24),

              _buildSectionTitle(tr?.shippingAddress ?? "Shipping Address", textColor,
                  action: TextButton(
                    onPressed: () => setState(() => _showAddressForm = true),
                    child: Text("+ Add New", style: TextStyle(fontSize: 13, color: _navyBlue)),
                  )
              ),
              const SizedBox(height: 12),
              _buildAddressSection(isDark, dividerColor, tr),
              const SizedBox(height: 24),

              _buildSectionTitle(tr?.shippingMethod ?? "Shipping Method", textColor),
              const SizedBox(height: 12),
              _buildShippingSection(isDark, dividerColor),
              const SizedBox(height: 24),

              _buildSectionTitle(tr?.paymentMethod ?? "Payment Method", textColor),
              const SizedBox(height: 12),
              _buildPaymentSection(isDark, dividerColor),
              const SizedBox(height: 24),

              _buildSectionTitle("Preferences", textColor),
              const SizedBox(height: 12),
              _buildPreferencesSection(isDark),
              const SizedBox(height: 24),

              _buildOrderSummary(isDark, dividerColor, textColor, tr),

              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPromotionsSection(bool isDark, Color textColor, Color borderColor) {
    final promos = _quote?.promotions;
    if (promos == null || (!promos.eligible['free_ship']! && !promos.eligible['ten_off']!)) {
      return const SizedBox();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle("Promotions", textColor),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF2A2A35) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor),
          ),
          child: Column(
            children: [
              if (promos.eligible['free_ship'] == true)
                RadioListTile<String>(
                  value: 'free_ship',
                  groupValue: _selectedPromo,
                  onChanged: _onPromoSelected,
                  activeColor: _navyBlue,
                  title: Row(
                    children: [
                      const Text("Free Shipping", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      const SizedBox(width: 8),
                      if(promos.savings['free_ship'] != null && promos.savings['free_ship']! > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(4)),
                          child: Text("- \$${promos.savings['free_ship']!.toStringAsFixed(2)}", style: const TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.bold)),
                        )
                    ],
                  ),
                  subtitle: Text(promos.notes['free_ship'] ?? 'Free shipping on eligible items.', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                ),

              if (promos.eligible['ten_off'] == true)
                RadioListTile<String>(
                  value: 'ten_off',
                  groupValue: _selectedPromo,
                  onChanged: _onPromoSelected,
                  activeColor: _navyBlue,
                  title: Row(
                    children: [
                      const Text("10% Off", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      const SizedBox(width: 8),
                      if(promos.savings['ten_off'] != null && promos.savings['ten_off']! > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(4)),
                          child: Text("- \$${promos.savings['ten_off']!.toStringAsFixed(2)}", style: const TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.bold)),
                        )
                    ],
                  ),
                  subtitle: Text(promos.notes['ten_off'] ?? '10% off for first order > \$700.', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                ),

              RadioListTile<String>(
                value: 'none',
                groupValue: _selectedPromo,
                onChanged: _onPromoSelected,
                activeColor: _navyBlue,
                title: const Text("No Promo", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                subtitle: Text("Do not apply any promotion.", style: TextStyle(fontSize: 12, color: Colors.grey[600])),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildErrorState(Color textColor) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.red),
          const SizedBox(height: 16),
          Text(_errorMessage!, style: TextStyle(color: textColor)),
          TextButton(onPressed: _fetchInitialData, child: const Text("Retry"))
        ],
      ),
    );
  }

  Widget _buildBlockedAlert() {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        children: [
          const Icon(Icons.block, color: Colors.red),
          const SizedBox(width: 12),
          Expanded(child: Text(_quote?.checkoutBlock?.message ?? "Checkout blocked", style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, Color textColor, {Widget? action}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor)),
        if (action != null) action
      ],
    );
  }

  Widget _buildExpandableOrderItems(bool isDark, Color textColor, Color borderColor) {
    final products = _quote?.products ?? [];
    if (products.isEmpty) return const SizedBox();

    final visibleItems = _showAllItems ? products : products.take(5).toList();
    final hiddenCount = products.length - 5;
    final bool canExpand = products.length > 5;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2A2A35) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        children: [
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: visibleItems.length,
            separatorBuilder: (_, __) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: MySeparator(color: isDark ? Colors.white12 : Colors.grey.shade200),
            ),
            itemBuilder: (ctx, i) {
              final item = visibleItems[i];
              double displayTotal = item.total;
              if (displayTotal <= 0) {
                displayTotal = item.price * item.quantity;
              }

              return Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: Colors.white,
                      border: Border.all(color: Colors.grey.withOpacity(0.1)),
                    ),
                    child: Image.network(
                      item.image,
                      fit: BoxFit.contain,
                      errorBuilder: (c,e,s) => const Icon(Icons.image_not_supported, color: Colors.grey),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontWeight: FontWeight.w600, color: textColor, fontSize: 13)),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text("Qty: ${item.quantity}", style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                            Text("\$${displayTotal.toStringAsFixed(2)}", style: TextStyle(fontWeight: FontWeight.bold, color: _navyBlue, fontSize: 14)),
                          ],
                        )
                      ],
                    ),
                  )
                ],
              );
            },
          ),

          if (canExpand)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: InkWell(
                onTap: () => setState(() => _showAllItems = !_showAllItems),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _showAllItems ? "Show Less" : "View $hiddenCount More Items",
                      style: TextStyle(color: _navyBlue, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                        _showAllItems ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                        color: _navyBlue,
                        size: 18
                    )
                  ],
                ),
              ),
            )
        ],
      ),
    );
  }

  Widget _buildCouponSection(bool isDark, AppLocalizations? tr) {
    final Color inputBg = isDark ? const Color(0xFF2A2A35) : const Color(0xFFF9FAFB);
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 50,
            decoration: BoxDecoration(
                color: inputBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: isDark ? Colors.white12 : Colors.transparent)
            ),
            child: TextField(
              controller: _couponCtrl,
              style: TextStyle(color: isDark ? Colors.white : Colors.black),
              decoration: InputDecoration(
                hintText: tr?.enterCouponCode ?? "Enter code",
                hintStyle: TextStyle(color: isDark ? Colors.white38 : Colors.grey),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                prefixIcon: const Icon(Icons.local_offer_outlined, size: 20, color: Colors.grey),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        ElevatedButton(
          onPressed: () => _fetchQuote(),
          style: ElevatedButton.styleFrom(
            backgroundColor: _navyBlue,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            minimumSize: const Size(80, 50),
          ),
          child: Text(tr?.apply ?? "Apply", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  Widget _buildAddressSection(bool isDark, Color borderColor, AppLocalizations? tr) {
    if (_showAddressForm) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2A2A35) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor),
        ),
        child: Form(
          key: _addressFormKey,
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("New Address", style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)),
                  IconButton(icon: const Icon(Icons.close, size: 20), onPressed: () => setState(() => _showAddressForm = false)),
                ],
              ),
              const Divider(),
              _buildModernInput("Country (Select)", isDark, isDropdown: true),
              const SizedBox(height: 12),
              _buildModernInput("City", isDark, onSaved: (v) => _addressFormData['city'] = v),
              const SizedBox(height: 12),
              _buildModernInput("Street", isDark, onSaved: (v) => _addressFormData['street'] = v),
              const SizedBox(height: 12),
              _buildModernInput("Address Detail", isDark, onSaved: (v) => _addressFormData['address'] = v),
              const SizedBox(height: 12),
              _buildModernInput("Phone", isDark, onSaved: (v) => _addressFormData['phone'] = v),
              const SizedBox(height: 12),
              _buildModernInput("Postal Code", isDark, onSaved: (v) => _addressFormData['postal_code'] = v),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                    onPressed: _saveAddress,
                    style: ElevatedButton.styleFrom(backgroundColor: _navyBlue, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                    child: const Text("Save & Use", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))
                ),
              ),
            ],
          ),
        ),
      );
    }

    final addresses = _quote?.addresses ?? [];
    if (addresses.isEmpty) {
      return Center(child: Text("No addresses found. Add one.", style: TextStyle(color: isDark ? Colors.white54 : Colors.grey)));
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: addresses.length,
      separatorBuilder: (_,__) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final addr = addresses[index];
        final bool isSelected = addr.id == _selectedAddressId;
        final Color cardBg = isDark
            ? (isSelected ? _navyBlue.withOpacity(0.3) : const Color(0xFF2A2A35))
            : (isSelected ? _navyBlue.withOpacity(0.05) : Colors.white);
        final Color borderC = isSelected ? _navyBlue : borderColor;

        return GestureDetector(
          onTap: () => _onAddressSelected(addr.id),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderC, width: isSelected ? 1.5 : 1),
            ),
            child: Row(
              children: [
                Icon(
                  isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
                  color: isSelected ? _navyBlue : Colors.grey,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("${addr.countryName ?? ''}, ${addr.city}", style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)),
                      const SizedBox(height: 4),
                      Text("${addr.street}, ${addr.address}", style: TextStyle(fontSize: 13, color: isDark ? Colors.white70 : Colors.grey[700])),
                      if(addr.phone.isNotEmpty)
                        Text(addr.phone, style: TextStyle(fontSize: 12, color: isDark ? Colors.white38 : Colors.grey)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildModernInput(String hint, bool isDark, {bool isDropdown = false, Function(String?)? onSaved}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1C1C23) : Colors.grey[50],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isDark ? Colors.white12 : Colors.grey.shade300)
      ),
      child: isDropdown
          ? DropdownButtonFormField<int>(
        isExpanded: true,
        decoration: const InputDecoration(border: InputBorder.none),
        dropdownColor: isDark ? const Color(0xFF2A2A35) : Colors.white,
        hint: Text(hint, style: TextStyle(color: isDark ? Colors.white54 : Colors.grey)),
        items: _countries.map((c) => DropdownMenuItem(
            value: c.id,
            child: Text(
              c.name,
              style: TextStyle(color: isDark ? Colors.white : Colors.black),
              overflow: TextOverflow.ellipsis,
            )
        )).toList(),
        onChanged: (val) => _addressFormData['country_id'] = val,
      )
          : TextFormField(
        style: TextStyle(color: isDark ? Colors.white : Colors.black),
        decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: isDark ? Colors.white38 : Colors.grey),
            border: InputBorder.none
        ),
        onSaved: onSaved,
        validator: (v) => v!.isEmpty ? "Required" : null,
      ),
    );
  }

  Widget _buildShippingSection(bool isDark, Color borderColor) {
    final options = _quote?.shipping.options ?? [];
    if (options.isEmpty) return const Text("Please select an address first.", style: TextStyle(color: Colors.grey));

    return Column(
      children: options.map((opt) {
        final bool isSelected = opt.key == _selectedShippingKey;
        final Color cardBg = isDark
            ? (isSelected ? _navyBlue.withOpacity(0.3) : const Color(0xFF2A2A35))
            : (isSelected ? _navyBlue.withOpacity(0.05) : Colors.white);

        return GestureDetector(
          onTap: opt.disabled ? null : () => _onShippingSelected(opt.key),
          child: Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: isSelected ? _navyBlue : borderColor, width: isSelected ? 1.5 : 1),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(isSelected ? Icons.check_circle : Icons.local_shipping_outlined, color: isSelected ? _navyBlue : Colors.grey),
                    const SizedBox(width: 12),
                    Text(opt.label, style: TextStyle(fontWeight: FontWeight.w600, color: isDark ? Colors.white : Colors.black)),
                  ],
                ),
                Text(
                  opt.price > 0 ? "\$${opt.price.toStringAsFixed(2)}" : "Free",
                  style: TextStyle(fontWeight: FontWeight.bold, color: _navyBlue),
                )
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPaymentSection(bool isDark, Color borderColor) {
    final methods = [
      {'key': 'card', 'name': 'Credit/Debit Card', 'icon': Icons.credit_card},
      {'key': 'paypal', 'name': 'PayPal', 'icon': Icons.payment},
      {'key': 'transfer', 'name': 'Bank Transfer', 'icon': Icons.account_balance},
    ];

    return Column(
      children: [
        ...methods.map((m) {
          final isSelected = _paymentMethod == m['key'];
          return GestureDetector(
            onTap: () => setState(() => _paymentMethod = m['key'].toString()),
            child: Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF2A2A35) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: isSelected ? _navyBlue : borderColor, width: isSelected ? 1.5 : 1),
              ),
              child: Row(
                children: [
                  Icon(m['icon'] as IconData, color: isSelected ? _navyBlue : Colors.grey),
                  const SizedBox(width: 12),
                  Text(m['name'] as String, style: TextStyle(fontWeight: FontWeight.w600, color: isDark ? Colors.white : Colors.black)),
                  const Spacer(),
                  if(isSelected) Icon(Icons.check, color: _navyBlue, size: 20),
                ],
              ),
            ),
          );
        }),
        if (_paymentMethod == 'transfer')
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1C1C23) : const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: borderColor)
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Bank Details", style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)),
                const SizedBox(height: 8),
                Text("Bank: ADCB\nAccount: 699321041001\nIBAN: AE4700...", style: TextStyle(fontSize: 13, height: 1.5, color: isDark ? Colors.white70 : Colors.grey[700])),
              ],
            ),
          )
      ],
    );
  }

  Widget _buildPreferencesSection(bool isDark) {
    final Color inputBg = isDark ? const Color(0xFF2A2A35) : const Color(0xFFF9FAFB);
    return Column(
      children: [
        TextField(
          controller: _noteCtrl,
          maxLines: 2,
          style: TextStyle(color: isDark ? Colors.white : Colors.black),
          decoration: InputDecoration(
            labelText: "Order Note (Optional)",
            labelStyle: const TextStyle(color: Colors.grey),
            filled: true,
            fillColor: inputBg,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _shipmentValueCtrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: TextStyle(color: isDark ? Colors.white : Colors.black),
          decoration: InputDecoration(
            labelText: "Declared Shipment Value (\$)",
            labelStyle: const TextStyle(color: Colors.grey),
            filled: true,
            fillColor: inputBg,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
        ),
      ],
    );
  }

  Widget _buildOrderSummary(bool isDark, Color borderColor, Color textColor, AppLocalizations? tr) {
    final s = _quote?.summary;
    if (s == null) return const SizedBox();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2A2A35) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        children: [
          _summaryRow(tr?.subtotal ?? "Subtotal", s.subTotal, textColor),
          if (s.couponDiscount > 0) _summaryRow(tr?.couponDiscount ?? "Coupon", -s.couponDiscount, Colors.green),
          if (s.promoDiscount > 0) _summaryRow("Promo", -s.promoDiscount, Colors.green),
          _summaryRow(tr?.shipping ?? "Shipping", s.shipping, textColor),

          // Removed the check box from here!
        ],
      ),
    );
  }

  Widget _summaryRow(String label, double val, Color color, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: isTotal ? 16 : 14, fontWeight: isTotal ? FontWeight.bold : FontWeight.w500, color: isTotal ? color : color.withOpacity(0.8))),
          Text("\$${val.toStringAsFixed(2)}", style: TextStyle(fontSize: isTotal ? 20 : 14, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  // ✅ FIX 2: MOVED TERMS CHECKBOX TO STICKY FOOTER
  Widget _buildStickyFooter(bool isDark, Color textColor, AppLocalizations? tr) {
    final s = _quote?.summary;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C23) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.08),
            blurRadius: 20,
            offset: const Offset(0, -5),
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
                Text("Total", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: textColor)),
                Text(
                  s != null ? "\$${s.total.toStringAsFixed(2)}" : "\$0.00",
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: _navyBlue),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // ✅ MOVED TERMS & CONDITIONS HERE
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: 24, width: 24,
                  child: Checkbox(
                      value: _acceptTerms,
                      activeColor: _navyBlue,
                      onChanged: (v) => setState(() => _acceptTerms = v!)
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      tr?.iAgreeToTerms ?? "I agree to Terms & Conditions and Privacy Policy.",
                      style: TextStyle(fontSize: 12, color: isDark ? Colors.white70 : Colors.grey[700]),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isCreatingOrder ? null : _createOrder,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _navyBlue,
                  elevation: 4,
                  shadowColor: _navyBlue.withOpacity(0.4),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: _isCreatingOrder
                    ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.lock_outline, color: Colors.white, size: 20),
                    const SizedBox(width: 8),
                    Text(tr?.placeOrder ?? "Place Order", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// 💀 SKELETON LOADER CLASS
// ==========================================

class CheckoutPageSkeleton extends StatelessWidget {
  const CheckoutPageSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const Skeleton(width: double.infinity, height: 100),
          const SizedBox(height: 24),
          const Skeleton(width: 150, height: 20),
          const SizedBox(height: 12),
          const Skeleton(width: double.infinity, height: 80),
          const SizedBox(height: 24),
          const Skeleton(width: 150, height: 20),
          const SizedBox(height: 12),
          const Skeleton(width: double.infinity, height: 60),
          const SizedBox(height: 24),
          const Skeleton(width: 150, height: 20),
          const SizedBox(height: 12),
          const Skeleton(width: double.infinity, height: 150),
          const SizedBox(height: 24),
          const Skeleton(width: double.infinity, height: 200),
        ],
      ),
    );
  }
}

// ==========================================
// 🔹 DASHED SEPARATOR WIDGET
// ==========================================
class MySeparator extends StatelessWidget {
  final double height;
  final Color color;
  const MySeparator({super.key, this.height = 1, this.color = Colors.grey});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final boxWidth = constraints.constrainWidth();
        const dashWidth = 5.0;
        final dashHeight = height;
        final dashCount = (boxWidth / (2 * dashWidth)).floor();
        return Flex(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          direction: Axis.horizontal,
          children: List.generate(dashCount, (_) {
            return SizedBox(
              width: dashWidth,
              height: dashHeight,
              child: DecoratedBox(decoration: BoxDecoration(color: color)),
            );
          }),
        );
      },
    );
  }
}