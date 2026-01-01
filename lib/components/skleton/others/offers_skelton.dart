import 'package:flutter/material.dart';
import '../../../constants.dart';
import '../skeleton.dart';
// import 'path/to/skeleton.dart'; // Import the file where you put the Skeleton class above

class OffersSkelton extends StatelessWidget {
  const OffersSkelton({super.key});

  @override
  Widget build(BuildContext context) {
    // Exact match for (1800/454)/0.92 = 4.31
    final double computedAspectRatio = (1800 / 454) / 0.92;

    return Padding(
      padding: const EdgeInsets.only(top: defaultPadding),
      child: AspectRatio(
        aspectRatio: computedAspectRatio,
        child: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            // Shimmering Banner Box
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Skeleton(
                width: double.infinity,
                height: double.infinity,
              ),
            ),
            // Fake Dots
            Positioned(
              bottom: 8,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(4, (index) => const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 3),
                  child: CircleAvatar(
                    radius: 3, // Small and rounded
                    backgroundColor: Colors.white38,
                  ),
                )),
              ),
            )
          ],
        ),
      ),
    );
  }
}