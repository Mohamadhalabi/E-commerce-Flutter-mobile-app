import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:shop/components/cart_button.dart';
import 'package:shop/components/custom_modal_bottom_sheet.dart';
import 'package:shop/components/product/product_card.dart';
import 'package:shop/components/skleton/skelton.dart';
import 'package:shop/constants.dart';
import 'package:shop/screens/product/views/components/product_attributes.dart';
import 'package:shop/route/screen_export.dart';
import '../../../components/common/app_bar.dart';
import '../../../components/common/drawer.dart';
import '../../../services/api_service.dart';
import 'components/expandable_section.dart';
import 'components/product_images.dart';
import 'components/product_info.dart';
import 'components/product_list_tile.dart';
import '../../../components/review_card.dart';
// import 'product_buy_now_screen.dart';
import 'package:flutter_html/flutter_html.dart';

class ProductDetailsScreen extends StatefulWidget {
  const ProductDetailsScreen({super.key, required this.productId, required this.onLocaleChange});
  final Function(String) onLocaleChange;
  final int productId;

  @override
  State<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}
class _ProductDetailsScreenState extends State<ProductDetailsScreen> {
  Map<String, dynamic>? product;
  bool isLoading = true;
  String? _currentLocale;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final locale = Localizations.localeOf(context).languageCode;

    if (_currentLocale != locale) {
      _currentLocale = locale;
      fetchProductDetails();
    }
  }

  Future<void> fetchProductDetails() async {
    if (_currentLocale == null) return;

    try {
      final result = await ApiService.fetchProductDetails(widget.productId, _currentLocale!);
      setState(() {
        product = result;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: Skeleton()),
      );
    }

    if (product == null) {
      return const Scaffold(
        body: Center(child: Text("Product not found.")),
      );
    }

    return Scaffold(
      appBar: const CustomAppBar(),
      endDrawer: CustomEndDrawer(onLocaleChange: widget.onLocaleChange),
      bottomNavigationBar: CartButton(
        price: (product!['price'] is int)
            ? (product!['price'] as int).toDouble()
            : product!['price'],
        press: () {
          // Add action here
        },
      ),
      body: SafeArea(
        child: RefreshIndicator(
        onRefresh: fetchProductDetails,
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              floating: true,
              actions: [
                IconButton(
                  onPressed: () {},
                  icon: SvgPicture.asset(
                    "assets/icons/Bookmark.svg",
                    color: Theme.of(context).textTheme.bodyLarge!.color,
                  ),
                ),
              ],
            ),
            ProductImages(
              images: (product?['gallery'] as List<dynamic>?)
                  ?.map((item) => item as String)
                  .toList() ?? [],
              isBestSeller: product?['is_best_seller'] == 1,
            ),
            ProductInfo(
              category: product!['category'] ?? "Unknown Category",
              title: product!['title'] ?? "Unknown Title",
              summaryName: product!['summary_name'] ?? "",
              rating: (product!['rating'] as num?)?.toDouble() ?? 0.0,
              numOfReviews: product!['num_of_reviews'] ?? 0,
            ),

            if(product!['attributes'].isNotEmpty)
            ExpandableSection(
              title: "Product Attributes",
              initiallyExpanded: true,
              leadingIcon: Icons.category,
              child: ProductAttributes(
                attributes: (product!['attributes'] is Map<String, dynamic>)
                    ? product!['attributes'] as Map<String, dynamic>
                    : {},
              ),
            ),

            ExpandableSection(
              title: "Product Description",
              leadingIcon: Icons.description,
              child: Html(
                data: product!['description'] ?? "<p>No description available.</p>",
                style: {
                  "body": Style(
                    fontSize: FontSize(13.0),
                    lineHeight: const LineHeight(1.6),
                  ),
                  "p": Style(
                    color: Colors.black87,
                    margin: Margins.zero,
                    padding: HtmlPaddings.zero,
                  ),
                  "li": Style(
                    color: Colors.black87,
                    margin: Margins.zero,
                    lineHeight: const LineHeight(2),
                  ),
                  "ul": Style(
                    padding: HtmlPaddings.only(left: 25),
                  ),

                  "h1": Style(
                    color: Colors.red,
                    fontSize: FontSize.xLarge,
                    padding: HtmlPaddings.only(bottom: 6),
                    margin: Margins.only(bottom: 8),
                    border: Border(bottom: BorderSide(color: Colors.grey.shade300, width: 1)),
                  ),
                  "h2": Style(
                    color: Colors.red,
                    fontSize: FontSize.larger,
                    padding: HtmlPaddings.only(bottom: 6),
                    margin: Margins.only(bottom: 8),
                    border: Border(bottom: BorderSide(color: Colors.grey.shade300, width: 1)),
                  ),
                  "h3": Style(
                    color: Colors.red,
                    fontSize: FontSize.large,
                    padding: HtmlPaddings.only(bottom: 6),
                    margin: Margins.only(bottom: 8),
                    border: Border(bottom: BorderSide(color: Colors.grey.shade300, width: 1)),
                  ),
                },
              ),
            ),
            // const SliverToBoxAdapter(
            //   child: Padding(
            //     padding: EdgeInsets.all(defaultPadding),
            //     child: ReviewCard(
            //       rating: 4.3,
            //       numOfReviews: 128,
            //       numOfFiveStar: 80,
            //       numOfFourStar: 30,
            //       numOfThreeStar: 5,
            //       numOfTwoStar: 4,
            //       numOfOneStar: 1,
            //     ),
            //   ),
            // ),
            // ProductListTile(
            //   svgSrc: "assets/icons/Chat.svg",
            //   title: "Reviews",
            //   isShowBottomBorder: true,
            //   press: () {
            //     Navigator.pushNamed(context, productReviewsScreenRoute);
            //   },
            // ),
            // SliverPadding(
            //   padding: const EdgeInsets.all(defaultPadding),
            //   sliver: SliverToBoxAdapter(
            //     child: Text(
            //       "You may also like",
            //       style: Theme
            //           .of(context)
            //           .textTheme
            //           .titleSmall!,
            //     ),
            //   ),
            // ),
            // SliverToBoxAdapter(
            //   child: SizedBox(
            //     height: 220,
            //     child: ListView.builder(
            //       scrollDirection: Axis.horizontal,
            //       itemCount: 5,
            //       itemBuilder: (context, index) =>
            //           Padding(
            //             padding: EdgeInsets.only(
            //                 left: defaultPadding,
            //                 right: index == 4 ? defaultPadding : 0),
            //             child: ProductCard(
            //               id: 11,
            //               image: productDemoImg2,
            //               title: "Sleeveless Tiered Dobby Swing Dress",
            //               category: "LIPSY LONDON",
            //               price: 24.65,
            //               // salePrice: index.isEven ? 20.99 : null,
            //               // dicountpercent: index.isEven ? 25 : null,
            //               sku: "Sku here",
            //               rating: 4.5,
            //               press: () {},
            //             ),
            //           ),
            //     ),
            //   ),
            // ),
            const SliverToBoxAdapter(
              child: SizedBox(height: defaultPadding),
            )
          ],
         ),
        ),
      )
    );
  }
}