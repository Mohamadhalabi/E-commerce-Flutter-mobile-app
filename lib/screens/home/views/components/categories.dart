import 'package:flutter/material.dart';
import 'package:shop/components/skleton/others/categories_skelton.dart';
import '../../../../constants.dart';
import '../../../../services/api_service.dart';
import 'package:shop/models/category_model.dart';
import 'package:shop/screens/category/sub_category_screen.dart'; // Import the screen

class Categories extends StatefulWidget {
  // Add these fields so they can be passed to the SubCategoryScreen
  final int currentIndex;
  final Map<String, dynamic>? user;
  final Function(int) onTabChanged;
  final Function(String) onLocaleChange;

  const Categories({
    super.key,
    required this.currentIndex,
    required this.user,
    required this.onTabChanged,
    required this.onLocaleChange,
  });

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
      fetchCategories(newLocale);
    }
  }

  Future<void> fetchCategories(String locale) async {
    setState(() => isLoading = true);
    try {
      final data = await ApiService.fetchCategories(locale);
      setState(() {
        categories = data;
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
                // NAVIGATION LOGIC
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SubCategoryScreen(
                      // Assuming your CategoryModel has an 'id' field
                      parentId: categories[index].id,
                      title: categories[index].name,
                      // Pass the required parameters down
                      currentIndex: widget.currentIndex,
                      user: widget.user,
                      onTabChanged: widget.onTabChanged,
                      onLocaleChange: widget.onLocaleChange,
                    ),
                  ),
                );
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
    return Material(
      color: Colors.transparent,
      child: InkWell(
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
                  color: greenColor, // Ensure greenColor is defined in constants
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}