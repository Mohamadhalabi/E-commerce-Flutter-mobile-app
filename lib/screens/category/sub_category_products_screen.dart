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

  // Flag to know if this is the Main "Shop" Tab
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
      color: Colors.white,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(children: chips.map((c) => Padding(padding: const EdgeInsets.only(right: 8), child: c)).toList()),
      ),
    );
  }

  Widget _buildChip(String label, VoidCallback onDeleted) {
    return Chip(
      label: Text(label, style: const TextStyle(fontSize: 12)),
      backgroundColor: Colors.grey[100],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      side: BorderSide.none,
      deleteIcon: const Icon(Icons.close, size: 16, color: Colors.black54),
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
    // If it's the main tab, we let the MainScaffold handle navigation, so we do nothing here
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

  Widget _buildGridDelegate({required int itemCount, required IndexedWidgetBuilder itemBuilder}) {
    return GridView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: itemCount,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.45,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemBuilder: itemBuilder,
    );
  }

  @override
  Widget build(BuildContext context) {
    String noProductsText = "No products found";

    // ✅ 1. Determine Leading Icon (Menu vs Back)
    Widget? leadingIcon;
    if (widget.isMainTab) {
      leadingIcon = Builder(
        builder: (context) => IconButton(
          icon: const Icon(Icons.menu_rounded, color: Colors.black),
          onPressed: () => Scaffold.of(context).openDrawer(),
        ),
      );
    } else {
      leadingIcon = IconButton(
        icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black),
        onPressed: () => Navigator.canPop(context) ? Navigator.pop(context) : null,
      );
    }

    return Scaffold(
      // ✅ 2. Show drawer only if this is the Main Tab
      drawer: widget.isMainTab
          ? CustomEndDrawer(
        onLocaleChange: widget.onLocaleChange,
        user: widget.user,
        onTabChanged: widget.onTabChanged,
      )
          : null,

      appBar: AppBar(
        title: Text(widget.title),
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.white,
        leading: leadingIcon, // Use logic from above
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: Stack(
              children: [
                const Icon(Icons.filter_list),
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
          )
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: AppLocalizations.of(context)!.search_for_title(widget.title),
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _searchController.clear();
                      _currentQuery = "";
                      products.clear();
                      isLoading = true;
                      setState(() {});
                      _fetchData(refresh: true);
                    })
                    : null,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Theme.of(context).brightness == Brightness.dark
                    ? Colors.grey[800]
                    : Colors.grey[200],
              ),
            ),
          ),
          _buildActiveFilters(),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => _fetchData(refresh: true),
              color: primaryColor,
              backgroundColor: Colors.white,
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
                    child: Center(child: Text(noProductsText)),
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
                  return ProductCard(
                    id: product.id,
                    image: product.image,
                    category: widget.title,
                    title: product.title,
                    price: product.price,
                    salePrice: product.salePrice ?? 0.0,
                    sku: product.sku,
                    rating: product.rating,
                    discount: product.discount,
                    freeShipping: product.freeShipping,
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
      // ✅ 3. HIDE Bottom Navigation Bar if this is the Main Tab
      // because the MainScaffold already has one.
      bottomNavigationBar: widget.isMainTab
          ? null
          : CustomBottomNavigationBar(
        currentIndex: _localCurrentIndex,
        onTap: _onTabTapped,
      ),
    );
  }
}