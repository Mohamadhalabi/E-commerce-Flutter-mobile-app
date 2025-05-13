import 'package:flutter/material.dart';

class CustomEndDrawer extends StatelessWidget {
  final Function(String) onLocaleChange;

  const CustomEndDrawer({super.key, required this.onLocaleChange});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(color: Theme.of(context).primaryColor),
            child: const Text('Drawer Header', style: TextStyle(color: Colors.white)),
          ),
          ListTile(
            title: const Text('🇬🇧 English'),
            onTap: () {
              onLocaleChange('en');
              Navigator.of(context).pop();
            },
          ),
          ListTile(
            title: const Text('🇸🇦 العربية'),
            onTap: () {
              onLocaleChange('ar');
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }
}