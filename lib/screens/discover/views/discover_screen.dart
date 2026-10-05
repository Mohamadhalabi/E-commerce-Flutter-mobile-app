import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shop/components/product/product_card.dart';
import 'package:shop/constants.dart';
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
  bool _isInit = true;

  @override
  void initState() {
    super.initState();
    _loadLocalData();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _searchFocus.requestFocus();
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
    if (!mounted) return;
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
    } catch (e) {/* not JSON */}
    return rawTitle;
  }

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    final trimmed = query.trim();

    if (trimmed.length < 3) {
      setState(() {
        _suggestions = [];
        _isSearching = false;
      });
      return;
    }

    setState(() => _isSearching = true);

    _debounce = Timer(const Duration(milliseconds: 500), () async {
      if (!mounted) return;
      final locale = Localizations.localeOf(context).languageCode;
      try {
        final results = await ApiService.fetchSearchSuggestions(trimmed, locale);
        // Ignore late answers for an older query
        if (!mounted || _searchCtrl.text.trim() != trimmed) return;
        setState(() {
          _suggestions = results;
          _isSearching = false;
        });
      } catch (e) {
        if (mounted) setState(() => _isSearching = false);
      }
    });
  }

  void _onSubmitSearch(String query) {
    final trimmed = query.trim();
    if (trimmed.length < 3) return;
    LocalStorageService.addToSearchHistory(trimmed);
    _loadLocalData();
    Navigator.pushNamed(
      context,
      "sub_category_products_screen",
      arguments: {
        'searchQuery': trimmed,
        'title': trimmed,
        'currentIndex': 0,
        'user': null,
        'onTabChanged': (int i) {},
        'onLocaleChange': (String s) {},
      },
    );
  }

  void _searchFor(String text) {
    _searchCtrl.text = text;
    _searchCtrl.selection = TextSelection.collapsed(offset: text.length);
    _onSearchChanged(text);
  }

  @override
  Widget build(BuildContext context) {
    final query = _searchCtrl.text.trim();
    // Room so content can scroll above the floating nav bar
    final bottomPad = MediaQuery.paddingOf(context).bottom + 16;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        body: SafeArea(
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: Text(
                  'Search',
                  style: TextStyle(
                    color: AppPalette.text(context),
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.4,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: _buildSearchField(),
              ),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: query.isNotEmpty
                      ? KeyedSubtree(
                    key: const ValueKey('results'),
                    child: _buildResults(query, bottomPad),
                  )
                      : KeyedSubtree(
                    key: const ValueKey('idle'),
                    child: _buildIdle(bottomPad),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // SEARCH FIELD
  // ---------------------------------------------------------------------------
  Widget _buildSearchField() {
    final muted = AppPalette.textMuted(context);
    final radius = BorderRadius.circular(26);
    OutlineInputBorder border(Color color, [double width = 1]) =>
        OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide(color: color, width: width),
        );

    return TextField(
      controller: _searchCtrl,
      focusNode: _searchFocus,
      textInputAction: TextInputAction.search,
      onChanged: _onSearchChanged,
      onSubmitted: _onSubmitSearch,
      cursorColor: primaryColor,
      style: TextStyle(color: AppPalette.text(context), fontSize: 14.5),
      decoration: InputDecoration(
        hintText: 'Search products or SKU',
        hintStyle: TextStyle(color: muted, fontSize: 14),
        filled: true,
        fillColor: AppPalette.cardElevated(context),
        isDense: true,
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        prefixIcon: Icon(Icons.search_rounded, color: muted, size: 22),
        suffixIcon: _searchCtrl.text.isEmpty
            ? null
            : IconButton(
          tooltip: 'Clear',
          icon: Icon(Icons.close_rounded, size: 20, color: muted),
          onPressed: () {
            _searchCtrl.clear();
            _onSearchChanged('');
            _searchFocus.requestFocus();
          },
        ),
        border: border(AppPalette.border(context)),
        enabledBorder: border(AppPalette.border(context)),
        focusedBorder: border(primaryColor, 1.4),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // RESULTS (while typing)
  // ---------------------------------------------------------------------------
  Widget _buildResults(String query, double bottomPad) {
    if (query.length < 3) {
      return _MessageState(
        icon: Icons.keyboard_rounded,
        title: 'Keep typing',
        subtitle: 'Enter at least 3 characters to search.',
        bottomPad: bottomPad,
      );
    }

    if (_isSearching) {
      return ListView.separated(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: EdgeInsets.fromLTRB(16, 8, 16, bottomPad),
        itemCount: 6,
        separatorBuilder: (_, __) =>
            Divider(height: 1, color: AppPalette.border(context)),
        itemBuilder: (_, __) => const SearchResultSkeleton(),
      );
    }

    if (_suggestions.isEmpty) {
      return _MessageState(
        icon: Icons.search_off_rounded,
        title: 'No products match "$query"',
        subtitle: 'Check the spelling or search by SKU.',
        bottomPad: bottomPad,
      );
    }

    final shown = _suggestions.take(5).toList();

    return ListView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: EdgeInsets.fromLTRB(12, 4, 12, bottomPad),
      children: [
        _SeeAllRow(query: query, onTap: () => _onSubmitSearch(query)),
        const SizedBox(height: 4),
        for (var i = 0; i < shown.length; i++) ...[
          _SuggestionTile(
            product: shown[i],
            title: _cleanTitle(shown[i].title),
            onTap: () => Navigator.pushNamed(
              context,
              productDetailsScreenRoute,
              arguments: shown[i].id,
            ),
          ),
          if (i < shown.length - 1)
            Divider(
              height: 1,
              indent: 80,
              color: AppPalette.border(context),
            ),
        ],
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // IDLE (history + recently viewed)
  // ---------------------------------------------------------------------------
  Widget _buildIdle(double bottomPad) {
    if (_history.isEmpty && _recentProducts.isEmpty) {
      return _MessageState(
        icon: Icons.search_rounded,
        title: 'Find parts, tools and remotes',
        subtitle: 'Search by product name or SKU.',
        bottomPad: bottomPad,
        highlighted: true,
      );
    }

    final width = MediaQuery.sizeOf(context).width;
    final columns = width > 600 ? 4 : 2;
    // Same card proportions as the home screen: square image + ~180px content
    final cellWidth = (width - 20) / columns;
    final ratio = cellWidth / (cellWidth + 180);

    return ListView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: EdgeInsets.only(top: 4, bottom: bottomPad),
      children: [
        if (_history.isNotEmpty) ...[
          _SectionHeader(
            title: 'Recent searches',
            actionLabel: 'Clear all',
            onAction: () async {
              await LocalStorageService.clearSearchHistory();
              _loadLocalData();
            },
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final item in _history)
                  _HistoryChip(
                    label: item,
                    onTap: () => _searchFor(item),
                    onRemove: () async {
                      await LocalStorageService.removeFromHistory(item);
                      _loadLocalData();
                    },
                  ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
        if (_recentProducts.isNotEmpty) ...[
          const _SectionHeader(title: 'Recently viewed'),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 10),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columns,
              childAspectRatio: ratio,
            ),
            itemCount: _recentProducts.length,
            itemBuilder: (context, index) {
              final product = _recentProducts[index];
              return ProductCard(
                key: ValueKey(product.id),
                product: product,
                press: () => Navigator.pushNamed(
                  context,
                  productDetailsScreenRoute,
                  arguments: product.id,
                ),
              );
            },
          ),
        ],
      ],
    );
  }
}

// =============================================================================
// PIECES
// =============================================================================
class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.actionLabel, this.onAction});

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(20, 8, 8, 8),
      child: SizedBox(
        height: 36,
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: AppPalette.text(context),
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            if (actionLabel != null)
              TextButton(
                onPressed: onAction,
                style: TextButton.styleFrom(foregroundColor: primaryColor),
                child: Text(
                  actionLabel!,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _HistoryChip extends StatelessWidget {
  const _HistoryChip({
    required this.label,
    required this.onTap,
    required this.onRemove,
  });

  final String label;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final muted = AppPalette.textMuted(context);
    final shape = StadiumBorder(
      side: BorderSide(color: AppPalette.border(context)),
    );

    return Material(
      color: AppPalette.cardElevated(context),
      shape: shape,
      child: InkWell(
        customBorder: shape,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(12, 6, 4, 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.history_rounded, size: 15, color: muted),
              const SizedBox(width: 6),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 180),
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppPalette.text(context),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              InkResponse(
                onTap: onRemove,
                radius: 14,
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Icon(
                    Icons.close_rounded,
                    size: 14,
                    color: muted,
                    semanticLabel: 'Remove $label',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SeeAllRow extends StatelessWidget {
  const _SeeAllRow({required this.query, required this.onTap});

  final String query;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    return Material(
      color: primaryColor.withOpacity(AppPalette.isDark(context) ? 0.14 : 0.06),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                  color: primaryColor,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.search_rounded,
                    color: Colors.white, size: 19),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'See all results for "$query"',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppPalette.text(context),
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Icon(
                isRtl ? Icons.chevron_left_rounded : Icons.chevron_right_rounded,
                color: primaryColor,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SuggestionTile extends StatelessWidget {
  const _SuggestionTile({
    required this.product,
    required this.title,
    required this.onTap,
  });

  final ProductModel product;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = AppPalette.isDark(context);
    final hasSale = product.salePrice != null && product.salePrice! > 0;
    final price = hasSale ? product.salePrice! : product.price;
    final showOld = hasSale && product.price > price;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 64,
              height: 64,
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppPalette.border(context)),
              ),
              child: Image.network(
                product.image,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.image_not_supported_outlined,
                  size: 20,
                  color: blackColor20,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppPalette.text(context),
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      height: 1.3,
                    ),
                  ),
                  if (product.sku.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      "SKU: ${product.sku}",
                      style: TextStyle(
                        color: isDark ? Colors.green.shade400 : greenColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                  const SizedBox(height: 4),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        "\$${price.toStringAsFixed(2)}",
                        style: const TextStyle(
                          color: primaryColor,
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      if (showOld) ...[
                        const SizedBox(width: 6),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 1),
                          child: Text(
                            "\$${product.price.toStringAsFixed(2)}",
                            style: TextStyle(
                              color: Colors.grey.shade500,
                              fontSize: 11.5,
                              decoration: TextDecoration.lineThrough,
                              decorationColor: Colors.grey.shade500,
                            ),
                          ),
                        ),
                      ],
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
}

class _MessageState extends StatelessWidget {
  const _MessageState({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.bottomPad,
    this.highlighted = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final double bottomPad;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final muted = AppPalette.textMuted(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(32, 0, 32, bottomPad + 40),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: highlighted
                    ? primaryColor.withOpacity(0.08)
                    : AppPalette.cardElevated(context),
              ),
              child: Icon(
                icon,
                size: 32,
                color: highlighted ? primaryColor : muted,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppPalette.text(context),
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(color: muted, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

class SearchResultSkeleton extends StatelessWidget {
  const SearchResultSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: const Skeleton(width: 64, height: 64),
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
          ),
        ],
      ),
    );
  }
}