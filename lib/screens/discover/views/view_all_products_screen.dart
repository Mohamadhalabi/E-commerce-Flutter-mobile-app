import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shop/components/product/product_card.dart';
import 'package:shop/components/skleton/product/product_card_skelton.dart';
import 'package:shop/components/filter_modal.dart'; // Import Filter Modal
import 'package:shop/components/common/CustomBottomNavigationBar.dart'; // Import Bottom Nav
import 'package:shop/models/product_model.dart';
import 'package:shop/services/api_service.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../../route/route_constants.dart';

enum ProductListType { newArrival, flashSale, freeShipping, bundle, bestSeller }

class ViewAllProductsScreen extends StatefulWidget {
  final String title;
  final ProductListType type;

  const ViewAllProductsScreen({
    super.key,
    required this.title,
    required this.type,
  });

  @override
  State<ViewAllProductsScreen> createState() => _ViewAllProductsScreenState();
}

class _ViewAllProductsScreenState extends State<ViewAllProductsScreen> {
  // Data State
  List<ProductModel> products = [];
  bool isLoading = true;
  bool isLoadingMore = false;
  int currentPage = 0;
  int lastPage = 1;

  // Filter State
  List<String> _selectedBrands = [];
  List<String> _selectedManufacturers = [];
  List<String> _selectedCategories = [];
  Map<String, List<String>> _selectedAttributes = {};
  Map<String, dynamic> _facets = {}; // Stores available filters from API

  // Search State
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  String _currentQuery = "";

  // UI State
  late ScrollController _scrollController;
  int _currentIndex = 0; // Default to Home or specific tab

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_onScroll);
    _searchController.addListener(_onSearchChanged);

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

  // ---------------------------------------------------------------------------
  // 1. DATA FETCHING (Combined Logic)
  // ---------------------------------------------------------------------------
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
      // Determine flags based on enum
      bool isNew = widget.type == ProductListType.newArrival;
      bool isOffer = widget.type == ProductListType.flashSale;
      bool isFree = widget.type == ProductListType.freeShipping;
      bool isBundle = widget.type == ProductListType.bundle;

      // Default sort
      String sort = 'price_desc';
      if(isNew) sort = 'newest';

      final result = await ApiService.fetchCatalog(
        page: currentPage + 1,
        locale: locale,
        sort: sort,
        // Flags
        isNewArrival: isNew,
        isFlashSale: isOffer,
        isFreeShipping: isFree,
        isBundle: isBundle,
        // Filters & Search
        searchQuery: _currentQuery,
        selectedBrands: _selectedBrands,
        selectedManufacturers: _selectedManufacturers,
        selectedCategories: _selectedCategories,
        selectedAttributes: _selectedAttributes,
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
      debugPrint("Error fetching data: $e");
    } finally {
      setState(() {
        isLoading = false;
        isLoadingMore = false;
      });
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      _fetchData(refresh: false);
    }
  }

  // ---------------------------------------------------------------------------
  // 2. SEARCH & FILTER LOGIC
  // ---------------------------------------------------------------------------
  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      final query = _searchController.text.trim();
      if (query.isNotEmpty && query.length < 3) return;

      if (query != _currentQuery) {
        setState(() {
          _currentQuery = query;
          // Reset list when search changes
          products.clear();
          isLoading = true;
        });
        _fetchData(refresh: true);
      }
    });
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

  // Helper to get readable names for chips
  String _lookupName(String slug, String type) {
    List<dynamic> list = [];
    if (_facets.containsKey(type)) list = _facets[type] as List<dynamic>;
    final found = list.firstWhere((item) => item['slug'] == slug, orElse: () => null);
    return found != null ? found['name'] : slug;
  }

  // ---------------------------------------------------------------------------
  // 3. UI BUILDERS (Chips & Navigation)
  // ---------------------------------------------------------------------------
  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
    // Navigate to EntryPoint (Home) with the selected tab
    Navigator.pushNamedAndRemoveUntil(
      context,
      entryPointScreenRoute,
          (route) => false,
      arguments: index,
    );
  }

  Widget _buildActiveFilters() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
      chips.add(_buildChip(_lookupName(slug, 'brands'), () => removeFilter(() => _selectedBrands.remove(slug))));
    }
    for (var slug in _selectedManufacturers) {
      chips.add(_buildChip(_lookupName(slug, 'manufacturers'), () => removeFilter(() => _selectedManufacturers.remove(slug))));
    }

    if (chips.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: isDark ? const Color(0xFF1C1C23) : Colors.white,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(children: chips.map((c) => Padding(padding: const EdgeInsets.only(right: 8), child: c)).toList()),
      ),
    );
  }

  Widget _buildChip(String label, VoidCallback onDeleted) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Chip(
      label: Text(label, style: TextStyle(fontSize: 12, color: isDark ? Colors.white : Colors.black)),
      backgroundColor: isDark ? const Color(0xFF2A2A35) : Colors.grey[100],
      deleteIcon: Icon(Icons.close, size: 16, color: isDark ? Colors.white70 : Colors.black54),
      onDeleted: onDeleted,
      visualDensity: VisualDensity.compact,
      side: BorderSide.none,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    );
  }

  Widget _buildGridDelegate({required int itemCount, required IndexedWidgetBuilder itemBuilder}) {
    double screenWidth = MediaQuery.of(context).size.width;
    int crossAxisCount = screenWidth > 900 ? 4 : (screenWidth > 600 ? 3 : 2);

    double totalSpacing = 32.0 + ((crossAxisCount - 1) * 16.0);
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
    final Color textColor = isDark ? Colors.white : Colors.black;
    final Color inputFill = isDark ? const Color(0xFF2A2A35) : Colors.grey[200]!;
    final Color hintColor = isDark ? Colors.white38 : Colors.grey[600]!;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          // Filter Button in AppBar
          IconButton(
            icon: Stack(
              children: [
                const Icon(Icons.filter_list),
                if (_selectedBrands.isNotEmpty || _selectedManufacturers.isNotEmpty)
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
          // Search Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: TextField(
              controller: _searchController,
              style: TextStyle(color: textColor),
              decoration: InputDecoration(
                hintText: AppLocalizations.of(context)!.search_for_title(widget.title),
                hintStyle: TextStyle(color: hintColor),
                prefixIcon: Icon(Icons.search, color: hintColor),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                    icon: Icon(Icons.clear, color: hintColor),
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
              ),
            ),
          ),

          // Active Filter Chips
          _buildActiveFilters(),

          // Product Grid
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => _fetchData(refresh: true),
              child: isLoading && products.isEmpty
                  ? _buildGridDelegate(
                itemCount: 6,
                itemBuilder: (ctx, i) => const ProductCardSkeleton(),
              )
                  : products.isEmpty
                  ? Center(child: Text("No products found", style: TextStyle(color: textColor)))
                  : _buildGridDelegate(
                itemCount: products.length + (isLoadingMore ? 2 : 0),
                itemBuilder: (context, index) {
                  if (index >= products.length) {
                    return const ProductCardSkeleton();
                  }
                  final product = products[index];
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
      bottomNavigationBar: CustomBottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
      ),
    );
  }
}