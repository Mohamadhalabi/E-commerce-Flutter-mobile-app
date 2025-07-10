import 'package:flutter/material.dart';
import 'package:shop/components/skleton/others/categories_skelton.dart';
import 'package:shop/services/api_service.dart';
import '../../../../constants.dart';
import '../screens/home/views/components/categories.dart';

class CategoryModel {
  final int id;
  final String name;
  final String image;
  final String? route;

  CategoryModel({
    required this.id,
    required this.name,
    required this.image,
    this.route,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'],
      name: json['name'],
      image: json['icon'] ?? 'https://dev-srv.tlkeys.com/storage/AAAA/180x180.jpg',
      route: json['slug'],
    );
  }
}

class Categories extends StatefulWidget {
  const Categories({super.key});

  @override
  State<Categories> createState() => _CategoriesState();
}

class _CategoriesState extends State<Categories> {
  List<CategoryModel> categories = [];
  bool isLoading = true;
  String? _currentLocale;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final newLocale = Localizations.localeOf(context).languageCode;
    if (_currentLocale != newLocale) {
      _currentLocale = newLocale;
      fetchCategories(_currentLocale!);
    }
  }

  Future<void> fetchCategories(String locale) async {
    setState(() => isLoading = true);
    try {
      final response = await ApiService.fetchCategories(locale);
      setState(() {
        categories = response;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) return const Center(child: CategoriesSkelton());

    if (categories.isEmpty) {
      return const Center(child: Text("No category found"));
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(
          categories.length,
              (index) => Padding(
            padding: EdgeInsets.only(
              top: 15.0,
              right: index == categories.length - 1 ? defaultPadding : 0,
            ),
            child: CategoryBtn(
              category: categories[index].name,
              image: categories[index].image,
              press: () {
                if (categories[index].route != null) {
                  Navigator.pushNamed(context, categories[index].route!);
                }
              },
            ),
          ),
        ),
      ),
    );
  }
}
