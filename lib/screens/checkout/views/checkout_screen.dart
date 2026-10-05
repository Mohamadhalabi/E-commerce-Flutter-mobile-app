import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shop/constants.dart';
import 'package:shop/models/checkout_models.dart';
import 'package:shop/models/country_model.dart';
import 'package:shop/providers/auth_provider.dart';
import 'package:shop/route/route_constants.dart';
import 'package:shop/services/api_service.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shop/components/skleton/skeleton.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
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

  String _selectedPromo = 'none';

  // ---------------------------------------------------------------------------
  // GATEWAY FEE — 3% on card & PayPal, none on bank transfer
  // ---------------------------------------------------------------------------
  static const double _gatewayFeeRate = 0.03;

  bool get _hasGatewayFee =>
      _paymentMethod == 'card' || _paymentMethod == 'paypal' || _paymentMethod == 'network_ae';

  /// Network International (Apple Pay + cards). Apple Pay only works on
  /// iPhone, so by default this option is shown on iOS only.
  /// Set to true to also offer it on Android (card payments only there).
  static const bool _showNetworkOnAndroid = true;

  /// Total from the server (after discounts + shipping), before the fee.
  double get _baseTotal => _quote?.summary.total ?? 0;

  /// Rounded to cents so the UI and the order body always agree.
  double get _gatewayFee =>
      _hasGatewayFee ? (_baseTotal * _gatewayFeeRate * 100).round() / 100 : 0;

  double get _grandTotal => _baseTotal + _gatewayFee;

  bool _showAddressForm = false;
  final _addressFormKey = GlobalKey<FormState>();
  final Map<String, dynamic> _addressFormData = {};
  List<CountryModel> _countries = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _fetchInitialData();
    });
  }

  @override
  void dispose() {
    _couponCtrl.dispose();
    _noteCtrl.dispose();
    _shipmentValueCtrl.dispose();
    super.dispose();
  }

  void _toast(String message, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: error ? primaryDarkColor : blackColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
  }

  // ---------------------------------------------------------------------------
  // DATA
  // ---------------------------------------------------------------------------
  Future<void> _fetchInitialData() async {
    final token = Provider.of<AuthProvider>(context, listen: false).token;
    if (token == null) {
      setState(() {
        _isLoading = false;
        _errorMessage = "You need to sign in to check out.";
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      _countries = await ApiService.fetchCountries(token);
      await _fetchQuote(initialLoad: true);
    } catch (e) {
      debugPrint('Checkout init failed: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = "Checkout didn't load. Check your connection and try again.";
        });
      }
    }
  }

  Future<void> _fetchQuote({bool initialLoad = false}) async {
    final token = Provider.of<AuthProvider>(context, listen: false).token;
    if (token == null) return;

    if (mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }
    final locale = Localizations.localeOf(context).languageCode;

    final params = <String, dynamic>{};
    if (initialLoad) params['skip_shipping'] = '1';
    if (_selectedAddressId != null) params['address_id'] = _selectedAddressId;
    if (_selectedShippingKey != null) params['shipping_method'] = _selectedShippingKey;
    if (_couponCtrl.text.isNotEmpty) params['coupon'] = _couponCtrl.text;
    params['promo'] = _selectedPromo;

    try {
      final json = await ApiService.fetchCheckoutQuote(params, locale, token);
      final newQuote = Quote.fromJson(json);
      if (!mounted) return;

      setState(() {
        _quote = newQuote;
        if (_selectedAddressId == null && newQuote.selectedAddressId != null) {
          _selectedAddressId = newQuote.selectedAddressId;
        }
        if (_selectedAddressId != null &&
            _selectedShippingKey == null &&
            newQuote.shipping.selected != null) {
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
    } catch (e) {
      debugPrint('Quote failed: $e');
      if (!mounted) return;
      if (_quote == null) {
        setState(() => _errorMessage = "Checkout didn't load. Check your connection and try again.");
      } else {
        _toast("Couldn't update the totals. Try again.", error: true);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _onAddressSelected(int? id) {
    if (id == null || id == _selectedAddressId) return;
    setState(() {
      _selectedAddressId = id;
      _selectedShippingKey = null;
    });
    _fetchQuote();
  }

  void _onShippingSelected(String key) {
    if (key == _selectedShippingKey) return;
    setState(() => _selectedShippingKey = key);
    _fetchQuote();
  }

  void _onPromoSelected(String? value) {
    if (value != null && value != _selectedPromo) {
      setState(() => _selectedPromo = value);
      _fetchQuote();
    }
  }

  /// Saves the address, then selects the newest one automatically.
  Future<void> _saveAddress() async {
    if (!_addressFormKey.currentState!.validate()) return;
    _addressFormKey.currentState!.save();
    FocusScope.of(context).unfocus();

    final token = Provider.of<AuthProvider>(context, listen: false).token;
    if (token == null) return;

    setState(() => _isLoading = true);
    final success = await ApiService.addAddress(_addressFormData, token);
    if (!mounted) return;

    if (!success) {
      setState(() => _isLoading = false);
      _toast("Couldn't save the address. Check the fields and try again.", error: true);
      return;
    }

    setState(() {
      _showAddressForm = false;
      _addressFormData.clear();
      _selectedAddressId = null;
    });

    await _fetchQuote();
    if (!mounted) return;

    final addresses = _quote?.addresses ?? [];
    if (addresses.isNotEmpty) {
      final newestId = addresses.map((a) => a.id).reduce((a, b) => a > b ? a : b);
      if (_selectedAddressId != newestId) {
        setState(() {
          _selectedAddressId = newestId;
          _selectedShippingKey = null;
        });
        await _fetchQuote();
      }
    }
  }

  Future<void> _createOrder() async {
    if (_quote?.checkoutBlock?.isBlocked == true) {
      _toast(_quote?.checkoutBlock?.message ?? "Checkout is unavailable for this order.", error: true);
      return;
    }
    if (_selectedAddressId == null) {
      _toast("Choose a shipping address first.", error: true);
      return;
    }
    if (!_acceptTerms) {
      _toast("Accept the Terms & Conditions to place your order.", error: true);
      return;
    }

    final token = Provider.of<AuthProvider>(context, listen: false).token;
    if (token == null || token.isEmpty) {
      _handleSessionExpired();
      return;
    }

    setState(() => _isCreatingOrder = true);
    final locale = Localizations.localeOf(context).languageCode;

    String apiPaymentMethod = 'ccavenue';
    if (_paymentMethod == 'paypal') apiPaymentMethod = 'paypal';
    if (_paymentMethod == 'transfer') apiPaymentMethod = 'transfer_online';
    if (_paymentMethod == 'network_ae') apiPaymentMethod = 'network_ae';

    final body = {
      'address': _selectedAddressId,
      'shipping_method': _selectedShippingKey,
      'payment_method': apiPaymentMethod,
      'coupon_code': _quote?.coupon?.applied == true ? _quote?.coupon?.code : null,
      'promo': _selectedPromo,
      'free_ship': _selectedPromo == 'free_ship' ? 1 : 0,
      'note': _noteCtrl.text,
      'shipment_value': _shipmentValueCtrl.text,
      'platform': 'mobile_app',
      'gateway_fee_percent': _hasGatewayFee ? (_gatewayFeeRate * 100) : 0,
      'gateway_fee': _gatewayFee,
    };

    final result = await ApiService.createOrder(body, locale, token);
    if (!mounted) return;
    setState(() => _isCreatingOrder = false);

    if (result['success'] == true) {
      final data = result['data'];
      final innerData = (data['data'] != null && data['data'] is Map) ? data['data'] : data;

      // The server returns "" for links that don't apply, so take the
      // first one that actually has a value.
      String? redirectUrl;
      for (final key in const ['networkae_url', 'paypal_url', 'card_url', 'url', 'payment_link']) {
        final value = innerData[key]?.toString() ?? '';
        if (value.isNotEmpty && value != 'null') {
          redirectUrl = value;
          break;
        }
      }

      if (redirectUrl != null) {
        _launchUrl(redirectUrl);
        return;
      }

      final orderInfo = innerData['order'];
      final orderId = orderInfo != null ? orderInfo['order_id']?.toString() : null;
      _showSuccessDialog(orderId ?? "Confirmed");
    } else {
      final msg = (result['message'] ?? '').toString().toLowerCase();
      if (msg.contains('unauthorized') || msg.contains('unauthenticated')) {
        _handleSessionExpired();
      } else {
        _toast(result['message']?.toString() ?? "The order didn't go through. Try again.", error: true);
      }
    }
  }

  void _handleSessionExpired() {
    _toast("Your session expired. Sign in again to continue.", error: true);
    Provider.of<AuthProvider>(context, listen: false).logout();
    Future.delayed(const Duration(seconds: 1), () {
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(context, logInScreenRoute, (route) => false);
    });
  }

  Future<void> _launchUrl(String urlString) async {
    var cleanUrl = urlString.trim();
    if (!cleanUrl.startsWith('http://') && !cleanUrl.startsWith('https://')) {
      cleanUrl = 'https://$cleanUrl';
    }
    final url = Uri.parse(cleanUrl);

    try {
      final ok = await launchUrl(url, mode: LaunchMode.externalApplication);
      if (!ok) await launchUrl(url, mode: LaunchMode.platformDefault);
    } catch (e) {
      _toast("Couldn't open the payment page.", error: true);
    }
  }

  void _showSuccessDialog(String orderId) {
    final green = Colors.green.shade600;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        backgroundColor: AppPalette.card(context),
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: green.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.check_rounded, color: green, size: 44),
              ),
              const SizedBox(height: 18),
              Text(
                "Order received",
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 20,
                  color: AppPalette.text(context),
                ),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppPalette.cardElevated(context),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  "Order #$orderId",
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    color: AppPalette.text(context),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                "We've received your order and will contact you soon.",
                textAlign: TextAlign.center,
                style: TextStyle(color: AppPalette.textMuted(context), height: 1.45),
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  },
                  child: const Text(
                    "Continue shopping",
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // BUILD
  // ---------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final tr = AppLocalizations.of(context);
    final bg = Theme.of(context).scaffoldBackgroundColor;
    final firstLoad = _isLoading && _quote == null;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
        leadingWidth: 64,
        leading: Padding(
          padding: const EdgeInsetsDirectional.only(start: defaultPadding),
          child: Center(
            child: _RoundButton(
              icon: Icons.arrow_back_ios_new_rounded,
              semanticLabel: 'Back',
              onTap: () => Navigator.maybePop(context),
            ),
          ),
        ),
        title: Text(
          tr?.checkout ?? "Checkout",
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 17,
            color: AppPalette.text(context),
          ),
        ),
        bottom: _isLoading && _quote != null
            ? const PreferredSize(
          preferredSize: Size.fromHeight(2),
          child: LinearProgressIndicator(
            minHeight: 2,
            color: primaryColor,
            backgroundColor: Colors.transparent,
          ),
        )
            : null,
      ),
      bottomNavigationBar:
      firstLoad || _errorMessage != null ? null : _buildStickyFooter(tr),
      body: firstLoad
          ? const CheckoutPageSkeleton()
          : _errorMessage != null
          ? _buildErrorState()
          : RefreshIndicator(
        onRefresh: () => _fetchQuote(),
        color: primaryColor,
        backgroundColor: AppPalette.card(context),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.fromLTRB(defaultPadding, 8, defaultPadding, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_quote?.checkoutBlock?.isBlocked == true) _buildBlockedAlert(),

              _Section(
                title: "Items in order",
                trailing: _quote != null
                    ? Text(
                  "${_quote!.products.length}",
                  style: TextStyle(
                    color: AppPalette.textMuted(context),
                    fontWeight: FontWeight.w700,
                  ),
                )
                    : null,
                child: _buildOrderItems(),
              ),


              _Section(
                title: tr?.shippingAddress ?? "Shipping address",
                trailing: _showAddressForm
                    ? null
                    : _LinkButton(
                  label: "Add new",
                  icon: Icons.add_rounded,
                  onTap: () => setState(() => _showAddressForm = true),
                ),
                child: _buildAddressSection(),
              ),

              _Section(
                title: tr?.shippingMethod ?? "Shipping method",
                child: _buildShippingSection(),
              ),

              _Section(
                title: tr?.paymentMethod ?? "Payment method",
                child: _buildPaymentSection(),
              ),

              _Section(
                title: "Preferences",
                child: _buildPreferencesSection(),
              ),

              _buildOrderSummary(tr),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // SECTIONS
  // ---------------------------------------------------------------------------
  Widget _buildErrorState() {
    final muted = AppPalette.textMuted(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.error_outline_rounded, size: 34, color: primaryColor),
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: TextStyle(color: muted, fontSize: 14, height: 1.4),
            ),
            const SizedBox(height: 18),
            ElevatedButton(
              onPressed: _fetchInitialData,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: const StadiumBorder(),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: const Text("Try again", style: TextStyle(fontWeight: FontWeight.w800)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBlockedAlert() {
    final isDark = AppPalette.isDark(context);
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: primaryColor.withOpacity(isDark ? 0.14 : 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: primaryColor.withOpacity(0.35)),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: const BoxDecoration(color: primaryColor, shape: BoxShape.circle),
            child: const Icon(Icons.block_rounded, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _quote?.checkoutBlock?.message ?? "Checkout is unavailable for this order.",
              style: const TextStyle(color: primaryColor, fontWeight: FontWeight.w700, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderItems() {
    final products = _quote?.products ?? [];
    if (products.isEmpty) return const SizedBox.shrink();

    final visible = _showAllItems ? products : products.take(5).toList();
    final hiddenCount = products.length - 5;

    return _Card(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
      child: Column(
        children: [
          for (var i = 0; i < visible.length; i++) ...[
            _OrderItemRow(
              title: visible[i].title,
              image: visible[i].image,
              quantity: visible[i].quantity,
              total: visible[i].total > 0
                  ? visible[i].total
                  : visible[i].price * visible[i].quantity,
            ),
            if (i < visible.length - 1)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: MySeparator(color: AppPalette.border(context)),
              ),
          ],
          if (products.length > 5)
            TextButton.icon(
              onPressed: () => setState(() => _showAllItems = !_showAllItems),
              style: TextButton.styleFrom(foregroundColor: primaryColor),
              icon: Icon(
                _showAllItems ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                size: 20,
              ),
              label: Text(
                _showAllItems ? "Show less" : "Show $hiddenCount more",
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
              ),
            )
          else
            const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildPromotionsSection() {
    final promos = _quote?.promotions;
    final freeShip = promos?.eligible['free_ship'] == true;
    final tenOff = promos?.eligible['ten_off'] == true;
    if (promos == null || (!freeShip && !tenOff)) return const SizedBox.shrink();

    String? savingLabel(String key) {
      final v = promos.savings[key];
      return (v != null && v > 0) ? "-\$${v.toStringAsFixed(2)}" : null;
    }

    return _Section(
      title: "Promotions",
      child: Column(
        children: [
          if (freeShip)
            _OptionTile(
              selected: _selectedPromo == 'free_ship',
              onTap: () => _onPromoSelected('free_ship'),
              icon: Icons.local_shipping_outlined,
              title: "Free shipping",
              subtitle: promos.notes['free_ship'] ?? "Free shipping on eligible items.",
              badge: savingLabel('free_ship'),
            ),
          if (tenOff)
            _OptionTile(
              selected: _selectedPromo == 'ten_off',
              onTap: () => _onPromoSelected('ten_off'),
              icon: Icons.percent_rounded,
              title: "10% off",
              subtitle: promos.notes['ten_off'] ?? "10% off your first order over \$700.",
              badge: savingLabel('ten_off'),
            ),
          _OptionTile(
            selected: _selectedPromo == 'none',
            onTap: () => _onPromoSelected('none'),
            icon: Icons.do_not_disturb_alt_outlined,
            title: "No promotion",
            subtitle: "Check out without a promotion.",
          ),
        ],
      ),
    );
  }

  Widget _buildAddressSection() {
    if (_showAddressForm) return _buildAddressForm();

    final addresses = _quote?.addresses ?? [];
    if (addresses.isEmpty) {
      return _EmptyHint(
        icon: Icons.location_off_outlined,
        text: "No saved addresses yet.",
        actionLabel: "Add an address",
        onAction: () => setState(() => _showAddressForm = true),
      );
    }

    return Column(
      children: [
        for (final addr in addresses)
          _OptionTile(
            selected: addr.id == _selectedAddressId,
            onTap: () => _onAddressSelected(addr.id),
            icon: Icons.location_on_outlined,
            title: [addr.countryName, addr.city]
                .where((s) => s != null && s.toString().isNotEmpty)
                .join(', '),
            subtitle: [addr.street, addr.address]
                .where((s) => s.toString().isNotEmpty)
                .join(', '),
            caption: addr.phone.isNotEmpty ? addr.phone : null,
          ),
      ],
    );
  }

  Widget _buildAddressForm() {
    return _Card(
      child: Form(
        key: _addressFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    "New address",
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                      color: AppPalette.text(context),
                    ),
                  ),
                ),
                _RoundButton(
                  icon: Icons.close_rounded,
                  semanticLabel: 'Close',
                  size: 32,
                  iconSize: 16,
                  onTap: () => setState(() => _showAddressForm = false),
                ),
              ],
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<int>(
              isExpanded: true,
              dropdownColor: AppPalette.card(context),
              borderRadius: BorderRadius.circular(14),
              decoration: _inputDecoration("Country", Icons.public_rounded),
              style: TextStyle(color: AppPalette.text(context), fontSize: 14.5),
              validator: (v) => v == null ? "Choose a country" : null,
              items: _countries
                  .map((c) => DropdownMenuItem(
                value: c.id,
                child: Text(c.name, overflow: TextOverflow.ellipsis),
              ))
                  .toList(),
              onChanged: (val) => _addressFormData['country_id'] = val,
            ),
            const SizedBox(height: 10),
            _formField("City", Icons.location_city_outlined, 'city'),
            const SizedBox(height: 10),
            _formField("Street", Icons.signpost_outlined, 'street'),
            const SizedBox(height: 10),
            _formField("Building, apartment…", Icons.home_outlined, 'address'),
            const SizedBox(height: 10),
            _formField("Phone", Icons.phone_outlined, 'phone',
                keyboardType: TextInputType.phone),
            const SizedBox(height: 10),
            _formField("Postal code", Icons.markunread_mailbox_outlined, 'postal_code'),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveAddress,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text(
                  "Save and use this address",
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint, IconData icon) {
    final radius = BorderRadius.circular(14);
    OutlineInputBorder border(Color c, [double w = 1]) =>
        OutlineInputBorder(borderRadius: radius, borderSide: BorderSide(color: c, width: w));
    final muted = AppPalette.textMuted(context);

    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: muted.withOpacity(0.8), fontSize: 14),
      filled: true,
      fillColor: AppPalette.cardElevated(context),
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      prefixIcon: Icon(icon, size: 19, color: muted),
      border: border(AppPalette.border(context)),
      enabledBorder: border(AppPalette.border(context)),
      focusedBorder: border(primaryColor, 1.4),
      errorBorder: border(errorColor),
      focusedErrorBorder: border(errorColor, 1.4),
    );
  }

  Widget _formField(String hint, IconData icon, String key, {TextInputType? keyboardType}) {
    return TextFormField(
      keyboardType: keyboardType,
      cursorColor: primaryColor,
      style: TextStyle(color: AppPalette.text(context), fontSize: 14.5),
      decoration: _inputDecoration(hint, icon),
      onSaved: (v) => _addressFormData[key] = v?.trim(),
      validator: (v) => (v == null || v.trim().isEmpty) ? "Required" : null,
    );
  }

  Widget _buildShippingSection() {
    final options = _quote?.shipping.options ?? [];
    if (options.isEmpty) {
      return const _EmptyHint(
        icon: Icons.local_shipping_outlined,
        text: "Choose an address to see shipping options.",
      );
    }

    return Column(
      children: [
        for (final opt in options)
          _OptionTile(
            selected: opt.key == _selectedShippingKey,
            disabled: opt.disabled,
            onTap: () => _onShippingSelected(opt.key),
            icon: Icons.local_shipping_outlined,
            title: opt.label,
            trailingText: opt.price > 0 ? "\$${opt.price.toStringAsFixed(2)}" : "Free",
          ),
      ],
    );
  }

  Widget _buildPaymentSection() {
    final isIOS = Theme.of(context).platform == TargetPlatform.iOS;
    final showNetwork = isIOS || _showNetworkOnAndroid;

    final methods = [
      if (showNetwork)
        {
          'key': 'network_ae',
          'name': isIOS ? 'Apple Pay' : 'Apple Pay',
          'icon': isIOS ? Icons.apple : Icons.apple,
          'note': isIOS
              ? 'Apple Pay or card · 3% gateway fee applies'
              : '3% gateway fee applies',
        },
      {
        'key': 'card',
        'name': 'Credit / debit card',
        'icon': Icons.credit_card_rounded,
        'note': '3% gateway fee applies',
      },
      {
        'key': 'paypal',
        'name': 'PayPal',
        'icon': Icons.account_balance_wallet_outlined,
        'note': '3% gateway fee applies',
      },
      {
        'key': 'transfer',
        'name': 'Bank transfer',
        'icon': Icons.account_balance_outlined,
        'note': 'No extra fees',
      },
    ];

    return Column(
      children: [
        for (final m in methods)
          _OptionTile(
            selected: _paymentMethod == m['key'],
            onTap: () => setState(() => _paymentMethod = m['key'] as String),
            icon: m['icon'] as IconData,
            title: m['name'] as String,
            subtitle: m['note'] as String,
          ),
        if (_paymentMethod == 'transfer')
          _Card(
            color: AppPalette.cardElevated(context),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Bank details",
                  style: TextStyle(fontWeight: FontWeight.w800, color: AppPalette.text(context)),
                ),
                const SizedBox(height: 8),
                SelectableText(
                  "Bank: ADCB\nAccount: 699321041001\nIBAN: AE4700...",
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.55,
                    color: AppPalette.textMuted(context),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildPreferencesSection() {
    return Column(
      children: [
        TextField(
          controller: _noteCtrl,
          maxLines: 2,
          cursorColor: primaryColor,
          style: TextStyle(color: AppPalette.text(context), fontSize: 14.5),
          decoration: _inputDecoration("Order note (optional)", Icons.edit_note_rounded),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _shipmentValueCtrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          cursorColor: primaryColor,
          style: TextStyle(color: AppPalette.text(context), fontSize: 14.5),
          decoration: _inputDecoration("Declared shipment value (\$)", Icons.receipt_long_outlined),
        ),
      ],
    );
  }

  Widget _buildOrderSummary(AppLocalizations? tr) {
    final s = _quote?.summary;
    if (s == null) return const SizedBox.shrink();

    return _Section(
      title: "Summary",
      child: _Card(
        child: Column(
          children: [
            _summaryRow(tr?.subtotal ?? "Subtotal", s.subTotal),
            if (s.couponDiscount > 0)
              _summaryRow(tr?.couponDiscount ?? "Coupon", -s.couponDiscount, highlight: true),
            if (s.promoDiscount > 0)
              _summaryRow("Promotion", -s.promoDiscount, highlight: true),
            _summaryRow(tr?.shipping ?? "Shipping", s.shipping),
            if (_gatewayFee > 0)
              _summaryRow("Gateway fee (3%)", _gatewayFee),
          ],
        ),
      ),
    );
  }

  Widget _summaryRow(String label, double val, {bool highlight = false}) {
    final green = Colors.green.shade600;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: highlight ? green : AppPalette.textMuted(context),
              ),
            ),
          ),
          Text(
            val < 0 ? "-\$${(-val).toStringAsFixed(2)}" : "\$${val.toStringAsFixed(2)}",
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: highlight ? green : AppPalette.text(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStickyFooter(AppLocalizations? tr) {
    final isDark = AppPalette.isDark(context);
    final blocked = _quote?.checkoutBlock?.isBlocked == true;

    return SafeArea(
      minimum: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(defaultPadding, 4, defaultPadding, 0),
        child: Container(
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
                      "Total",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppPalette.textMuted(context),
                      ),
                    ),
                  ),
                  if (_gatewayFee > 0) ...[
                    Text(
                      "incl. 3% fee",
                      style: TextStyle(
                        fontSize: 11.5,
                        color: AppPalette.textMuted(context),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    "\$${_grandTotal.toStringAsFixed(2)}",
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: primaryColor,
                      letterSpacing: -0.4,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // The whole row toggles the checkbox (bigger tap target)
              InkWell(
                onTap: () => setState(() => _acceptTerms = !_acceptTerms),
                borderRadius: BorderRadius.circular(10),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        height: 22,
                        width: 22,
                        child: Checkbox(
                          value: _acceptTerms,
                          activeColor: primaryColor,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                          side: BorderSide(color: AppPalette.textMuted(context), width: 1.5),
                          onChanged: (v) => setState(() => _acceptTerms = v ?? false),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          tr?.iAgreeToTerms ?? "I agree to the Terms & Conditions and Privacy Policy.",
                          style: TextStyle(
                            fontSize: 12.5,
                            height: 1.35,
                            color: AppPalette.textMuted(context),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isCreatingOrder || blocked ? null : _createOrder,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    disabledBackgroundColor: primaryColor.withOpacity(0.5),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: _isCreatingOrder
                      ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                      : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.lock_outline_rounded, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        tr?.placeOrder ?? "Place order",
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                      ),
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
}

// =============================================================================
// PIECES
// =============================================================================
class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child, this.trailing});

  final String title;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 36,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppPalette.text(context),
                    ),
                  ),
                ),
                if (trailing != null) trailing!,
              ],
            ),
          ),
          const SizedBox(height: 6),
          child,
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({
    required this.child,
    this.padding = const EdgeInsets.all(14),
    this.color,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? AppPalette.card(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppPalette.border(context)),
      ),
      child: child,
    );
  }
}

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

class _LinkButton extends StatelessWidget {
  const _LinkButton({required this.label, required this.icon, required this.onTap});

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: primaryColor.withOpacity(AppPalette.isDark(context) ? 0.16 : 0.08),
      shape: const StadiumBorder(),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(8, 6, 12, 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: primaryColor),
              const SizedBox(width: 4),
              Text(
                label,
                style: const TextStyle(
                  color: primaryColor,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Selectable card used for promotions, addresses, shipping and payment.
class _OptionTile extends StatelessWidget {
  const _OptionTile({
    required this.selected,
    required this.onTap,
    required this.icon,
    required this.title,
    this.subtitle,
    this.caption,
    this.badge,
    this.trailingText,
    this.disabled = false,
  });

  final bool selected;
  final VoidCallback onTap;
  final IconData icon;
  final String title;
  final String? subtitle;
  final String? caption;
  final String? badge;
  final String? trailingText;
  final bool disabled;

  @override
  Widget build(BuildContext context) {
    final isDark = AppPalette.isDark(context);
    final muted = AppPalette.textMuted(context);
    final green = Colors.green.shade600;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Opacity(
        opacity: disabled ? 0.5 : 1,
        child: Material(
          color: selected
              ? primaryColor.withOpacity(isDark ? 0.14 : 0.05)
              : AppPalette.card(context),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: selected ? primaryColor : AppPalette.border(context),
              width: selected ? 1.5 : 1,
            ),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: disabled ? null : onTap,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: selected ? primaryColor : AppPalette.cardElevated(context),
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: Icon(
                      icon,
                      size: 19,
                      color: selected ? Colors.white : AppPalette.text(context),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(
                              title,
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                                color: AppPalette.text(context),
                              ),
                            ),
                            if (badge != null)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: green.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  badge!,
                                  style: TextStyle(
                                    color: green,
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        if (subtitle != null && subtitle!.isNotEmpty) ...[
                          const SizedBox(height: 3),
                          Text(
                            subtitle!,
                            style: TextStyle(fontSize: 12.5, color: muted, height: 1.35),
                          ),
                        ],
                        if (caption != null) ...[
                          const SizedBox(height: 2),
                          Text(caption!, style: TextStyle(fontSize: 12, color: muted)),
                        ],
                      ],
                    ),
                  ),
                  if (trailingText != null) ...[
                    const SizedBox(width: 8),
                    Text(
                      trailingText!,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                        color: primaryColor,
                      ),
                    ),
                  ],
                  const SizedBox(width: 10),
                  _RadioDot(selected: selected),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RadioDot extends StatelessWidget {
  const _RadioDot({required this.selected});
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: selected ? primaryColor : Colors.transparent,
        border: Border.all(
          color: selected ? primaryColor : AppPalette.textMuted(context).withOpacity(0.5),
          width: 1.6,
        ),
      ),
      child: selected ? const Icon(Icons.check_rounded, size: 14, color: Colors.white) : null,
    );
  }
}

class _OrderItemRow extends StatelessWidget {
  const _OrderItemRow({
    required this.title,
    required this.image,
    required this.quantity,
    required this.total,
  });

  final String title;
  final String image;
  final int quantity;
  final double total;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 58,
          height: 58,
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: Colors.white,
            border: Border.all(color: AppPalette.border(context)),
          ),
          child: Image.network(
            image,
            fit: BoxFit.contain,
            errorBuilder: (c, e, s) =>
            const Icon(Icons.image_not_supported_outlined, color: blackColor20),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppPalette.text(context),
                  fontSize: 13,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppPalette.cardElevated(context),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      "× $quantity",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppPalette.textMuted(context),
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    "\$${total.toStringAsFixed(2)}",
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      color: primaryColor,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _EmptyHint extends StatelessWidget {
  const _EmptyHint({
    required this.icon,
    required this.text,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String text;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final muted = AppPalette.textMuted(context);
    return _Card(
      color: AppPalette.cardElevated(context),
      child: Row(
        children: [
          Icon(icon, color: muted, size: 20),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: TextStyle(color: muted, fontSize: 13))),
          if (actionLabel != null)
            TextButton(
              onPressed: onAction,
              style: TextButton.styleFrom(foregroundColor: primaryColor),
              child: Text(actionLabel!, style: const TextStyle(fontWeight: FontWeight.w700)),
            ),
        ],
      ),
    );
  }
}

// =============================================================================
// SKELETON
// =============================================================================
class CheckoutPageSkeleton extends StatelessWidget {
  const CheckoutPageSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return const SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Skeleton(width: 140, height: 18),
          SizedBox(height: 12),
          Skeleton(width: double.infinity, height: 150),
          SizedBox(height: 24),
          Skeleton(width: 160, height: 18),
          SizedBox(height: 12),
          Skeleton(width: double.infinity, height: 72),
          SizedBox(height: 10),
          Skeleton(width: double.infinity, height: 72),
          SizedBox(height: 24),
          Skeleton(width: 150, height: 18),
          SizedBox(height: 12),
          Skeleton(width: double.infinity, height: 64),
          SizedBox(height: 24),
          Skeleton(width: double.infinity, height: 140),
        ],
      ),
    );
  }
}

// =============================================================================
// DASHED SEPARATOR
// =============================================================================
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
        final dashCount = (boxWidth / (2 * dashWidth)).floor();
        return Flex(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          direction: Axis.horizontal,
          children: List.generate(dashCount, (_) {
            return SizedBox(
              width: dashWidth,
              height: height,
              child: DecoratedBox(decoration: BoxDecoration(color: color)),
            );
          }),
        );
      },
    );
  }
}