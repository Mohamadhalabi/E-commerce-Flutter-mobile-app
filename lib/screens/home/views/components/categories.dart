import 'package:flutter/material.dart';
import 'package:shop/route/screen_export.dart';
import '../../../../constants.dart';

class CategoryModel {
  final String name;
  final String? route;

  CategoryModel({
    required this.name,
    this.route,
  });
}

List<CategoryModel> demoCategories = [
  CategoryModel(
      name: "On Sale",
      route: onSaleScreenRoute),
  CategoryModel(name: "Man's"),
  CategoryModel(name: "Woman’s"),
  CategoryModel(
      name: "Kids", route: kidsScreenRoute),
];

class Categories extends StatelessWidget {
  const Categories({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          ...List.generate(
            demoCategories.length,
                (index) => Padding(
              padding: EdgeInsets.only(
                  top: 7.0,
                  bottom: 15.0,
                  left: index == 0 ? defaultPadding : defaultPadding / 2,
                  right:
                  index == demoCategories.length - 1 ? defaultPadding : 0),
              child: CategoryBtn(
                category: demoCategories[index].name,
                press: () {
                  if (demoCategories[index].route != null) {
                    Navigator.pushNamed(context, demoCategories[index].route!);
                  }
                },
              ),
            ),
          ),
        ],
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