import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:shop/components/common/CustomBottomNavigationBar.dart';
import 'package:shop/components/common/drawer.dart';
import 'package:shop/components/filter_modal.dart';
import 'package:shop/components/product/product_card.dart';
import 'package:shop/components/skleton/product/product_card_skelton.dart';
import 'package:shop/constants.dart';
import 'package:shop/models/product_model.dart';
import 'package:shop/route/route_constants.dart';
import 'package:shop/services/api_service.dart';

// -----------------------------------------------------------------------------
// SORT OPTIONS — `value` is what the API receives as ?sort=
// If your Laravel controller uses different names, change them here only.
// -----------------------------------------------------------------------------
class _SortOption {
  const _SortOption(this.value, this.label, this.shortLabel, this.icon);
  final String value;
  final String label;
  final String shortLabel;
  final IconData icon;
}

const List<_SortOption> _sortOptions = [
  _SortOption('newest', 'Newest first', 'Newest', Icons.fiber_new_outlined),
  _SortOption('oldest', 'Oldest first', 'Oldest', Icons.history_rounded),
  _SortOption('price_asc', 'Price: low to high', 'Price ↑', Icons.arrow_upward_rounded),
  _SortOption('price_desc', 'Price: high to low', 'Price ↓', Icons.arrow_downward_rounded),
];

