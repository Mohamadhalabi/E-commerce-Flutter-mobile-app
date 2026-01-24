import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shop/components/product/product_card.dart';
import 'package:shop/components/skleton/product/products_skelton.dart';
import 'package:shop/models/product_model.dart';
import 'package:shop/services/api_service.dart';
import '../../../../constants.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../../../../route/route_constants.dart';

class NewArrivalProducts extends StatefulWidget {
  const NewArrivalProducts({super.key});

  @override
  State<NewArrivalProducts> createState() => _NewArrivalProductsState();
}

class _NewArrivalProductsState extends State<NewArrivalProducts> {
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
      final response = await ApiService.fetchLatestProducts(locale);
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
    // 1. Calculate width to fit 3 items (Screen Width / 3) minus a little padding
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
                AppLocalizations.of(context)!.newArrival,
                style: Theme.of(context).textTheme.titleSmall,
              ),
              TextButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/new-arrival');
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
        // 2. Reduce the container height (was 420, now ~260 is enough for small cards)
          SizedBox(
            height: 340,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: products.length,
              itemBuilder: (context, index) {
                final product = products[index];
                return Padding(
                  padding: EdgeInsets.only(
                    left: defaultPadding,
                    // Add right padding to the last item so it doesn't stick to the edge
                    right: index == products.length - 1 ? defaultPadding : 0,
                  ),
                  // 3. Wrap ProductCard in a SizedBox with the calculated width
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
      ],
    );
  }
}