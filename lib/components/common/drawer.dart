import 'package:flutter/material.dart';

class CustomEndDrawer extends StatelessWidget {
  const CustomEndDrawer({super.key});

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
          ListTile(title: const Text('Item 1'), onTap: () {}),
          ListTile(title: const Text('Item 2'), onTap: () {}),
        ],
      ),
    );
  }
}