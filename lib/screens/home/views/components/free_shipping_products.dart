import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shop/components/product/product_card.dart';
import 'package:shop/components/skleton/product/products_skelton.dart';
import 'package:shop/models/product_model.dart';
import 'package:shop/route/screen_export.dart';
import 'package:shop/services/api_service.dart';
import 'package:visibility_detector/visibility_detector.dart';
import '../../../../constants.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../../../discover/views/view_all_products_screen.dart';

class FreeShippingProducts extends StatefulWidget {
  const FreeShippingProducts({super.key});

  @override
  State<FreeShippingProducts> createState() => _FreeShippingProductsState();
}

class _FreeShippingProductsState extends State<FreeShippingProducts> {
  List<ProductModel> products = [];
  bool isLoading = true;
  String errorMessage = "";
  bool isSectionVisible = false;

  @override
  void initState() {
    super.initState();
  }

  Future<void> fetchProducts() async {
    final locale = Localizations.localeOf(context).languageCode;
    try {
      final response = await ApiService.fetchFreeShippingProducts(locale);
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
    Size size = MediaQuery.of(context).size;

    // ---------------------------------------------------------
    // 📱 RESPONSIVE CALCULATIONS
    // ---------------------------------------------------------
    // 1. Tablet Check
    bool isTablet = size.width > 600;

    // 2. Card Width
    // Mobile: Shows ~2.3 cards (peek)
    // Tablet: Shows ~4.5 cards (peek)
    double cardWidth = isTablet ? size.width / 4.5 : size.width / 2.6;

    // 3. List Height
    // Image height (square) + Content height (~190px)
    double listHeight = cardWidth + 180;
    // ---------------------------------------------------------

    return VisibilityDetector(
      key: const Key('free-shipping-products-section'),
      onVisibilityChanged: (visibilityInfo) {
        if (visibilityInfo.visibleFraction > 0.5 && !isSectionVisible) {
          setState(() {
            isSectionVisible = true;
            fetchProducts();
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
                  AppLocalizations.of(context)!.freeShipping,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                TextButton(
                  onPressed: () {
                    // ✅ UPDATED NAVIGATION
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ViewAllProductsScreen(
                          title: AppLocalizations.of(context)!.freeShipping,
                          type: ProductListType.freeShipping, // Select correct type
                        ),
                      ),
                    );
                  },
                  child: Text(AppLocalizations.of(context)!.viewAll),
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
              height: listHeight, // Dynamic Height Applied Here
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: products.length,
                itemBuilder: (context, index) {
                  final product = products[index];
                  return Padding(
                    padding: EdgeInsets.only(
                      left: index == 0 ? defaultPadding : defaultPadding / 2,
                      right: index == products.length - 1 ? defaultPadding : 0,
                    ),
                    child: SizedBox(
                      width: cardWidth, // Dynamic Width Applied Here
                      child: ProductCard(
                        product: product,
                        press: () {
                          Navigator.pushNamed(
                            context,
                            productDetailsScreenRoute,
                            arguments: product.id,
                          );
                        },
                      ),
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