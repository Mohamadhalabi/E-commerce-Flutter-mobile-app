import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../services/api_service.dart';
import '../../../constants.dart';
import '../../components/common/drawer.dart';
import '../../components/common/CustomBottomNavigationBar.dart';
import '../../../route/route_constants.dart';
import '../../../providers/auth_provider.dart';

class ToyotaPasscodeScreen extends StatefulWidget {
  const ToyotaPasscodeScreen({super.key});

  @override
  State<ToyotaPasscodeScreen> createState() => _ToyotaPasscodeScreenState();
}

class _ToyotaPasscodeScreenState extends State<ToyotaPasscodeScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  final TextEditingController _vinController = TextEditingController();
  final TextEditingController _data1Controller = TextEditingController();
  final TextEditingController _data2Controller = TextEditingController();
  final TextEditingController _data3Controller = TextEditingController();

  bool _isLoading = false;
  String? _passcode;
  int? _attemptsLeft;
  String? _errorMsg;

  bool get _isFormValid =>
      _vinController.text.trim().length == 17 &&
          _data1Controller.text.trim().isNotEmpty &&
          _data2Controller.text.trim().isNotEmpty &&
          _data3Controller.text.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AuthProvider>(context, listen: false).fetchUserProfile();
    });
  }

  void _onBottomNavTap(int index) {
    Navigator.pushNamedAndRemoveUntil(
      context,
      entryPointScreenRoute,
          (route) => false,
      arguments: index,
    );
  }

  Future<void> _handleRefresh() async {
    await Provider.of<AuthProvider>(context, listen: false).fetchUserProfile();
    await Future.delayed(const Duration(milliseconds: 500));

    _vinController.clear();
    _data1Controller.clear();
    _data2Controller.clear();
    _data3Controller.clear();

    setState(() {
      _passcode = null;
      _attemptsLeft = null;
      _errorMsg = null;
      _isLoading = false;
    });
  }

  void _formatDataField(String value, TextEditingController controller) {
    final parsed = value.toUpperCase().replaceAll('O', '0');
    if (parsed != controller.text) {
      controller.value = TextEditingValue(
        text: parsed,
        selection: TextSelection.collapsed(offset: parsed.length),
      );
    }
    setState(() {});
  }

  Future<void> _handleCalculate() async {
    if (!_isFormValid) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    // ✅ PREVENT GUESTS FROM CALCULATING
    if (!authProvider.isAuthenticated || authProvider.token == null || authProvider.token!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please log in to calculate Toyota Passcodes."),
          backgroundColor: Colors.red,
        ),
      );
      Navigator.pushNamed(context, logInScreenRoute);
      return;
    }

    String realToken = authProvider.token!;
    String locale = Localizations.localeOf(context).languageCode;

    setState(() {
      _isLoading = true;
      _passcode = null;
      _attemptsLeft = null;
      _errorMsg = null;
    });

    Map<String, String> body = {
      'vin': _vinController.text,
      'data1': _data1Controller.text,
      'data2': _data2Controller.text,
      'data3': _data3Controller.text,
    };

    final res = await ApiService.calculateToyotaPasscode(body, realToken, locale);

    setState(() {
      _isLoading = false;
      if (res['success']) {
        final data = res['data'];
        _passcode = data['passcode'] ?? data['data']?['passcode'];
        _attemptsLeft = data['attempts_left'] ?? data['data']?['attempts_left'];

        if (_passcode == null) {
          _errorMsg = "Calculation failed. Please check your data.";
        }

        // Force refresh user profile to update Toyota tokens count
        authProvider.fetchUserProfile();
      } else {
        _errorMsg = res['message'];
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final Color scaffoldBg = isDark ? const Color(0xFF101015) : const Color(0xFFF4F5F7);
    final Color cardBg = isDark ? const Color(0xFF1C1C23) : Colors.white;
    final Color textColor = isDark ? Colors.white : Colors.black87;

    final authProvider = Provider.of<AuthProvider>(context);
    final Map<String, dynamic>? user = authProvider.user;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: scaffoldBg,
      drawer: CustomEndDrawer(
        onLocaleChange: (locale) {},
        user: null,
        onTabChanged: _onBottomNavTap,
      ),
      bottomNavigationBar: CustomBottomNavigationBar(
        currentIndex: 0,
        onTap: _onBottomNavTap,
      ),
      body: Column(
        children: [
          _buildCustomAppBar(isDark, cardBg, textColor),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _handleRefresh,
              color: const Color(0xFF0C1E4E),
              backgroundColor: cardBg,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(defaultPadding),
                children: [

                  // 1. HOW TO USE GUIDE
                  _buildHowToUseBox(isDark),
                  const SizedBox(height: 24),

                  // 2. TOYOTA TOKEN BADGE (Only shows if logged in)
                  if (authProvider.isAuthenticated)
                    _buildTokenBadge(user, isDark),
                  const SizedBox(height: 16),

                  // 3. INPUT FORM
                  _buildInputForm(isDark, cardBg, textColor),
                  const SizedBox(height: 24),

                  // 4. ERRORS (If any)
                  if (_errorMsg != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: 24),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: isDark ? Colors.red.shade900.withOpacity(0.3) : Colors.red.shade50, borderRadius: BorderRadius.circular(12)),
                      child: Text(_errorMsg!, style: TextStyle(color: isDark ? Colors.red.shade300 : Colors.red, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                    ),

                  // 5. RESULT BOX
                  if (_passcode != null)
                    _buildResultBox(isDark, textColor),

                  // 6. IMPORTANT WARNING
                  _buildImportantWarningBox(isDark),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // UI COMPONENTS
  // ===========================================================================

  Widget _buildHowToUseBox(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A233A) : const Color(0xFFF4F8FE),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.blue.shade900 : Colors.blue.shade100, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: isDark ? Colors.blue.shade300 : const Color(0xFF0C1E4E), size: 22),
              const SizedBox(width: 10),
              Text("How to Use Toyota Passcode",
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.blue.shade300 : const Color(0xFF0C1E4E),
                      fontSize: 16
                  )),
            ],
          ),
          const SizedBox(height: 20),
          _buildNumberedStep("1", "Enter the 17-character VIN number exactly as it appears on the vehicle.", isDark ? Colors.blue.shade100 : const Color(0xFF0C1E4E), isDark),
          const SizedBox(height: 16),
          _buildNumberedStep("2", "Input Data 1, Data 2, and Data 3 from your diagnostic tool. (The letter 'O' is auto-converted to zero '0').", isDark ? Colors.blue.shade100 : const Color(0xFF0C1E4E), isDark),
          const SizedBox(height: 16),
          _buildNumberedStep("3", "Ensure you have enough Toyota tokens in your account.", isDark ? Colors.blue.shade100 : const Color(0xFF0C1E4E), isDark),
          const SizedBox(height: 16),
          _buildNumberedStep("4", "Click calculate to retrieve the 6-digit passcode.", isDark ? Colors.blue.shade100 : const Color(0xFF0C1E4E), isDark),
        ],
      ),
    );
  }

  // ✅ DISPLAY AVAILABLE TOKENS
  Widget _buildTokenBadge(Map<String, dynamic>? user, bool isDark) {
    if (user == null) return const SizedBox.shrink();

    int toyotaTokens = user['toyota_tokens'] ?? 0;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center, // Centered like the website
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1C1C23) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: isDark ? Colors.grey.shade800 : Colors.grey.shade300),
          ),
          child: Row(
            children: [
              Icon(Icons.vpn_key_outlined, size: 16, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600),
              const SizedBox(width: 8),
              Text(
                "Toyota Tokens: $toyotaTokens",
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: isDark ? Colors.grey.shade300 : Colors.black87),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInputForm(bool isDark, Color cardBg, Color textColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            TextFormField(
              controller: _vinController,
              maxLength: 17,
              textCapitalization: TextCapitalization.characters,
              style: TextStyle(color: textColor, fontWeight: FontWeight.w600, letterSpacing: 1.0),
              decoration: InputDecoration(
                labelText: "VIN NUMBER",
                hintText: "Enter 17 Character VIN",
                counterText: "",
                hintStyle: TextStyle(color: isDark ? Colors.white54 : Colors.black54, letterSpacing: 0),
                labelStyle: TextStyle(color: isDark ? Colors.white70 : Colors.black87, letterSpacing: 0, fontSize: 13),
                prefixIcon: Icon(Icons.directions_car, color: isDark ? Colors.white70 : Colors.black54),
                filled: true,
                fillColor: cardBg,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
              onChanged: (v) {
                _vinController.value = TextEditingValue(text: v.toUpperCase(), selection: _vinController.selection);
                setState(() {});
              },
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]'))],
            ),
            const SizedBox(height: 4),
            Text(
              "${_vinController.text.length}/17",
              style: TextStyle(fontSize: 12, color: isDark ? Colors.white54 : Colors.grey.shade600),
            ),
          ],
        ),

        const SizedBox(height: 12),
        _buildDataField("DATA 1", "00000", _data1Controller, isDark, cardBg, textColor),
        const SizedBox(height: 16),
        _buildDataField("DATA 2", "0000", _data2Controller, isDark, cardBg, textColor),
        const SizedBox(height: 16),
        _buildDataField("DATA 3", "000", _data3Controller, isDark, cardBg, textColor),
        const SizedBox(height: 24),

        ElevatedButton(
          onPressed: _isFormValid && !_isLoading ? _handleCalculate : null,
          style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E50FF),
              disabledBackgroundColor: Colors.grey.shade400,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
          ),
          child: _isLoading
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : const Text(
              "Calculate Passcode (Costs 1 Token)",
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)
          ),
        ),
      ],
    );
  }

  Widget _buildDataField(String label, String hint, TextEditingController controller, bool isDark, Color cardBg, Color textColor) {
    return TextFormField(
      controller: controller,
      textCapitalization: TextCapitalization.characters,
      style: TextStyle(color: textColor, fontWeight: FontWeight.bold, letterSpacing: 1.5),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        hintStyle: TextStyle(color: isDark ? Colors.white54 : Colors.black54, letterSpacing: 1.5),
        labelStyle: TextStyle(color: isDark ? Colors.white70 : Colors.black87, letterSpacing: 0, fontSize: 12),
        prefixIcon: Icon(Icons.data_array, color: isDark ? Colors.white70 : Colors.black54),
        suffixIcon: controller.text.isNotEmpty
            ? IconButton(
          icon: Icon(Icons.clear, color: isDark ? Colors.white54 : Colors.black54, size: 20),
          onPressed: () => setState(() => controller.clear()),
        )
            : null,
        filled: true,
        fillColor: cardBg,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      ),
      onChanged: (v) => _formatDataField(v, controller),
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]'))],
    );
  }

  Widget _buildResultBox(bool isDark, Color textColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E2841) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isDark ? const Color(0xFF2E3A5A) : const Color(0xFFE0E7FF), width: 2),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))
          ]
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: const BoxDecoration(
              color: Color(0xFFF4F8FE),
              borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
            ),
            alignment: Alignment.center,
            child: const Text("SUCCESS!", style: TextStyle(color: Color(0xFF1E50FF), fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 0.5)),
          ),

          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Text("YOUR TOYOTA PASSCODE", style: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.w600, fontSize: 12)),
                const SizedBox(height: 12),

                // ✅ PREVENT TEXT OVERFLOW: Added FittedBox to scale down long passcodes
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    _passcode!,
                    style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2.0,
                        color: isDark ? Colors.white : const Color(0xFF0C1E4E)
                    ),
                    maxLines: 1,
                  ),
                ),

                if (_attemptsLeft != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                        color: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12)
                    ),
                    child: Text(
                        "Free Retries Left: $_attemptsLeft",
                        style: TextStyle(color: isDark ? Colors.grey.shade300 : Colors.grey.shade700, fontSize: 11, fontWeight: FontWeight.bold)
                    ),
                  ),
                ],

                const SizedBox(height: 24),
                OutlinedButton.icon(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: _passcode!));
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Passcode copied!")));
                  },
                  style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFF1E50FF)),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))
                  ),
                  icon: const Icon(Icons.copy, color: Color(0xFF1E50FF), size: 18),
                  label: const Text("Copy Passcode", style: TextStyle(color: Color(0xFF1E50FF), fontWeight: FontWeight.bold)),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImportantWarningBox(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2C1E16) : const Color(0xFFFFF8F3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.orange.shade900 : Colors.orange.shade200, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.deepOrange.shade700, size: 22),
              const SizedBox(width: 10),
              Text("Important — Read Before Searching",
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.deepOrange.shade800, fontSize: 16)),
            ],
          ),
          const SizedBox(height: 20),
          _buildWarningStep("Each new Toyota calculation will consume 1 Toyota Token.", isBold: false, textColor: isDark ? Colors.orange.shade100 : Colors.brown.shade700),
          const SizedBox(height: 16),
          _buildWarningStep("You receive 3 free retries for the same VIN within 48 hours to correct any mistyped data.", isBold: false, textColor: isDark ? Colors.orange.shade100 : Colors.brown.shade700),
          const SizedBox(height: 16),
          _buildWarningStep("Please double-check all data before calculating. Tokens cannot be refunded for typos.", isBold: true, textColor: isDark ? Colors.orange.shade200 : Colors.brown.shade800),
        ],
      ),
    );
  }

  // ===========================================================================
  // HELPERS
  // ===========================================================================

  Widget _buildCustomAppBar(bool isDark, Color cardBg, Color textColor) {
    return Container(
      color: cardBg,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              _buildAppBarIcon(icon: Icons.menu, isDark: isDark, onTap: () => _scaffoldKey.currentState?.openDrawer()),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: () => Navigator.pushNamed(context, searchScreenRoute),
                  child: Container(
                    height: 45,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(color: isDark ? Colors.grey.shade900 : Colors.grey.shade100, borderRadius: BorderRadius.circular(30)),
                    child: Row(
                      children: [
                        Icon(Icons.search, color: Colors.grey.shade500, size: 20),
                        const SizedBox(width: 8),
                        Text("Search...", style: TextStyle(color: Colors.grey.shade500, fontSize: 14)),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              _buildAppBarIcon(icon: Icons.notifications_none, isDark: isDark, onTap: () => Navigator.pushNamed(context, notificationsScreenRoute)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBarIcon({required IconData icon, required bool isDark, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(25),
      child: Container(
        width: 40, height: 40,
        decoration: BoxDecoration(
            color: isDark ? Colors.grey.shade900 : Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: isDark ? Colors.transparent : Colors.grey.shade200),
            boxShadow: isDark ? [] : [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4, offset: const Offset(0, 2))]
        ),
        child: Icon(icon, color: isDark ? Colors.white : Colors.black87, size: 20),
      ),
    );
  }

  Widget _buildNumberedStep(String number, String text, Color textColor, bool isDark) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 24, height: 24,
          decoration: BoxDecoration(color: isDark ? Colors.blue.shade900 : const Color(0xFFD6E4FF), shape: BoxShape.circle),
          alignment: Alignment.center,
          child: Text(number, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isDark ? Colors.blue.shade100 : const Color(0xFF0C1E4E))),
        ),
        const SizedBox(width: 12),
        Expanded(child: Padding(padding: const EdgeInsets.only(top: 2.0), child: Text(text, style: TextStyle(color: textColor, height: 1.4, fontSize: 13)))),
      ],
    );
  }

  Widget _buildWarningStep(String text, {required bool isBold, required Color textColor}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(padding: const EdgeInsets.only(top: 2.0), child: Icon(Icons.warning_amber_rounded, size: 20, color: Colors.deepOrange.shade600)),
        const SizedBox(width: 12),
        Expanded(child: Text(text, style: TextStyle(color: textColor, fontWeight: isBold ? FontWeight.bold : FontWeight.normal, height: 1.4, fontSize: 13))),
      ],
    );
  }
}