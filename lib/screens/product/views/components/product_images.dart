import 'package:flutter/material.dart';
import '/components/network_image_with_loader.dart';
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
    _controller = PageController(viewportFraction: 1.0, initialPage: _currentPage);
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
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          AspectRatio(
            aspectRatio: 1.1,
            child: Stack(
              children: [
                PageView.builder(
                  controller: _controller,
                  onPageChanged: (pageNum) {
                    setState(() {
                      _currentPage = pageNum;
                    });
                  },
                  itemCount: widget.images.length,
                  itemBuilder: (context, index) => GestureDetector(
                    onTap: () => _openImageModal(index),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: NetworkImageWithLoader(
                        widget.images[index],
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
                if (widget.isBestSeller)
                  Positioned(
                    top: 16,
                    left: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        AppLocalizations.of(context)!.bestSeller.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (widget.images.length > 1)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: SizedBox(
                height: 60,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: widget.images.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    final isActive = index == _currentPage;
                    return GestureDetector(
                      onTap: () {
                        _controller.animateToPage(
                          index,
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 60,
                        decoration: BoxDecoration(
                          // ✅ FIXED: Border is now Orange when active
                          border: Border.all(
                            color: isActive
                                ? const Color(0xFFF37A20) // The Orange Color you requested
                                : Colors.transparent,
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(8),
                          color: Colors.grey.shade50,
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: Image.network(
                            widget.images[index],
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }
}