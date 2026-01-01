import 'package:flutter/material.dart';
import 'offers_carousel.dart';
import 'categories.dart';

class OffersCarouselAndCategories extends StatelessWidget {
  // 1. Add these variables to hold the data coming from Home Screen
  final int currentIndex;
  final Map<String, dynamic>? user;
  final Function(int) onTabChanged;
  final Function(String) onLocaleChange;

  const OffersCarouselAndCategories({
    super.key,
    required this.currentIndex,
    required this.user,
    required this.onTabChanged,
    required this.onLocaleChange,
  });

  @override
  Widget build(BuildContext context) {
    // 2. Removed 'const' before Column (because Categories uses dynamic data)
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const OffersCarousel(),
        // 3. Pass the variables to Categories
        Categories(
          currentIndex: currentIndex,
          user: user,
          onTabChanged: onTabChanged,
          onLocaleChange: onLocaleChange,
        )
      ],
    );
  }
}