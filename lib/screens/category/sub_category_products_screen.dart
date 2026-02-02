import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shop/components/product/product_card.dart';
import 'package:shop/components/filter_modal.dart';
import 'package:shop/models/product_model.dart';
import 'package:shop/services/api_service.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../components/common/CustomBottomNavigationBar.dart';
import '../../components/skleton/product/product_card_skelton.dart';
import 'package:shop/route/route_constants.dart';
import '../../constants.dart';
import '../../components/common/drawer.dart';

class SubCategoryProductsScreen extends StatefulWidget {
  final String categorySlug;
  final String title;
  final int currentIndex;
  final Map<String, dynamic>? user;

  final String? initialBrandSlug;
  final String? initialManufacturerSlug;
  final String? searchQuery;

  final Function(int) onTabChanged;
  final Function(String) onLocaleChange;

  final bool isMainTab;

  const SubCategoryProductsScreen({
    super.key,
    required this.categorySlug,
    required this.title,
    required this.currentIndex,
    required this.user,
    this.initialBrandSlug,
    this.initialManufacturerSlug,
    this.searchQuery,
    required this.onTabChanged,
    required this.onLocaleChange,
    this.isMainTab = false,
  });

  @override
  State<SubCategoryProductsScreen> createState() => _SubCategoryProductsScreenState();
}

class _SubCategoryProductsScreenState extends State<SubCategoryProductsScreen> {
  List<ProductModel> products = [];
  bool isLoading = true;
  bool isLoadingMore = false;
  int currentPage = 0;
  int lastPage = 1;

  late ScrollController _scrollController;
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  String _currentQuery = "";

  List<String> _selectedBrands = [];
  List<String> _selectedManufacturers = [];
  List<String> _selectedCategories = [];
  Map<String, List<String>> _selectedAttributes = {};
  Map<String, dynamic> _facets = {};

  late int _localCurrentIndex;

  @override
  void initState() {
    super.initState();
    _localCurrentIndex = widget.currentIndex;
    _scrollController = ScrollController()..addListener(_onScroll);
    _searchController.addListener(_onSearchChanged);

    if (widget.categorySlug.isNotEmpty) _selectedCategories.add(widget.categorySlug);
    if (widget.initialBrandSlug != null) _selectedBrands.add(widget.initialBrandSlug!);
    if (widget.initialManufacturerSlug != null) _selectedManufacturers.add(widget.initialManufacturerSlug!);

    if (widget.searchQuery != null && widget.searchQuery!.isNotEmpty) {
      _currentQuery = widget.searchQuery!;
      _searchController.text = widget.searchQuery!;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchData(refresh: true);
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _fetchData({bool refresh = false}) async {
    if (isLoadingMore) return;
    final locale = Localizations.localeOf(context).languageCode;
    if (refresh) {
      setState(() => isLoading = true);
      currentPage = 0;
    } else {
      if (currentPage >= lastPage) return;
      setState(() => isLoadingMore = true);
    }
    try {
      final result = await ApiService.fetchCatalog(
        categorySlug: widget.categorySlug,
        searchQuery: _currentQuery,
        selectedBrands: _selectedBrands,
        selectedManufacturers: _selectedManufacturers,
        selectedCategories: _selectedCategories,
        selectedAttributes: _selectedAttributes,
        page: currentPage + 1,
        locale: locale,
        sort: 'price_desc',
      );
      setState(() {
        if (refresh) {
          products = result['products'];
          if (result['facets'] != null) _facets = result['facets'];
        } else {
          products.addAll(result['products']);
        }
        currentPage = result['current_page'];
        lastPage = result['last_page'];
      });
    } catch (e) {
      debugPrint("Error fetching catalog: $e");
    } finally {
      setState(() {
        isLoading = false;
        isLoadingMore = false;
      });
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 300) {
      _fetchData(refresh: false);
    }
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      final query = _searchController.text.trim();

      if (query.isNotEmpty && query.length < 3) return;

      if (query != _currentQuery) {
        setState(() {
          _currentQuery = query;
          _selectedAttributes.clear();
          _selectedBrands.clear();
          if (widget.initialBrandSlug != null) _selectedBrands.add(widget.initialBrandSlug!);
          _selectedManufacturers.clear();
          if (widget.initialManufacturerSlug != null) _selectedManufacturers.add(widget.initialManufacturerSlug!);
          _selectedCategories.clear();
          if (widget.categorySlug.isNotEmpty) _selectedCategories.add(widget.categorySlug);

          products.clear();
          isLoading = true;
        });
        _fetchData(refresh: true);
      }
    });
  }

