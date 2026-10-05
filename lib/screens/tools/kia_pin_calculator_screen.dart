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

enum _Outcome { none, success, notFound, noTokens, error }

/// Token balances. The exact keys depend on UserToken::balancesFor(),
/// so this reads them flexibly (pre/old/0 vs post/new/1).
class _Balances {
  const _Balances(this.pre, this.post);
  final int? pre;
  final int? post;

  static _Balances parse(dynamic raw) {
    int? toInt(dynamic v) {
      if (v is Map) v = v['balance'] ?? v['tokens'] ?? v['remaining'] ?? v['count'];
      if (v is num) return v.toInt();
      return int.tryParse('$v');
    }

    int? pre;
    int? post;
    if (raw is Map) {
      raw.forEach((k, v) {
        final key = k.toString().toLowerCase();
        if (key.contains('pre') || key.contains('old') || key.contains('before') || key == '0') {
          pre = toInt(v);
        } else if (key.contains('post') || key.contains('new') || key.contains('after') ||
            key.contains('2017') || key == '1') {
          post = toInt(v);
        }
      });
    } else if (raw is List && raw.length >= 2) {
      pre = toInt(raw[0]);
      post = toInt(raw[1]);
    }
    return _Balances(pre, post);
  }
}

class KiaPinCalculatorScreen extends StatefulWidget {
  const KiaPinCalculatorScreen({super.key});

  @override
  State<KiaPinCalculatorScreen> createState() => _KiaPinCalculatorScreenState();
}

class _KiaPinCalculatorScreenState extends State<KiaPinCalculatorScreen> {
  final _vinController = TextEditingController();

  _Balances? _balances;
  bool _loadingBalances = false;
  bool _loading = false;

  _Outcome _outcome = _Outcome.none;
  Map<String, dynamic> _result = {};
  String? _errorMessage;
  String _lastVin = "";

