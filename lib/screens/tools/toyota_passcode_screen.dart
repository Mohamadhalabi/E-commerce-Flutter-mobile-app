import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shop/components/common/CustomBottomNavigationBar.dart';
import 'package:shop/constants.dart';
import 'package:shop/providers/auth_provider.dart';
import 'package:shop/route/route_constants.dart';
import 'package:shop/services/api_service.dart';

const String _whatsAppNumber = "971504429045";

/// VIN / frame number length accepted by this tool.
const int _vinMin = 9;
const int _vinMax = 20;

class ToyotaPasscodeScreen extends StatefulWidget {
  const ToyotaPasscodeScreen({super.key});

  @override
  State<ToyotaPasscodeScreen> createState() => _ToyotaPasscodeScreenState();
}

class _ToyotaPasscodeScreenState extends State<ToyotaPasscodeScreen> {
  final TextEditingController _vinController = TextEditingController();
  final TextEditingController _data1Controller = TextEditingController();
  final TextEditingController _data2Controller = TextEditingController();
  final TextEditingController _data3Controller = TextEditingController();

  bool _isLoading = false;
  String? _passcode;
  int? _attemptsLeft;
  String? _errorMsg;
  String _lastVin = "";

  String get _vin => _vinController.text.trim();

  bool get _vinValid => _vin.length >= _vinMin && _vin.length <= _vinMax;