  String _lookupName(String slug, String type) {
    List<dynamic> list = [];
    if (_facets.containsKey(type)) list = _facets[type] as List<dynamic>;
    final found = list.firstWhere((item) => item['slug'] == slug, orElse: () => null);
    return found != null ? found['name'] : slug;
  }

  String _lookupAttributeName(String groupSlug, String itemSlug) {
    if (_facets.containsKey('attributes')) {
      final attrList = _facets['attributes'] as List<dynamic>;
      final group = attrList.firstWhere((g) => g['slug'] == groupSlug, orElse: () => null);
      if (group != null) {
        final items = group['items'] as List<dynamic>;
        final item = items.firstWhere((i) => i['slug'] == itemSlug, orElse: () => null);
        if (item != null) return "${group['name']}: ${item['name']}";
      }
    }
    return itemSlug;
  }

  Widget _buildActiveFilters() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final containerBg = isDark ? const Color(0xFF1C1C23) : Colors.white;

    List<Widget> chips = [];
    void removeFilter(VoidCallback action) {
      setState(() {
        action();
        products.clear();
        isLoading = true;
      });
      _fetchData(refresh: true);
    }
    for (var slug in _selectedBrands) {
      if (widget.initialBrandSlug == slug) continue;
      chips.add(_buildChip(_lookupName(slug, 'brands'), () => removeFilter(() => _selectedBrands.remove(slug))));
    }
    for (var slug in _selectedManufacturers) {
      if (widget.initialManufacturerSlug == slug) continue;
      chips.add(_buildChip(_lookupName(slug, 'manufacturers'), () => removeFilter(() => _selectedManufacturers.remove(slug))));
    }
    for (var slug in _selectedCategories) {
      if (widget.categorySlug == slug) continue;
      chips.add(_buildChip(_lookupName(slug, 'categories'), () => removeFilter(() => _selectedCategories.remove(slug))));
    }
    _selectedAttributes.forEach((group, items) {
      for (var itemSlug in items) {
        chips.add(_buildChip(_lookupAttributeName(group, itemSlug), () => removeFilter(() {
          _selectedAttributes[group]?.remove(itemSlug);
          if (_selectedAttributes[group]?.isEmpty ?? false) _selectedAttributes.remove(group);
        })));
      }
    });
    if (chips.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: containerBg,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(children: chips.map((c) => Padding(padding: const EdgeInsets.only(right: 8), child: c)).toList()),
      ),
    );
  }

  Widget _buildChip(String label, VoidCallback onDeleted) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final chipBg = isDark ? const Color(0xFF2A2A35) : Colors.grey[100];
    final textColor = isDark ? Colors.white : Colors.black;
    final iconColor = isDark ? Colors.white70 : Colors.black54;

    return Chip(
      label: Text(label, style: TextStyle(fontSize: 12, color: textColor)),
      backgroundColor: chipBg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      side: BorderSide.none,
      deleteIcon: Icon(Icons.close, size: 16, color: iconColor),
      onDeleted: onDeleted,
      visualDensity: VisualDensity.compact,
    );
  }

  void _openFilterModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => FilterModal(
        facets: _facets,
        selectedBrands: _selectedBrands,
        selectedManufacturers: _selectedManufacturers,
        selectedCategories: _selectedCategories,
        selectedAttributes: _selectedAttributes,
        onApply: (brands, manufs, cats, attrs) {
          setState(() {
            _selectedBrands = brands;
            _selectedManufacturers = manufs;
            _selectedCategories = cats;
            _selectedAttributes = attrs;
            products.clear();
            isLoading = true;
          });
          _fetchData(refresh: true);
        },
      ),
    );
  }

  void _onTabTapped(int index) {
    if (widget.isMainTab) return;

    setState(() {
      _localCurrentIndex = index;
    });

    if (index == widget.currentIndex) {
      Navigator.of(context).popUntil((route) => route.isFirst);
      return;
    }

    Navigator.pushNamedAndRemoveUntil(
      context,
      entryPointScreenRoute,
          (route) => false,
      arguments: index,
    );
  }

  // =========================================================
  // 📱 RESPONSIVE GRID DELEGATE
  // =========================================================
  Widget _buildGridDelegate({required int itemCount, required IndexedWidgetBuilder itemBuilder}) {
    double screenWidth = MediaQuery.of(context).size.width;

    int crossAxisCount;
    if (screenWidth > 900) {
      crossAxisCount = 4;
    } else if (screenWidth > 600) {
      crossAxisCount = 3;
    } else {
      crossAxisCount = 2;
    }

    double totalSpacing =  ((crossAxisCount - 1));
    double cardWidth = (screenWidth - totalSpacing) / crossAxisCount;
    double childAspectRatio = cardWidth / (cardWidth + 195);

    return GridView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: itemCount,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: childAspectRatio,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemBuilder: itemBuilder,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final Color scaffoldBg = Theme.of(context).scaffoldBackgroundColor;
    final Color appBarBg = isDark ? const Color(0xFF1C1C23) : Colors.white;
    final Color textColor = isDark ? Colors.white : Colors.black;
    final Color inputFill = isDark ? const Color(0xFF2A2A35) : const Color(0xFFF5F5F5);
    final Color hintColor = isDark ? Colors.white38 : Colors.grey[600]!;
    final Color loadingBg = isDark ? const Color(0xFF1C1C23) : Colors.white;
    final Color dividerColor = isDark ? Colors.white12 : Colors.grey.withOpacity(0.1);

    String noProductsText = "No products found";

    Widget? leadingIcon;
    if (widget.isMainTab) {
      leadingIcon = Builder(
        builder: (context) => IconButton(
          icon: Icon(Icons.menu_rounded, color: textColor),
          onPressed: () => Scaffold.of(context).openDrawer(),
        ),
      );
    } else {
      leadingIcon = IconButton(
        icon: Icon(Icons.arrow_back_ios_new, size: 20, color: textColor),
        onPressed: () => Navigator.canPop(context) ? Navigator.pop(context) : null,
      );
    }

    return Scaffold(
      backgroundColor: scaffoldBg,
      drawer: widget.isMainTab
          ? CustomEndDrawer(
        onLocaleChange: widget.onLocaleChange,
        user: widget.user,
        onTabChanged: widget.onTabChanged,
      )
          : null,

      // ✅ UPDATED PROFESSIONAL HEADER
      appBar: AppBar(
        backgroundColor: appBarBg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        // Hairline border
        shape: Border(bottom: BorderSide(color: dividerColor, width: 1)),

        leading: leadingIcon,
        automaticallyImplyLeading: false,

        title: Text(
          widget.title,
          style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.w700,
              fontSize: 17,
              letterSpacing: 0.5
          ),
        ),

        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: IconButton(
              icon: Stack(
                children: [
                  Icon(Icons.filter_list, color: textColor),
                  if (_selectedBrands.isNotEmpty || _selectedManufacturers.isNotEmpty || _selectedCategories.isNotEmpty || _selectedAttributes.isNotEmpty)
                    Positioned(
                      right: 0, top: 0,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                        constraints: const BoxConstraints(minWidth: 8, minHeight: 8),
                      ),
                    )
                ],
              ),
              onPressed: _openFilterModal,
            ),
          )
        ],
      ),

      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8), // Adjusted padding
            child: TextField(
              controller: _searchController,
              style: TextStyle(color: textColor),
              decoration: InputDecoration(
                hintText: AppLocalizations.of(context)!.search_for_title(widget.title),
                hintStyle: TextStyle(color: hintColor, fontSize: 14),
                prefixIcon: Icon(Icons.search, color: hintColor, size: 22),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                    icon: Icon(Icons.clear, color: hintColor, size: 20),
                    onPressed: () {
                      _searchController.clear();
                      _currentQuery = "";
                      products.clear();
                      isLoading = true;
                      setState(() {});
                      _fetchData(refresh: true);
                    })
                    : null,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                filled: true,
                fillColor: inputFill,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
              ),
            ),
          ),
          _buildActiveFilters(),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => _fetchData(refresh: true),
              color: primaryColor,
              backgroundColor: loadingBg,
              child: isLoading && products.isEmpty
                  ? _buildGridDelegate(
                itemCount: 6,
                itemBuilder: (ctx, i) => const ProductCardSkeleton(),
              )
                  : products.isEmpty
                  ? LayoutBuilder(
                builder: (context, constraints) => SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: Center(
                      child: Text(noProductsText, style: TextStyle(color: textColor)),
                    ),
                  ),
                ),
              )
                  : _buildGridDelegate(
                itemCount: products.length + (isLoadingMore ? 2 : 0),
                itemBuilder: (context, index) {
                  if (index >= products.length) {
                    return const ProductCardSkeleton();
                  }
                  final product = products[index];
                  // [UPDATED PRODUCT CARD CALL]
                  return ProductCard(
                    product: product,
                    press: () {
                      Navigator.pushNamed(
                          context,
                          productDetailsScreenRoute,
                          arguments: product.id
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: widget.isMainTab
          ? null
          : CustomBottomNavigationBar(
        currentIndex: _localCurrentIndex,
        onTap: _onTabTapped,
      ),
    );
  }
}