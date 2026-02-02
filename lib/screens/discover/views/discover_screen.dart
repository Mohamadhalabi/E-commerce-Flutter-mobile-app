import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shop/components/product/product_card.dart';
import 'package:shop/models/product_model.dart';
import 'package:shop/services/local_storage_service.dart';
import 'package:shop/services/api_service.dart';
import 'package:shop/route/route_constants.dart';

// Ensure this import points to your Skeleton file
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
  bool _isInit = true;

  @override
  void initState() {
    super.initState();
    _loadLocalData();
    // Auto-focus the search field when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _searchFocus.requestFocus();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isInit) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args != null && args is String && args.isNotEmpty) {
        _searchCtrl.text = args;
        _onSearchChanged(args);
      }
      _isInit = false;
    }
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

  String _cleanTitle(String rawTitle) {
    try {
      if (rawTitle.trim().startsWith('{') && rawTitle.contains('"en"')) {
        final Map<String, dynamic> json = jsonDecode(rawTitle);
        return json['en'] ?? rawTitle;
      }
    } catch (e) { }
    return rawTitle;
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();

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
    if (query.trim().length < 3) return;
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Custom Header Colors
    final Color inputBg = isDark ? const Color(0xFF2A2A35) : const Color(0xFFF5F5F5);
    final Color inputBorder = isDark ? Colors.white12 : Colors.transparent;
    final Color hintColor = isDark ? Colors.white38 : Colors.grey[500]!;

    bool isTyping = _searchCtrl.text.isNotEmpty;

    // ✅ FIXED: Using Scaffold again to provide 'Material' context, but with NO AppBar.
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // --- Custom Search Header ---
            Container(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                height: 50,
                child: TextField(
                  controller: _searchCtrl,
                  focusNode: _searchFocus,
                  textInputAction: TextInputAction.search,
                  onChanged: _onSearchChanged,
                  onSubmitted: _onSubmitSearch,
                  style: TextStyle(color: isDark ? Colors.white : Colors.black),
                  decoration: InputDecoration(
                    hintText: "Search products (min 3 chars)...",
                    hintStyle: TextStyle(color: hintColor, fontSize: 14),
                    filled: true,
                    fillColor: inputBg,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                    prefixIcon: Icon(Icons.search, color: hintColor),
                    suffixIcon: _searchCtrl.text.isNotEmpty
                        ? IconButton(
                      icon: Icon(Icons.close, size: 20, color: hintColor),
                      onPressed: () {
                        _searchCtrl.clear();
                        _onSearchChanged("");
                      },
                    )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: inputBorder),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFF37A20), width: 1.5),
                    ),
                  ),
                ),
              ),
            ),

            // --- Body Content ---
            Expanded(
              child: isTyping
                  ? _buildSearchResults(isDark)
                  : _buildHistoryAndRecents(isDark),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchResults(bool isDark) {
    final Color textColor = isDark ? Colors.white : Colors.black;
    final Color skuColor = isDark ? Colors.greenAccent : Colors.green;
    final Color dividerColor = isDark ? Colors.white12 : const Color(0xFFEEEEEE);
    final Color imgBg = isDark ? Colors.white : Colors.white;

    if (_isSearching) {
      return ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: 6,
        separatorBuilder: (_, __) => Divider(height: 1, color: dividerColor),
        itemBuilder: (_, __) => const SearchResultSkeleton(),
      );
    }

    if (_suggestions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: isDark ? Colors.white38 : Colors.grey),
            const SizedBox(height: 16),
            Text("No results found", style: TextStyle(color: isDark ? Colors.white38 : Colors.grey)),
          ],
        ),
      );
    }

    final int displayCount = _suggestions.length > 5 ? 5 : _suggestions.length;
    final bool showMore = _suggestions.length > 5;

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        ...List.generate(displayCount, (index) {
          final product = _suggestions[index];
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
                    color: imgBg,
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
                  _cleanTitle(product.title),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, height: 1.2, color: textColor),
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (product.sku.isNotEmpty)
                        Text(
                          "SKU: ${product.sku}",
                          style: TextStyle(
                              color: skuColor,
                              fontSize: 12,
                              fontWeight: FontWeight.bold
                          ),
                        ),
                      const SizedBox(height: 4),
                      Text(
                        "\$${displayPrice.toStringAsFixed(2)}",
                        style: const TextStyle(
                          color: Color(0xFFFF3B30),
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
              Divider(height: 1, color: dividerColor),
            ],
          );
        }),

        if (showMore)
          Padding(
            padding: const EdgeInsets.only(top: 16, bottom: 20),
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
                  backgroundColor: isDark ? const Color(0xFF2A2A35) : Colors.white,
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

  Widget _buildHistoryAndRecents(bool isDark) {
    final Color textColor = isDark ? Colors.white : Colors.black;
    final Color subTextColor = isDark ? Colors.white70 : Colors.black87;
    final Color iconColor = isDark ? Colors.white38 : Colors.grey;
    final Color dividerColor = isDark ? Colors.white12 : const Color(0xFFF9F9F9);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_history.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Recent Searches", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: textColor)),
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
                  leading: Icon(Icons.history, size: 22, color: iconColor),
                  title: Text(item, style: TextStyle(fontSize: 14, color: subTextColor)),
                  trailing: IconButton(
                    icon: Icon(Icons.close, size: 18, color: iconColor),
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
            Divider(thickness: 6, color: dividerColor),
          ],

          if (_recentProducts.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Text("Recently Viewed", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: textColor)),
            ),
            SizedBox(
              height: 340,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                scrollDirection: Axis.horizontal,
                itemCount: _recentProducts.length,
                separatorBuilder: (_, __) => const SizedBox(width: 16),
                itemBuilder: (context, index) {
                  final product = _recentProducts[index];
                  return SizedBox(
                    width: 150,
                    child: ProductCard(
                      product: product,
                      press: () {
                        Navigator.pushNamed(context, productDetailsScreenRoute, arguments: product.id);
                      },
                    ),
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

class SearchResultSkeleton extends StatelessWidget {
  const SearchResultSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
                Skeleton(width: 80, height: 12),
                SizedBox(height: 6),
                Skeleton(width: 60, height: 14),
              ],
            ),
          )
        ],
      ),
    );
  }
}