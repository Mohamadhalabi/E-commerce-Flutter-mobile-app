import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shop/components/product/product_card.dart';
import 'package:shop/models/product_model.dart';
import 'package:shop/services/api_service.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class SubCategoryProductsScreen extends StatefulWidget {
  final int subCategoryId;
  final String title;
  final int currentIndex;
  final Map<String, dynamic>? user;
  final Function(int) onTabChanged;
  final Function(String) onLocaleChange;

  const SubCategoryProductsScreen({
    super.key,
    required this.subCategoryId,
    required this.title,
    required this.currentIndex,
    required this.user,
    required this.onTabChanged,
    required this.onLocaleChange,
  });

  @override
  State<SubCategoryProductsScreen> createState() => _SubCategoryProductsScreenState();
}

class _SubCategoryProductsScreenState extends State<SubCategoryProductsScreen> {
  List<ProductModel> products = [];
  List<ProductModel> searchResults = [];
  bool isLoadingMore = false;
  int currentPage = 0;
  int lastPage = 1;
  late ScrollController _scrollController;
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  bool isSearching = false;
  bool _isInit = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_onScroll);
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInit) {
      final locale = Localizations.localeOf(context).languageCode;
      loadMoreProducts(locale);
      _isInit = true;
    }
  }

  Future<void> loadMoreProducts(String locale) async {
    if (isLoadingMore || currentPage >= lastPage) return;

    setState(() => isLoadingMore = true);

    try {
      final result = await ApiService.fetchProductsBySubcategory(
        widget.subCategoryId,
        locale,
        page: currentPage + 1,
      );

      setState(() {
        products.addAll(result['products']);
        currentPage = (result['current_page'] as num).toInt();
        lastPage = (result['last_page'] as num).toInt();
      });
    } catch (e) {
      debugPrint("Error fetching products: $e");
    } finally {
      setState(() => isLoadingMore = false);
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 300) {
      if (!isLoadingMore && currentPage < lastPage && !isSearching) {
        final locale = Localizations.localeOf(context).languageCode;
        loadMoreProducts(locale);
      }
    }
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    _debounce = Timer(const Duration(milliseconds: 400), () {
      final query = _searchController.text.trim();
      if (query.length > 3) {
        final locale = Localizations.localeOf(context).languageCode;
        _performLiveSearch(query, locale);
      } else {
        setState(() {
          isSearching = false;
          searchResults.clear();
        });
      }
    });
  }

  Future<void> _performLiveSearch(String query, String locale) async {
    setState(() {
      isSearching = true;
      isLoadingMore = false;
    });

    try {
      final result = await ApiService.searchSubCategoryProducts(
        widget.subCategoryId,
        query,
        locale,
      );
      setState(() {
        searchResults = result;
      });
    } catch (e) {
      debugPrint("❌ Search error: $e");
    }
  }

  void _onTabTapped(int index) {
    widget.onTabChanged(index);
    Navigator.pop(context);
  }

  Widget _buildGrid(List<ProductModel> items) {
    if (items.isEmpty) {
      return const Center(child: Text("No products found"));
    }

    return GridView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: items.length + (isLoadingMore && !isSearching ? 1 : 0),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.47,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemBuilder: (context, index) {
        if (index >= items.length) {
          return const Center(child: CircularProgressIndicator());
        }

        final product = items[index];

        return ProductCard(
          id: product.id ?? 0,
          image: product.image,
          category: product.category,
          title: product.title,
          price: product.price,
          salePrice: product.salePrice,
          sku: product.sku,
          rating: product.rating,
          discount: product.discount,
          freeShipping: product.freeShipping,
          press: () {
            Navigator.pushNamed(
              context,
              '/product-details',
              arguments: product.id,
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
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
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Theme.of(context).brightness == Brightness.dark
                    ? Colors.grey[800]
                    : Colors.grey[200],
              ),
            ),
          ),
          Expanded(
            child: isSearching ? _buildGrid(searchResults) : _buildGrid(products),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: widget.currentIndex,
        onTap: _onTabTapped,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.blue,
        selectedFontSize: 12,
        backgroundColor: Theme.of(context).brightness == Brightness.light
            ? Colors.white
            : const Color(0xFF101015),
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.home),
            label: AppLocalizations.of(context)!.home,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.search),
            label: AppLocalizations.of(context)!.search,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.store),
            label: AppLocalizations.of(context)!.shop,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.shopping_cart),
            label: AppLocalizations.of(context)!.cart,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.person),
            label: AppLocalizations.of(context)!.profile,
          ),
        ],
      ),
    );
  }
}