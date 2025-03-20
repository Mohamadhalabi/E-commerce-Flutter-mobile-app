import 'package:flutter/material.dart';
// import 'package:shop/route/screen_export.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../../../constants.dart';

// For API fetch
class CategoryModel {
  final String name;
  final String? route;

  CategoryModel({
    required this.name,
    this.route,
  });

  // Factory constructor to create CategoryModel from JSON data
  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      name: json['name'],
      route: json['route'],
    );
  }
}

Future<List<CategoryModel>> fetchCategories() async {
  final response = await http.get(
    Uri.parse('${AppConstants.baseUrl}/get-categories'),
    headers: {
      'Accept-Language': 'en',
      'Content-Type': 'application/json',
      'currency': 'USD',
      'Accept': 'application/json',
      'secret-key': AppConstants.secretKey,
      'api-key': AppConstants.apiKey,
    },
  );

  if (response.statusCode == 200) {
    final Map<String, dynamic> jsonResponse = json.decode(response.body);
    final List<dynamic> categoriesData = jsonResponse['categories']; // ✅ Extract categories list

    return categoriesData.map((json) => CategoryModel.fromJson(json)).toList();
  } else {
    throw Exception('Failed to load categories');
  }
}
// End For API fetch

class Categories extends StatelessWidget {
  const Categories({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<CategoryModel>>(
      future: fetchCategories(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return CircularProgressIndicator();
        } else if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Text('No categories available');
        }

        final categories = snapshot.data!;

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              ...List.generate(
                categories.length,
                    (index) => Padding(
                  padding: EdgeInsets.only(
                    left: index == 0 ? defaultPadding : defaultPadding / 2,
                    right: index == categories.length - 1 ? defaultPadding : 0,
                  ),
                  child: CategoryBtn(
                    category: categories[index].name,
                    isActive: index == 0,
                    press: () {
                      if (categories[index].route != null) {
                        Navigator.pushNamed(context, categories[index].route!);
                      }
                    },
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class CategoryBtn extends StatelessWidget {
  const CategoryBtn({
    super.key,
    required this.category,
    required this.isActive,
    required this.press,
  });

  final String category;
  final bool isActive;
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
          color: isActive ? primaryColor : Colors.transparent,
          border: Border.all(
              color: isActive
                  ? Colors.transparent
                  : Theme.of(context).dividerColor),
          borderRadius: const BorderRadius.all(Radius.circular(30)),
        ),
        child: Row(
          children: [
            Text(
              category,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: isActive
                    ? Colors.white
                    : Theme.of(context).textTheme.bodyLarge!.color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}