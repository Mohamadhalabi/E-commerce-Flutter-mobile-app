import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shop/components/skleton/skelton.dart';
import 'package:shop/components/skleton/subcategory_card_skeleton.dart';
import 'package:shop/screens/category/sub_category_products_screen.dart';
import 'package:shop/services/api_service.dart';
import '../../components/common/CustomBottomNavigationBar.dart';
import 'package:shop/route/route_constants.dart';

class SubCategoryScreen extends StatefulWidget {
  final int parentId;
  final String title;
  final int currentIndex;
  final Map<String, dynamic>? user;
  final Function(int) onTabChanged;
  final Function(String) onLocaleChange;

  const SubCategoryScreen({
    super.key,
    required this.parentId,
    required this.title,
    required this.currentIndex,
    required this.user,
    required this.onTabChanged,
    required this.onLocaleChange,
  });

  @override
  State<SubCategoryScreen> createState() => _SubCategoryScreenState();
}

class _SubCategoryScreenState extends State<SubCategoryScreen> {
  List<dynamic> subcategories = [];
  bool isLoading = true;
  late int _localCurrentIndex;

  @override
  void initState() {
    super.initState();
    _localCurrentIndex = widget.currentIndex;
    fetchSubcategories();
  }

  Future<void> fetchSubcategories() async {
    try {
      final data = await ApiService.fetchSubcategories(widget.parentId);
      setState(() {
        subcategories = data;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  // ✅ FIXED NAVIGATION: Reset Stack completely (Same as Products Screen)
  void _onTabTapped(int index) {
    setState(() {
      _localCurrentIndex = index;
    });

    if (index == widget.currentIndex) {
      Navigator.of(context).popUntil((route) => route.isFirst);
      return;
    }

    // PUSH AND REMOVE UNTIL -> Prevents Home Screen Flash
    Navigator.pushNamedAndRemoveUntil(
      context,
      entryPointScreenRoute,
          (route) => false,
      arguments: index,
    );
  }

  Widget _buildGrid({required int itemCount, required IndexedWidgetBuilder itemBuilder}) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 15),
      itemCount: itemCount,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.0,
      ),
      itemBuilder: itemBuilder,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.white,
      ),
      body: isLoading
          ? _buildGrid(
        itemCount: 8,
        itemBuilder: (ctx, i) => const SubCategoryCardSkeleton(),
      )
          : subcategories.isEmpty
          ? const Center(child: Text("No subcategories found"))
          : _buildGrid(
        itemCount: subcategories.length,
        itemBuilder: (context, index) {
          final item = subcategories[index];
          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => SubCategoryProductsScreen(
                    categorySlug: item['slug'] ?? '',
                    title: item['name'] ?? '',
                    currentIndex: widget.currentIndex,
                    user: widget.user,
                    onTabChanged: widget.onTabChanged,
                    onLocaleChange: widget.onLocaleChange,
                  ),
                ),
              );
            },
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200, width: 1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: CachedNetworkImage(
                      imageUrl: item['image'] ?? '',
                      fit: BoxFit.contain,
                      placeholder: (context, url) => const Skeleton(),
                      errorWidget: (context, url, error) =>
                      const Icon(Icons.image_not_supported, color: Colors.grey),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    item['name'] ?? '',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          );
        },
      ),

      bottomNavigationBar: CustomBottomNavigationBar(
        currentIndex: _localCurrentIndex,
        onTap: _onTabTapped,
      ),
    );
  }
}