import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class CustomEndDrawer extends StatelessWidget {
  final Function(String) onLocaleChange;

  const CustomEndDrawer({super.key, required this.onLocaleChange});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(color: Theme.of(context).primaryColor),
            child: Text(
              localizations.drawerHeader,
              style: const TextStyle(color: Colors.white, fontSize: 18),
            ),
          ),
          Padding(
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
                  leading: const Icon(Icons.language),
                  title: Text(localizations.language),
                  childrenPadding: EdgeInsets.zero,
                  children: [
                    const Divider(height: 0.6),
                    _buildLanguageOption(
                      context,
                      flagAsset: '🇬🇧',
                      label: localizations.english,
                      localeCode: 'en',
                    ),
                    const Divider(height: 0.6),
                    _buildLanguageOption(
                      context,
                      flagAsset: '🇸🇦',
                      label: localizations.arabic,
                      localeCode: 'ar',
                    ),
                    const Divider(height: 0.3),
                    _buildLanguageOption(
                      context,
                      flagAsset: '🇪🇸',
                      label: localizations.spanish,
                      localeCode: 'es',
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageOption(
      BuildContext context, {
        required String flagAsset,
        required String label,
        required String localeCode,
      }) {
    return InkWell(
      onTap: () {
        onLocaleChange(localeCode);
        Navigator.of(context).pop();
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Text(flagAsset, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 10),
            Text(label, style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}