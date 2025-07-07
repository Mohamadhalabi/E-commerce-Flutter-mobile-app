import 'package:flutter/material.dart';
import 'package:shop/components/skleton/others/categories_skelton.dart';
import 'package:shop/services/api_service.dart';
import '../../../../constants.dart';
import '../screens/home/views/components/categories.dart';

class BrandModel {
  final String name;
  final String image;
  final String? route;

  BrandModel({
    required this.name,
    required this.image,
    this.route,
  });

  factory BrandModel.fromJson(Map<String, dynamic> json) {
    return BrandModel(
      name: json['name'],
      image: json['icon'] ?? 'https://dev-srv.tlkeys.com/storage/AAAA/180x180.jpg',
      route: json['slug'],
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
      return const Center(child: Text("No categories found"));
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
              category: brands[index].name,
              image: brands[index].image,
              press: () {
                if (brands[index].route != null) {
                  Navigator.pushNamed(context, brands[index].route!);
                }
              },
            ),
          ),
        ),
      ),
    );
  }
}
