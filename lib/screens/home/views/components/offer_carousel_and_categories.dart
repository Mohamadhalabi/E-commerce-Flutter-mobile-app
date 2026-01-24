import 'package:flutter/material.dart';
import 'package:showcaseview/showcaseview.dart';
import 'package:shop/components/tutorial_tooltip.dart';
import 'offers_carousel.dart';
import 'categories.dart';

class OffersCarouselAndCategories extends StatelessWidget {
  final int currentIndex;
  final Map<String, dynamic>? user;
  final Function(int) onTabChanged;
  final Function(String) onLocaleChange;
  final GlobalKey? categoryKey;

  const OffersCarouselAndCategories({
    super.key,
    required this.currentIndex,
    required this.user,
    required this.onTabChanged,
    required this.onLocaleChange,
    this.categoryKey,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const OffersCarousel(),

        // ✅ STEP 2: Custom Tooltip around Categories
        categoryKey != null
            ? Showcase.withWidget(
          key: categoryKey!,
          height: 200,
          width: 280,
          container: const TutorialTooltip(
            title: "Categories",
            description: "Browse our products by category here. Swipe to see more options.",
            currentStep: 2,
            totalSteps: 6,
          ),
          child: Categories(
            currentIndex: currentIndex,
            user: user,
            onTabChanged: onTabChanged,
            onLocaleChange: onLocaleChange,
          ),
        )
            : Categories(
          currentIndex: currentIndex,
          user: user,
          onTabChanged: onTabChanged,
          onLocaleChange: onLocaleChange,
        ),
      ],
    );
  }
}