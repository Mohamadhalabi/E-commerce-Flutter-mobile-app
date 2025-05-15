import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../constants.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class ProductInfo extends StatelessWidget {
  const ProductInfo({
    super.key,
    required this.title,
    required this.category,
    required this.rating,
    required this.numOfReviews,
    required this.summaryName,
  });

  final String title, category, summaryName;
  final double rating;
  final int numOfReviews;

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.all(defaultPadding),
      sliver: SliverToBoxAdapter(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              category.toUpperCase(),
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: defaultPadding / 2),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: defaultPadding / 2),
            Text(
              summaryName,
              maxLines: 2,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: greenColor, // hex code converted
              ),
            ),
            const SizedBox(height: defaultPadding),
            Row(
              children: [
                const Spacer(),
                SvgPicture.asset("assets/icons/Star_filled.svg"),
                const SizedBox(width: defaultPadding / 4),
                Text(
                  "$rating ",
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                Text("($numOfReviews ${AppLocalizations.of(context)!.reviews})")

              ],
            ),
            const SizedBox(height: defaultPadding),
            Text(
              AppLocalizations.of(context)!.productInfo,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium!
                  .copyWith(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: defaultPadding / 2),
          ],
        ),
      ),
    );
  }
}
