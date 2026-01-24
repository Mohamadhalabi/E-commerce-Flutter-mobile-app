import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dropdown_search/dropdown_search.dart';

import 'package:shop/constants.dart';
import 'package:shop/models/address_model.dart';
import 'package:shop/models/country_model.dart';
import 'package:shop/providers/auth_provider.dart';
import 'package:shop/services/api_service.dart';
import 'package:shop/services/notification_service.dart';
import 'package:shop/components/common/CustomBottomNavigationBar.dart';
import 'package:shop/route/route_constants.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class AddAddressScreen extends StatefulWidget {
  final AddressModel? address;

  const AddAddressScreen({super.key, this.address});

  @override
  State<AddAddressScreen> createState() => _AddAddressScreenState();
}

class _AddAddressScreenState extends State<AddAddressScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  late TextEditingController _addressController;
  late TextEditingController _streetController;
  late TextEditingController _postalController;
  late TextEditingController _phoneController;

  // Selection
  List<CountryModel> _countries = [];
  List<String> _cities = [];

  CountryModel? _selectedCountry;
  String? _selectedCity;

  bool _isDefault = false;
  bool _isLoading = false;
  int _currentIndex = 4;

  @override
  void initState() {
    super.initState();
    final a = widget.address;

    _addressController = TextEditingController(text: a?.address ?? '');
    _streetController = TextEditingController(text: a?.street ?? '');
    _postalController = TextEditingController(text: a?.postalCode ?? '');
    _phoneController = TextEditingController(text: a?.phone ?? '');
    _isDefault = a?.isDefault ?? false;

    _loadCountries();
  }

  Future<void> _loadCountries() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final list = await ApiService.fetchCountries(auth.token ?? '');

    if (mounted) {
      setState(() {
        _countries = list;
        if (widget.address != null && widget.address!.countryId != null) {
          try {
            _selectedCountry = list.firstWhere((c) => c.id == widget.address!.countryId);
            _loadCities(_selectedCountry!.name);
            _selectedCity = widget.address!.city;
          } catch (_) {}
        }
      });
    }
  }

  Future<void> _loadCities(String countryName) async {
    setState(() => _cities = []);
    final list = await ApiService.fetchCities(countryName);

    if (mounted) {
      setState(() {
        _cities = list;
        if (_selectedCity != null && !list.contains(_selectedCity)) {
          _selectedCity = null;
        }
      });
    }
  }

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

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCountry == null) {
      NotificationService.show(
          context: context,
          title: AppLocalizations.of(context)!.error,
          message: AppLocalizations.of(context)!.selectCountryError,
          isError: true
      );
      return;
    }
    if (_selectedCity == null) {
      NotificationService.show(
          context: context,
          title: AppLocalizations.of(context)!.error,
          message: AppLocalizations.of(context)!.selectCityError,
          isError: true
      );
      return;
    }

    setState(() => _isLoading = true);
    final auth = Provider.of<AuthProvider>(context, listen: false);

    final Map<String, dynamic> data = {
      'country_id': _selectedCountry!.id,
      'city': _selectedCity,
      'address': _addressController.text.trim(),
      'street': _streetController.text.trim(),
      'postal_code': _postalController.text.trim(),
      'phone': _phoneController.text.trim(),
      'is_default': _isDefault,
    };

    bool success;
    if (widget.address == null) {
      success = await ApiService.addAddress(data, auth.token ?? '');
    } else {
      success = await ApiService.updateAddress(widget.address!.id, data, auth.token ?? '');
    }

    if (mounted) {
      setState(() => _isLoading = false);
      if (success) {
        NotificationService.show(
            context: context,
            title: AppLocalizations.of(context)!.success,
            message: AppLocalizations.of(context)!.addressSaved
        );
        Navigator.pop(context, true);
      } else {
        NotificationService.show(
            context: context,
            title: AppLocalizations.of(context)!.error,
            message: AppLocalizations.of(context)!.failedToSaveAddress,
            isError: true
        );
      }
    }
  }

  // ✅ Helper: Input Decoration (Dark Mode Ready)
  InputDecoration _buildInputDecoration(BuildContext context, String hint) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fillColor = isDark ? const Color(0xFF2A2A35) : const Color(0xFFF9F9F9);
    final hintColor = isDark ? Colors.white38 : Colors.grey[400];

    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: hintColor, fontSize: 14),
      filled: true,
      fillColor: fillColor,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: primaryColor, width: 1)),
      errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.red, width: 1)),
    );
  }

  @override
  Widget build(BuildContext context) {
    // ✅ Dark Mode Colors
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final Color scaffoldBg = Theme.of(context).scaffoldBackgroundColor;
    final Color appBarBg = isDark ? const Color(0xFF1C1C23) : Colors.white;
    final Color cardBg = isDark ? const Color(0xFF1C1C23) : Colors.white;
    final Color textColor = isDark ? Colors.white : Colors.black;
    final Color popupBg = isDark ? const Color(0xFF2A2A35) : Colors.white;

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        title: Text(widget.address == null
            ? AppLocalizations.of(context)!.addAddress
            : AppLocalizations.of(context)!.editAddress,
            style: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.bold)
        ),
        backgroundColor: appBarBg,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: textColor),
      ),
      bottomNavigationBar: CustomBottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onBottomNavTap,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // 2. The Form Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    if (!isDark)
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- Country Dropdown ---
                    _buildLabel(context, AppLocalizations.of(context)!.country),
                    DropdownSearch<CountryModel>(
                      items: (filter, loadProps) => _countries,
                      compareFn: (i1, i2) => i1.id == i2.id,
                      itemAsString: (CountryModel u) => u.name,
                      selectedItem: _selectedCountry,

                      // Decoration for Dropdown Button
                      decoratorProps: DropDownDecoratorProps(
                        decoration: _buildInputDecoration(context, AppLocalizations.of(context)!.selectCountry),
                        baseStyle: TextStyle(color: textColor), // Selected Text Color
                      ),

                      popupProps: PopupProps.menu(
                        showSearchBox: true,
                        menuProps: MenuProps(
                          backgroundColor: popupBg,
                          borderRadius: BorderRadius.circular(12),
                          elevation: 4,
                        ),
                        searchFieldProps: TextFieldProps(
                          padding: const EdgeInsets.all(12),
                          style: TextStyle(color: textColor),
                          decoration: _buildInputDecoration(context, AppLocalizations.of(context)!.searchCountry),
                        ),
                        itemBuilder: (context, item, isDisabled, isSelected) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            child: Text(
                              item.name,
                              style: TextStyle(
                                  fontSize: 14,
                                  color: isSelected ? primaryColor : textColor,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal
                              ),
                            ),
                          );
                        },
                      ),
                      onChanged: (CountryModel? data) {
                        setState(() {
                          _selectedCountry = data;
                          _selectedCity = null;
                          _cities = [];
                        });
                        if (data != null) {
                          _loadCities(data.name);
                        }
                      },
                    ),
                    const SizedBox(height: 16),

                    // --- City Dropdown ---
                    _buildLabel(context, AppLocalizations.of(context)!.city),
                    DropdownSearch<String>(
                      items: (filter, loadProps) => _cities,
                      selectedItem: _selectedCity,
                      enabled: _selectedCountry != null,

                      decoratorProps: DropDownDecoratorProps(
                        decoration: _buildInputDecoration(context,
                            _selectedCountry == null
                                ? AppLocalizations.of(context)!.selectCountryFirst
                                : AppLocalizations.of(context)!.selectCity
                        ),
                        baseStyle: TextStyle(color: textColor),
                      ),

                      popupProps: PopupProps.menu(
                        showSearchBox: true,
                        menuProps: MenuProps(
                          backgroundColor: popupBg,
                          borderRadius: BorderRadius.circular(12),
                          elevation: 4,
                        ),
                        searchFieldProps: TextFieldProps(
                          padding: const EdgeInsets.all(12),
                          style: TextStyle(color: textColor),
                          decoration: _buildInputDecoration(context, AppLocalizations.of(context)!.searchCity),
                        ),
                        itemBuilder: (context, item, isDisabled, isSelected) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            child: Text(
                              item,
                              style: TextStyle(
                                  fontSize: 14,
                                  color: isSelected ? primaryColor : textColor,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal
                              ),
                            ),
                          );
                        },
                      ),
                      onChanged: (String? data) => setState(() => _selectedCity = data),
                    ),
                    const SizedBox(height: 16),

                    // --- Text Fields ---
                    _buildLabel(context, AppLocalizations.of(context)!.street),
                    _buildTextField(context, null, _streetController),
                    const SizedBox(height: 16),

                    _buildLabel(context, AppLocalizations.of(context)!.address),
                    _buildTextField(context, null, _addressController),
                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildLabel(context, AppLocalizations.of(context)!.postalCode),
                              _buildTextField(context, null, _postalController, isNumber: true),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildLabel(context, AppLocalizations.of(context)!.phone),
                              _buildTextField(context, null, _phoneController, isNumber: true),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // --- Checkbox ---
                    Row(
                      children: [
                        SizedBox(
                          height: 24, width: 24,
                          child: Checkbox(
                            value: _isDefault,
                            activeColor: primaryColor,
                            checkColor: Colors.white,
                            side: BorderSide(color: isDark ? Colors.white54 : Colors.grey),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                            onChanged: (val) => setState(() => _isDefault = val!),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          AppLocalizations.of(context)!.setAsDefault,
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: textColor),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              // 3. Save Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    elevation: 2,
                    shadowColor: primaryColor.withOpacity(0.4),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isLoading
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : Text(
                    AppLocalizations.of(context)!.save,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(BuildContext context, String text) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 2),
      child: Text(text, style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 14, fontWeight: FontWeight.w600)),
    );
  }

  Widget _buildTextField(BuildContext context, String? hint, TextEditingController controller, {bool isNumber = false}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return TextFormField(
      controller: controller,
      style: TextStyle(color: isDark ? Colors.white : Colors.black), // Input Text Color
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      validator: (val) => val == null || val.isEmpty
          ? AppLocalizations.of(context)!.requiredField
          : null,
      decoration: _buildInputDecoration(context, hint ?? ""),
    );
  }
}