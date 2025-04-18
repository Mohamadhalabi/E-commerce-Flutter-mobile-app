import 'package:flutter/material.dart';
import 'package:shop/components/skleton/others/categories_skelton.dart';
import 'package:shop/services/api_initializer.dart';
import '../../../../constants.dart';

class CategoryModel {
  final String name;
  final String? route;

  CategoryModel({
    required this.name,
    this.route,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      name: json['name'],
      route: null,
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

  @override
  void initState() {
    super.initState();
    fetchCategories();
  }

  Future<void> fetchCategories() async {
    try {
      final response = await apiClient.get('/get-categories');
      final List data = response['categories'] ?? [];

      setState(() {
        categories = data.map((item) => CategoryModel.fromJson(item)).toList();
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CategoriesSkelton());
    }

    if (categories.isEmpty) {
      return const Center(child: Text("No categories found"));
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(
          categories.length,
              (index) => Padding(
            padding: EdgeInsets.only(
              top: 7.0,
              bottom: 15.0,
              left: index == 0 ? defaultPadding : defaultPadding / 2,
              right: index == categories.length - 1 ? defaultPadding : 0,
            ),
            child: CategoryBtn(
              category: categories[index].name,
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

class CategoryBtn extends StatelessWidget {
  const CategoryBtn({
    super.key,
    required this.category,
    required this.press,
  });

  final String category;
  final VoidCallback press;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: press,
      borderRadius: const BorderRadius.all(Radius.circular(30)),
      child: Container(
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: defaultPadding),
        decoration: BoxDecoration(
          color: Colors.transparent,
          border: Border.all(
            color: Colors.grey,
          ),
          borderRadius: const BorderRadius.all(Radius.circular(15)),
        ),
        child: Row(
          children: [
            Text(
              category,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).textTheme.bodyLarge!.color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}