  @override
  void initState() {
    super.initState();
    _vinController.addListener(() => setState(() {}));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _loadBalances();
    });
  }

  @override
  void dispose() {
    _vinController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // HELPERS
  // ---------------------------------------------------------------------------
  String? get _token => Provider.of<AuthProvider>(context, listen: false).token;

  String get _vin => _vinController.text;

  bool get _vinValid => RegExp(r'^[A-HJ-NPR-Z0-9]{17}$').hasMatch(_vin);

  /// Model year from VIN position 10 (display only; the server decides).
  static int? _modelYear(String vin) {
    if (vin.length < 10) return null;
    final c = vin[9];
    if (RegExp(r'[1-9]').hasMatch(c)) return 2000 + int.parse(c);
    const letters = 'ABCDEFGHJKLMNPRSTVWXY';
    final i = letters.indexOf(c);
    return i < 0 ? null : 2010 + i;
  }

  Future<void> _openWhatsApp(String message) async {
    final uri = Uri.parse(
      'https://wa.me/$_whatsAppNumber?text=${Uri.encodeComponent(message)}',
    );
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  // ---------------------------------------------------------------------------
  // API
  // ---------------------------------------------------------------------------
  Future<void> _loadBalances() async {
    final token = _token;
    if (token == null) return;
    setState(() => _loadingBalances = true);

    final res = await ApiService.fetchPinBalances(
      token,
      Localizations.localeOf(context).languageCode,
    );
    if (!mounted) return;

    setState(() {
      _loadingBalances = false;
      final data = res['data'] as Map<String, dynamic>;
      if (res['status'] == 200 && data['balances'] != null) {
        _balances = _Balances.parse(data['balances']);
      }
    });
  }

  Future<void> _submit() async {
    final token = _token;
    if (token == null || !_vinValid || _loading) return;

    FocusScope.of(context).unfocus();
    final vin = _vin;

    setState(() {
      _loading = true;
      _outcome = _Outcome.none;
      _errorMessage = null;
      _lastVin = vin;
    });

    final res = await ApiService.calculatePinCode(
      vin,
      token,
      Localizations.localeOf(context).languageCode,
    );
    if (!mounted) return;

    final status = res['status'] as int;
    final data = res['data'] as Map<String, dynamic>;

    setState(() {
      _loading = false;
      if (data['balances'] != null) _balances = _Balances.parse(data['balances']);

      if (status == 200 && data['success'] == true) {
        _outcome = _Outcome.success;
        _result = data;
      } else if (status == 402) {
        _outcome = _Outcome.noTokens;
      } else if (data['not_found'] == true || status == 404) {
        _outcome = _Outcome.notFound;
        _errorMessage = data['error']?.toString();
      } else if (status == 429) {
        _outcome = _Outcome.error;
        _errorMessage = "Too many lookups in a short time. Wait a minute and try again.";
      } else if (status == 401) {
        _outcome = _Outcome.error;
        _errorMessage = "Your session expired. Sign in again to continue.";
      } else if (status == 0) {
        _outcome = _Outcome.error;
        _errorMessage = "No connection, or the lookup took too long. Check your internet and try again.";
      } else {
        _outcome = _Outcome.error;
        final vinErrors = (data['errors'] is Map) ? data['errors']['vin'] : null;
        _errorMessage = data['error']?.toString() ??
            (vinErrors is List && vinErrors.isNotEmpty ? vinErrors.first.toString() : null) ??
            data['message']?.toString() ??
            "Something went wrong. Try again.";
      }
    });
  }

  /// Copies in this format (key code line skipped if there is none):
  ///   5NMP5DGL7SH111476
  ///   I1659
  ///   375750
  Future<void> _copyAll(String vin, String? keyCode, String pin) async {
    final text = [vin, if (keyCode != null) keyCode, pin].join('\n');
    await Clipboard.setData(ClipboardData(text: text));
    HapticFeedback.lightImpact();
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: const Text("VIN, key code and PIN copied"),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
  }

  void _reset() {
    setState(() {
      _outcome = _Outcome.none;
      _result = {};
      _errorMessage = null;
      _vinController.clear();
    });
  }

  void _onNavTap(int index) {
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

  // ---------------------------------------------------------------------------
  // BUILD
  // ---------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final bg = Theme.of(context).scaffoldBackgroundColor;
    final isLoggedIn = Provider.of<AuthProvider>(context).isAuthenticated;

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
            "PIN Calculator",
            style: TextStyle(
              color: AppPalette.text(context),
              fontWeight: FontWeight.w800,
              fontSize: 17,
            ),
          ),
        ),
        bottomNavigationBar: CustomBottomNavigationBar(currentIndex: 0, onTap: _onNavTap),
        body: Builder(
          builder: (bodyContext) => RefreshIndicator(
            onRefresh: _loadBalances,
            color: primaryColor,
            backgroundColor: AppPalette.card(context),
            child: ListView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: EdgeInsets.fromLTRB(
                defaultPadding,
                8,
                defaultPadding,
                MediaQuery.paddingOf(bodyContext).bottom + 24,
              ),
              children: [
                _buildHero(isLoggedIn),
                const SizedBox(height: 12),
                if (!isLoggedIn) _buildSignInCard() else ...[
                  const _HowItWorks(),
                  const SizedBox(height: 12),
                  if (_outcome == _Outcome.success)
                    _buildSuccess()
                  else
                    _buildForm(),
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
  Widget _buildHero(bool isLoggedIn) {
    return Container(
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
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.pin_outlined, color: Colors.white, size: 23),
              ),
              const Spacer(),
              if (isLoggedIn)
                IconButton(
                  tooltip: 'Refresh balances',
                  onPressed: _loadingBalances ? null : _loadBalances,
                  icon: _loadingBalances
                      ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                      : const Icon(Icons.refresh_rounded, color: Colors.white),
                ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            "Kia / Hyundai PIN calculator",
            style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(
            "Enter the VIN and we read the model year from it automatically.",
            style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 13.5, height: 1.45),
          ),
          if (isLoggedIn) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _BalanceTile(label: "Pre-2017", value: _balances?.pre)),
                const SizedBox(width: 10),
                Expanded(child: _BalanceTile(label: "2017+", value: _balances?.post)),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSignInCard() {
    return _Card(
      children: [
        const _CardTitle("Sign in to continue"),
        Text(
          "The PIN calculator uses the tokens on your account. Sign in to see your balance and look up a VIN.",
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

  Widget _buildForm() {
    final year = _vin.length >= 10 ? _modelYear(_vin) : null;
    final isPre = year != null && year < 2017;
    final tokensForType = year == null ? null : (isPre ? _balances?.pre : _balances?.post);

    final muted = AppPalette.textMuted(context);
    final radius = BorderRadius.circular(16);
    OutlineInputBorder border(Color c, [double w = 1]) =>
        OutlineInputBorder(borderRadius: radius, borderSide: BorderSide(color: c, width: w));

    return Column(
      children: [
        _Card(
          children: [
            Text(
              "VIN",
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: AppPalette.text(context),
                letterSpacing: 0.3,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _vinController,
              enabled: !_loading,
              textCapitalization: TextCapitalization.characters,
              autocorrect: false,
              enableSuggestions: false,
              cursorColor: primaryColor,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _submit(),
              inputFormatters: [_VinFormatter()],
              style: TextStyle(
                color: AppPalette.text(context),
                fontSize: 17,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.6,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
              decoration: InputDecoration(
                hintText: "KNADN512AF6123456",
                hintStyle: TextStyle(
                  color: muted.withOpacity(0.5),
                  letterSpacing: 1.6,
                  fontWeight: FontWeight.w500,
                ),
                filled: true,
                fillColor: AppPalette.cardElevated(context),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                suffixIcon: _vin.isEmpty || _loading
                    ? IconButton(
                  tooltip: 'Paste',
                  icon: Icon(Icons.content_paste_rounded, color: muted, size: 20),
                  onPressed: _loading
                      ? null
                      : () async {
                    final clip = await Clipboard.getData('text/plain');
                    final text = clip?.text ?? '';
                    _vinController.value = _VinFormatter().formatEditUpdate(
                      TextEditingValue.empty,
                      TextEditingValue(text: text),
                    );
                  },
                )
                    : IconButton(
                  tooltip: 'Clear',
                  icon: Icon(Icons.close_rounded, color: muted, size: 20),
                  onPressed: () => _vinController.clear(),
                ),
                border: border(AppPalette.border(context)),
                enabledBorder: border(AppPalette.border(context)),
                disabledBorder: border(AppPalette.border(context)),
                focusedBorder: border(primaryColor, 1.4),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(
                    "All 17 characters, exactly as printed on the vehicle.",
                    style: TextStyle(color: muted, fontSize: 12),
                  ),
                ),
                Text(
                  "${_vin.length}/17",
                  style: TextStyle(
                    color: _vinValid ? Colors.green.shade600 : muted,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
            if (year != null) ...[
              const SizedBox(height: 12),
              _YearChip(
                year: year,
                tokenLabel: isPre ? "Pre-2017" : "2017+",
                tokensLeft: tokensForType,
              ),
            ],
            const SizedBox(height: 16),
            _PrimaryButton(
              label: _loading ? "Looking up…" : "Get PIN code",
              icon: Icons.key_rounded,
              loading: _loading,
              onPressed: _vinValid && !_loading ? _submit : null,
            ),
            const SizedBox(height: 10),
            Text(
              _loading
                  ? "This can take up to a minute. Please keep the app open."
                  : !_vinValid
                  ? "Enter a valid 17-character VIN to continue. VINs never contain I, O or Q."
                  : "Ready. Tap Get PIN code.",
              style: TextStyle(color: muted, fontSize: 12.5, height: 1.4),
            ),
            const SizedBox(height: 6),
            Text(
              "One token is used per successful lookup. Nothing is charged if no PIN is found.",
              style: TextStyle(color: muted.withOpacity(0.8), fontSize: 11.5, height: 1.4),
            ),
          ],
        ),
        if (_outcome == _Outcome.notFound) _buildNotFound(),
        if (_outcome == _Outcome.noTokens) _buildNoTokens(year),
        if (_outcome == _Outcome.error) _buildError(),
      ],
    );
  }

  Widget _buildSuccess() {
    final pin = _result['pin_code']?.toString() ?? '';
    final rawKey = _result['key_code']?.toString();
    final keyCode = (rawKey == null || rawKey.isEmpty || rawKey == 'xxx') ? null : rawKey;
    final vin = _result['vin']?.toString() ?? _lastVin;
    final year = _result['year']?.toString();
    final emailed = _result['emailed'] == true;
    final email = _result['email']?.toString();
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
                "PIN found",
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
        _InfoRow(label: "VIN", value: vin, mono: true),
        if (year != null && year.isNotEmpty) _InfoRow(label: "Model year", value: year),
        const SizedBox(height: 10),
        _CodeTile(label: "PIN code", value: pin, highlight: true),
        if (keyCode != null) ...[
          const SizedBox(height: 10),
          _CodeTile(label: "Key code", value: keyCode),
        ],
        if (emailed) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.mark_email_read_outlined, size: 18, color: AppPalette.textMuted(context)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  email != null ? "Also sent to $email" : "Also sent to your email",
                  style: TextStyle(color: AppPalette.textMuted(context), fontSize: 12.5),
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: OutlinedButton.icon(
            onPressed: () => _copyAll(vin, keyCode, pin),
            style: OutlinedButton.styleFrom(
              foregroundColor: primaryColor,
              side: const BorderSide(color: primaryColor, width: 1.4),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            icon: const Icon(Icons.copy_rounded, size: 18),
            label: const Text(
              "Copy",
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
            ),
          ),
        ),
        const SizedBox(height: 10),
        _PrimaryButton(
          label: "Look up another VIN",
          icon: Icons.refresh_rounded,
          onPressed: _reset,
        ),
      ],
    );
  }

  Widget _buildNotFound() {
    return _NoticeCard(
      icon: Icons.search_off_rounded,
      title: "PIN code and key code not found",
      message: "Your token was not used. Send us the VIN on WhatsApp and our team will check it for you.",
      actionLabel: "Send VIN on WhatsApp",
      whatsApp: true,
      onAction: () => _openWhatsApp(
        "Hello, the PIN calculator couldn't find the PIN code and key code for this VIN:\n$_lastVin",
      ),
    );
  }

  Widget _buildNoTokens(int? year) {
    final kind = year == null ? "" : (year < 2017 ? "Pre-2017 " : "2017+ ");
    return _NoticeCard(
      icon: Icons.token_outlined,
      title: "No ${kind}tokens left",
      message: "This VIN needs a ${kind}token. Contact us to top up your balance.",
      actionLabel: "Buy tokens on WhatsApp",
      whatsApp: true,
      onAction: () => _openWhatsApp("Hello, I'd like to buy ${kind}PIN code tokens."),
    );
  }

  Widget _buildError() {
    return _NoticeCard(
      icon: Icons.error_outline_rounded,
      title: "Lookup didn't complete",
      message: _errorMessage ?? "Something went wrong. Try again.",
      actionLabel: "Try again",
      onAction: _vinValid ? _submit : null,
    );
  }
}

// =============================================================================
// PIECES
// =============================================================================
class _VinFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    var text = newValue.text.toUpperCase().replaceAll(RegExp(r'[^A-HJ-NPR-Z0-9]'), '');
    if (text.length > 17) text = text.substring(0, 17);
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
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

class _BalanceTile extends StatelessWidget {
  const _BalanceTile({required this.label, required this.value});
  final String label;
  final int? value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.16),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          Text(
            value?.toString() ?? "–",
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w900,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  "tokens",
                  style: TextStyle(color: Colors.white.withOpacity(0.75), fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HowItWorks extends StatelessWidget {
  const _HowItWorks();

  @override
  Widget build(BuildContext context) {
    final shape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(20));
    final muted = AppPalette.isDark(context) ? Colors.white70 : blackColor80;

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
              child: Text(text, style: TextStyle(fontSize: 13.5, height: 1.45, color: muted)),
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
            step(1, "Enter the full 17-character VIN, exactly as printed on the vehicle."),
            step(2, "We read the model year from the VIN and use the matching token: Pre-2017 or 2017+."),
            step(3, "You get the PIN code (and key code when available). A copy is also emailed to you."),
            step(4, "One token per successful lookup. If no PIN is found, your token is returned."),
          ],
        ),
      ),
    );
  }
}

class _YearChip extends StatelessWidget {
  const _YearChip({required this.year, required this.tokenLabel, required this.tokensLeft});
  final int year;
  final String tokenLabel;
  final int? tokensLeft;

  @override
  Widget build(BuildContext context) {
    final empty = tokensLeft != null && tokensLeft! <= 0;
    final color = empty ? primaryColor : Colors.green.shade600;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(AppPalette.isDark(context) ? 0.16 : 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Row(
        children: [
          Icon(empty ? Icons.warning_amber_rounded : Icons.event_available_rounded,
              color: color, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              empty
                  ? "Model year $year · needs a $tokenLabel token, but you have none left."
                  : "Model year $year · uses 1 $tokenLabel token"
                  "${tokensLeft != null ? ' ($tokensLeft left)' : ''}",
              style: TextStyle(color: color, fontSize: 12.5, fontWeight: FontWeight.w700),
            ),
          ),
        ],
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

class _CardTitle extends StatelessWidget {
  const _CardTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 16.5,
          fontWeight: FontWeight.w800,
          color: AppPalette.text(context),
        ),
      ),
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
          disabledBackgroundColor: loading
              ? primaryColor.withOpacity(0.75)
              : AppPalette.cardElevated(context),
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

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value, this.mono = false});
  final String label;
  final String value;
  final bool mono;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: TextStyle(color: AppPalette.textMuted(context), fontSize: 13),
            ),
          ),
          Expanded(
            child: SelectableText(
              value,
              style: TextStyle(
                color: AppPalette.text(context),
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                letterSpacing: mono ? 1.1 : 0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Big code display with a copy button.
class _CodeTile extends StatelessWidget {
  const _CodeTile({required this.label, required this.value, this.highlight = false});
  final String label;
  final String value;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final isDark = AppPalette.isDark(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
      decoration: BoxDecoration(
        color: highlight
            ? primaryColor.withOpacity(isDark ? 0.16 : 0.06)
            : AppPalette.cardElevated(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: highlight ? primaryColor.withOpacity(0.45) : AppPalette.border(context),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: AppPalette.textMuted(context),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                SelectableText(
                  value,
                  style: TextStyle(
                    color: highlight ? primaryColor : AppPalette.text(context),
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NoticeCard extends StatelessWidget {
  const _NoticeCard({
    required this.icon,
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.onAction,
    this.whatsApp = false,
  });

  final IconData icon;
  final String title;
  final String message;
  final String actionLabel;
  final VoidCallback? onAction;

  /// Shows the action as a green WhatsApp button.
  final bool whatsApp;

  @override
  Widget build(BuildContext context) {
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
              Icon(icon, color: primaryColor, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
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
            message,
            style: TextStyle(color: AppPalette.textMuted(context), fontSize: 13.5, height: 1.5),
          ),
          if (onAction != null) ...[
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              height: whatsApp ? 50 : 46,
              child: whatsApp
                  ? ElevatedButton.icon(
                onPressed: onAction,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1DA851),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18),
                label: Text(
                  actionLabel,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                ),
              )
                  : OutlinedButton(
                onPressed: onAction,
                style: OutlinedButton.styleFrom(
                  foregroundColor: primaryColor,
                  side: const BorderSide(color: primaryColor, width: 1.4),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: Text(actionLabel, style: const TextStyle(fontWeight: FontWeight.w800)),
              ),
            ),
          ],
        ],
      ),
    );
  }
}