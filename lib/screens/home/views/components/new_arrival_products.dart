import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shop/components/product/product_card.dart';
import 'package:shop/components/skleton/product/products_skelton.dart';
import 'package:shop/models/product_model.dart';
import 'package:shop/services/api_service.dart';
import '../../../../constants.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../../../route/route_constants.dart';
import '../../../discover/views/view_all_products_screen.dart';

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
    Size size = MediaQuery.of(context).size;

    // -------------------------------------------------------------------------
    // 📱 RESPONSIVE CALCULATIONS
    // -------------------------------------------------------------------------
    // 1. Tablet Check: If width > 600, we consider it a tablet.
    bool isTablet = size.width > 600;

    // 2. Card Width:
    //    - Mobile: Divide by 2.3 (Shows 2 full cards + a peek of the 3rd)
    //    - Tablet: Divide by 4.5 (Shows 4 full cards + a peek of the 5th)
    double cardWidth = isTablet ? size.width / 4.5 : size.width / 2.6;

    // 3. List Height:
    //    Since the ProductCard image is square (AspectRatio 1.0),
    //    Image Height = Card Width.
    //    We add ~190px for the text, price, buttons, and padding below the image.
    double listHeight = cardWidth + 180;

    // 4. Red Background Height:
    //    Slightly shorter than the list to create the "pop-out" effect.
    double redSectionHeight = listHeight - 20;
    // -------------------------------------------------------------------------

    return Padding(
      padding: const EdgeInsets.only(top: defaultPadding),
      child: Stack(
        children: [
          // Red Gradient Background
          Container(
            height: redSectionHeight,
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFFD32F2F),
                  Color(0xFF9A0007),
                ],
              ),
            ),
          ),

          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: defaultPadding),

              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: defaultPadding),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.newArrival,
                      style: Theme.of(context).textTheme.titleSmall!.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ViewAllProductsScreen(
                              title: AppLocalizations.of(context)!.newArrival,
                              type: ProductListType.newArrival, // <--- Passes the type
                            ),
                          ),
                        );
                      },
                      child: Text(AppLocalizations.of(context)!.viewAll),
                    ),
                  ],
                ),
              ),

              // Product List
              if (isLoading)
                const Center(child: ProductsSkelton())
              else if (errorMessage.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.all(defaultPadding),
                  child: Text(errorMessage, style: const TextStyle(color: Colors.white)),
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
        ],
      ),
    );
  }
}