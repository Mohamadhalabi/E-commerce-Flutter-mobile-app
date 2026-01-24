import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'package:shop/models/category_model.dart';
import 'package:shop/models/brand_model.dart';
import 'package:shop/models/manufacturer_model.dart';
import 'package:shop/services/api_service.dart';

import '../../route/route_constants.dart';
import '../skleton/common/skeleton_circle.dart';

// Cache globals
List<CategoryModel>? _cachedCategories;
List<BrandModel>? _cachedBrands;
List<ManufacturerModel>? _cachedManufacturers;
String? _cachedLocale;

class CustomEndDrawer extends StatefulWidget {
  final Function(String) onLocaleChange;
  final Map<String, dynamic>? user;
  final Function(int) onTabChanged;

  const CustomEndDrawer({
    super.key,
    required this.onLocaleChange,
    required this.user,
    required this.onTabChanged,
  });

  @override
  State<CustomEndDrawer> createState() => _CustomEndDrawerState();
}

class _CustomEndDrawerState extends State<CustomEndDrawer> {

  List<CategoryModel> categories = [];
  List<BrandModel> brands = [];
  List<ManufacturerModel> manufacturers = [];

  bool isLoadingCategories = true;
  bool isLoadingBrands = true;
  bool isLoadingManufacturers = true;
  String? _currentLocale;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final locale = Localizations.localeOf(context).languageCode;
    if (_currentLocale != locale) {
      _currentLocale = locale;
      fetchCategories(locale);
      fetchBrands(locale);
      fetchManufacturers(locale);
    }
  }

  Future<void> fetchCategories(String locale) async {
    if (_cachedCategories != null && _cachedLocale == locale) {
      setState(() { categories = _cachedCategories!; isLoadingCategories = false; });
      return;
    }
    setState(() => isLoadingCategories = true);
    try {
      final data = await ApiService.fetchCategories(locale);
      setState(() { categories = data; isLoadingCategories = false; _cachedCategories = data; _cachedLocale = locale; });
    } catch (e) { setState(() => isLoadingCategories = false); }
  }

  Future<void> fetchBrands(String locale) async {
    if (_cachedBrands != null && _cachedLocale == locale) {
      setState(() { brands = _cachedBrands!; isLoadingBrands = false; });
      return;
    }
    setState(() => isLoadingBrands = true);
    try {
      final data = await ApiService.fetchBrands(locale);
      setState(() { brands = data; isLoadingBrands = false; _cachedBrands = data; _cachedLocale = locale; });
    } catch (e) { setState(() => isLoadingBrands = false); }
  }

  Future<void> fetchManufacturers(String locale) async {
    if (_cachedManufacturers != null && _cachedLocale == locale) {
      setState(() { manufacturers = _cachedManufacturers!; isLoadingManufacturers = false; });
      return;
    }
    setState(() => isLoadingManufacturers = true);
    try {
      final data = await ApiService.fetchManufacturers(locale);
      setState(() { manufacturers = data; isLoadingManufacturers = false; _cachedManufacturers = data; _cachedLocale = locale; });
    } catch (e) { setState(() => isLoadingManufacturers = false); }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    // ✅ 1. Detect Dark Mode
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    // ✅ 2. Define Colors
    final Color drawerBg = isDark ? const Color(0xFF101015) : Colors.white;
    final Color dividerColor = isDark ? Colors.white10 : Colors.grey.shade100;

    return Drawer(
      backgroundColor: drawerBg, // Dynamic BG
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(topRight: Radius.circular(0), bottomRight: Radius.circular(0)),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // 1. HEADER
            Container(
              height: 150,
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
              alignment: Alignment.centerLeft,
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: dividerColor)),
              ),
              child: isDark
              // ✅ FIXED: Used ColorFiltered (Widget) instead of ColorFilter (Object)
                  ? ColorFiltered(
                  colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
                  child: Image.asset('assets/logo/techno-lock-mobile-logo.webp', fit: BoxFit.contain, alignment: Alignment.centerLeft)
              )
                  : Image.asset('assets/logo/techno-lock-mobile-logo.webp', fit: BoxFit.contain, alignment: Alignment.centerLeft),
            ),

            // 2. MENU LIST
            Expanded(
              child: ListView(
                padding: const EdgeInsets.only(top: 10, bottom: 20),
                children: [
                  _buildMenuSection(
                    context, isDark,
                    icon: Icons.category_outlined,
                    activeIcon: Icons.category_rounded,
                    title: localizations.categoriesSectionTitle,
                    children: isLoadingCategories
                        ? [_buildLoadingIndicator(isDark)]
                        : [_buildGrid(isDark, categories.map((cat) => {
                      'type': 'category',
                      'id': cat.id,
                      'title': cat.name,
                      'image': cat.image,
                    }).toList())],
                  ),

                  _buildDivider(isDark),

                  _buildMenuSection(
                    context, isDark,
                    icon: Icons.precision_manufacturing_outlined,
                    activeIcon: Icons.precision_manufacturing_rounded,
                    title: localizations.manufacturers,
                    children: isLoadingManufacturers
                        ? [_buildLoadingIndicator(isDark)]
                        : [_buildGrid(isDark, manufacturers.map((man) => {
                      'type': 'manufacturer',
                      'slug': man.slug,
                      'title': man.title,
                      'image': man.image,
                    }).toList())],
                  ),

                  _buildDivider(isDark),

                  _buildMenuSection(
                    context, isDark,
                    icon: Icons.branding_watermark_outlined,
                    activeIcon: Icons.branding_watermark_rounded,
                    title: localizations.brands,
                    children: isLoadingBrands
                        ? [_buildLoadingIndicator(isDark)]
                        : [_buildGrid(isDark, brands.map((brand) => {
                      'type': 'brand',
                      'slug': brand.slug,
                      'title': brand.title,
                      'image': brand.image,
                    }).toList())],
                  ),

                  _buildDivider(isDark),

                  _buildMenuSection(
                    context, isDark,
                    icon: Icons.language_outlined,
                    activeIcon: Icons.language_rounded,
                    title: localizations.language,
                    children: [
                      _buildLanguageOption(context, isDark, flagAsset: '🇬🇧', label: localizations.english, localeCode: 'en'),
                      _buildLanguageOption(context, isDark, flagAsset: '🇸🇦', label: localizations.arabic, localeCode: 'ar'),
                      _buildLanguageOption(context, isDark, flagAsset: '🇪🇸', label: localizations.spanish, localeCode: 'es'),
                    ],
                  ),

                  _buildDivider(isDark),

                  _buildMenuSection(
                    context, isDark,
                    icon: Icons.attach_money_outlined,
                    activeIcon: Icons.attach_money_rounded,
                    title: 'Currency',
                    children: [
                      _buildSimpleOption(isDark, localizations.usd),
                      _buildSimpleOption(isDark, localizations.eur),
                      _buildSimpleOption(isDark, localizations.turkishLira),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuSection(BuildContext context, bool isDark,
      {required IconData icon, required IconData activeIcon, required String title, required List<Widget> children}) {

    // Dynamic Colors
    final Color iconColor = isDark ? Colors.white70 : Colors.grey.shade700;
    final Color textColor = isDark ? Colors.white : Colors.black87;
    final Color activeColor = isDark ? Colors.white : const Color(0xFF0C1E4E);
    final Color tileBg = isDark ? const Color(0xFF101015) : Colors.white;

    return Theme(
      data: Theme.of(context).copyWith(
        dividerColor: Colors.transparent,
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
      ),
      child: ExpansionTile(
        backgroundColor: tileBg,
        collapsedBackgroundColor: tileBg,
        shape: const Border(),
        collapsedShape: const Border(),
        tilePadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        childrenPadding: const EdgeInsets.only(bottom: 16),
        leading: Icon(icon, color: iconColor, size: 24),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 15,
            color: textColor,
          ),
        ),
        iconColor: activeColor,
        textColor: activeColor,
        children: children,
      ),
    );
  }

  Widget _buildGrid(bool isDark, List<Map<String, dynamic>> items) {
    final double gridHeight = (items.length / 2).ceil() * 140.0;

    // Grid Item Colors
    final Color cardBg = isDark ? const Color(0xFF1C1C23) : Colors.white;
    final Color borderColor = isDark ? Colors.transparent : Colors.grey.shade100;
    final Color textColor = isDark ? Colors.white70 : Colors.black87;

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: gridHeight),
      child: Container(
        color: Colors.transparent,
        child: GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 1.0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          children: items.map((item) {
            return GestureDetector(
              onTap: () {
                Navigator.pop(context);
                final String type = item['type'] ?? 'category';

                if (type == 'category' && item['id'] != null) {
                  Navigator.pushNamed(
                    context,
                    subCategoryScreenRoute,
                    arguments: {
                      'parentId': item['id'],
                      'title': item['title'],
                      'currentIndex': 0,
                      'onTabChanged': widget.onTabChanged,
                      'onLocaleChange': widget.onLocaleChange,
                      'user': widget.user,
                    },
                  );
                }
                else if (type == 'brand') {
                  Navigator.pushNamed(
                      context,
                      "sub_category_products_screen",
                      arguments: {
                        'categorySlug': '',
                        'initialBrandSlug': item['slug'],
                        'title': item['title'],
                        'currentIndex': 0,
                        'user': widget.user,
                        'onTabChanged': widget.onTabChanged,
                        'onLocaleChange': widget.onLocaleChange,
                      }
                  );
                }
                else if (type == 'manufacturer') {
                  Navigator.pushNamed(
                      context,
                      "sub_category_products_screen",
                      arguments: {
                        'categorySlug': '',
                        'initialManufacturerSlug': item['slug'],
                        'title': item['title'],
                        'currentIndex': 0,
                        'user': widget.user,
                        'onTabChanged': widget.onTabChanged,
                        'onLocaleChange': widget.onLocaleChange,
                      }
                  );
                }
              },
              child: Container(
                decoration: BoxDecoration(
                  color: cardBg, // Dynamic Card BG
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: borderColor, width: 1.5),
                  boxShadow: [
                    if (!isDark) // Only show shadow in light mode
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: CachedNetworkImage(
                          imageUrl: item['image'] ?? '',
                          fit: BoxFit.contain,
                          placeholder: (context, url) => const SkeletonCircle(size: 50),
                          errorWidget: (context, url, error) => const Icon(Icons.broken_image, color: Colors.grey),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(8, 0, 8, 12),
                      child: Text(
                        item['title'] ?? '',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: textColor, // Dynamic Text
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildLanguageOption(BuildContext context, bool isDark,
      {required String flagAsset, required String label, required String localeCode}) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 40),
      dense: true,
      leading: Text(flagAsset, style: const TextStyle(fontSize: 20)),
      title: Text(label, style: TextStyle(fontSize: 14, color: isDark ? Colors.white : Colors.black87)),
      onTap: () {
        widget.onLocaleChange(localeCode);
        Navigator.pop(context);
      },
    );
  }

  Widget _buildSimpleOption(bool isDark, String label) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 40),
      dense: true,
      title: Text(label, style: TextStyle(fontSize: 14, color: isDark ? Colors.white : Colors.black87)),
      onTap: () {},
    );
  }

  Widget _buildDivider(bool isDark) {
    return Divider(height: 1, color: isDark ? Colors.white10 : Colors.grey.shade100, indent: 24, endIndent: 24);
  }

  Widget _buildLoadingIndicator(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Center(child: CircularProgressIndicator(color: isDark ? Colors.white : const Color(0xFF0C1E4E))),
    );
  }
}