import 'package:flutter/material.dart';
// import '../../../../components/skleton/others/categories_skelton.dart';
import '../../../../constants.dart';
import 'offers_carousel.dart';
import 'categories.dart';

class OffersCarouselAndCategories extends StatelessWidget {
  const OffersCarouselAndCategories({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Padding(
          // padding: EdgeInsets.all(5),
        // ),
        Categories(),
        // While loading use 👇
        // const OffersSkelton(),
        // Padding(
        //   padding: EdgeInsets.only(bottom: 15.0),
        // ),
        OffersCarousel(),
        Padding(
          padding: EdgeInsets.all(defaultPadding),
          child: Text(
            "Categories",
            // style: Theme.of(context).textTheme.titleSmall,
          ),
        ),
      ],
    );
  }
}