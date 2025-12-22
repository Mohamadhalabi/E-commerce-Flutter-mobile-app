import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart'; // ✅ Import Localization
import 'package:shop/constants.dart';

// -----------------------------------------------------------------------------
// 1. REUSABLE PROFESSIONAL LAYOUT
// -----------------------------------------------------------------------------
class InfoPageLayout extends StatelessWidget {
  final String title;
  final String? iconSrc;
  final List<Widget> children;
  final Widget? bottomAction;

  const InfoPageLayout({
    super.key,
    required this.title,
    this.iconSrc,
    required this.children,
    this.bottomAction,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F5F7),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Text(
          title,
          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      bottomNavigationBar: bottomAction != null
          ? Container(
        padding: const EdgeInsets.all(defaultPadding),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(child: bottomAction!),
      )
          : null,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(defaultPadding),
        child: Column(
          children: [
            if (iconSrc != null) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: SvgPicture.asset(
                  iconSrc!,
                  width: 40,
                  height: 40,
                  colorFilter: const ColorFilter.mode(primaryColor, BlendMode.srcIn),
                ),
              ),
              const SizedBox(height: 24),
            ],
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: children,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// 2. HELPER WIDGETS
// -----------------------------------------------------------------------------
class InfoSectionTitle extends StatelessWidget {
  final String title;
  const InfoSectionTitle(this.title, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
    );
  }
}

class InfoText extends StatelessWidget {
  final String text;
  const InfoText(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 15,
          height: 1.6,
          color: Colors.grey.shade700,
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// 3. ACTUAL SCREENS (Now using Localization)
// -----------------------------------------------------------------------------

class AboutUsScreen extends StatelessWidget {
  const AboutUsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tr = AppLocalizations.of(context)!;
    return InfoPageLayout(
      title: tr.aboutUsTitle, // "About Us"
      children: [
        InfoSectionTitle(tr.whoWeAreTitle),
        InfoText(tr.whoWeAreText),
        InfoSectionTitle(tr.ourMissionTitle),
        InfoText(tr.ourMissionText),
      ],
    );
  }
}

class DeliveryInfoScreen extends StatelessWidget {
  const DeliveryInfoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tr = AppLocalizations.of(context)!;
    return InfoPageLayout(
      title: tr.deliveryInfoTitle, // "Delivery Information"
      children: [
        InfoSectionTitle(tr.shippingPolicyTitle),
        InfoText(tr.shippingPolicyText),
        InfoSectionTitle(tr.estimatedDeliveryTitle),
        InfoText(tr.estimatedDeliveryText),
        InfoSectionTitle(tr.trackingOrdersTitle),
        InfoText(tr.trackingOrdersText),
      ],
    );
  }
}

class TermsConditionScreen extends StatelessWidget {
  const TermsConditionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tr = AppLocalizations.of(context)!;
    return InfoPageLayout(
      title: tr.termsConditionsTitle, // "Terms & Conditions"
      children: [
        InfoSectionTitle(tr.termsIntroTitle),
        InfoText(tr.termsIntroText),
        InfoSectionTitle(tr.termsUserAccountsTitle),
        InfoText(tr.termsUserAccountsText),
        InfoSectionTitle(tr.termsReturnsTitle),
        InfoText(tr.termsReturnsText),
      ],
    );
  }
}

class ContactUsScreen extends StatelessWidget {
  const ContactUsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tr = AppLocalizations.of(context)!;

    return InfoPageLayout(
      title: tr.contactUsTitle, // "Contact Us"
      bottomAction: ElevatedButton(
        onPressed: () {
          // Add logic to open email or phone dialer
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: Text(
          tr.sendMessageButton,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ),
      children: [
        InfoSectionTitle(tr.getInTouchTitle),
        InfoText(tr.getInTouchText),
        const SizedBox(height: 10),

        // Contact Details List
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: Colors.grey.shade100, shape: BoxShape.circle),
            child: const Icon(Icons.email_outlined, color: primaryColor),
          ),
          title: Text(tr.emailUs),
          subtitle: const Text("support@tlkeys.com"), // Keeps email standard
        ),
        const Divider(),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: Colors.grey.shade100, shape: BoxShape.circle),
            child: const Icon(Icons.phone_outlined, color: primaryColor),
          ),
          title: Text(tr.callUs),
          subtitle: const Text("+971504429045"), // Keeps phone standard
        ),
        const Divider(),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: Colors.grey.shade100, shape: BoxShape.circle),
            child: const Icon(Icons.location_on_outlined, color: primaryColor),
          ),
          title: Text(tr.visitUs),
          subtitle: Text(tr.addressFull), // Address is translated
        ),
      ],
    );
  }
}