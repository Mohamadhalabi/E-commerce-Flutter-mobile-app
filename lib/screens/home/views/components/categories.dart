import 'package:flutter/material.dart';
import 'package:shop/components/skleton/others/categories_skelton.dart';
import 'package:shop/constants.dart';
import 'package:shop/models/category_model.dart';
import 'package:shop/screens/category/sub_category_screen.dart';
import 'package:shop/services/api_service.dart';

class Categories extends StatefulWidget {
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
  List<CategoryModel> _categories = [];
  bool _isLoading = true;
  String? _locale;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final locale = Localizations.localeOf(context).languageCode;
    if (locale == _locale) return;
    _locale = locale;
    _isLoading = true;
    _fetch(locale);
  }

  Future<void> _fetch(String locale) async {
    try {
      final data = await ApiService.fetchCategories(locale);
      if (!mounted || locale != _locale) return;
      setState(() {
        _categories = data;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Categories failed: $e');
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  void _open(CategoryModel category) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SubCategoryScreen(
          parentId: category.id,
          title: category.name,
          currentIndex: widget.currentIndex,
          user: widget.user,
          onTabChanged: widget.onTabChanged,
          onLocaleChange: widget.onLocaleChange,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.only(top: 12),
        child: Center(child: CategoriesSkelton()),
      );
    }
    // No categories → no empty "No category found" text on the home screen
    if (_categories.isEmpty) return const SizedBox.shrink();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(
        defaultPadding - 4,
        14,
        defaultPadding - 4,
        4,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final category in _categories)
            CategoryBtn(
              category: category.name,
              image: category.image,
              press: () => _open(category),
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
    required this.image,
    required this.press,
  });

  final String category;
  final String image;
  final VoidCallback press;

  @override
  Widget build(BuildContext context) {
    final isDark = AppPalette.isDark(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: press,
        borderRadius: BorderRadius.circular(16),
        child: SizedBox(
          width: 84,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            child: Column(
              children: [
                Container(
                  width: 68,
                  height: 68,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isDark ? Colors.white12 : blackColor10,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Image.network(
                    image,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => const Icon(
                      Icons.category_outlined,
                      color: blackColor40,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  category,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    height: 1.25,
                    color: AppPalette.text(context),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}