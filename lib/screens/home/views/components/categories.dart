import 'package:flutter/material.dart';
import 'package:shop/components/skleton/others/categories_skelton.dart';
import 'package:shop/services/api_initializer.dart';
import '../../../../constants.dart';

class CategoryModel {
  final String name;
  final String image;
  final String? route;

  CategoryModel({
    required this.name,
    required this.image,
    this.route,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
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
              top: 15.0,
              // bottom: 15.0,
              // left: index == 0 ? defaultPadding : defaultPadding / 2,
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

class CategoryBtn extends StatelessWidget {
  const CategoryBtn({
    super.key,
    required this.category,
    required this.image,
    required this.press,
  });

  final String category;
  final String image;
  final VoidCallback press;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: press,
      borderRadius: BorderRadius.circular(15),
      child: Column(
        children: [
          Container(
            width: 90,
            height: 90,
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  spreadRadius: 2,
                  blurRadius: 5,
                )
              ],
            ),
            child: Image.network(image, fit: BoxFit.contain),
          ),
          const SizedBox(height: 6),
          SizedBox(
            width: 130,
            child: Text(
              category,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: greenColor
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}