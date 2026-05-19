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
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color drawerBg = isDark ? const Color(0xFF101015) : Colors.white;
    final Color dividerColor = isDark ? Colors.white10 : Colors.grey.shade100;

    return Drawer(
      backgroundColor: drawerBg,
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

                  // --- BRANDS ACCORDION ---
                  _buildMenuSection(
                    context, isDark,
                    icon: Icons.branding_watermark_outlined,
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

                  // --- MANUFACTURERS ACCORDION ---
                  _buildMenuSection(
                    context, isDark,
                    icon: Icons.precision_manufacturing_outlined,
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

                  // --- DYNAMIC CATEGORIES ACCORDIONS ---
                  if (isLoadingCategories)
                    _buildLoadingIndicator(isDark)
                  else
                    ...categories.map((cat) => Column(
                      children: [
                        CategoryExpansionTile(
                          category: cat,
                          isDark: isDark,
                          user: widget.user,
                          onTabChanged: widget.onTabChanged,
                          onLocaleChange: widget.onLocaleChange,
                        ),
                        _buildDivider(isDark),
                      ],
                    )),

                  // --- TOOLS (Moved to the Bottom) ---
                  _buildSimpleToolOption(
                      context, isDark,
                      "Kia/Hyundai Part Lookup",
                      Icons.directions_car_outlined,
                          () {
                        Navigator.pop(context);
                        Navigator.pushNamed(context, kiaHyundaiScreenRoute);
                      }
                  ),

                  _buildDivider(isDark), // <hr> between them

                  _buildSimpleToolOption(
                      context, isDark,
                      "Toyota Passcode",
                      Icons.pin_outlined,
                          () {
                        Navigator.pop(context);
                        Navigator.pushNamed(context, toyotaPasscodeScreenRoute);
                      }
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
      {required IconData icon, required String title, required List<Widget> children}) {

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
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: textColor),
        ),
        iconColor: activeColor,
        textColor: activeColor,
        children: children,
      ),
    );
  }

  Widget _buildGrid(bool isDark, List<Map<String, dynamic>> items) {
    final double gridHeight = (items.length / 2).ceil() * 140.0;
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
                final String type = item['type'] ?? 'brand';

                Navigator.pushNamed(
                    context,
                    "sub_category_products_screen",
                    arguments: {
                      'categorySlug': '',
                      'initialBrandSlug': type == 'brand' ? item['slug'] : null,
                      'initialManufacturerSlug': type == 'manufacturer' ? item['slug'] : null,
                      'title': item['title'],
                      'currentIndex': 0,
                      'user': widget.user,
                      'onTabChanged': widget.onTabChanged,
                      'onLocaleChange': widget.onLocaleChange,
                    }
                );
              },
              child: Container(
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: borderColor, width: 1.5),
                  boxShadow: [
                    if (!isDark)
                      BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 4)),
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
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: textColor),
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

  Widget _buildDivider(bool isDark) {
    return Divider(height: 1, color: isDark ? Colors.white10 : Colors.grey.shade100, indent: 24, endIndent: 24);
  }

  Widget _buildLoadingIndicator(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Center(child: CircularProgressIndicator(color: isDark ? Colors.white : const Color(0xFF0C1E4E))),
    );
  }

  Widget _buildSimpleToolOption(BuildContext context, bool isDark, String label, IconData icon, VoidCallback onTap) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      leading: Icon(icon, color: isDark ? Colors.white70 : Colors.grey.shade700, size: 24),
      title: Text(label, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: isDark ? Colors.white : Colors.black87)),
      onTap: onTap,
    );
  }
}

// =========================================================================
// CUSTOM TILE FOR CATEGORIES (Fetches subcategories when expanded)
// =========================================================================
class CategoryExpansionTile extends StatefulWidget {
  final CategoryModel category;
  final bool isDark;
  final Map<String, dynamic>? user;
  final Function(int) onTabChanged;
  final Function(String) onLocaleChange;

  const CategoryExpansionTile({
    super.key,
    required this.category,
    required this.isDark,
    required this.user,
    required this.onTabChanged,
    required this.onLocaleChange,
  });

  @override
  State<CategoryExpansionTile> createState() => _CategoryExpansionTileState();
}

