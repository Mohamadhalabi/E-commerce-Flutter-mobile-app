import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../services/api_service.dart';
import '../../../constants.dart';
import '../../components/common/drawer.dart';
import '../../components/common/CustomBottomNavigationBar.dart';
import '../../../route/route_constants.dart'; // Needed for bottom nav routing

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
  int _currentIndex = 0; // Active tab index for bottom nav

  bool get _isFormValid =>
      _vinController.text.trim().length == 17 &&
          _data1Controller.text.trim().isNotEmpty &&
          _data2Controller.text.trim().isNotEmpty &&
          _data3Controller.text.trim().isNotEmpty;

  // Handles Bottom Navigation
  void _onBottomNavTap(int index) {
    if (_currentIndex == index) return;
    setState(() => _currentIndex = index);
    switch (index) {
      case 0: Navigator.pushNamedAndRemoveUntil(context, entryPointScreenRoute, (r) => false); break;
      case 1: Navigator.pushNamed(context, searchScreenRoute); break;
      case 3: Navigator.pushNamed(context, cartScreenRoute); break;
      case 4: Navigator.popUntil(context, ModalRoute.withName(entryPointScreenRoute)); break;
    }
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

    // NOTE: You will need to get the user's Auth token from your provider here
    String dummyToken = "YOUR_USER_TOKEN";
    String locale = Localizations.localeOf(context).languageCode;

    setState(() {
      _isLoading = true;
      _passcode = null;
      _errorMsg = null;
    });

    Map<String, String> body = {
      'vin': _vinController.text,
      'data1': _data1Controller.text,
      'data2': _data2Controller.text,
      'data3': _data3Controller.text,
    };

    final res = await ApiService.calculateToyotaPasscode(body, dummyToken, locale);

    setState(() {
      _isLoading = false;
      if (res['success']) {
        final data = res['data'];
        _passcode = data['passcode'] ?? data['data']?['passcode'];
        _attemptsLeft = data['attempts_left'] ?? data['data']?['attempts_left'];

        if (_passcode == null) {
          _errorMsg = "Calculation failed. Please check your data.";
        }
      } else {
        _errorMsg = res['message'];
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Toyota Passcode Calculator")),

      endDrawer: CustomEndDrawer(
        onLocaleChange: (locale) {},
        user: null,
        onTabChanged: (index) {},
      ),

      // Fixed Bottom Navigation
      bottomNavigationBar: CustomBottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onBottomNavTap,
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _vinController,
              maxLength: 17,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(labelText: "VIN NUMBER *"),
              onChanged: (v) {
                _vinController.value = TextEditingValue(text: v.toUpperCase(), selection: _vinController.selection);
                setState(() {});
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _data1Controller,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(labelText: "DATA 1 *"),
              onChanged: (v) => _formatDataField(v, _data1Controller),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _data2Controller,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(labelText: "DATA 2 *"),
              onChanged: (v) => _formatDataField(v, _data2Controller),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _data3Controller,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(labelText: "DATA 3 *"),
              onChanged: (v) => _formatDataField(v, _data3Controller),
            ),
            const SizedBox(height: 24),

            ElevatedButton(
              onPressed: _isFormValid && !_isLoading ? _handleCalculate : null,
              style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
              ),
              child: _isLoading
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text("CALCULATE PASSCODE"),
            ),

            const SizedBox(height: 30),

            if (_errorMsg != null)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(12)),
                child: Text(_errorMsg!, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
              ),

            if (_passcode != null)
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.blue.shade200)),
                child: Column(
                  children: [
                    const Text("SUCCESS! YOUR PASSCODE:", style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 12)),
                    const SizedBox(height: 8),
                    Text(_passcode!, style: const TextStyle(fontSize: 40, fontWeight: FontWeight.w900, color: Colors.black)),
                    const SizedBox(height: 8),
                    if (_attemptsLeft != null)
                      Text("Attempts remaining: $_attemptsLeft", style: const TextStyle(color: Colors.grey, fontSize: 12)),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: _passcode!));
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Passcode copied!")));
                      },
                      icon: const Icon(Icons.copy),
                      label: const Text("Copy Passcode"),
                    )
                  ],
                ),
              )
          ],
        ),
      ),
    );
  }
}