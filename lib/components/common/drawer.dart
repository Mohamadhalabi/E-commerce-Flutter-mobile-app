import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'package:shop/constants.dart';
import 'package:shop/models/category_model.dart';
import 'package:shop/models/brand_model.dart';
import 'package:shop/models/manufacturer_model.dart';
import 'package:shop/services/api_service.dart';

import '../../route/route_constants.dart';
import '../skleton/common/skeleton_circle.dart';

import 'package:shop/screens/tools/kia_pin_calculator_screen.dart';

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
      setState(() {
        categories = _cachedCategories!;
        isLoadingCategories = false;
      });
      return;
    }
    setState(() => isLoadingCategories = true);
    try {
      final data = await ApiService.fetchCategories(locale);
      _cachedCategories = data;
      _cachedLocale = locale;
      if (!mounted) return;
      setState(() {
        categories = data;
        isLoadingCategories = false;
      });
    } catch (e) {
      if (mounted) setState(() => isLoadingCategories = false);
    }
  }

  Future<void> fetchBrands(String locale) async {
    if (_cachedBrands != null && _cachedLocale == locale) {
      setState(() {
        brands = _cachedBrands!;
        isLoadingBrands = false;
      });
      return;
    }
    setState(() => isLoadingBrands = true);
    try {
      final data = await ApiService.fetchBrands(locale);
      _cachedBrands = data;
      _cachedLocale = locale;
      if (!mounted) return;
      setState(() {
        brands = data;
        isLoadingBrands = false;
      });
    } catch (e) {
      if (mounted) setState(() => isLoadingBrands = false);
    }
  }

  Future<void> fetchManufacturers(String locale) async {
    if (_cachedManufacturers != null && _cachedLocale == locale) {
      setState(() {
        manufacturers = _cachedManufacturers!;
        isLoadingManufacturers = false;
      });
      return;
    }
    setState(() => isLoadingManufacturers = true);
    try {
      final data = await ApiService.fetchManufacturers(locale);
      _cachedManufacturers = data;
      _cachedLocale = locale;
      if (!mounted) return;
      setState(() {
        manufacturers = data;
        isLoadingManufacturers = false;
      });
    } catch (e) {
      if (mounted) setState(() => isLoadingManufacturers = false);
    }
  }

  void _openFiltered(Map<String, dynamic> item) {
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
      },
    );
  }

  void _openTool(String route) {
    Navigator.pop(context);
    Navigator.pushNamed(context, route);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Drawer(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      surfaceTintColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadiusDirectional.only(
          topEnd: Radius.circular(28),
          bottomEnd: Radius.circular(28),
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            const _DrawerHeader(),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(12, 4, 12, 24),
                children: [
                  const _SectionLabel('Browse'),
                  DrawerExpansionTile(
                    icon: Icons.verified_outlined,
                    title: l10n.brands,
                    children: [
                      if (isLoadingBrands)
                        const DrawerGridSkeleton()
                      else
                        DrawerItemGrid(
                          items: brands
                              .map((b) => {
                            'type': 'brand',
                            'slug': b.slug,
                            'title': b.title,
                            'image': b.image,
                          })
                              .toList(),
                          onTap: _openFiltered,
                        ),
                    ],
                  ),
                  DrawerExpansionTile(
                    icon: Icons.precision_manufacturing_outlined,
                    title: l10n.manufacturers,
                    children: [
                      if (isLoadingManufacturers)
                        const DrawerGridSkeleton()
                      else
                        DrawerItemGrid(
                          items: manufacturers
                              .map((m) => {
                            'type': 'manufacturer',
                            'slug': m.slug,
                            'title': m.title,
                            'image': m.image,
                          })
                              .toList(),
                          onTap: _openFiltered,
                        ),
                    ],
                  ),
                  if (isLoadingCategories)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Center(
                        child: SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: primaryColor,
                          ),
                        ),
                      ),
                    )
                  else
                    ...categories.map(
                          (cat) => CategoryExpansionTile(
                        category: cat,
                        isDark: AppPalette.isDark(context),
                        user: widget.user,
                        onTabChanged: widget.onTabChanged,
                        onLocaleChange: widget.onLocaleChange,
                      ),
                    ),
                  const SizedBox(height: 12),
                  const _SectionLabel('Tools'),
                  _DrawerLinkTile(
                    icon: Icons.key_rounded,
                    title: "Kia/Hyundai PIN Code",
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const KiaPinCalculatorScreen()),
                      );
                    },
                  ),
                  _DrawerLinkTile(
                    icon: Icons.pin_outlined,
                    title: "Toyota Passcode",
                    onTap: () => _openTool(toyotaPasscodeScreenRoute),
                  ),
                  _DrawerLinkTile(
                    icon: Icons.directions_car_outlined,
                    title: "Kia/Hyundai Remote Fob Part number Lookup",
                    onTap: () => _openTool(kiaHyundaiScreenRoute),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =========================================================================
// HEADER
// =========================================================================
class _DrawerHeader extends StatelessWidget {
  const _DrawerHeader();

  @override
  Widget build(BuildContext context) {
    final isDark = AppPalette.isDark(context);
    final logo = Image.asset(
      'assets/logo/techno-lock-mobile-logo.webp',
      fit: BoxFit.contain,
      alignment: AlignmentDirectional.centerStart,
    );

    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(20, 16, 12, 12),
      child: Row(
        children: [
          Expanded(
            child: SizedBox(
              height: 52,
              child: isDark
                  ? ColorFiltered(
                colorFilter: const ColorFilter.mode(
                    Colors.white, BlendMode.srcIn),
                child: logo,
              )
                  : logo,
            ),
          ),
          const SizedBox(width: 12),
          Material(
            color: AppPalette.cardElevated(context),
            shape: CircleBorder(
              side: BorderSide(color: AppPalette.border(context)),
            ),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: () => Navigator.pop(context),
              child: SizedBox(
                width: 40,
                height: 40,
                child: Icon(
                  Icons.close_rounded,
                  size: 20,
                  color: AppPalette.text(context),
                  semanticLabel: 'Close menu',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(12, 10, 12, 6),
      child: Text(
        label,
        style: TextStyle(
          color: AppPalette.textMuted(context),
          fontSize: 12.5,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

// =========================================================================
// ROWS
// =========================================================================
class _IconTile extends StatelessWidget {
  const _IconTile({required this.icon, required this.active});
  final IconData icon;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: active ? primaryColor : AppPalette.cardElevated(context),
        borderRadius: BorderRadius.circular(11),
      ),
      child: Icon(
        icon,
        size: 19,
        color: active ? Colors.white : AppPalette.text(context),
      ),
    );
  }
}

/// Rounded accordion row used by Brands, Manufacturers and categories.
class DrawerExpansionTile extends StatefulWidget {
  const DrawerExpansionTile({
    super.key,
    required this.icon,
    required this.title,
    required this.children,
    this.onExpansionChanged,
  });

  final IconData icon;
  final String title;
  final List<Widget> children;
  final ValueChanged<bool>? onExpansionChanged;

  @override
  State<DrawerExpansionTile> createState() => _DrawerExpansionTileState();
}

class _DrawerExpansionTileState extends State<DrawerExpansionTile> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final isDark = AppPalette.isDark(context);
    final shape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(16));

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          shape: shape,
          collapsedShape: shape,
          clipBehavior: Clip.antiAlias,
          backgroundColor: primaryColor.withOpacity(isDark ? 0.12 : 0.05),
          collapsedBackgroundColor: Colors.transparent,
          tilePadding: const EdgeInsets.symmetric(horizontal: 10),
          childrenPadding: const EdgeInsets.fromLTRB(10, 0, 10, 12),
          leading: _IconTile(icon: widget.icon, active: _expanded),
          title: Text(
            widget.title,
            style: TextStyle(
              fontSize: 14.5,
              fontWeight: _expanded ? FontWeight.w700 : FontWeight.w600,
              color: AppPalette.text(context),
            ),
          ),
          iconColor: primaryColor,
          collapsedIconColor: AppPalette.textMuted(context),
          onExpansionChanged: (value) {
            setState(() => _expanded = value);
            widget.onExpansionChanged?.call(value);
          },
          children: widget.children,
        ),
      ),
    );
  }
}

class _DrawerLinkTile extends StatelessWidget {
  const _DrawerLinkTile({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            child: Row(
              children: [
                _IconTile(icon: icon, active: false),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                      color: AppPalette.text(context),
                    ),
                  ),
                ),
                Icon(
                  isRtl ? Icons.chevron_left_rounded : Icons.chevron_right_rounded,
                  color: AppPalette.textMuted(context),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// =========================================================================
// GRIDS
// =========================================================================
const _gridDelegate = SliverGridDelegateWithFixedCrossAxisCount(
  crossAxisCount: 2,
  mainAxisSpacing: 10,
  crossAxisSpacing: 10,
  childAspectRatio: 1.0,
);

class DrawerItemGrid extends StatelessWidget {
  const DrawerItemGrid({super.key, required this.items, required this.onTap});

  final List<Map<String, dynamic>> items;
  final void Function(Map<String, dynamic> item) onTap;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.only(top: 4),
      gridDelegate: _gridDelegate,
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return Material(
          color: AppPalette.card(context),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: AppPalette.border(context)),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => onTap(item),
            child: Column(
              children: [
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.all(6),
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white, // logos have white backgrounds
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: CachedNetworkImage(
                      imageUrl: item['image'] ?? '',
                      fit: BoxFit.contain,
                      placeholder: (context, url) =>
                      const SkeletonCircle(size: 32),
                      errorWidget: (context, url, error) => const Icon(
                        Icons.image_not_supported_outlined,
                        color: blackColor20,
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
                  child: Text(
                    item['title'] ?? '',
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      height: 1.2,
                      color: AppPalette.text(context),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class DrawerGridSkeleton extends StatelessWidget {
  const DrawerGridSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final skeleton = AppPalette.isDark(context) ? Colors.white10 : blackColor5;
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.only(top: 4),
      gridDelegate: _gridDelegate,
      itemCount: 4,
      itemBuilder: (_, __) => Container(
        decoration: BoxDecoration(
          color: skeleton,
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}

// =========================================================================
// CATEGORY TILE (fetches subcategories when expanded)
// =========================================================================
class CategoryExpansionTile extends StatefulWidget {
  final CategoryModel category;
  final bool isDark; // kept for compatibility
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
    return Icons.category_outlined;
  }

  Future<void> _fetchSubcategories() async {
    if (_hasFetched || _isLoading) return;
    setState(() => _isLoading = true);
    try {
      final data = await ApiService.fetchSubcategories(widget.category.id);
      if (!mounted) return;
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
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _openSubcategory(Map<String, dynamic> item) {
    Navigator.pop(context);
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
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return DrawerExpansionTile(
      icon: _getCategoryIcon(widget.category.name),
      title: widget.category.name,
      onExpansionChanged: (expanded) {
        if (expanded) _fetchSubcategories();
      },
      children: [
        if (_isLoading)
          const DrawerGridSkeleton()
        else if (_subcategories.isEmpty)
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              "No subcategories yet",
              style: TextStyle(
                color: AppPalette.textMuted(context),
                fontSize: 13,
              ),
            ),
          )
        else
          DrawerItemGrid(items: _subcategories, onTap: _openSubcategory),
      ],
    );
  }
}