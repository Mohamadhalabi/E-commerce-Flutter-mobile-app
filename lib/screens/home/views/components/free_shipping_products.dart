import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shop/components/product/product_card.dart';
import 'package:shop/components/skleton/product/products_skelton.dart';
import 'package:shop/models/product_model.dart';
import 'package:shop/route/screen_export.dart';
import 'package:shop/services/api_service.dart';
import 'package:visibility_detector/visibility_detector.dart';
import '../../../../constants.dart';

class FreeShippingProducts extends StatefulWidget {
  const FreeShippingProducts({super.key});

  @override
  State<FreeShippingProducts> createState() => _FreeShippingProductsState();
}

class _FreeShippingProductsState extends State<FreeShippingProducts> {
  List<ProductModel> products = [];
  bool isLoading = true;
  String errorMessage = "";
  bool isSectionVisible = false; // Track if the section is visible

  @override
  void initState() {
    super.initState();
  }

  // Fetch products when the section becomes visible
  Future<void> fetchProducts() async {
    try {
      final response = await ApiService.fetchFreeShippingProducts();
      setState(() {
        products = response;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = e.toString();
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return VisibilityDetector(
      key: Key('free-shipping-products-section'),
      onVisibilityChanged: (visibilityInfo) {
        if (visibilityInfo.visibleFraction > 0.5 && !isSectionVisible) {
          setState(() {
            isSectionVisible = true;
            fetchProducts(); // Trigger fetch when section is visible
          });
        }
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: defaultPadding / 2),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: defaultPadding),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Free Shipping",
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                TextButton(
                  onPressed: () {
                    // Navigate or perform desired action
                    Navigator.pushNamed(context, '/free-shipping'); // Change to your route
                  },
                  child: const Text("View all"),
                ),
              ],
            ),
          ),
          if (isLoading && isSectionVisible)
            const Center(child: ProductsSkelton())
          else if (errorMessage.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(defaultPadding),
              child: Text(errorMessage, style: const TextStyle(color: Colors.red)),
            )
          else
            SizedBox(
              height: 370,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: products.length,
                itemBuilder: (context, index) {
                  final product = products[index];
                  return Padding(
                    padding: EdgeInsets.only(
                      left: defaultPadding,
                      right: index == products.length - 1 ? defaultPadding : 0,
                    ),
                    child: ProductCard(
                      id: product.id,
                      image: product.image,
                      category: product.category,
                      title: product.title,
                      price: product.price,
                      salePrice: product.salePrice,
                      discount: product.discount,
                      dicountpercent: product.discountPercent,
                      sku: product.sku,
                      rating: product.rating,
                      freeShipping: product.freeShipping,
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
            ),
        ],
      ),
    );
  }
}