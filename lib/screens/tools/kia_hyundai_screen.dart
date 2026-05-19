import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../services/api_service.dart';
import '../../../constants.dart';
import '../../components/common/drawer.dart';
import '../../components/common/CustomBottomNavigationBar.dart';
import '../../../route/route_constants.dart';
import '../../../providers/auth_provider.dart';

class KiaHyundaiScreen extends StatefulWidget {
  const KiaHyundaiScreen({super.key});

  @override
  State<KiaHyundaiScreen> createState() => _KiaHyundaiScreenState();
}

class _KiaHyundaiScreenState extends State<KiaHyundaiScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  final TextEditingController _vinController = TextEditingController();
  bool _isLoading = false;
  String? _partNumber;
  String? _errorMsg;

  bool get _isVinValid => _vinController.text.trim().length == 17;

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
    setState(() {
      _partNumber = null;
      _errorMsg = null;
      _isLoading = false;
    });
  }

  Future<void> _handleSearch() async {
    if (!_isVinValid) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    if (!authProvider.isAuthenticated || authProvider.token == null || authProvider.token!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please log in to use the VIN lookup feature."),
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
      _partNumber = null;
      _errorMsg = null;
    });

    final res = await ApiService.vinLookup(_vinController.text, realToken, locale);

    setState(() {
      _isLoading = false;
      if (res['success']) {
        final data = res['data'];
        _partNumber = data['part_details']?['part_number'] ??
            data['data']?['part_details']?['part_number'] ??
            data['part_number'];
        if (_partNumber == null) {
          _errorMsg = "Part number not found";
        }
        // Force an immediate refresh of the user profile so tokens update instantly
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
    // Ensure we are getting the actual user map
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

                  // 1. HOW TO USE GUIDE (First)
                  _buildHowToUseBox(isDark),
                  const SizedBox(height: 24),

                  // 2. SUBSCRIPTION & TOKEN BADGES
                  if (authProvider.isAuthenticated)
                    _buildSubscriptionBadges(user, isDark),
                  const SizedBox(height: 16),

                  // 3. VIN INPUT & SEARCH BUTTON
                  _buildVinInputAndSearch(isDark, cardBg, textColor),
                  const SizedBox(height: 24),

                  // 4. ERRORS (If any)
                  if (_errorMsg != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: 24),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: isDark ? Colors.red.shade900.withOpacity(0.3) : Colors.red.shade50, borderRadius: BorderRadius.circular(12)),
                      child: Text(_errorMsg!, style: TextStyle(color: isDark ? Colors.red.shade300 : Colors.red, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                    ),

                  // 5. RESULT BOX (OEM Part Number)
                  if (_partNumber != null)
                    _buildResultBox(isDark, textColor),

                  // 6. IMPORTANT WARNING (Last)
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
  // UI COMPONENTS EXTRACTED FOR CLEAN ORDERING
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
              Text("How to Use Kia/Hyundai Lookup",
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
          _buildNumberedStep("2", "Ensure you have enough tokens in your account.", isDark ? Colors.blue.shade100 : const Color(0xFF0C1E4E), isDark),
          const SizedBox(height: 16),
          _buildNumberedStep("3", "Click search to retrieve the corresponding Remote Part Number for your vehicle.", isDark ? Colors.blue.shade100 : const Color(0xFF0C1E4E), isDark),
        ],
      ),
    );
  }

  Widget _buildSubscriptionBadges(Map<String, dynamic>? user, bool isDark) {
    if (user == null) return const SizedBox.shrink();

    // 1. Get Values
    int tokens = user['available_tokens'] ?? user['tokens'] ?? 0;
    int lookupsToday = user['vin_lookups_today'] ?? 0;
    String? subEndsAt = user['vin_sub_ends_at'];

    // 2. Define Limit (Using 5, but you can change this anytime)
    int maxQuota = 5;

    // 3. Calculate REMAINING instead of USED
    int remainingLookups = (maxQuota - lookupsToday) < 0 ? 0 : (maxQuota - lookupsToday);

    // 4. Logic for Subscription
    bool hasActiveSub = false;
    int subDaysLeft = 0;

    if (subEndsAt != null) {
      DateTime? endDate = DateTime.tryParse(subEndsAt);
      if (endDate != null && endDate.isAfter(DateTime.now())) {
        hasActiveSub = true;
        subDaysLeft = endDate.difference(DateTime.now()).inDays;
      }
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (hasActiveSub) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF2D2A4A) : const Color(0xFFF0EDFF),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Icon(Icons.calendar_month, size: 14, color: isDark ? Colors.purple.shade300 : const Color(0xFF5A4FCF)),
                const SizedBox(width: 6),
                Text(
                  // ✅ Now shows "0/5 Remaining"
                  "$remainingLookups/$maxQuota Today • (${subDaysLeft}d left)",
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.purple.shade200 : const Color(0xFF5A4FCF)
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
        ],
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1C1C23) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: isDark ? Colors.grey.shade800 : Colors.grey.shade300),
          ),
          child: Row(
            children: [
              Icon(Icons.monetization_on_outlined, size: 14, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600),
              const SizedBox(width: 6),
              Text(
                "Tokens: $tokens",
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isDark ? Colors.grey.shade300 : Colors.black87),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildVinInputAndSearch(bool isDark, Color cardBg, Color textColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextFormField(
          controller: _vinController,
          maxLength: 17,
          textCapitalization: TextCapitalization.characters,
          style: TextStyle(color: textColor, fontWeight: FontWeight.bold, letterSpacing: 1.2),
          decoration: InputDecoration(
            labelText: "VIN NUMBER",
            hintText: "Enter 17 Character VIN",
            hintStyle: TextStyle(color: isDark ? Colors.white54 : Colors.black54, letterSpacing: 0),
            labelStyle: TextStyle(color: isDark ? Colors.white70 : Colors.black87, letterSpacing: 0),
            prefixIcon: Icon(Icons.directions_car, color: isDark ? Colors.white70 : Colors.black54),
            suffixIcon: _vinController.text.isNotEmpty
                ? IconButton(
              icon: Icon(Icons.clear, color: isDark ? Colors.white54 : Colors.black54),
              onPressed: () => setState(() => _vinController.clear()),
            )
                : null,
            filled: true,
            fillColor: cardBg,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
          onChanged: (v) => setState(() {}),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]')),
          ],
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: _isVinValid && !_isLoading ? _handleSearch : null,
          style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E50FF),
              disabledBackgroundColor: Colors.grey.shade400,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
          ),
          child: _isLoading
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : const Text(
              "Search Part Number (Costs 1 Token)",
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)
          ),
        ),
      ],
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
          // Blue Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: const BoxDecoration(
              color: Color(0xFFF4F8FE),
              borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
            ),
            alignment: Alignment.center,
            child: const Text("MATCH FOUND", style: TextStyle(color: Color(0xFF1E50FF), fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 0.5)),
          ),

          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Text("OEM PART NUMBER", style: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.w600, fontSize: 12)),
                const SizedBox(height: 12),
                Text(_partNumber!, style: TextStyle(fontSize: 34, fontWeight: FontWeight.w900, color: isDark ? Colors.white : const Color(0xFF0C1E4E))),
                const SizedBox(height: 20),
                OutlinedButton.icon(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: _partNumber!));
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Copied to clipboard!")));
                  },
                  style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFF1E50FF)),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))
                  ),
                  icon: const Icon(Icons.copy, color: Color(0xFF1E50FF), size: 18),
                  label: const Text("Copy Part Number", style: TextStyle(color: Color(0xFF1E50FF), fontWeight: FontWeight.bold)),
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
          _buildWarningStep("Each successful lookup will consume 1 token from your account balance.", isBold: false, textColor: isDark ? Colors.orange.shade100 : Colors.brown.shade700),
          const SizedBox(height: 16),
          _buildWarningStep("Please double-check the VIN before searching. We cannot refund tokens for typos or incorrect VINs.", isBold: true, textColor: isDark ? Colors.orange.shade200 : Colors.brown.shade800),
          const SizedBox(height: 16),
          _buildWarningStep("Do NOT double-click the search button or refresh the page while it is loading.", isBold: true, textColor: isDark ? Colors.red.shade300 : Colors.red.shade800),
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