import 'package:flutter/material.dart';

class ProductAttributes extends StatelessWidget {
  final dynamic attributes;

  const ProductAttributes({
    super.key,
    required this.attributes,
  });

  @override
  Widget build(BuildContext context) {
    if (attributes == null) return const SizedBox();

    // ✅ Detect Theme
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // 1. Handle New API Format (List of Groups)
    if (attributes is List) {
      if (attributes.isEmpty) return const SizedBox();
      return Column(
        children: attributes.map<Widget>((group) {
          String groupName = group['name'] ?? 'Feature';
          List items = group['items'] ?? [];

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: items.map<Widget>((item) {
              String label = groupName;
              String value = item['value'] ?? '';
              return _buildAttributeRow(label, value, isDark);
            }).toList(),
          );
        }).toList(),
      );
    }

    // 2. Handle Old API Format (Map)
    if (attributes is Map) {
      if (attributes.isEmpty) return const SizedBox();
      return Column(
        children: attributes.entries.map<Widget>((entry) {
          return _buildAttributeRow(entry.key, entry.value.toString(), isDark);
        }).toList(),
      );
    }

    return const SizedBox();
  }

  Widget _buildAttributeRow(String label, String value, bool isDark) {
    // ✅ Dynamic Colors
    final Color labelColor = isDark ? Colors.white60 : Colors.grey;
    final Color valueColor = isDark ? Colors.white : Colors.black87;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(color: labelColor, fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: TextStyle(color: valueColor, fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}