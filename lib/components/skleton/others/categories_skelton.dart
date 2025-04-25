import 'package:flutter/material.dart';

import '../../../constants.dart';
import '../skelton.dart';

class CategoriesSkelton extends StatelessWidget {
  const CategoriesSkelton({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(
          3,
          (_) => const Padding(
            padding: EdgeInsets.only(left: defaultPadding, top: defaultPadding),
            child: Skeleton(
              height: 90,
              width: 90,
              radious: 90,
            ),
          ),
        ),
      ),
    );
  }
}