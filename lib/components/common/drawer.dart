import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:shop/models/category_model.dart';
import 'package:shop/services/api_service.dart';
class CustomEndDrawer extends StatefulWidget {
  final Function(String) onLocaleChange;
  final Map<String, dynamic>? user;

  const CustomEndDrawer({
    super.key,
    required this.onLocaleChange,
    required this.user,
  });

  @override
  State<CustomEndDrawer> createState() => _CustomEndDrawerState();
}

class _CustomEndDrawerState extends State<CustomEndDrawer> {
  List<CategoryModel> categories = [];
  bool isLoading = true;
  String? _currentLocale;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final newLocale = Localizations.localeOf(context).languageCode;
    if (_currentLocale != newLocale) {
      _currentLocale = newLocale;
      fetchCategories(newLocale);
    }
  }

  Future<void> fetchCategories(String locale) async {
    setState(() => isLoading = true);
    try {
      final data = await ApiService.fetchCategories(locale);
      setState(() {
        categories = data;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          // Logo Header
          Container(
            height: 90,
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: Image.asset(
              'assets/logo/techno-lock-mobile-logo.webp',
              height: 70,
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(height: 12),
          // Categories
          _buildExpansionSection(
            context,
            icon: Icons.category,
            title: localizations.categoriesSectionTitle,
            children: isLoading
                ? [
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(child: CircularProgressIndicator()),
              ),
            ]
                : categories.map((cat) {
              return ListTile(
                title: Text(cat.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                onTap: () {
                  Navigator.pop(context);
                  if (cat.route != null) {
                    Navigator.pushNamed(context, cat.route!);
                  }
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          // Language Selector
          _buildExpansionSection(
            context,
            icon: Icons.language,
            title: localizations.language,
            children: [
              _buildLanguageOption(context, flagAsset: '🇬🇧', label: localizations.english, localeCode: 'en'),
              _buildLanguageOption(context, flagAsset: '🇸🇦', label: localizations.arabic, localeCode: 'ar'),
              _buildLanguageOption(context, flagAsset: '🇪🇸', label: localizations.spanish, localeCode: 'es'),
            ],
          ),

          const SizedBox(height: 12),

          // Currency Selector
          _buildExpansionSection(
            context,
            icon: Icons.attach_money,
            title: 'Currency',
            children: [
              ListTile(title: Text(localizations.usd)),
              ListTile(title: Text(localizations.eur)),
              ListTile(title: Text(localizations.turkishLira)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildExpansionSection(BuildContext context,
      {required IconData icon, required String title, required List<Widget> children}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            tilePadding: const EdgeInsets.symmetric(horizontal: 16),
            leading: Icon(icon),
            title: Text(title),
            children: children,
          ),
        ),
      ),
    );
  }

  Widget _buildLanguageOption(
      BuildContext context, {
        required String flagAsset,
        required String label,
        required String localeCode,
      }) {
    return ListTile(
      leading: Text(flagAsset, style: const TextStyle(fontSize: 20)),
      title: Text(label),
      onTap: () {
        widget.onLocaleChange(localeCode);
        Navigator.pop(context);
      },
    );
  }
}
