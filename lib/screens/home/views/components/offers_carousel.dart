import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shop/components/dot_indicators.dart';
import '../../../../constants.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class OffersCarousel extends StatefulWidget {
  const OffersCarousel({super.key});

  @override
  State<OffersCarousel> createState() => _OffersCarouselState();
}

class _OffersCarouselState extends State<OffersCarousel> {
  int _selectedIndex = 0;
  late PageController _pageController;
  late Timer _timer;
  List<Map<String, String>> offers = [];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
    _fetchSliders();

    _timer = Timer.periodic(const Duration(seconds: 4), (Timer timer) {
      if (_selectedIndex < offers.length - 1) {
        _selectedIndex++;
      } else {
        _selectedIndex = 0;
      }
      _pageController.animateToPage(
        _selectedIndex,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
      );
    });
  }

  Future<void> _fetchSliders() async {
    // Load the environment variables
    await dotenv.load();

    // Retrieve the API base URL, API key, and Secret key from the .env file
    String apiBaseUrl = dotenv.env['API_BASE_URL'] ?? '';
    String apiKey = dotenv.env['API_KEY'] ?? '';
    String secretKey = dotenv.env['SECRET_KEY'] ?? '';

    // Construct the full API URL
    String url = '$apiBaseUrl/get-sliders';

    // Make the HTTP request with headers including API_KEY and SECRET_KEY
    final response = await http.get(
      Uri.parse(url),
      headers: {
        'api-key': apiKey,
        'secret-key': secretKey,
      },
    );

    if (response.statusCode == 200) {
      List<dynamic> data = jsonDecode(response.body);

      // Explicitly cast the dynamic data to List<Map<String, String>>
      setState(() {
        offers = data.map((item) {
          return {
            'image': item['image'].toString(),
            'link': item['link'].toString(),
          };
        }).toList();
      });
    }
  }


  @override
  void dispose() {
    _pageController.dispose();
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1.87,
      child: Stack(
        alignment: Alignment.bottomRight,
        children: [
          if (offers.isNotEmpty)
            PageView.builder(
              controller: _pageController,
              itemCount: offers.length,
              onPageChanged: (int index) {
                setState(() {
                  _selectedIndex = index;
                });
              },
              itemBuilder: (context, index) => BannerMStyle1(
                image: offers[index]['image']!,
                press: () {
                  print("Redirecting to: ${offers[index]['link']}");
                },
              ),
            ),
          FittedBox(
            child: Padding(
              padding: const EdgeInsets.all(defaultPadding),
              child: SizedBox(
                height: 16,
                child: Row(
                  children: List.generate(
                    offers.length,
                        (index) => Padding(
                      padding: const EdgeInsets.only(left: defaultPadding / 4),
                      child: DotIndicator(
                        isActive: index == _selectedIndex,
                        activeColor: Colors.white70,
                        inActiveColor: Colors.white54,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}

class BannerMStyle1 extends StatelessWidget {
  const BannerMStyle1({super.key, required this.image, required this.press});

  final String image;
  final VoidCallback press;

  @override
  Widget build(BuildContext context) {
    return BannerM(
      image: image,
      press: press,
      children: const [Padding(padding: EdgeInsets.all(defaultPadding), child: SizedBox.shrink())],
    );
  }
}

class BannerM extends StatelessWidget {
  const BannerM({super.key, required this.image, required this.press, required this.children});

  final String image;
  final VoidCallback press;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1.00,
      child: GestureDetector(
        onTap: press,
        child: Stack(
          children: [
            Image.network(image, fit: BoxFit.contain),
            ...children,
          ],
        ),
      ),
    );
  }
}