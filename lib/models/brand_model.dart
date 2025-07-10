import 'package:flutter/material.dart';
import 'package:shop/components/skleton/others/categories_skelton.dart';
import 'package:shop/services/api_service.dart';
import '../../../../constants.dart';
import '../screens/home/views/components/categories.dart';

class BrandModel {
  final String title;
  final String image;
  final String? slug;

  BrandModel({
    required this.title,
    required this.image,
    this.slug,
  });

  factory BrandModel.fromJson(Map<String, dynamic> json) {
    return BrandModel(
      title: json['title'],
      image: json['image'] ?? 'https://dev-srv.tlkeys.com/storage/AAAA/180x180.jpg',
      slug: json['slug'],
    );
  }
}

class Brands extends StatefulWidget {
  const Brands({super.key});

  @override
  State<Brands> createState() => _BrandsState();
}

class _BrandsState extends State<Brands> {
  List<BrandModel> brands = [];
  bool isLoading = true;
  String? _currentLocale;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final newLocale = Localizations.localeOf(context).languageCode;
    if (_currentLocale != newLocale) {
      _currentLocale = newLocale;
      fetchBrands(_currentLocale!);
    }
  }

  Future<void> fetchBrands(String locale) async {
    setState(() => isLoading = true);
    try {
      final response = await ApiService.fetchBrands(locale);
      setState(() {
        brands = response;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) return const Center(child: CategoriesSkelton());

    if (brands.isEmpty) {
      return const Center(child: Text("No category found"));
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(
          brands.length,
              (index) => Padding(
            padding: EdgeInsets.only(
              top: 15.0,
              right: index == brands.length - 1 ? defaultPadding : 0,
            ),
            child: CategoryBtn(
              category: brands[index].title,
              image: brands[index].image,
              press: () {
                if (brands[index].slug != null) {
                  Navigator.pushNamed(context, brands[index].slug!);
                }
              },
            ),
          ),
        ),
      ),
    );
  }
}
