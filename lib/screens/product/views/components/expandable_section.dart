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
    // ✅ 1. Theme Detection
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // ✅ 2. Dynamic Colors
    final Color backgroundColor = isDark ? const Color(0xFF1C1C23) : Colors.white;
    final Color titleColor = isDark ? Colors.white : Colors.black87;
    final Color iconColor = isDark ? Colors.white70 : Colors.black87;
    final Color arrowColor = isDark ? Colors.white54 : Colors.grey;
    final Color contentTextColor = isDark ? Colors.white70 : Colors.black54;

    return SliverToBoxAdapter(
      child: Container(
        color: backgroundColor, // Dynamic Background
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
                        color: iconColor, // Dynamic Icon
                      ),
                      const SizedBox(width: 12),
                    ],
                    Expanded(
                      child: Text(
                        widget.title,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: titleColor, // Dynamic Title
                        ),
                      ),
                    ),
                    // ✨ Animated Rotation for the arrow
                    AnimatedRotation(
                      turns: isExpanded ? 0.5 : 0.0,
                      duration: const Duration(milliseconds: 200),
                      child: Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: arrowColor, // Dynamic Arrow
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
                      style: TextStyle(height: 1.5, color: contentTextColor), // Dynamic Text
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