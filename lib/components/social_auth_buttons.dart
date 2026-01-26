import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart'; // Ensure you have flutter_svg

class SocialAuthButtons extends StatelessWidget {
  final VoidCallback onGoogleTap;
  final VoidCallback onFacebookTap;

  const SocialAuthButtons({
    super.key,
    required this.onGoogleTap,
    required this.onFacebookTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildSocialBtn(
          iconPath: "assets/icons/google.svg", // Make sure you have this SVG
          onTap: onGoogleTap,
        ),
        const SizedBox(width: 20),
        _buildSocialBtn(
          iconPath: "assets/icons/facebook.svg", // Make sure you have this SVG
          onTap: onFacebookTap,
        ),
      ],
    );
  }

  Widget _buildSocialBtn({required String iconPath, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 50,
        width: 50,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          shape: BoxShape.circle,
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: SvgPicture.asset(iconPath),
      ),
    );
  }
}