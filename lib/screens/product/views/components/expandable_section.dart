import 'package:flutter/material.dart';

class ExpandableSection extends StatefulWidget {
  final String title;
  final String? text;
  final Widget? child;
  final bool initiallyExpanded;
  final IconData? leadingIcon;

  const ExpandableSection({
    super.key,
    required this.title,
    this.text,
    this.child,
    this.initiallyExpanded = false,
    this.leadingIcon,
  });

  @override
  State<ExpandableSection> createState() => _ExpandableSectionState();
}

class _ExpandableSectionState extends State<ExpandableSection> {
  late bool isExpanded;

  @override
  void initState() {
    super.initState();
    isExpanded = widget.initiallyExpanded;
  }

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(height: 0.1),
          ListTile(
            onTap: () => setState(() => isExpanded = !isExpanded),
            leading: Icon(
              widget.leadingIcon ?? Icons.info_outline,
              color: Theme.of(context).iconTheme.color,
            ),
            title: Text(widget.title),
            trailing: Icon(
              isExpanded ? Icons.expand_less : Icons.expand_more,
              color: Theme.of(context).iconTheme.color,
            ),
          ),
          if (isExpanded)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: widget.child ?? Text(widget.text ?? ''),
            ),
          const Divider(height: 1),
        ],
      ),
    );
  }
}