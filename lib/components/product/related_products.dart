import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shop/components/product/product_card.dart';
import 'package:shop/components/skleton/product/products_skelton.dart';
import 'package:shop/models/product_model.dart';
import 'package:shop/route/screen_export.dart';
import 'package:shop/services/api_service.dart';
import '../../../../constants.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class RelatedProducts extends StatefulWidget {
  final int productId;

  const RelatedProducts({super.key, required this.productId});

  @override
  State<RelatedProducts> createState() => _RelatedProductsState();
}

class _RelatedProductsState extends State<RelatedProducts> {
  List<ProductModel> products = [];
  bool isLoading = true;
  String errorMessage = "";
  String? _currentLocale;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final newLocale = Localizations.localeOf(context).languageCode;
    if (_currentLocale != newLocale) {
      _currentLocale = newLocale;
      fetchProducts(_currentLocale!);
    }
  }

  Future<void> fetchProducts(String locale) async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });
    try {
      final response = await ApiService.fetchRelatedProducts(locale, widget.productId);
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
    double cardWidth = (MediaQuery.of(context).size.width / 2.5) - 16;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: defaultPadding / 2),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: defaultPadding, vertical: defaultPadding),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppLocalizations.of(context)!.relatedProducts,
                style: Theme.of(context).textTheme.titleSmall,
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
            height: 330,
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
                  // START FIX: Update ProductCard signature
                  child: SizedBox(
                    width: cardWidth,
                    child: ProductCard(
                      product: product, // Pass the whole model object
                      press: () {
                        Navigator.pushNamed(
                          context,
                          productDetailsScreenRoute,
                          arguments: product.id,
                        );
                      },
                    ),
                  ),
                  // END FIX
                );
              },
            ),
          ),
      ],
    );
  }
}