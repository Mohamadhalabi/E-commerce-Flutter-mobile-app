import 'package:flutter/material.dart';
import '/components/network_image_with_loader.dart';

import '../../../../constants.dart';
import 'image_gallery_modal.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class ProductImages extends StatefulWidget {
  const ProductImages({
    super.key,
    required this.images,
    this.isBestSeller = false,
  });

  final List<String> images;
  final bool isBestSeller;

  @override
  State<ProductImages> createState() => _ProductImagesState();
}

class _ProductImagesState extends State<ProductImages> {
  late PageController _controller;

  int _currentPage = 0;

  @override
  void initState() {
    _controller =
        PageController(viewportFraction: 0.9, initialPage: _currentPage);
    super.initState();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  void _openImageModal(int initialIndex) {
    showDialog(
      context: context,
      builder: (_) {
        return Dialog(
          insetPadding: const EdgeInsets.all(10),
          backgroundColor: Colors.transparent,
          child: ImageGalleryModal(
            images: widget.images,
            initialIndex: initialIndex,
          ),
        );
      },
    );
  }
  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Column(
        children: [
          AspectRatio(
            aspectRatio: 1,
            child: PageView.builder(
              controller: _controller,
              onPageChanged: (pageNum) {
                setState(() {
                  _currentPage = pageNum;
                });
              },
              itemCount: widget.images.length,
              itemBuilder: (context, index) => Padding(
                padding: const EdgeInsets.all(20.0),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(defaultBorderRadious * 2),
                  ),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.all(
                      Radius.circular(defaultBorderRadious * 2),
                    ),
                    child: GestureDetector(
                      onTap: () => _openImageModal(index),
                      child: Stack(
                        alignment: Alignment.topLeft,
                        children: [
                          NetworkImageWithLoader(widget.images[index]),
                          if (widget.isBestSeller)
                            Positioned(
                              top: 10,
                              left: 10,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.orange,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  AppLocalizations.of(context)!.bestSeller,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),

                  ),
                ),
              ),
            ),
          ),
          if (widget.images.length > 1)
            Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  widget.images.length,
                      (index) => AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: index == _currentPage ? 10 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .textTheme
                          .bodyLarge!
                          .color!
                          .withOpacity(index == _currentPage ? 1 : 0.3),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
              ),
            ),
          const Divider(thickness: 0.1, color: Colors.grey),
        ],
      ),
    );
  }
}