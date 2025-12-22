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
    // 🎨 White block design separates it from the grey background
    return SliverToBoxAdapter(
      child: Container(
        color: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              onTap: () => setState(() => isExpanded = !isExpanded),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                child: Row(
                  children: [
                    if (widget.leadingIcon != null) ...[
                      Icon(
                        widget.leadingIcon,
                        size: 22,
                        color: Colors.black87, // Darker, cleaner icon color
                      ),
                      const SizedBox(width: 12),
                    ],
                    Expanded(
                      child: Text(
                        widget.title,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600, // Semi-bold title
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    // ✨ Animated Rotation for the arrow
                    AnimatedRotation(
                      turns: isExpanded ? 0.5 : 0.0,
                      duration: const Duration(milliseconds: 200),
                      child: const Icon(
                        Icons.keyboard_arrow_down_rounded, // Sleeker chevron
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Content
            AnimatedCrossFade(
              firstChild: Container(),
              secondChild: Padding(
                padding: const EdgeInsets.only(left: 20, right: 20, bottom: 20),
                child: widget.child ??
                    Text(
                      widget.text ?? '',
                      style: const TextStyle(height: 1.5, color: Colors.black54),
                    ),
              ),
              crossFadeState: isExpanded
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 300),
            ),
          ],
        ),
      ),
    );
  }
}