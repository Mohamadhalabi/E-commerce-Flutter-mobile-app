  import 'package:flutter/material.dart';
  import 'offers_carousel.dart';
  import 'categories.dart';

  class OffersCarouselAndCategories extends StatelessWidget {
    const OffersCarouselAndCategories({super.key});

    @override
    Widget build(BuildContext context) {
      return const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          OffersCarousel(),
          Categories(),
        ],
      );
    }
  }