  bool get _isFormValid =>
      _vinValid &&
          _data1Controller.text.trim().isNotEmpty &&
          _data2Controller.text.trim().isNotEmpty &&
          _data3Controller.text.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    for (final c in [_vinController, _data1Controller, _data2Controller, _data3Controller]) {
      c.addListener(() => setState(() {}));
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) Provider.of<AuthProvider>(context, listen: false).fetchUserProfile();
    });
  }

  @override
  void dispose() {
    _vinController.dispose();
    _data1Controller.dispose();
    _data2Controller.dispose();
    _data3Controller.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // ACTIONS
  // ---------------------------------------------------------------------------
  void _onBottomNavTap(int index) {
    if (index == 3) {
      Navigator.pushNamed(context, cartScreenRoute);
    } else {
      Navigator.pushNamedAndRemoveUntil(
        context,
        entryPointScreenRoute,
            (route) => false,
        arguments: index,
      );
    }
  }

  /// Pull-to-refresh only updates the token balance; it no longer wipes the form.
  Future<void> _handleRefresh() async {
    await Provider.of<AuthProvider>(context, listen: false).fetchUserProfile();
  }

  void _reset() {
    _vinController.clear();
    _data1Controller.clear();
    _data2Controller.clear();
    _data3Controller.clear();
    setState(() {
      _passcode = null;
      _attemptsLeft = null;
      _errorMsg = null;
    });
  }

  Future<void> _openWhatsApp(String message) async {
    final uri = Uri.parse(
      'https://wa.me/$_whatsAppNumber?text=${Uri.encodeComponent(message)}',
    );
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _handleCalculate() async {
    if (!_isFormValid || _isLoading) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token;
    if (!authProvider.isAuthenticated || token == null || token.isEmpty) {
      Navigator.pushNamed(context, logInScreenRoute);
      return;
    }

    FocusScope.of(context).unfocus();
    final locale = Localizations.localeOf(context).languageCode;

    setState(() {
      _isLoading = true;
      _passcode = null;
      _attemptsLeft = null;
      _errorMsg = null;
      _lastVin = _vin;
    });

    final body = <String, String>{
      'vin': _vin,
      'data1': _data1Controller.text.trim(),
      'data2': _data2Controller.text.trim(),
      'data3': _data3Controller.text.trim(),
    };

    final res = await ApiService.calculateToyotaPasscode(body, token, locale);
    if (!mounted) return;

    setState(() {
      _isLoading = false;
      if (res['success'] == true) {
        final data = res['data'] ?? {};
        _passcode = (data['passcode'] ?? data['data']?['passcode'])?.toString();
        final attempts = data['attempts_left'] ?? data['data']?['attempts_left'];
        _attemptsLeft = attempts is num ? attempts.toInt() : int.tryParse('$attempts');

        if (_passcode == null || _passcode!.isEmpty) {
          _passcode = null;
          _errorMsg = "Calculation failed. Please check your data.";
        }
      } else {
        _errorMsg = res['message']?.toString() ?? "Something went wrong. Try again.";
      }
    });

    // Update the Toyota token count shown at the top
    authProvider.fetchUserProfile();
  }

  // ---------------------------------------------------------------------------
  // BUILD
  // ---------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final bg = Theme.of(context).scaffoldBackgroundColor;
    final authProvider = Provider.of<AuthProvider>(context);
    final isLoggedIn = authProvider.isAuthenticated;

    final rawTokens = authProvider.user?['toyota_tokens'];
    final int? tokens = rawTokens is num ? rawTokens.toInt() : int.tryParse('${rawTokens ?? ''}');

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: bg,
        extendBody: true,
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
                label: 'Back',
                onTap: () => Navigator.maybePop(context),
              ),
            ),
          ),
          title: Text(
            "Toyota Passcode",
            style: TextStyle(
              color: AppPalette.text(context),
              fontWeight: FontWeight.w800,
              fontSize: 17,
            ),
          ),
        ),
        bottomNavigationBar: CustomBottomNavigationBar(
          currentIndex: 0,
          onTap: _onBottomNavTap,
        ),
        body: Builder(
          builder: (bodyContext) => RefreshIndicator(
            onRefresh: _handleRefresh,
            color: primaryColor,
            backgroundColor: AppPalette.card(context),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: EdgeInsets.fromLTRB(
                defaultPadding,
                8,
                defaultPadding,
                MediaQuery.paddingOf(bodyContext).bottom + 24,
              ),
              children: [
                _buildHero(isLoggedIn, tokens),
                const SizedBox(height: 12),
                if (!isLoggedIn)
                  _buildSignInCard()
                else ...[
                  const _HowItWorks(),
                  const SizedBox(height: 12),
                  if (_passcode != null) _buildResult() else _buildForm(tokens),
                  if (_errorMsg != null) _buildError(),
                  const _ImportantNotes(),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // SECTIONS
  // ---------------------------------------------------------------------------
  Widget _buildHero(bool isLoggedIn, int? tokens) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [primaryColor, primaryDeepColor],
        ),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.22),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.18),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.directions_car_filled_rounded, color: Colors.white, size: 23),
          ),
          const SizedBox(height: 12),
          const Text(
            "Toyota passcode calculator",
            style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(
            "Get the 12-digit passcode from the VIN and your diagnostic tool's data.",
            style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 13.5, height: 1.45),
          ),
          if (isLoggedIn) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.16),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white.withOpacity(0.25)),
              ),
              child: Row(
                children: [
                  Text(
                    tokens?.toString() ?? "–",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      "Toyota tokens available",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  if (tokens != null && tokens <= 0)
                    TextButton(
                      onPressed: () => _openWhatsApp("Hello, I'd like to buy Toyota passcode tokens."),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: Colors.white.withOpacity(0.2),
                        shape: const StadiumBorder(),
                        visualDensity: VisualDensity.compact,
                      ),
                      child: const Text("Buy tokens", style: TextStyle(fontWeight: FontWeight.w800)),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSignInCard() {
    return _Card(
      children: [
        Text(
          "Sign in to continue",
          style: TextStyle(
            fontSize: 16.5,
            fontWeight: FontWeight.w800,
            color: AppPalette.text(context),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          "The Toyota calculator uses the tokens on your account. Sign in to see your balance and calculate a passcode.",
          style: TextStyle(color: AppPalette.textMuted(context), fontSize: 13.5, height: 1.5),
        ),
        const SizedBox(height: 14),
        _PrimaryButton(
          label: "Sign in",
          onPressed: () => Navigator.pushNamed(context, logInScreenRoute),
        ),
      ],
    );
  }

  Widget _buildForm(int? tokens) {
    final muted = AppPalette.textMuted(context);
    final noTokens = tokens != null && tokens <= 0;

    return _Card(
      children: [
        _FieldLabel("VIN / frame number"),
        _CodeField(
          controller: _vinController,
          hint: "JTDKB20U0034567",
          enabled: !_isLoading,
          formatter: _UpperAlnumFormatter(maxLength: _vinMax),
          icon: Icons.directions_car_outlined,
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: Text(
                "$_vinMin to $_vinMax characters, exactly as on the vehicle.",
                style: TextStyle(color: muted, fontSize: 12),
              ),
            ),
            Text(
              "${_vin.length}/$_vinMax",
              style: TextStyle(
                color: _vinValid ? Colors.green.shade600 : muted,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _FieldLabel("Data 1"),
        _CodeField(
          controller: _data1Controller,
          hint: "00000",
          enabled: !_isLoading,
          formatter: _UpperAlnumFormatter(oToZero: true),
          icon: Icons.data_array_rounded,
        ),
        const SizedBox(height: 12),
        _FieldLabel("Data 2"),
        _CodeField(
          controller: _data2Controller,
          hint: "0000",
          enabled: !_isLoading,
          formatter: _UpperAlnumFormatter(oToZero: true),
          icon: Icons.data_array_rounded,
        ),
        const SizedBox(height: 12),
        _FieldLabel("Data 3"),
        _CodeField(
          controller: _data3Controller,
          hint: "000",
          enabled: !_isLoading,
          formatter: _UpperAlnumFormatter(oToZero: true),
          icon: Icons.data_array_rounded,
        ),
        const SizedBox(height: 6),
        Text(
          "The letter O is changed to zero (0) automatically.",
          style: TextStyle(color: muted, fontSize: 12),
        ),
        const SizedBox(height: 18),
        _PrimaryButton(
          label: _isLoading ? "Calculating…" : "Calculate passcode",
          icon: Icons.key_rounded,
          loading: _isLoading,
          onPressed: _isFormValid && !_isLoading && !noTokens ? _handleCalculate : null,
        ),
        const SizedBox(height: 10),
        Text(
          _isLoading
              ? "This can take up to 2 minutes. Please keep the app open."
              : noTokens
              ? "You have no Toyota tokens left. Tap Buy tokens above."
              : !_vinValid
              ? "Enter a VIN of $_vinMin to $_vinMax characters to continue."
              : !_isFormValid
              ? "Fill in Data 1, Data 2 and Data 3 to continue."
              : "Uses 1 Toyota token.",
          style: TextStyle(color: muted, fontSize: 12.5, height: 1.4),
        ),
      ],
    );
  }

  Widget _buildResult() {
    final green = Colors.green.shade600;

    return _Card(
      children: [
        Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(color: green.withOpacity(0.12), shape: BoxShape.circle),
              child: Icon(Icons.check_rounded, color: green, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                "Passcode ready",
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: AppPalette.text(context),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            SizedBox(
              width: 50,
              child: Text("VIN", style: TextStyle(color: AppPalette.textMuted(context), fontSize: 13)),
            ),
            Expanded(
              child: SelectableText(
                _lastVin,
                style: TextStyle(
                  color: AppPalette.text(context),
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.1,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: primaryColor.withOpacity(AppPalette.isDark(context) ? 0.16 : 0.06),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: primaryColor.withOpacity(0.45)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Toyota passcode",
                style: TextStyle(
                  color: AppPalette.textMuted(context),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: AlignmentDirectional.centerStart,
                child: Text(
                  _passcode!,
                  maxLines: 1,
                  style: const TextStyle(
                    color: primaryColor,
                    fontSize: 30,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
              ),
            ],
          ),
        ),
        if (_attemptsLeft != null) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppPalette.cardElevated(context),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              "Free retries left for this VIN: $_attemptsLeft",
              style: TextStyle(
                color: AppPalette.textMuted(context),
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: OutlinedButton.icon(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: _passcode!));
              HapticFeedback.lightImpact();
              if (!mounted) return;
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(SnackBar(
                  content: const Text("Passcode copied"),
                  behavior: SnackBarBehavior.floating,
                  duration: const Duration(seconds: 2),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ));
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: primaryColor,
              side: const BorderSide(color: primaryColor, width: 1.4),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            icon: const Icon(Icons.copy_rounded, size: 18),
            label: const Text("Copy passcode", style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
          ),
        ),
        const SizedBox(height: 10),
        _PrimaryButton(
          label: "New calculation",
          icon: Icons.refresh_rounded,
          onPressed: _reset,
        ),
      ],
    );
  }

  Widget _buildError() {
    final isDark = AppPalette.isDark(context);
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: primaryColor.withOpacity(isDark ? 0.14 : 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: primaryColor.withOpacity(0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.error_outline_rounded, color: primaryColor, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  "Calculation didn't complete",
                  style: TextStyle(
                    color: AppPalette.text(context),
                    fontSize: 15.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _errorMsg!,
            style: TextStyle(color: AppPalette.textMuted(context), fontSize: 13.5, height: 1.5),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: () => _openWhatsApp(
                "Hello, the Toyota passcode calculator didn't work for:\n"
                    "VIN: $_lastVin\n"
                    "Data 1: ${_data1Controller.text}\n"
                    "Data 2: ${_data2Controller.text}\n"
                    "Data 3: ${_data3Controller.text}",
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1DA851),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18),
              label: const Text(
                "Ask us on WhatsApp",
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// PIECES
// =============================================================================

/// Uppercase letters and digits only. Optionally turns O into 0 and limits length.
class _UpperAlnumFormatter extends TextInputFormatter {
  _UpperAlnumFormatter({this.maxLength, this.oToZero = false});
  final int? maxLength;
  final bool oToZero;

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    var text = newValue.text.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');
    if (oToZero) text = text.replaceAll('O', '0');
    if (maxLength != null && text.length > maxLength!) text = text.substring(0, maxLength);
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w800,
          color: AppPalette.text(context),
        ),
      ),
    );
  }
}

class _CodeField extends StatelessWidget {
  const _CodeField({
    required this.controller,
    required this.hint,
    required this.formatter,
    this.enabled = true,
    this.icon,
  });

  final TextEditingController controller;
  final String hint;
  final TextInputFormatter formatter;
  final bool enabled;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final muted = AppPalette.textMuted(context);
    final radius = BorderRadius.circular(16);
    OutlineInputBorder border(Color c, [double w = 1]) =>
        OutlineInputBorder(borderRadius: radius, borderSide: BorderSide(color: c, width: w));

    return TextField(
      controller: controller,
      enabled: enabled,
      textCapitalization: TextCapitalization.characters,
      autocorrect: false,
      enableSuggestions: false,
      cursorColor: primaryColor,
      inputFormatters: [formatter],
      style: TextStyle(
        color: AppPalette.text(context),
        fontSize: 16,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.5,
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          color: muted.withOpacity(0.5),
          letterSpacing: 1.5,
          fontWeight: FontWeight.w500,
        ),
        filled: true,
        fillColor: AppPalette.cardElevated(context),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
        prefixIcon: icon == null ? null : Icon(icon, color: muted, size: 20),
        suffixIcon: controller.text.isEmpty || !enabled
            ? null
            : IconButton(
          tooltip: 'Clear',
          icon: Icon(Icons.close_rounded, color: muted, size: 19),
          onPressed: controller.clear,
        ),
        border: border(AppPalette.border(context)),
        enabledBorder: border(AppPalette.border(context)),
        disabledBorder: border(AppPalette.border(context)),
        focusedBorder: border(primaryColor, 1.4),
      ),
    );
  }
}

class _RoundButton extends StatelessWidget {
  const _RoundButton({required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: Material(
        color: AppPalette.cardElevated(context),
        shape: CircleBorder(side: BorderSide(color: AppPalette.border(context))),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox(
            width: 42,
            height: 42,
            child: Icon(icon, size: 17, color: AppPalette.text(context)),
          ),
        ),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final isDark = AppPalette.isDark(context);
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppPalette.card(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppPalette.border(context)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.25 : 0.03),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({
    required this.label,
    required this.onPressed,
    this.icon,
    this.loading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          disabledBackgroundColor:
          loading ? primaryColor.withOpacity(0.75) : AppPalette.cardElevated(context),
          disabledForegroundColor: loading ? Colors.white : AppPalette.textMuted(context),
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (loading)
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
            else if (icon != null)
              Icon(icon, size: 18),
            if (loading || icon != null) const SizedBox(width: 8),
            Text(label, style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w800)),
          ],
        ),
      ),
    );
  }
}

class _HowItWorks extends StatelessWidget {
  const _HowItWorks();

  @override
  Widget build(BuildContext context) {
    final shape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(20));
    final textColor = AppPalette.isDark(context) ? Colors.white70 : blackColor80;

    Widget step(int n, String text) => Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            alignment: Alignment.center,
            decoration: const BoxDecoration(color: primaryColor, shape: BoxShape.circle),
            child: Text(
              "$n",
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 3),
              child: Text(text, style: TextStyle(fontSize: 13.5, height: 1.45, color: textColor)),
            ),
          ),
        ],
      ),
    );

    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: Material(
        color: AppPalette.card(context),
        shape: shape.copyWith(side: BorderSide(color: AppPalette.border(context))),
        clipBehavior: Clip.antiAlias,
        child: ExpansionTile(
          shape: shape,
          collapsedShape: shape,
          tilePadding: const EdgeInsets.symmetric(horizontal: 16),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          iconColor: primaryColor,
          collapsedIconColor: AppPalette.textMuted(context),
          leading: const Icon(Icons.help_outline_rounded, color: primaryColor),
          title: Text(
            "How it works",
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 14.5,
              color: AppPalette.text(context),
            ),
          ),
          children: [
            step(1, "Enter the VIN or frame number exactly as on the vehicle."),
            step(2, "Enter Data 1, Data 2 and Data 3 from your diagnostic tool."),
            step(3, "Make sure you have at least one Toyota token."),
            step(4, "Tap Calculate passcode to get the 12-digit passcode."),
          ],
        ),
      ),
    );
  }
}

class _ImportantNotes extends StatelessWidget {
  const _ImportantNotes();

  @override
  Widget build(BuildContext context) {
    final isDark = AppPalette.isDark(context);
    final textColor = isDark ? Colors.red.shade100 : primaryDarkColor;

    Widget note(String text, {bool bold = false}) => Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 7),
            width: 6,
            height: 6,
            decoration: const BoxDecoration(color: primaryColor, shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: textColor,
                fontSize: 13.5,
                height: 1.5,
                fontWeight: bold ? FontWeight.w800 : FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
      decoration: BoxDecoration(
        color: primaryColor.withOpacity(isDark ? 0.14 : 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: primaryColor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: primaryColor, size: 21),
              const SizedBox(width: 8),
              Text(
                "Read before calculating",
                style: TextStyle(
                  color: AppPalette.text(context),
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          note("Each new Toyota calculation uses 1 Toyota token."),
          note("You get 2 free retries for the same VIN within 48 hours."),
          note("Double-check all data before calculating. Tokens can't be refunded for typos.", bold: true),
        ],
      ),
    );
  }
}