class _CategoryExpansionTileState extends State<CategoryExpansionTile> {
  bool _isLoading = false;
  bool _hasFetched = false;
  List<Map<String, dynamic>> _subcategories = [];

  IconData _getCategoryIcon(String categoryName) {
    final name = categoryName.toLowerCase();
    if (name.contains('key') || name.contains('remote')) return Icons.vpn_key_outlined;
    if (name.contains('machine') || name.contains('device')) return Icons.precision_manufacturing_outlined;
    if (name.contains('accessor') || name.contains('tool')) return Icons.handyman_outlined;
    if (name.contains('software') || name.contains('token')) return Icons.integration_instructions_outlined;
    if (name.contains('pin')) return Icons.password_outlined;

    return Icons.category_outlined; // Default fallback icon
  }

  Future<void> _fetchSubcategories() async {
    if (_hasFetched) return; // Don't fetch again if already loaded

    setState(() => _isLoading = true);
    try {
      final data = await ApiService.fetchSubcategories(widget.category.id);
      if (mounted) {
        setState(() {
          _subcategories = data.map<Map<String, dynamic>>((sub) {
            return {
              'id': sub['id'],
              'title': sub['name'] ?? sub['title'] ?? '',
              'image': sub['image'] ?? sub['icon'] ?? '',
              'slug': sub['slug'] ?? '',
            };
          }).toList();
          _hasFetched = true;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color iconColor = widget.isDark ? Colors.white70 : Colors.grey.shade700;
    final Color textColor = widget.isDark ? Colors.white : Colors.black87;
    final Color activeColor = widget.isDark ? Colors.white : const Color(0xFF0C1E4E);
    final Color tileBg = widget.isDark ? const Color(0xFF101015) : Colors.white;

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
        leading: Icon(_getCategoryIcon(widget.category.name), color: iconColor, size: 24),
        title: Text(
          widget.category.name,
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: textColor),
        ),
        iconColor: activeColor,
        textColor: activeColor,
        onExpansionChanged: (expanded) {
          if (expanded) _fetchSubcategories();
        },
        children: [
          if (_isLoading)
            _buildSkeletonGrid() // NEW SKELETON LOADER
          else if (_subcategories.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text("No subcategories found", style: TextStyle(color: textColor)),
            )
          else
            _buildSubcategoryGrid(),
        ],
      ),
    );
  }

  Widget _buildSkeletonGrid() {
    final double gridHeight = 280.0; // Height for 2 rows (4 items total)
    final Color cardBg = widget.isDark ? const Color(0xFF1C1C23) : Colors.white;
    final Color borderColor = widget.isDark ? Colors.transparent : Colors.grey.shade100;
    final Color skeletonColor = widget.isDark ? Colors.white10 : Colors.grey.shade200;

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
          children: List.generate(4, (index) {
            return Container(
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: borderColor, width: 1.5),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Container(
                        decoration: BoxDecoration(
                          color: skeletonColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(8, 0, 8, 12),
                    child: Container(
                      height: 10,
                      width: 50,
                      decoration: BoxDecoration(
                        color: skeletonColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ),
      ),
    );
  }

  // Identical grid design specifically for Subcategories routing
  Widget _buildSubcategoryGrid() {
    final double gridHeight = (_subcategories.length / 2).ceil() * 140.0;
    final Color cardBg = widget.isDark ? const Color(0xFF1C1C23) : Colors.white;
    final Color borderColor = widget.isDark ? Colors.transparent : Colors.grey.shade100;
    final Color textColor = widget.isDark ? Colors.white70 : Colors.black87;

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
          children: _subcategories.map((item) {
            return GestureDetector(
              onTap: () {
                Navigator.pop(context); // Close Drawer
                // Navigate directly to products passing the Subcategory Slug
                Navigator.pushNamed(
                    context,
                    "sub_category_products_screen",
                    arguments: {
                      'categorySlug': item['slug'] ?? '',
                      'title': item['title'],
                      'currentIndex': 0,
                      'user': widget.user,
                      'onTabChanged': widget.onTabChanged,
                      'onLocaleChange': widget.onLocaleChange,
                    }
                );
              },
              child: Container(
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: borderColor, width: 1.5),
                  boxShadow: [
                    if (!widget.isDark)
                      BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 4)),
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
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: textColor),
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
}