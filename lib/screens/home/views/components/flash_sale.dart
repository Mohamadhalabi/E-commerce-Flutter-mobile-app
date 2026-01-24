import 'dart:async';
import 'package:flutter/material.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:shop/components/product/product_card.dart';
import 'package:shop/components/skleton/product/products_skelton.dart';
import 'package:shop/models/product_model.dart';
import 'package:shop/route/screen_export.dart';
import 'package:shop/services/api_service.dart';
import '../../../../constants.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class FlashSaleProducts extends StatefulWidget {
  const FlashSaleProducts({super.key});

  @override
  State<FlashSaleProducts> createState() => _FlashSaleProductsState();
}

class _FlashSaleProductsState extends State<FlashSaleProducts> {
  List<ProductModel> products = [];
  bool isLoading = true;
  String errorMessage = "";

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    fetchProducts();
  }

  Future<void> fetchProducts() async {
    final locale = Localizations.localeOf(context).languageCode;

    try {
      final response = await ApiService.fetchFlashSaleProducts(locale);
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
    // 1. Calculate width to fit 2.5 items
    double cardWidth = (MediaQuery.of(context).size.width / 2.5) - 16;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: defaultPadding / 2),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: defaultPadding),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppLocalizations.of(context)!.specialOffer,
                style: Theme.of(context).textTheme.titleSmall,
              ),
              TextButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/discount');
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
          VisibilityDetector(
            key: const Key('flash-sale-products'),
            onVisibilityChanged: (VisibilityInfo visibilityInfo) {},
            child: SizedBox(
              height: 330, // 2. Adjusted height
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
                    // 3. Wrap in SizedBox with calculated width
                    child: SizedBox(
                      width: cardWidth,
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
                    ),
                  );
                },
              ),
            ),
          ),
      ],
    );
  }
}