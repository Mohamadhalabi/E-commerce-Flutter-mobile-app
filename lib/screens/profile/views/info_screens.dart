import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:shop/constants.dart';

// -----------------------------------------------------------------------------
// 1. REUSABLE PROFESSIONAL LAYOUT (Dark Mode Ready)
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
    // ✅ Dark Mode Detection
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final Color scaffoldBg = Theme.of(context).scaffoldBackgroundColor;
    final Color cardBg = isDark ? const Color(0xFF1C1C23) : Colors.white;
    final Color appBarBg = isDark ? const Color(0xFF1C1C23) : Colors.white;
    final Color textColor = isDark ? Colors.white : Colors.black;
    final Color iconColor = isDark ? Colors.white : Colors.black;

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        backgroundColor: appBarBg,
        elevation: 0,
        centerTitle: true,
        surfaceTintColor: Colors.transparent,
        title: Text(
          title,
          style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, size: 20, color: iconColor),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      bottomNavigationBar: bottomAction != null
          ? Container(
        padding: const EdgeInsets.all(defaultPadding),
        decoration: BoxDecoration(
          color: cardBg, // Dynamic BG
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
                color: cardBg, // Dynamic Card BG
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  if (!isDark) // Only show shadow in light mode
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
// 2. HELPER WIDGETS (Dark Mode Ready)
// -----------------------------------------------------------------------------
class InfoSectionTitle extends StatelessWidget {
  final String title;
  const InfoSectionTitle(this.title, {super.key});

  @override
  Widget build(BuildContext context) {
    // ✅ Dynamic Text Color
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final Color color = isDark ? Colors.white : Colors.black87;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: color,
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
    // ✅ Dynamic Text Color
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final Color color = isDark ? Colors.white70 : Colors.grey.shade700;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 15,
          height: 1.6,
          color: color,
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
      title: tr.aboutUsTitle,
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
      title: tr.deliveryInfoTitle,
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
      title: tr.termsConditionsTitle,
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

    // ✅ Colors for ListTiles
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final Color iconBg = isDark ? const Color(0xFF2A2A35) : Colors.grey.shade100;
    final Color textColor = isDark ? Colors.white : Colors.black;
    final Color subTextColor = isDark ? Colors.white60 : Colors.grey.shade600;

    return InfoPageLayout(
      title: tr.contactUsTitle,
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
            decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
            child: const Icon(Icons.email_outlined, color: primaryColor),
          ),
          title: Text(tr.emailUs, style: TextStyle(color: textColor, fontWeight: FontWeight.w600)),
          subtitle: Text("support@tlkeys.com", style: TextStyle(color: subTextColor)),
        ),
        const Divider(),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
            child: const Icon(Icons.phone_outlined, color: primaryColor),
          ),
          title: Text(tr.callUs, style: TextStyle(color: textColor, fontWeight: FontWeight.w600)),
          subtitle: Text("+971504429045", style: TextStyle(color: subTextColor)),
        ),
        const Divider(),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
            child: const Icon(Icons.location_on_outlined, color: primaryColor),
          ),
          title: Text(tr.visitUs, style: TextStyle(color: textColor, fontWeight: FontWeight.w600)),
          subtitle: Text(tr.addressFull, style: TextStyle(color: subTextColor)),
        ),
      ],
    );
  }
}