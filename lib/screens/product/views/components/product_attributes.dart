import 'package:flutter/material.dart';

class ProductAttributes extends StatelessWidget {
  // ✅ FIX: Accept dynamic input (can be List or Map)
  final dynamic attributes;

  const ProductAttributes({
    super.key,
    required this.attributes,
  });

  @override
  Widget build(BuildContext context) {
    if (attributes == null) return const SizedBox();

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
              // Use group name as label unless item has specific label logic
              String label = groupName;
              String value = item['value'] ?? '';
              return _buildAttributeRow(label, value);
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
          return _buildAttributeRow(entry.key, entry.value.toString());
        }).toList(),
      );
    }

    return const SizedBox();
  }

  Widget _buildAttributeRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: const TextStyle(color: Colors.black87, fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}