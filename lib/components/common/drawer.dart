import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'package:shop/models/category_model.dart';
import 'package:shop/models/brand_model.dart';
import 'package:shop/models/manufacturer_model.dart';
import 'package:shop/services/api_service.dart';

import '../../constants.dart';
import '../skleton/common/skeleton_circle.dart';

List<CategoryModel>? _cachedCategories;
List<BrandModel>? _cachedBrands;
List<ManufacturerModel>? _cachedManufacturers;
String? _cachedLocale;

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
      setState(() {
        categories = data;
        isLoadingCategories = false;
        _cachedCategories = data;
        _cachedLocale = locale;
      });
    } catch (e) {
      setState(() => isLoadingCategories = false);
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
      setState(() {
        brands = data;
        isLoadingBrands = false;
        _cachedBrands = data;
        _cachedLocale = locale;
      });
    } catch (e) {
      setState(() => isLoadingBrands = false);
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
      setState(() {
        manufacturers = data;
        isLoadingManufacturers = false;
        _cachedManufacturers = data;
        _cachedLocale = locale;
      });
    } catch (e) {
      setState(() => isLoadingManufacturers = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return Drawer(
      child: SafeArea(
        child: Container(
          color: const Color(0xFFFBFBFD),
          child: ListView(
            padding: const EdgeInsets.only(bottom: 20),
            children: [
              Container(
                height: 90,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Color.fromRGBO(0, 0, 0, 0.1),
                      blurRadius: 6,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: Image.asset(
                  'assets/logo/techno-lock-mobile-logo.webp',
                  height: 70,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 12),

              _buildExpansionSection(
                context,
                icon: Icons.category,
                title: localizations.categoriesSectionTitle,
                children: isLoadingCategories
                    ? [_buildLoadingIndicator()]
                    : [_buildGrid(categories.map((cat) => {
                  'title': cat.name,
                  'image': cat.image,
                  'route': cat.route,
                }).toList())],
              ),

              const SizedBox(height: 12),

              _buildExpansionSection(
                context,
                icon: Icons.precision_manufacturing,
                title: localizations.manufacturers,
                children: isLoadingManufacturers
                    ? [_buildLoadingIndicator()]
                    : [_buildGrid(manufacturers.map((man) => {
                  'title': man.title,
                  'image': man.image,
                  'route': '/manufacturers/${man.slug}',
                }).toList())],
              ),

              const SizedBox(height: 12),

              _buildExpansionSection(
                context,
                icon: Icons.branding_watermark_outlined,
                title: localizations.brands,
                children: isLoadingBrands
                    ? [_buildLoadingIndicator()]
                    : [
                  _buildGrid(brands.map((brand) => {
                    'title': brand.title,
                    'image': brand.image,
                    'route': '/brands/${brand.slug}',
                  }).toList())
                ],
              ),

              const SizedBox(height: 12),

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
        ),
      ),
    );
  }

  Widget _buildExpansionSection(BuildContext context,
      {required IconData icon, required String title, required List<Widget> children}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFFBFBFD),
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(
              color: Color.fromRGBO(0, 0, 0, 0.1),
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            tilePadding: const EdgeInsets.symmetric(horizontal: 16),
            leading: Icon(icon),
            title: Text(title),
            iconColor: primaryColor,
            children: children,
          ),
        ),
      ),
    );
  }

  Widget _buildGrid(List<Map<String, dynamic>> items) {
    final double gridHeight = (items.length / 2).ceil() * 170.0;

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: gridHeight),
      child: GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.85,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        children: items.map((item) {
          return GestureDetector(
            onTap: () {
              Navigator.pop(context);
              if (item['route'] != null) {
                Navigator.pushNamed(context, item['route']);
              }
            },
            child: Column(
              children: [
                Container(
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Color.fromRGBO(0, 0, 0, 0.1),
                        blurRadius: 6,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: CachedNetworkImage(
                      imageUrl: item['image'] ?? '',
                      width: 80,
                      height: 80,
                      fit: BoxFit.contain,
                      placeholder: (context, url) => const SkeletonCircle(),
                      errorWidget: (context, url, error) => Container(
                        width: 80,
                        height: 80,
                        color: Colors.grey.shade200,
                        child: const Icon(Icons.image_not_supported),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  item['title'] ?? '',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildLanguageOption(BuildContext context,
      {required String flagAsset, required String label, required String localeCode}) {
    return ListTile(
      leading: Text(flagAsset, style: const TextStyle(fontSize: 20)),
      title: Text(label),
      onTap: () {
        widget.onLocaleChange(localeCode);
        Navigator.pop(context);
      },
    );
  }

  Widget _buildLoadingIndicator() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 16),
      child: Center(child: CircularProgressIndicator()),
    );
  }
}