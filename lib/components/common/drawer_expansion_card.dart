import 'package:flutter/material.dart';

class DrawerExpansionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final List<Widget> children;

  const DrawerExpansionCard({
    super.key,
    required this.icon,
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Card(
        color: Colors.white,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            tilePadding: const EdgeInsets.symmetric(horizontal: 16),
            leading: Icon(icon),
            title: Text(title),
            childrenPadding: EdgeInsets.zero,
            children: children,
          ),
        ),
      ),
    );
  }
}