import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shop/components/product/product_card.dart';
import 'package:shop/models/product_model.dart';
import 'package:shop/services/local_storage_service.dart';
import 'package:shop/services/api_service.dart';
import 'package:shop/route/route_constants.dart';

import '../../../components/skleton/skeleton.dart';

class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({super.key});

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  final FocusNode _searchFocus = FocusNode();

  List<String> _history = [];
  List<ProductModel> _recentProducts = [];

  List<ProductModel> _suggestions = [];
  bool _isSearching = false;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _loadLocalData();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _searchFocus.requestFocus();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _searchFocus.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _loadLocalData() async {
    final history = await LocalStorageService.getSearchHistory();
    final recents = await LocalStorageService.getRecentlyViewed();
    setState(() {
      _history = history;
      _recentProducts = recents;
    });
  }

  // ✅ HELPER: Clean the Title (Remove {"en": ...})
  String _cleanTitle(String rawTitle) {
    try {
      if (rawTitle.trim().startsWith('{') && rawTitle.contains('"en"')) {
        final Map<String, dynamic> json = jsonDecode(rawTitle);
        return json['en'] ?? rawTitle;
      }
    } catch (e) {
      // If parsing fails, return original
    }
    return rawTitle;
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    // ✅ 1. CHECK: Only search if length >= 3
    if (query.trim().length < 3) {
      setState(() {
        _suggestions = [];
        _isSearching = false;
      });
      return;
    }

    setState(() => _isSearching = true);

    _debounce = Timer(const Duration(milliseconds: 500), () async {
      final locale = Localizations.localeOf(context).languageCode;
      try {
        final results = await ApiService.fetchSearchSuggestions(query, locale);
        if (mounted) {
          setState(() {
            _suggestions = results;
            _isSearching = false;
          });
        }
      } catch (e) {
        if (mounted) setState(() => _isSearching = false);
      }
    });
  }

  void _onSubmitSearch(String query) {
    if (query.trim().length < 3) return; // Enforce limit on submit too
    LocalStorageService.addToSearchHistory(query);
    _loadLocalData();
    Navigator.pushNamed(
        context,
        "sub_category_products_screen",
        arguments: {
          'searchQuery': query,
          'title': query,
          'currentIndex': 0,
          'user': null,
          'onTabChanged': (int i) {},
          'onLocaleChange': (String s) {},
        }
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isTyping = _searchCtrl.text.isNotEmpty;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // --- SEARCH HEADER ---
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
              ),
              child: Row(
                children: [
                  InkWell(
                    onTap: () => Navigator.pop(context),
                    borderRadius: BorderRadius.circular(20),
                    child: const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Icon(Icons.arrow_back, color: Colors.black),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: SizedBox(
                      height: 45,
                      child: TextField(
                        controller: _searchCtrl,
                        focusNode: _searchFocus,
                        textInputAction: TextInputAction.search,
                        onChanged: _onSearchChanged,
                        onSubmitted: _onSubmitSearch,
                        decoration: InputDecoration(
                          hintText: "Search products (min 3 chars)...",
                          hintStyle: TextStyle(color: Colors.grey[500], fontSize: 14),
                          filled: true,
                          fillColor: const Color(0xFFF5F5F5),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                          prefixIcon: null,
                          suffixIcon: _searchCtrl.text.isNotEmpty
                              ? IconButton(
                            icon: const Icon(Icons.close, size: 20, color: Colors.grey),
                            onPressed: () {
                              _searchCtrl.clear();
                              _onSearchChanged("");
                            },
                          )
                              : const Icon(Icons.search, color: Colors.grey),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFFF37A20), width: 1.5),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // --- BODY ---
            Expanded(
              child: isTyping
                  ? _buildSearchResults()
                  : _buildHistoryAndRecents(),
            ),
          ],
        ),
      ),
    );
  }

  // --- WIDGET: SEARCH RESULTS ---
  Widget _buildSearchResults() {
    // ✅ 4. SKELETON LOADER
    if (_isSearching) {
      return ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: 6,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (_, __) => const SearchResultSkeleton(),
      );
    }

    if (_suggestions.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text("No results found", style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    final int displayCount = _suggestions.length > 5 ? 5 : _suggestions.length;
    final bool showMore = _suggestions.length > 5;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ...List.generate(displayCount, (index) {
          final product = _suggestions[index];

          // Logic for Price (Red if sale)
          final bool hasSale = product.salePrice != null && product.salePrice! > 0;
          final double displayPrice = hasSale ? product.salePrice! : product.price;

          return Column(
            children: [
              ListTile(
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
                leading: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.white,
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      product.image,
                      fit: BoxFit.contain,
                      errorBuilder: (_,__,___) => const Icon(Icons.image_not_supported, size: 20, color: Colors.grey),
                    ),
                  ),
                ),
                title: Text(
                  _cleanTitle(product.title), // ✅ Clean Title
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, height: 1.2),
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ✅ 3. SKU IN GREEN
                      if (product.sku.isNotEmpty)
                        Text(
                          "SKU: ${product.sku}",
                          style: const TextStyle(
                              color: Colors.green,
                              fontSize: 12,
                              fontWeight: FontWeight.bold
                          ),
                        ),
                      const SizedBox(height: 4),
                      // ✅ 2. PRICE IN RED
                      Text(
                        "\$${displayPrice.toStringAsFixed(2)}",
                        style: const TextStyle(
                          color: Color(0xFFFF3B30), // Red Color
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),
                onTap: () {
                  Navigator.pushNamed(context, productDetailsScreenRoute, arguments: product.id);
                },
              ),
              const Divider(height: 1, color: Color(0xFFEEEEEE)),
            ],
          );
        }),

        if (showMore)
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(
                      context,
                      "sub_category_products_screen",
                      arguments: {
                        'searchQuery': _searchCtrl.text,
                        'title': _searchCtrl.text,
                        'currentIndex': 0,
                        'user': null,
                        'onTabChanged': (int i) {},
                        'onLocaleChange': (String s) {},
                      }
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFFF37A20),
                  elevation: 0,
                  side: const BorderSide(color: Color(0xFFF37A20)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: Text(
                  "Show all results for \"${_searchCtrl.text}\"",
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
      ],
    );
  }

  // --- WIDGET: HISTORY & RECENTLY VIEWED ---
  Widget _buildHistoryAndRecents() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_history.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Recent Searches", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  TextButton(
                    onPressed: () async {
                      await LocalStorageService.clearSearchHistory();
                      _loadLocalData();
                    },
                    child: const Text("Clear all", style: TextStyle(color: Colors.red, fontSize: 12)),
                  )
                ],
              ),
            ),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _history.length,
              itemBuilder: (context, index) {
                final item = _history[index];
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                  leading: const Icon(Icons.history, size: 22, color: Colors.grey),
                  title: Text(item, style: const TextStyle(fontSize: 14)),
                  trailing: IconButton(
                    icon: const Icon(Icons.close, size: 18, color: Colors.grey),
                    onPressed: () async {
                      await LocalStorageService.removeFromHistory(item);
                      _loadLocalData();
                    },
                  ),
                  onTap: () {
                    _searchCtrl.text = item;
                    _onSearchChanged(item);
                  },
                );
              },
            ),
            const Divider(thickness: 6, color: Color(0xFFF9F9F9)),
          ],

          if (_recentProducts.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Text("Recently Viewed", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
            SizedBox(
              height: 410, // Matches ProductCard Height
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                scrollDirection: Axis.horizontal,
                itemCount: _recentProducts.length,
                separatorBuilder: (_, __) => const SizedBox(width: 16),
                itemBuilder: (context, index) {
                  final product = _recentProducts[index];
                  // Use _cleanTitle here too if Recent Products are saved with raw JSON
                  return ProductCard(
                    id: product.id,
                    image: product.image,
                    category: "Recent",
                    title: _cleanTitle(product.title), // Applied clean here too
                    price: product.price,
                    salePrice: product.salePrice ?? 0.0,
                    sku: product.sku,
                    rating: product.rating,
                    discount: product.discount,
                    freeShipping: product.freeShipping,
                    press: () {
                      Navigator.pushNamed(context, productDetailsScreenRoute, arguments: product.id);
                    },
                  );
                },
              ),
            ),
          ]
        ],
      ),
    );
  }
}

// --- LOCAL SKELETON WIDGET ---
class SearchResultSkeleton extends StatelessWidget {
  const SearchResultSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ✅ FIX: Use ClipRRect for radius instead of passing it to Skeleton
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: const Skeleton(width: 60, height: 60),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Skeleton(width: double.infinity, height: 14),
                SizedBox(height: 6),
                Skeleton(width: 150, height: 14),
                SizedBox(height: 8),
                Skeleton(width: 80, height: 12), // SKU
                SizedBox(height: 6),
                Skeleton(width: 60, height: 14), // Price
              ],
            ),
          )
        ],
      ),
    );
  }
}