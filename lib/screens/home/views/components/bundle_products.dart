import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shop/components/product/product_card.dart';
import 'package:shop/components/skleton/product/products_skelton.dart';
import 'package:shop/models/product_model.dart';
import 'package:shop/route/screen_export.dart';
import 'package:shop/services/api_service.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../../../constants.dart';

class BundleProducts extends StatefulWidget {
  const BundleProducts({super.key});

  @override
  State<BundleProducts> createState() => _BundleProductsState();
}
class _BundleProductsState extends State<BundleProducts> {
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
      final response = await ApiService.fetchBundleProducts(locale);
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
      key: Key('bundle-products-section'),
      onVisibilityChanged: (visibilityInfo) {
        if (visibilityInfo.visibleFraction > 0.5 && !isSectionVisible) {
          setState(() {
            isSectionVisible = true;
          });
          fetchProducts();
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
                  AppLocalizations.of(context)!.bundleProducts,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/bundle-products'); // Change to your route
                  },
                  child: Text(AppLocalizations.of(context)!.viewAll),
                ),
              ],
            ),
          ),
          if (isLoading)
            const Center(child: ProductsSkelton())
          else if (errorMessage.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(defaultPadding),
              child: Text(errorMessage, style: const TextStyle(color: Colors.red)),
            )
          else
            SizedBox(
              height: 390,
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
                      sku: product.sku,
                      rating: product.rating,
                      discount: product.discount,
                      freeShipping: product.freeShipping,
                      press: () {
                        Navigator.pushNamed(
                          context,
                          productDetailsScreenRoute,
                          arguments: product.id,
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