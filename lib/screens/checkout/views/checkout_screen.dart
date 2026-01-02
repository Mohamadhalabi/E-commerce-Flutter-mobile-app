import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shop/constants.dart';
import 'package:shop/models/address_model.dart';
import 'package:shop/models/checkout_models.dart';
import 'package:shop/models/country_model.dart';
import 'package:shop/providers/auth_provider.dart';
import 'package:shop/services/api_service.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  // State
  Quote? _quote;
  bool _isLoading = true;
  bool _isCreatingOrder = false;
  String? _errorMessage;

  // Selection State
  int? _selectedAddressId;
  String? _selectedShippingKey;
  String? _paymentMethod;
  bool _acceptTerms = false;

  // Inputs
  final TextEditingController _couponCtrl = TextEditingController();
  final TextEditingController _noteCtrl = TextEditingController();
  final TextEditingController _shipmentValueCtrl = TextEditingController();
  String _selectedPromo = 'none';

  // Address Form
  bool _showAddressForm = false;
  final _addressFormKey = GlobalKey<FormState>();
  final Map<String, dynamic> _addressFormData = {};
  List<CountryModel> _countries = [];

  // Constants
  static const int UAE_COUNTRY_ID = 231;

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

  // Core Quote Fetch Logic
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
    if (_selectedPromo != 'none') params['promo'] = _selectedPromo;

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
        });
      }
    } catch (e) {
      if (mounted) {
        if (_quote == null) {
          setState(() => _errorMessage = "Failed to load quote. Please try again.");
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
        }
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- ACTIONS ---

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
      });
      await _fetchQuote();
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

    final token = Provider.of<AuthProvider>(context, listen: false).token;
    if (token == null) return;

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
      if (_paymentMethod == 'paypal' && data['paypal_url'] != null) {
        _launchUrl(data['paypal_url']);
      } else if (data['order'] != null && data['order']['order_id'] != null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Order Created Successfully!")));
          Navigator.pop(context);
        }
      }
    } else {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result['message'] ?? "Order Failed")));
    }
  }

  Future<void> _launchUrl(String url) async {
    if (!await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $url');
    }
  }

  // --- UI WIDGETS ---

  @override
  Widget build(BuildContext context) {
    final tr = AppLocalizations.of(context);
    final String title = tr?.checkout ?? "Checkout";

    return Scaffold(
      appBar: AppBar(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      backgroundColor: const Color(0xFFF9FAFB),
      body: _isLoading && _quote == null
          ? const Center(child: CircularProgressIndicator(color: primaryColor))
          : _errorMessage != null
          ? Center(child: Text(_errorMessage!, style: const TextStyle(color: Colors.red)))
          : _quote == null
          ? const Center(child: Text("Unable to load checkout information."))
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Blocked Warning
            if (_quote?.checkoutBlock?.isBlocked == true)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(color: const Color(0xFFFFF1F2), borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.red.shade200)),
                child: Row(
                  children: [
                    const Icon(Icons.block, color: Colors.red),
                    const SizedBox(width: 12),
                    Expanded(child: Text(_quote?.checkoutBlock?.message ?? "Checkout blocked for this country", style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold))),
                  ],
                ),
              ),

            // Coupon Section
            _buildSectionCard(
              title: tr?.couponCode ?? "Coupon",
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _couponCtrl,
                      decoration: InputDecoration(
                        hintText: tr?.enterCouponCode ?? "Enter code",
                        isDense: true,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () => _fetchQuote(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      // ✅ FIX: Constrain width to fix layout crash
                      minimumSize: const Size(80, 48),
                    ),
                    child: Text(tr?.apply ?? "Apply", style: const TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            ),

            _buildAddressSection(tr),
            _buildShippingSection(tr),
            _buildPaymentSection(tr),

            // ✅ NEW: Order Items Section
            _buildOrderItemsSection(),

            _buildSectionCard(
              title: "Order Preferences",
              child: Column(
                children: [
                  TextField(
                    controller: _noteCtrl,
                    maxLines: 2,
                    decoration: InputDecoration(
                      labelText: "Order Note",
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _shipmentValueCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: "Declared Shipment Value (\$)",
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ],
              ),
            ),

            _buildSummarySection(tr),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard({required String title, required Widget child, Widget? trailing}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            if (trailing != null) trailing
          ]),
          const Divider(height: 24),
          child,
        ],
      ),
    );
  }

  // ✅ NEW WIDGET: Display Product List (Image, Title, SKU, Price)
  Widget _buildOrderItemsSection() {
    final products = _quote?.products ?? [];
    if (products.isEmpty) return const SizedBox();

    return _buildSectionCard(
      title: "Items in Order",
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: products.length,
        separatorBuilder: (_, __) => const Divider(height: 24),
        itemBuilder: (context, index) {
          final item = products[index];
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product Image
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade200),
                  color: Colors.white,
                ),
                child: item.image.isNotEmpty
                    ? ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    item.image,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const Icon(Icons.image_not_supported, color: Colors.grey, size: 30),
                  ),
                )
                    : const Icon(Icons.image_not_supported, color: Colors.grey, size: 30),
              ),
              const SizedBox(width: 12),

              // Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 4),
                    // SKU (Green)
                    if (item.sku.isNotEmpty)
                      Text(
                        "SKU: ${item.sku}",
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.green),
                      ),
                    const SizedBox(height: 4),
                    // Quantity & Price
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("Qty: ${item.quantity}", style: const TextStyle(fontSize: 12, color: Colors.grey)),
                        Text(
                            "\$${item.price.toStringAsFixed(2)}",
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: primaryColor)
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildAddressSection(AppLocalizations? tr) {
    if (_showAddressForm) {
      return _buildSectionCard(
        title: "Add Address",
        trailing: IconButton(icon: const Icon(Icons.close), onPressed: () => setState(() => _showAddressForm = false)),
        child: Form(
          key: _addressFormKey,
          child: Column(
            children: [
              DropdownButtonFormField<int>(
                decoration: const InputDecoration(labelText: "Country"),
                items: _countries.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))).toList(),
                onChanged: (val) => _addressFormData['country_id'] = val,
                validator: (v) => v == null ? "Required" : null,
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: "City"),
                onSaved: (v) => _addressFormData['city'] = v,
                validator: (v) => v!.isEmpty ? "Required" : null,
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: "Street"),
                onSaved: (v) => _addressFormData['street'] = v,
                validator: (v) => v!.isEmpty ? "Required" : null,
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: "Address Detail"),
                onSaved: (v) => _addressFormData['address'] = v,
                validator: (v) => v!.isEmpty ? "Required" : null,
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: "Phone"),
                onSaved: (v) => _addressFormData['phone'] = v,
                validator: (v) => v!.isEmpty ? "Required" : null,
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: "Postal Code"),
                onSaved: (v) => _addressFormData['postal_code'] = v,
                validator: (v) => v!.isEmpty ? "Required" : null,
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                  onPressed: _saveAddress,
                  style: ElevatedButton.styleFrom(backgroundColor: primaryColor, minimumSize: const Size(double.infinity, 48)),
                  child: const Text("Save Address", style: TextStyle(color: Colors.white))
              ),
            ],
          ),
        ),
      );
    }

    return _buildSectionCard(
      title: tr?.shippingAddress ?? "Shipping Address",
      trailing: TextButton(onPressed: () => setState(() => _showAddressForm = true), child: const Text("+ Add")),
      child: Column(
        children: (_quote?.addresses ?? []).map((addr) {
          return RadioListTile<int>(
            value: addr.id,
            groupValue: _selectedAddressId,
            onChanged: _onAddressSelected,
            title: Text("${addr.countryName ?? ''}, ${addr.city}"),
            subtitle: Text("${addr.street}, ${addr.address}"),
            activeColor: primaryColor,
            contentPadding: EdgeInsets.zero,
          );
        }).toList(),
      ),
    );
  }

  Widget _buildShippingSection(AppLocalizations? tr) {
    final options = _quote?.shipping.options ?? [];

    return _buildSectionCard(
      title: tr?.shippingMethod ?? "Shipping Method",
      child: options.isEmpty
          ? const Text("No shipping options available.", style: TextStyle(color: Colors.red))
          : Column(
        children: options.map((opt) {
          return RadioListTile<String>(
            value: opt.key,
            groupValue: _selectedShippingKey,
            onChanged: opt.disabled ? null : (val) => _onShippingSelected(val!),
            title: Text(opt.label),
            subtitle: opt.price > 0 ? Text("\$${opt.price}") : const Text("Free"),
            activeColor: primaryColor,
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPaymentSection(AppLocalizations? tr) {
    return _buildSectionCard(
      title: tr?.paymentMethod ?? "Payment Method",
      child: Column(
        children: [
          RadioListTile(
            value: 'card',
            groupValue: _paymentMethod,
            onChanged: (v) => setState(() => _paymentMethod = v.toString()),
            title: const Text("Credit/Debit Card"),
            secondary: const Icon(Icons.credit_card),
            activeColor: primaryColor,
          ),
          RadioListTile(
            value: 'paypal',
            groupValue: _paymentMethod,
            onChanged: (v) => setState(() => _paymentMethod = v.toString()),
            title: const Text("PayPal"),
            secondary: const Icon(Icons.payment),
            activeColor: primaryColor,
          ),
          RadioListTile(
            value: 'transfer',
            groupValue: _paymentMethod,
            onChanged: (v) => setState(() => _paymentMethod = v.toString()),
            title: const Text("Bank Transfer"),
            secondary: const Icon(Icons.account_balance),
            activeColor: primaryColor,
          ),
          if (_paymentMethod == 'transfer')
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(top: 8),
              decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(8)),
              child: const Text("Bank: ADCB\nAccount: 699321041001\nIBAN: AE4700...", style: TextStyle(fontSize: 12)),
            )
        ],
      ),
    );
  }

  Widget _buildSummarySection(AppLocalizations? tr) {
    final s = _quote?.summary;
    if (s == null) return const SizedBox();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]),
      child: Column(
        children: [
          _row(tr?.subtotal ?? "Subtotal", s.subTotal),
          if (s.couponDiscount > 0) _row(tr?.couponDiscount ?? "Coupon", -s.couponDiscount, color: Colors.green),
          if (s.promoDiscount > 0) _row("Promo Discount", -s.promoDiscount, color: Colors.green),
          _row(tr?.shipping ?? "Shipping", s.shipping),
          const Divider(),
          _row(tr?.total ?? "Total", s.total, isBold: true, size: 18),

          const SizedBox(height: 20),

          Row(children: [
            Checkbox(value: _acceptTerms, activeColor: primaryColor, onChanged: (v) => setState(() => _acceptTerms = v!)),
            Expanded(child: Text(tr?.iAgreeToTerms ?? "I agree to Terms & Conditions", style: const TextStyle(fontSize: 12))),
          ]),

          const SizedBox(height: 10),

          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _isCreatingOrder ? null : _createOrder,
              style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
              child: _isCreatingOrder
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : Text(tr?.placeOrder ?? "Place Order", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
            ),
          )
        ],
      ),
    );
  }

  Widget _row(String label, double val, {bool isBold = false, Color? color, double size = 14}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: size, fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
          Text("\$${val.toStringAsFixed(2)}", style: TextStyle(fontSize: size, fontWeight: isBold ? FontWeight.bold : FontWeight.normal, color: color ?? (isBold ? primaryColor : Colors.black))),
        ],
      ),
    );
  }
}