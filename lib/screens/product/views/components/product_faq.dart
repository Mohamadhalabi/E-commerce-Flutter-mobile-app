import 'package:flutter/material.dart';

class ProductFaq extends StatelessWidget {
  final List<List<String>> faq;

  const ProductFaq({super.key, required this.faq});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: faq.map((pair) {
        final question = pair[0];
        final answer = pair[1];

        return Container(
          margin: const EdgeInsets.symmetric(vertical: 8.0),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
            boxShadow: const [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Theme(
            data: Theme.of(context).copyWith(
              dividerColor: Colors.transparent, // hide ExpansionTile divider
              splashColor: Colors.transparent,
              highlightColor: Colors.transparent,
            ),
            child: ExpansionTile(
              tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              childrenPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              title: Text(
                question,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              iconColor: Colors.black54,
              collapsedIconColor: Colors.black45,
              children: [
                Text(
                  answer,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey.shade800,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}