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
  // ✅ Branding Colors
  final Color brandingColor = const Color(0xFF0C1E4E);
  final Color activeHighlight = Colors.white; // Very light grey-blue for expanded items

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

  // (Fetch methods remain the same)
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

    return Drawer(
      backgroundColor: Colors.white, // ✅ Clean White Background
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(topRight: Radius.circular(0), bottomRight: Radius.circular(0)), // Standard straight edge
      ),
      child: SafeArea(
        child: Column(
          children: [
            // 1. HEADER (Logo Area)
            Container(
              height: 150,
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
              alignment: Alignment.centerLeft,
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
              ),
              child: Image.asset(
                'assets/logo/techno-lock-mobile-logo.webp',
                fit: BoxFit.contain,
                alignment: Alignment.centerLeft,
              ),
            ),

            // 2. MENU LIST
            Expanded(
              child: ListView(
                padding: const EdgeInsets.only(top: 10, bottom: 20),
                children: [
                  _buildMenuSection(
                    context,
                    icon: Icons.category_outlined,
                    activeIcon: Icons.category_rounded,
                    title: localizations.categoriesSectionTitle,
                    children: isLoadingCategories
                        ? [_buildLoadingIndicator()]
                        : [_buildGrid(categories.map((cat) => {
                      'id' : cat.id,
                      'title': cat.name,
                      'image': cat.image,
                      'route': cat.route,
                    }).toList())],
                  ),

                  _buildDivider(),

                  _buildMenuSection(
                    context,
                    icon: Icons.precision_manufacturing_outlined,
                    activeIcon: Icons.precision_manufacturing_rounded,
                    title: localizations.manufacturers,
                    children: isLoadingManufacturers
                        ? [_buildLoadingIndicator()]
                        : [_buildGrid(manufacturers.map((man) => {
                      'title': man.title,
                      'image': man.image,
                      'route': '/manufacturers/${man.slug}',
                    }).toList())],
                  ),

                  _buildDivider(),

                  _buildMenuSection(
                    context,
                    icon: Icons.branding_watermark_outlined,
                    activeIcon: Icons.branding_watermark_rounded,
                    title: localizations.brands,
                    children: isLoadingBrands
                        ? [_buildLoadingIndicator()]
                        : [_buildGrid(brands.map((brand) => {
                      'title': brand.title,
                      'image': brand.image,
                      'route': '/brands/${brand.slug}',
                    }).toList())],
                  ),

                  _buildDivider(),

                  _buildMenuSection(
                    context,
                    icon: Icons.language_outlined,
                    activeIcon: Icons.language_rounded,
                    title: localizations.language,
                    children: [
                      _buildLanguageOption(context, flagAsset: '🇬🇧', label: localizations.english, localeCode: 'en'),
                      _buildLanguageOption(context, flagAsset: '🇸🇦', label: localizations.arabic, localeCode: 'ar'),
                      _buildLanguageOption(context, flagAsset: '🇪🇸', label: localizations.spanish, localeCode: 'es'),
                    ],
                  ),

                  _buildDivider(),

                  _buildMenuSection(
                    context,
                    icon: Icons.attach_money_outlined,
                    activeIcon: Icons.attach_money_rounded,
                    title: 'Currency',
                    children: [
                      _buildSimpleOption(localizations.usd),
                      _buildSimpleOption(localizations.eur),
                      _buildSimpleOption(localizations.turkishLira),
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

  Widget _buildMenuSection(BuildContext context,
      {required IconData icon, required IconData activeIcon, required String title, required List<Widget> children}) {
    return Theme(
      data: Theme.of(context).copyWith(
        dividerColor: Colors.transparent, // Removes top/bottom lines
        splashColor: Colors.transparent,  // Removes tap splash
        highlightColor: Colors.transparent, // Removes tap highlight
      ),
      child: ExpansionTile(
        backgroundColor: Colors.white,
        collapsedBackgroundColor: Colors.white,

        shape: const Border(),
        collapsedShape: const Border(),

        tilePadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        childrenPadding: const EdgeInsets.only(bottom: 16),

        leading: Icon(icon, color: Colors.grey.shade700, size: 24),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 15,
            color: Colors.black87,
          ),
        ),
        iconColor: brandingColor,
        textColor: brandingColor,

        children: children,
      ),
    );
  }

  Widget _buildGrid(List<Map<String, dynamic>> items) {
    final double gridHeight = (items.length / 2).ceil() * 140.0;

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: gridHeight),
      child: Container(
        // ✅ CHANGE: Set to transparent or remove the color property entirely
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
                if (item['id'] != null) {
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
              },
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  // ✅ Added a subtle grey border to separate items since background is white now
                  border: Border.all(color: Colors.grey.shade100, width: 1.5),
                  boxShadow: [
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
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
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

  Widget _buildLanguageOption(BuildContext context,
      {required String flagAsset, required String label, required String localeCode}) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 40), // Indented for hierarchy
      dense: true,
      leading: Text(flagAsset, style: const TextStyle(fontSize: 20)),
      title: Text(label, style: const TextStyle(fontSize: 14)),
      onTap: () {
        widget.onLocaleChange(localeCode);
        Navigator.pop(context);
      },
    );
  }

  Widget _buildSimpleOption(String label) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 40),
      dense: true,
      title: Text(label, style: const TextStyle(fontSize: 14)),
      onTap: () {}, // Add logic later
    );
  }

  Widget _buildDivider() {
    return Divider(height: 1, color: Colors.grey.shade100, indent: 24, endIndent: 24);
  }

  Widget _buildLoadingIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Center(child: CircularProgressIndicator(color: brandingColor)),
    );
  }
}