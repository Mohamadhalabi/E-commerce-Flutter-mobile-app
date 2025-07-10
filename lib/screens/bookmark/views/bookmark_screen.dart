import 'package:flutter/material.dart';
class BookmarkScreen extends StatelessWidget {
  const BookmarkScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // While loading use 👇
          //  BookMarksSlelton(),
          // SliverPadding(
          //   padding: const EdgeInsets.symmetric(
          //       horizontal: defaultPadding, vertical: defaultPadding),
          //   sliver: SliverGrid(
          //     gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          //       maxCrossAxisExtent: 200.0,
          //       mainAxisSpacing: defaultPadding,
          //       crossAxisSpacing: defaultPadding,
          //       childAspectRatio: 0.66,
          //     ),
          //     delegate: SliverChildBuilderDelegate(
          //       (BuildContext context, int index) {
          //         return ProductCard(
          //           id: demoPopularProducts[index].id,
          //           image: demoPopularProducts[index].image,
          //           category: demoPopularProducts[index].category,
          //           title: demoPopularProducts[index].title,
          //           price: demoPopularProducts[index].price,
          //           sku: "SKU here",
          //           rating: 4.5,
          //           salePrice: demoPopularProducts[index].salePrice,
          //           dicountpercent: demoPopularProducts[index].discountPercent,
          //           press: () {
          //             Navigator.pushNamed(context, productDetailsScreenRoute);
          //           },
          //         );
          //       },
          //       childCount: demoPopularProducts.length,
          //     ),
          //   ),
          // ),
        ],
      ),
    );
  }
}
