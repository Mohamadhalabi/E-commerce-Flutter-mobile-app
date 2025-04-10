import 'dart:async'; // Import Timer for auto-play
import 'package:flutter/material.dart';
import 'package:shop/components/product/product_card.dart';
import 'package:shop/models/product_model.dart';
import 'package:shop/route/screen_export.dart';
import 'package:shop/services/api_service.dart'; // Make sure this path is correct
import '../../../../constants.dart';

class PopularProducts extends StatefulWidget {
  const PopularProducts({super.key});

  @override
  State<PopularProducts> createState() => _PopularProductsState();
}

class _PopularProductsState extends State<PopularProducts> {
  List<ProductModel> popularProducts = [];
  bool isLoading = true;
  String errorMessage = "";
  late PageController _pageController;
  int _currentPage = 0; // To track the current page
  Timer? _autoPlayTimer; // Timer for auto-play

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.5, initialPage: 0);
    fetchPopularProducts();

    // Set up auto-play with Timer
    _autoPlayTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (_currentPage < popularProducts.length - 1) {
        _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
      }
      else {
        _pageController.jumpToPage(0); // Loop to the first page
      }
    });
  }

  Future<void> fetchPopularProducts() async {
    try {
      final products = await ApiService.fetchLatestProducts();
      setState(() {
        popularProducts = products;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = e.toString();
        isLoading = false;
      });
    }
  }

  void _nextPage() {
    if (_currentPage < popularProducts.length - 1) {
      _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _autoPlayTimer?.cancel(); // Cancel the auto-play timer when the widget is disposed
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: defaultPadding / 2),
        Padding(
          padding: const EdgeInsets.all(defaultPadding),
          child: Text(
            "Latest Products",
            style: Theme.of(context).textTheme.titleSmall,
          ),
        ),
        if (isLoading)
          const Center(child: CircularProgressIndicator())
        else if (errorMessage.isNotEmpty)
          Padding(
            padding: const EdgeInsets.all(defaultPadding),
            child: Text(errorMessage, style: const TextStyle(color: Colors.red)),
          )
        else
          Column(
            children: [
              // PageView for Carousel
              SizedBox(
                height: 250,
                child: Stack(
                  children: [
                    PageView.builder(
                      controller: _pageController,
                      padEnds: false,
                      itemCount: popularProducts.length,
                      onPageChanged: (int page) {
                        setState(() {
                          _currentPage = page;
                        });
                      },
                      itemBuilder: (context, index) {
                        final product = popularProducts[index];
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: ProductCard(
                            image: product.image,
                            brandName: product.brandName,
                            title: product.title,
                            price: product.price,
                            priceAfetDiscount: product.priceAfterDiscount,
                            dicountpercent: product.discountPercent,
                            press: () {
                              Navigator.pushNamed(
                                context,
                                productDetailsScreenRoute,
                                arguments: index.isEven,
                              );
                            },
                          ),
                        );
                      },
                    ),
                    // Left and Right Navigation Icons inside the grid
                    Positioned(
                      left: 0,
                      top: 100,
                      bottom: 100,
                      child: IconButton(
                        icon: const Icon(Icons.arrow_left),
                        onPressed: _previousPage,
                        color: Colors.black,
                      ),
                    ),
                    Positioned(
                      right: 0,
                      top: 100,
                      bottom: 100,
                      child: IconButton(
                        icon: const Icon(Icons.arrow_right),
                        onPressed: _nextPage,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
              ),
              // Dots Indicator below the grid (outside PageView)
              Padding(
                padding: const EdgeInsets.only(top: 10.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(popularProducts.length - 1, (index) {
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      height: 8,
                      width: _currentPage == index ? 20 : 8,
                      decoration: BoxDecoration(
                        color: _currentPage == index
                            ? Colors.blue
                            : Colors.grey,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    );
                  }),
                ),
              ),
            ],
          ),
      ],
    );
  }
}