const String _defaultSort = 'newest';

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
  int? _total;

  String _sort = _defaultSort;
  int _requestId = 0; // ignores answers from outdated requests

  late final ScrollController _scrollController;
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

    _resetFiltersToInitial();

    if (widget.searchQuery != null && widget.searchQuery!.isNotEmpty) {
      _currentQuery = widget.searchQuery!;
      _searchController.text = widget.searchQuery!;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _fetchData(refresh: true);
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
  // DATA
  // ---------------------------------------------------------------------------
  void _resetFiltersToInitial() {
    _selectedBrands = [if (widget.initialBrandSlug != null) widget.initialBrandSlug!];
    _selectedManufacturers = [
      if (widget.initialManufacturerSlug != null) widget.initialManufacturerSlug!
    ];
    _selectedCategories = [if (widget.categorySlug.isNotEmpty) widget.categorySlug];
    _selectedAttributes = {};
  }

  Future<void> _fetchData({bool refresh = false}) async {
    if (!refresh && (isLoading || isLoadingMore || currentPage >= lastPage)) return;

    final locale = Localizations.localeOf(context).languageCode;
    final requestId = ++_requestId;

    setState(() {
      if (refresh) {
        isLoading = true;
      } else {
        isLoadingMore = true;
      }
    });

    try {
      final result = await ApiService.fetchCatalog(
        categorySlug: widget.categorySlug,
        searchQuery: _currentQuery,
        selectedBrands: _selectedBrands,
        selectedManufacturers: _selectedManufacturers,
        selectedCategories: _selectedCategories,
        selectedAttributes: _selectedAttributes,
        page: refresh ? 1 : currentPage + 1,
        locale: locale,
        sort: _sort,
      );
      if (!mounted || requestId != _requestId) return;

      setState(() {
        final newProducts = List<ProductModel>.from(result['products']);
        if (refresh) {
          products = newProducts;
          if (result['facets'] != null) _facets = result['facets'];
        } else {
          products.addAll(newProducts);
        }
        currentPage = (result['current_page'] as num?)?.toInt() ?? 1;
        lastPage = (result['last_page'] as num?)?.toInt() ?? 1;
        _total = (result['total'] as num?)?.toInt();
      });
    } catch (e) {
      debugPrint("Error fetching catalog: $e");
    } finally {
      if (mounted && requestId == _requestId) {
        setState(() {
          isLoading = false;
          isLoadingMore = false;
        });
      }
    }
  }

  /// Clears the grid and loads page 1 again (after a filter/sort/search change).
  void _reload() {
    setState(() {
      products = [];
      _total = null;
    });
    if (_scrollController.hasClients) _scrollController.jumpTo(0);
    _fetchData(refresh: true);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 300) {
      _fetchData(refresh: false);
    }
  }

  void _onSearchChanged() {
    if (mounted) setState(() {}); // show/hide the clear (✕) button
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      final query = _searchController.text.trim();
      if (query.isNotEmpty && query.length < 3) return;
      if (query == _currentQuery) return;

      _currentQuery = query;
      _resetFiltersToInitial();
      _reload();
    });
  }

  // ---------------------------------------------------------------------------
  // FILTERS & SORT
  // ---------------------------------------------------------------------------
  /// Filters the user picked (the screen's own category/brand doesn't count).
  int get _activeFilterCount {
    var n = 0;
    n += _selectedBrands.where((s) => s != widget.initialBrandSlug).length;
    n += _selectedManufacturers.where((s) => s != widget.initialManufacturerSlug).length;
    n += _selectedCategories.where((s) => s != widget.categorySlug).length;
    _selectedAttributes.forEach((_, v) => n += v.length);
    return n;
  }

  void _clearAllFilters() {
    _resetFiltersToInitial();
    _reload();
  }

  String _lookupName(String slug, String type) {
    final list = (_facets[type] as List<dynamic>?) ?? const [];
    final found = list.firstWhere((item) => item['slug'] == slug, orElse: () => null);
    return found != null ? found['name'].toString() : slug;
  }

  String _lookupAttributeName(String groupSlug, String itemSlug) {
    final attrList = (_facets['attributes'] as List<dynamic>?) ?? const [];
    final group = attrList.firstWhere((g) => g['slug'] == groupSlug, orElse: () => null);
    if (group != null) {
      final items = group['items'] as List<dynamic>;
      final item = items.firstWhere((i) => i['slug'] == itemSlug, orElse: () => null);
      if (item != null) return "${group['name']}: ${item['name']}";
    }
    return itemSlug;
  }

  void _openFilterModal() {
    String primaryType = 'categories';
    if (widget.initialBrandSlug != null && widget.initialBrandSlug!.isNotEmpty) {
      primaryType = 'brands';
    } else if (widget.initialManufacturerSlug != null &&
        widget.initialManufacturerSlug!.isNotEmpty) {
      primaryType = 'manufacturers';
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => FilterModal(
        primaryFilterType: primaryType,
        facets: _facets,
        selectedBrands: _selectedBrands,
        selectedManufacturers: _selectedManufacturers,
        selectedCategories: _selectedCategories,
        selectedAttributes: _selectedAttributes,
        onApply: (brands, manufs, cats, attrs) {
          _selectedBrands = brands;
          _selectedManufacturers = manufs;
          _selectedCategories = cats;
          _selectedAttributes = attrs..removeWhere((_, v) => v.isEmpty);
          _reload();
        },
      ),
    );
  }

  void _openSortSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppPalette.card(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppPalette.border(context),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                "Sort by",
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: AppPalette.text(context),
                ),
              ),
              const SizedBox(height: 12),
              for (final option in _sortOptions)
                _SortRow(
                  option: option,
                  selected: option.value == _sort,
                  onTap: () {
                    Navigator.pop(sheetContext);
                    if (option.value == _sort) return;
                    _sort = option.value;
                    _reload();
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _onTabTapped(int index) {
    if (widget.isMainTab) return;
    setState(() => _localCurrentIndex = index);

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

  // ---------------------------------------------------------------------------
  // BUILD
  // ---------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final bg = Theme.of(context).scaffoldBackgroundColor;

    return Scaffold(
      backgroundColor: bg,
      extendBody: !widget.isMainTab,
      drawer: widget.isMainTab
          ? CustomEndDrawer(
        onLocaleChange: widget.onLocaleChange,
        user: widget.user,
        onTabChanged: widget.onTabChanged,
      )
          : null,
      appBar: AppBar(
        backgroundColor: bg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
        leadingWidth: 64,
        leading: Padding(
          padding: const EdgeInsetsDirectional.only(start: defaultPadding),
          child: Center(
            child: widget.isMainTab
                ? Builder(
              builder: (ctx) => _RoundButton(
                icon: Icons.menu_rounded,
                iconSize: 21,
                semanticLabel: 'Menu',
                onTap: () => Scaffold.of(ctx).openDrawer(),
              ),
            )
                : _RoundButton(
              icon: Icons.arrow_back_ios_new_rounded,
              semanticLabel: 'Back',
              onTap: () => Navigator.maybePop(context),
            ),
          ),
        ),
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: AppPalette.text(context),
                fontWeight: FontWeight.w800,
                fontSize: 17,
              ),
            ),
            if (_total != null)
              Text(
                "$_total ${_total == 1 ? 'product' : 'products'}",
                style: TextStyle(
                  color: AppPalette.textMuted(context),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
          ],
        ),
      ),
      bottomNavigationBar: widget.isMainTab
          ? null
          : CustomBottomNavigationBar(
        currentIndex: _localCurrentIndex,
        onTap: _onTabTapped,
      ),
      body: Builder(
        // context INSIDE the body, so the bottom padding includes the nav
        builder: (bodyContext) {
          final bottomPad = MediaQuery.paddingOf(bodyContext).bottom + 16;
          return Column(
            children: [
              _buildSearchRow(),
              _buildActiveFilters(),
              Expanded(child: _buildBody(bottomPad)),
            ],
          );
        },
      ),
    );
  }

  /// Search + Sort + Filter in a single row.
  Widget _buildSearchRow() {
    final muted = AppPalette.textMuted(context);
    final radius = BorderRadius.circular(24);
    OutlineInputBorder border(Color c, [double w = 1]) =>
        OutlineInputBorder(borderRadius: radius, borderSide: BorderSide(color: c, width: w));

    final sort = _sortOptions.firstWhere(
          (o) => o.value == _sort,
      orElse: () => _sortOptions.first,
    );
    final filterCount = _activeFilterCount;

    return Padding(
      padding: const EdgeInsets.fromLTRB(defaultPadding, 4, defaultPadding, 8),
      child: Row(
        children: [
          Expanded(
            child: SizedBox(
              height: 46,
              child: TextField(
                controller: _searchController,
                cursorColor: primaryColor,
                textInputAction: TextInputAction.search,
                style: TextStyle(color: AppPalette.text(context), fontSize: 14.5),
                decoration: InputDecoration(
                  hintText: AppLocalizations.of(context)!.search_for_title(widget.title),
                  hintStyle: TextStyle(color: muted, fontSize: 14),
                  prefixIcon: Icon(Icons.search_rounded, color: muted, size: 21),
                  suffixIcon: _searchController.text.isEmpty
                      ? null
                      : IconButton(
                    tooltip: 'Clear',
                    icon: Icon(Icons.close_rounded, color: muted, size: 19),
                    onPressed: () => _searchController.clear(),
                  ),
                  filled: true,
                  fillColor: AppPalette.cardElevated(context),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14),
                  border: border(AppPalette.border(context)),
                  enabledBorder: border(AppPalette.border(context)),
                  focusedBorder: border(primaryColor, 1.4),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          _IconToolbarButton(
            icon: Icons.swap_vert_rounded,
            tooltip: "Sort: ${sort.label}",
            active: _sort != _defaultSort,
            onTap: _openSortSheet,
          ),
          const SizedBox(width: 8),
          _IconToolbarButton(
            icon: Icons.tune_rounded,
            tooltip: filterCount > 0 ? "Filters ($filterCount)" : "Filters",
            active: filterCount > 0,
            count: filterCount,
            onTap: _openFilterModal,
          ),
        ],
      ),
    );
  }

  Widget _buildActiveFilters() {
    final chips = <Widget>[];

    void remove(VoidCallback action) {
      action();
      _reload();
    }

    for (final slug in List<String>.from(_selectedBrands)) {
      if (widget.initialBrandSlug == slug) continue;
      chips.add(_FilterChip(
        label: _lookupName(slug, 'brands'),
        onRemove: () => remove(() => _selectedBrands.remove(slug)),
      ));
    }
    for (final slug in List<String>.from(_selectedManufacturers)) {
      if (widget.initialManufacturerSlug == slug) continue;
      chips.add(_FilterChip(
        label: _lookupName(slug, 'manufacturers'),
        onRemove: () => remove(() => _selectedManufacturers.remove(slug)),
      ));
    }
    for (final slug in List<String>.from(_selectedCategories)) {
      if (widget.categorySlug == slug) continue;
      chips.add(_FilterChip(
        label: _lookupName(slug, 'categories'),
        onRemove: () => remove(() => _selectedCategories.remove(slug)),
      ));
    }
    _selectedAttributes.forEach((group, items) {
      for (final itemSlug in List<String>.from(items)) {
        chips.add(_FilterChip(
          label: _lookupAttributeName(group, itemSlug),
          onRemove: () => remove(() {
            _selectedAttributes[group]?.remove(itemSlug);
            if (_selectedAttributes[group]?.isEmpty ?? false) {
              _selectedAttributes.remove(group);
            }
          }),
        ));
      }
    });

    if (chips.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(defaultPadding, 2, defaultPadding, 8),
        children: [
          for (final chip in chips)
            Padding(
              padding: const EdgeInsetsDirectional.only(end: 8),
              child: chip,
            ),
          TextButton(
            onPressed: _clearAllFilters,
            style: TextButton.styleFrom(
              foregroundColor: primaryColor,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              visualDensity: VisualDensity.compact,
            ),
            child: const Text(
              "Clear all",
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(double bottomPad) {
    if (isLoading && products.isEmpty) {
      return _buildGrid(
        itemCount: 6,
        bottomPad: bottomPad,
        itemBuilder: (_, __) => const ProductCardSkeleton(),
      );
    }

    if (products.isEmpty) {
      return RefreshIndicator(
        onRefresh: () => _fetchData(refresh: true),
        color: primaryColor,
        backgroundColor: AppPalette.card(context),
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: _EmptyState(
                hasFilters: _activeFilterCount > 0,
                onClearFilters: _clearAllFilters,
                bottomPad: bottomPad,
              ),
            ),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _fetchData(refresh: true),
      color: primaryColor,
      backgroundColor: AppPalette.card(context),
      child: _buildGrid(
        itemCount: products.length + (isLoadingMore ? 2 : 0),
        bottomPad: bottomPad,
        itemBuilder: (context, index) {
          if (index >= products.length) return const ProductCardSkeleton();
          final product = products[index];
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
    );
  }

  /// Same card proportions as the home screen: square image + ~180px content.
  Widget _buildGrid({
    required int itemCount,
    required IndexedWidgetBuilder itemBuilder,
    required double bottomPad,
  }) {
    final width = MediaQuery.sizeOf(context).width;
    final columns = width > 900 ? 4 : (width > 600 ? 3 : 2);
    final cellWidth = (width - 20) / columns; // cards have their own 6px margin

    return GridView.builder(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(10, 0, 10, bottomPad),
      itemCount: itemCount,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        childAspectRatio: cellWidth / (cellWidth + 180),
      ),
      itemBuilder: itemBuilder,
    );
  }
}

// =============================================================================
// PIECES
// =============================================================================
class _RoundButton extends StatelessWidget {
  const _RoundButton({
    required this.icon,
    required this.semanticLabel,
    required this.onTap,
    this.iconSize = 17,
  });

  final IconData icon;
  final String semanticLabel;
  final VoidCallback onTap;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticLabel,
      child: Material(
        color: AppPalette.cardElevated(context),
        shape: CircleBorder(side: BorderSide(color: AppPalette.border(context))),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox(
            width: 42,
            height: 42,
            child: Icon(icon, size: iconSize, color: AppPalette.text(context)),
          ),
        ),
      ),
    );
  }
}

/// Round Sort / Filter button. Solid red when something non-default is active.
class _IconToolbarButton extends StatelessWidget {
  const _IconToolbarButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.active = false,
    this.count = 0,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final bool active;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Semantics(
        button: true,
        label: tooltip,
        child: Material(
          color: active ? primaryColor : AppPalette.cardElevated(context),
          shape: CircleBorder(
            side: active ? BorderSide.none : BorderSide(color: AppPalette.border(context)),
          ),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: SizedBox(
              width: 46,
              height: 46,
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  Icon(
                    icon,
                    size: 21,
                    color: active ? Colors.white : AppPalette.text(context),
                  ),
                  if (count > 0)
                    Positioned(
                      top: -2,
                      right: -2,
                      child: Container(
                        height: 18,
                        constraints: const BoxConstraints(minWidth: 18),
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(9),
                          border: Border.all(color: primaryColor, width: 1.5),
                        ),
                        child: Text(
                          "$count",
                          style: const TextStyle(
                            color: primaryColor,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                            height: 1,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// An active filter. Tap ✕ to remove it.
class _FilterChip extends StatelessWidget {
  const _FilterChip({required this.label, required this.onRemove});

  final String label;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final isDark = AppPalette.isDark(context);
    return Container(
      padding: const EdgeInsetsDirectional.fromSTEB(12, 0, 4, 0),
      decoration: BoxDecoration(
        color: primaryColor.withOpacity(isDark ? 0.18 : 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: primaryColor.withOpacity(0.45)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 200),
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: isDark ? Colors.red.shade200 : primaryDarkColor,
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          InkResponse(
            onTap: onRemove,
            radius: 16,
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: Icon(
                Icons.close_rounded,
                size: 15,
                color: isDark ? Colors.red.shade200 : primaryDarkColor,
                semanticLabel: 'Remove $label',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SortRow extends StatelessWidget {
  const _SortRow({required this.option, required this.selected, required this.onTap});

  final _SortOption option;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Material(
        color: selected
            ? primaryColor.withOpacity(AppPalette.isDark(context) ? 0.16 : 0.06)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: selected ? primaryColor : AppPalette.cardElevated(context),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Icon(
                    option.icon,
                    size: 19,
                    color: selected ? Colors.white : AppPalette.text(context),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    option.label,
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                      color: selected ? primaryColor : AppPalette.text(context),
                    ),
                  ),
                ),
                if (selected)
                  const Icon(Icons.check_circle_rounded, color: primaryColor, size: 22),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.hasFilters,
    required this.onClearFilters,
    required this.bottomPad,
  });

  final bool hasFilters;
  final VoidCallback onClearFilters;
  final double bottomPad;

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
                color: AppPalette.cardElevated(context),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.search_off_rounded, size: 32, color: muted),
            ),
            const SizedBox(height: 16),
            Text(
              "No products found",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppPalette.text(context),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              hasFilters
                  ? "Try removing some filters."
                  : "Try a different search.",
              textAlign: TextAlign.center,
              style: TextStyle(color: muted, fontSize: 13),
            ),
            if (hasFilters) ...[
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: onClearFilters,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: const StadiumBorder(),
                ),
                child: const Text(
                  "Clear filters",
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}