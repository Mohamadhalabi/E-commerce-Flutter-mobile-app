import 'package:flutter/material.dart';
import 'package:shop/constants.dart';

class FilterModal extends StatefulWidget {
  final Map<String, dynamic> facets;
  final List<String> selectedBrands;
  final List<String> selectedManufacturers;
  final List<String> selectedCategories;
  final Map<String, List<String>> selectedAttributes;

  /// Which section goes first: 'categories', 'brands' or 'manufacturers'.
  final String? primaryFilterType;

  final Function(
      List<String> brands,
      List<String> manufs,
      List<String> cats,
      Map<String, List<String>> attrs,
      ) onApply;

  const FilterModal({
    super.key,
    required this.facets,
    required this.selectedBrands,
    required this.selectedManufacturers,
    required this.selectedCategories,
    required this.selectedAttributes,
    this.primaryFilterType,
    required this.onApply,
  });

  @override
  State<FilterModal> createState() => _FilterModalState();
}

class _FilterModalState extends State<FilterModal> {
  late List<String> _brands;
  late List<String> _manufacturers;
  late List<String> _categories;
  late Map<String, List<String>> _attributes;

  @override
  void initState() {
    super.initState();
    _brands = List.from(widget.selectedBrands);
    _manufacturers = List.from(widget.selectedManufacturers);
    _categories = List.from(widget.selectedCategories);
    _attributes = {
      for (final e in widget.selectedAttributes.entries) e.key: List.from(e.value),
    };
  }

  int get _selectedCount {
    var n = _brands.length + _manufacturers.length + _categories.length;
    _attributes.forEach((_, v) => n += v.length);
    return n;
  }

  void _clearAll() {
    setState(() {
      _brands.clear();
      _manufacturers.clear();
      _categories.clear();
      _attributes.clear();
    });
  }

  void _toggle(List<String> list, String slug) {
    setState(() {
      if (list.contains(slug)) {
        list.remove(slug);
      } else {
        list.add(slug);
      }
    });
  }

  // ---------------------------------------------------------------------------
  // SECTIONS
  // ---------------------------------------------------------------------------
  Widget _section({
    required String title,
    required List<dynamic> items,
    required List<String> selected,
  }) {
    if (items.isEmpty) return const SizedBox.shrink();

    final selectedHere =
        items.where((i) => selected.contains(i['slug'].toString())).length;

    return _FilterSection(
      title: title,
      selectedCount: selectedHere,
      children: [
        for (final item in items)
          _CheckRow(
            label: item['name'].toString(),
            count: item['count'],
            selected: selected.contains(item['slug'].toString()),
            onTap: () => _toggle(selected, item['slug'].toString()),
          ),
      ],
    );
  }

