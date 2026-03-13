import 'package:flutter/material.dart';

class FilterModal extends StatefulWidget {
  final Map<String, dynamic> facets;
  final List<String> selectedBrands;
  final List<String> selectedManufacturers;
  final List<String> selectedCategories;
  final Map<String, List<String>> selectedAttributes;

  // ✅ NEW: Property to determine which section goes first
  final String? primaryFilterType;

  final Function(
      List<String> brands,
      List<String> manufs,
      List<String> cats,
      Map<String, List<String>> attrs
      ) onApply;

  const FilterModal({
    super.key,
    required this.facets,
    required this.selectedBrands,
    required this.selectedManufacturers,
    required this.selectedCategories,
    required this.selectedAttributes,
    this.primaryFilterType, // ✅ NEW: Added to constructor
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
    _attributes = {};
    widget.selectedAttributes.forEach((key, value) {
      _attributes[key] = List.from(value);
    });
  }

  // --- UI Helpers ---

  Widget _buildSectionHeader(String title, bool isDark, {VoidCallback? onClear}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
              title,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black,
              )
          ),
          if (onClear != null)
            TextButton(
              onPressed: onClear,
              child: Text(
                  "Clear All",
                  style: TextStyle(color: isDark ? Colors.red.shade400 : Colors.red)
              ),
            ),
        ],
      ),
    );
  }

  // Custom Expansion Tile with cleaner look
  Widget _buildExpansionSection(String title, List<dynamic> items, List<String> selectedList, bool isDark) {
    if (items.isEmpty) return const SizedBox.shrink();

    bool hasSelection = items.any((i) => selectedList.contains(i['slug'].toString()));

    final highlightColor = isDark ? Colors.blue.shade300 : Colors.blue;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subTextColor = isDark ? Colors.white70 : Colors.black;
    final countColor = isDark ? Colors.white38 : Colors.grey[500];

    return Theme(
      data: Theme.of(context).copyWith(
        dividerColor: Colors.transparent, // Remove borders
        unselectedWidgetColor: isDark ? Colors.white54 : Colors.black54, // Checkbox border color
      ),
      child: ExpansionTile(
        initiallyExpanded: hasSelection,
        textColor: highlightColor,
        iconColor: highlightColor,
        collapsedIconColor: isDark ? Colors.white54 : Colors.grey,
        title: Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 16,
              color: hasSelection ? highlightColor : textColor,
            )
        ),
        children: items.map((item) {
          final slug = item['slug'].toString();
          final name = item['name'].toString();
          final count = item['count'];
          final isSelected = selectedList.contains(slug);

          return CheckboxListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 0),
            dense: true,
            visualDensity: VisualDensity.compact,
            title: Row(
              children: [
                Expanded(
                    child: Text(
                        name,
                        style: TextStyle(fontSize: 14, color: subTextColor)
                    )
                ),
                if (count != null)
                  Text(
                      "($count)",
                      style: TextStyle(color: countColor, fontSize: 12)
                  ),
              ],
            ),
            value: isSelected,
            activeColor: isDark ? Theme.of(context).primaryColor : const Color(0xFF333333),
            checkColor: Colors.white,
            controlAffinity: ListTileControlAffinity.leading,
            onChanged: (val) {
              setState(() {
                if (val == true) {
                  selectedList.add(slug);
                } else {
                  selectedList.remove(slug);
                }
              });
            },
          );
        }).toList(),
      ),
    );
  }

  Widget _buildAttributeSections(List<dynamic> attributesData, bool isDark) {
    if (attributesData.isEmpty) return const SizedBox.shrink();

    final highlightColor = isDark ? Colors.blue.shade300 : Colors.blue;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subTextColor = isDark ? Colors.white70 : Colors.black;
    final countColor = isDark ? Colors.white38 : Colors.grey[500];

    return Column(
      children: attributesData.map((attrGroup) {
        final groupName = attrGroup['name'];
        final groupSlug = attrGroup['slug'];
        final items = attrGroup['items'] as List<dynamic>;

        if (!_attributes.containsKey(groupSlug)) {
          _attributes[groupSlug] = [];
        }

        bool hasSelection = items.any((i) => _attributes[groupSlug]!.contains(i['slug'].toString()));

        return Theme(
          data: Theme.of(context).copyWith(
            dividerColor: Colors.transparent,
            unselectedWidgetColor: isDark ? Colors.white54 : Colors.black54,
          ),
          child: ExpansionTile(
            initiallyExpanded: hasSelection,
            textColor: highlightColor,
            iconColor: highlightColor,
            collapsedIconColor: isDark ? Colors.white54 : Colors.grey,
            title: Text(
                groupName,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                  color: hasSelection ? highlightColor : textColor,
                )
            ),
            children: items.map((subItem) {
              final subSlug = subItem['slug'].toString();
              final subName = subItem['name'];
              final count = subItem['count'];
              final isSelected = _attributes[groupSlug]!.contains(subSlug);

              return CheckboxListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 0),
                dense: true,
                visualDensity: VisualDensity.compact,
                title: Row(
                  children: [
                    Expanded(
                        child: Text(
                            subName,
                            style: TextStyle(fontSize: 14, color: subTextColor)
                        )
                    ),
                    Text(
                        "($count)",
                        style: TextStyle(color: countColor, fontSize: 12)
                    ),
                  ],
                ),
                value: isSelected,
                activeColor: isDark ? Theme.of(context).primaryColor : const Color(0xFF333333),
                checkColor: Colors.white,
                controlAffinity: ListTileControlAffinity.leading,
                onChanged: (val) {
                  setState(() {
                    if (val == true) {
                      _attributes[groupSlug]!.add(subSlug);
                    } else {
                      _attributes[groupSlug]!.remove(subSlug);
                    }
                  });
                },
              );
            }).toList(),
          ),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Detect theme brightness
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF1C1C23) : Colors.white;
    final dividerColor = isDark ? Colors.white12 : Colors.grey.shade300;
    final buttonBgColor = isDark ? Theme.of(context).primaryColor : const Color(0xFF333333);

    final brandsList = widget.facets['brands'] as List<dynamic>? ?? [];
    final manufList = widget.facets['manufacturers'] as List<dynamic>? ?? [];
    final catList = widget.facets['categories'] as List<dynamic>? ?? [];
    final attrList = widget.facets['attributes'] as List<dynamic>? ?? [];

    // ✅ NEW: Pre-build the filter sections
    final catSection = _buildExpansionSection("Categories", catList, _categories, isDark);
    final manSection = _buildExpansionSection("Manufacturers", manufList, _manufacturers, isDark);
    final brandSection = _buildExpansionSection("Brands", brandsList, _brands, isDark);
    final attrSection = _buildAttributeSections(attrList, isDark);

    // ✅ NEW: Reorder them based on the 'primaryFilterType'
    List<Widget> filterSections;
    if (widget.primaryFilterType == 'brands') {
      filterSections = [brandSection, catSection, manSection, attrSection];
    } else if (widget.primaryFilterType == 'manufacturers') {
      filterSections = [manSection, catSection, brandSection, attrSection];
    } else {
      // Default (Categories first)
      filterSections = [catSection, manSection, brandSection, attrSection];
    }

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      padding: const EdgeInsets.only(top: 16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          _buildSectionHeader("Filters", isDark, onClear: () {
            setState(() {
              _brands.clear();
              _manufacturers.clear();
              _categories.clear();
              _attributes.clear();
            });
          }),
          Divider(height: 1, color: dividerColor),

          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 0),
              // ✅ NEW: Feed the dynamically ordered list to the UI
              children: filterSections,
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: buttonBgColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                onPressed: () {
                  widget.onApply(_brands, _manufacturers, _categories, _attributes);
                  Navigator.pop(context);
                },
                child: const Text("Apply Filters", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}