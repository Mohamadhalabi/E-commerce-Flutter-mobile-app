import 'package:flutter/material.dart';
import 'banner_m.dart';
import '../../../constants.dart';

class BannerMStyle1 extends StatelessWidget {
  const BannerMStyle1({
    super.key,
    this.image = "https://dev-srv.tlkeys.com/storage/mobile/ramadan-promo-slider.webp",
    required this.press,
  });
  final String? image;
  final VoidCallback press;

  @override
  Widget build(BuildContext context) {
    return BannerM(
      image: image!,
      press: press,
      children: const [
        Padding(
          padding: EdgeInsets.all(defaultPadding),
          child: SizedBox.shrink(),
        ),
      ],
    );
  }
}