  Widget _attributeSections(List<dynamic> groups) {
    if (groups.isEmpty) return const SizedBox.shrink();

    return Column(
      children: [
        for (final group in groups)
          _section(
            title: group['name'].toString(),
            items: group['items'] as List<dynamic>,
            selected: _attributes.putIfAbsent(group['slug'].toString(), () => []),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final brandsList = widget.facets['brands'] as List<dynamic>? ?? [];
    final manufList = widget.facets['manufacturers'] as List<dynamic>? ?? [];
    final catList = widget.facets['categories'] as List<dynamic>? ?? [];
    final attrList = widget.facets['attributes'] as List<dynamic>? ?? [];

    final catSection = _section(title: "Categories", items: catList, selected: _categories);
    final manSection =
    _section(title: "Manufacturers", items: manufList, selected: _manufacturers);
    final brandSection = _section(title: "Brands", items: brandsList, selected: _brands);
    final attrSection = _attributeSections(attrList);

    final List<Widget> sections;
    if (widget.primaryFilterType == 'brands') {
      sections = [brandSection, catSection, manSection, attrSection];
    } else if (widget.primaryFilterType == 'manufacturers') {
      sections = [manSection, catSection, brandSection, attrSection];
    } else {
      sections = [catSection, manSection, brandSection, attrSection];
    }

    final count = _selectedCount;

    return Container(
      height: MediaQuery.sizeOf(context).height * 0.85,
      decoration: BoxDecoration(
        color: AppPalette.card(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 10),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppPalette.border(context),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(20, 12, 8, 8),
            child: Row(
              children: [
                Text(
                  "Filters",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppPalette.text(context),
                  ),
                ),
                if (count > 0) ...[
                  const SizedBox(width: 8),
                  _CountBadge(count: count),
                ],
                const Spacer(),
                TextButton(
                  onPressed: count > 0 ? _clearAll : null,
                  style: TextButton.styleFrom(foregroundColor: primaryColor),
                  child: const Text(
                    "Clear all",
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: AppPalette.border(context)),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
              children: sections,
            ),
          ),
          // Apply
          SafeArea(
            top: false,
            minimum: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: () {
                    widget.onApply(_brands, _manufacturers, _categories, _attributes);
                    Navigator.pop(context);
                  },
                  child: Text(
                    count > 0 ? "Apply filters ($count)" : "Apply filters",
                    style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// PIECES
// =============================================================================
class _CountBadge extends StatelessWidget {
  const _CountBadge({required this.count});
  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 22,
      constraints: const BoxConstraints(minWidth: 22),
      padding: const EdgeInsets.symmetric(horizontal: 7),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: primaryColor,
        borderRadius: BorderRadius.circular(11),
      ),
      child: Text(
        "$count",
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w800,
          height: 1,
        ),
      ),
    );
  }
}

/// A collapsible group. Sections with selections start open and are tinted red.
class _FilterSection extends StatelessWidget {
  const _FilterSection({
    required this.title,
    required this.selectedCount,
    required this.children,
  });

  final String title;
  final int selectedCount;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final hasSelection = selectedCount > 0;
    final shape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(16));

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: hasSelection,
          shape: shape,
          collapsedShape: shape,
          clipBehavior: Clip.antiAlias,
          backgroundColor: AppPalette.cardElevated(context),
          collapsedBackgroundColor: hasSelection
              ? primaryColor.withOpacity(AppPalette.isDark(context) ? 0.14 : 0.05)
              : Colors.transparent,
          tilePadding: const EdgeInsets.symmetric(horizontal: 12),
          childrenPadding: const EdgeInsets.fromLTRB(6, 0, 6, 8),
          iconColor: primaryColor,
          collapsedIconColor: AppPalette.textMuted(context),
          title: Row(
            children: [
              Flexible(
                child: Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    color: hasSelection ? primaryColor : AppPalette.text(context),
                  ),
                ),
              ),
              if (hasSelection) ...[
                const SizedBox(width: 8),
                _CountBadge(count: selectedCount),
              ],
            ],
          ),
          children: children,
        ),
      ),
    );
  }
}

class _CheckRow extends StatelessWidget {
  const _CheckRow({
    required this.label,
    required this.selected,
    required this.onTap,
    this.count,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final dynamic count;

  @override
  Widget build(BuildContext context) {
    final isDark = AppPalette.isDark(context);
    final muted = AppPalette.textMuted(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Material(
        color: selected
            ? primaryColor.withOpacity(isDark ? 0.18 : 0.08)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: selected ? primaryColor : Colors.transparent,
                    borderRadius: BorderRadius.circular(7),
                    border: Border.all(
                      color: selected ? primaryColor : muted.withOpacity(0.6),
                      width: 1.6,
                    ),
                  ),
                  child: selected
                      ? const Icon(Icons.check_rounded, size: 16, color: Colors.white)
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
                      color: selected
                          ? (isDark ? Colors.red.shade200 : primaryDarkColor)
                          : AppPalette.text(context),
                    ),
                  ),
                ),
                if (count != null)
                  Text("$count", style: TextStyle(color: muted, fontSize: 12.5)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}