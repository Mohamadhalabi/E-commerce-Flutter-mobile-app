import 'package:flutter/material.dart';

class FilterModal extends StatefulWidget {
  final Map<String, dynamic> facets;
  final List<String> selectedBrands;
  final List<String> selectedManufacturers;
  final List<String> selectedCategories;
  final Map<String, List<String>> selectedAttributes;

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

  final Color _applyButtonColor = const Color(0xFF333333);

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

  Widget _buildSectionHeader(String title, {VoidCallback? onClear}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          if (onClear != null)
            TextButton(
              onPressed: onClear,
              child: const Text("Clear All", style: TextStyle(color: Colors.red)),
            ),
        ],
      ),
    );
  }

  // Custom Expansion Tile with cleaner look
  Widget _buildExpansionSection(String title, List<dynamic> items, List<String> selectedList) {
    if (items.isEmpty) return const SizedBox.shrink();

    // Check if any item in this section is selected to possibly style the title
    bool hasSelection = items.any((i) => selectedList.contains(i['slug'].toString()));

    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent), // Remove borders
      child: ExpansionTile(
        initiallyExpanded: hasSelection, // Auto-expand if something is selected
        textColor: Colors.black,
        iconColor: Colors.black,
        collapsedIconColor: Colors.grey,
        title: Text(
            title,
            style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
                color: hasSelection ? Colors.blue : Colors.black87
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
                Expanded(child: Text(name, style: const TextStyle(fontSize: 14))),
                if (count != null)
                  Text("($count)", style: TextStyle(color: Colors.grey[500], fontSize: 12)),
              ],
            ),
            value: isSelected,
            activeColor: _applyButtonColor,
            controlAffinity: ListTileControlAffinity.leading, // Checkbox on left
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

  Widget _buildAttributeSections(List<dynamic> attributesData) {
    if (attributesData.isEmpty) return const SizedBox.shrink();

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
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            initiallyExpanded: hasSelection,
            textColor: Colors.black,
            title: Text(
                groupName,
                style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: hasSelection ? Colors.blue : Colors.black87
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
                    Expanded(child: Text(subName, style: const TextStyle(fontSize: 14))),
                    Text("($count)", style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                  ],
                ),
                value: isSelected,
                activeColor: _applyButtonColor,
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
    final brandsList = widget.facets['brands'] as List<dynamic>? ?? [];
    final manufList = widget.facets['manufacturers'] as List<dynamic>? ?? [];
    final catList = widget.facets['categories'] as List<dynamic>? ?? [];
    final attrList = widget.facets['attributes'] as List<dynamic>? ?? [];

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      padding: const EdgeInsets.only(top: 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          _buildSectionHeader("Filters", onClear: () {
            setState(() {
              _brands.clear();
              _manufacturers.clear();
              _categories.clear();
              _attributes.clear();
            });
          }),
          const Divider(height: 1),

          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 0), // Tiles have padding
              children: [
                _buildExpansionSection("Categories", catList, _categories),
                _buildExpansionSection("Manufacturers", manufList, _manufacturers),
                _buildExpansionSection("Brands", brandsList, _brands),
                _buildAttributeSections(attrList),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _applyButtonColor,
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