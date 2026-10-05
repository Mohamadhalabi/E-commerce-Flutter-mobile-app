import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shop/constants.dart';
import 'package:shop/route/route_constants.dart';
import 'package:shop/components/common/CustomBottomNavigationBar.dart';

// Shared contact details (used by every page below)
const String kSupportEmail = "info@tlkeys.com";
const String kSupportPhone = "+971504429045";
const String kWhatsAppNumber = "971504429045";

Future<void> _openUri(BuildContext context, Uri uri) async {
  final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
  if (!ok && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Couldn't open this on your device.")),
    );
  }
}

// =============================================================================
// 1. LAYOUT
// =============================================================================
class InfoPageLayout extends StatelessWidget {
  final String title;
  final List<Widget> children;
  final Widget? bottomAction;

  /// Shows the glass bottom nav (Profile tab highlighted).
  final bool showBottomNav;

  const InfoPageLayout({
    super.key,
    required this.title,
    required this.children,
    this.bottomAction,
    this.showBottomNav = true,
  });

  // Same behaviour as the other pushed screens (product details, etc.)
  void _onNavTap(BuildContext context, int index) {
    if (index == 3) {
      Navigator.pushNamed(context, cartScreenRoute);
    } else {
      Navigator.pushNamedAndRemoveUntil(
        context,
        entryPointScreenRoute,
            (route) => false,
        arguments: index,
      );
    }
  }

  Widget _actionCard(BuildContext context) {
    final isDark = AppPalette.isDark(context);
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppPalette.card(context),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppPalette.border(context)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.4 : 0.10),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: bottomAction,
    );
  }

  Widget? _buildBottom(BuildContext context) {
    if (!showBottomNav) {
      if (bottomAction == null) return null;
      return SafeArea(
        minimum: const EdgeInsets.only(bottom: 12),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(defaultPadding, 4, defaultPadding, 0),
          child: _actionCard(context),
        ),
      );
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (bottomAction != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(defaultPadding, 4, defaultPadding, 10),
            child: _actionCard(context),
          ),
        CustomBottomNavigationBar(
          currentIndex: 4,
          onTap: (index) => _onNavTap(context, index),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final bg = Theme.of(context).scaffoldBackgroundColor;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
        leadingWidth: 64,
        leading: Padding(
          padding: const EdgeInsetsDirectional.only(start: defaultPadding),
          child: Center(
            child: Semantics(
              button: true,
              label: 'Back',
              child: Material(
                color: AppPalette.cardElevated(context),
                shape: CircleBorder(side: BorderSide(color: AppPalette.border(context))),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () => Navigator.maybePop(context),
                  child: SizedBox(
                    width: 42,
                    height: 42,
                    child: Icon(
                      Icons.arrow_back_ios_new_rounded,
                      size: 17,
                      color: AppPalette.text(context),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        title: Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: AppPalette.text(context),
            fontWeight: FontWeight.w800,
            fontSize: 17,
          ),
        ),
      ),
      extendBody: showBottomNav, // content scrolls under the glass nav
      bottomNavigationBar: _buildBottom(context),
      body: Builder(
        // context inside the body: its bottom padding includes nav + action card
        builder: (bodyContext) => ListView(
          padding: EdgeInsets.fromLTRB(
            defaultPadding,
            8,
            defaultPadding,
            MediaQuery.paddingOf(bodyContext).bottom + 24,
          ),
          children: children,
        ),
      ),
    );
  }
}

// =============================================================================
// 2. BUILDING BLOCKS
// =============================================================================

/// Red header card at the top of each page.
class InfoHero extends StatelessWidget {
  const InfoHero({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.lastUpdated,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final String? lastUpdated;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [primaryColor, primaryDeepColor],
        ),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.22),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Stack(
          children: [
            PositionedDirectional(
              top: -40,
              end: -30,
              child: Container(
                width: 130,
                height: 130,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.08),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(icon, color: Colors.white, size: 23),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 21,
                      fontWeight: FontWeight.w800,
                      height: 1.25,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      subtitle!,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.85),
                        fontSize: 13.5,
                        height: 1.45,
                      ),
                    ),
                  ],
                  if (lastUpdated != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.18),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        "Last updated: $lastUpdated",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// White rounded card that groups one section.
class InfoCard extends StatelessWidget {
  const InfoCard({super.key, required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final isDark = AppPalette.isDark(context);
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 8),
      decoration: BoxDecoration(
        color: AppPalette.card(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppPalette.border(context)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.25 : 0.03),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }
}

/// Section title. With [number], shows a red numbered badge (used in Terms).
class InfoSectionTitle extends StatelessWidget {
  final String title;
  final int? number;
  const InfoSectionTitle(this.title, {super.key, this.number});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          if (number != null)
            Container(
              width: 26,
              height: 26,
              alignment: Alignment.center,
              decoration: const BoxDecoration(color: primaryColor, shape: BoxShape.circle),
              child: Text(
                "$number",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            )
          else
            Container(
              width: 4,
              height: 18,
              decoration: BoxDecoration(
                color: primaryColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 16.5,
                fontWeight: FontWeight.w800,
                color: AppPalette.text(context),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class InfoSubTitle extends StatelessWidget {
  final String text;
  const InfoSubTitle(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 6),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 14.5,
          fontWeight: FontWeight.w800,
          color: AppPalette.text(context),
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
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 14,
          height: 1.6,
          color: AppPalette.isDark(context) ? Colors.white70 : blackColor80,
        ),
      ),
    );
  }
}

class InfoBullets extends StatelessWidget {
  final List<String> items;
  const InfoBullets(this.items, {super.key});

  @override
  Widget build(BuildContext context) {
    final color = AppPalette.isDark(context) ? Colors.white70 : blackColor80;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        children: [
          for (final item in items)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: primaryColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      item,
                      style: TextStyle(fontSize: 14, height: 1.55, color: color),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// List with an icon tile per item (used for "Future goals").
class InfoIconList extends StatelessWidget {
  final List<InfoIconItem> items;
  const InfoIconList(this.items, {super.key});

  @override
  Widget build(BuildContext context) {
    final textColor = AppPalette.isDark(context) ? Colors.white70 : blackColor80;
    return Column(
      children: [
        for (final item in items)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(AppPalette.isDark(context) ? 0.18 : 0.08),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Icon(item.icon, size: 19, color: primaryColor),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 7),
                    child: Text(
                      item.text,
                      style: TextStyle(fontSize: 14, height: 1.5, color: textColor),
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class InfoIconItem {
  final IconData icon;
  final String text;
  const InfoIconItem(this.icon, this.text);
}

/// Numbered timeline (used for the shipping process).
class InfoSteps extends StatelessWidget {
  final List<InfoStep> steps;
  const InfoSteps(this.steps, {super.key});

  @override
  Widget build(BuildContext context) {
    final muted = AppPalette.isDark(context) ? Colors.white70 : blackColor80;
    return Column(
      children: [
        for (var i = 0; i < steps.length; i++)
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Column(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(
                        color: primaryColor,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        "${i + 1}",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    if (i < steps.length - 1)
                      Expanded(
                        child: Container(
                          width: 2,
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          color: primaryColor.withOpacity(0.25),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 14, top: 3),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          steps[i].title,
                          style: TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w800,
                            color: AppPalette.text(context),
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          steps[i].text,
                          style: TextStyle(fontSize: 13.5, height: 1.5, color: muted),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class InfoStep {
  final String title;
  final String text;
  const InfoStep(this.title, this.text);
}

/// Side-by-side highlight tiles (used for delivery times).
class InfoStatTiles extends StatelessWidget {
  final List<InfoStat> stats;
  const InfoStatTiles(this.stats, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < stats.length; i++) ...[
            if (i > 0) const SizedBox(width: 10),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppPalette.cardElevated(context),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(stats[i].icon, color: primaryColor, size: 22),
                    const SizedBox(height: 8),
                    Text(
                      stats[i].title,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppPalette.textMuted(context),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      stats[i].value,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: AppPalette.text(context),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      stats[i].caption,
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.4,
                        color: AppPalette.textMuted(context),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class InfoStat {
  final IconData icon;
  final String title;
  final String value;
  final String caption;
  const InfoStat(this.icon, this.title, this.value, this.caption);
}

/// Highlighted callout for important notes and warnings.
class InfoNote extends StatelessWidget {
  final String text;
  final IconData icon;
  const InfoNote(this.text, {super.key, this.icon = Icons.info_outline_rounded});

  @override
  Widget build(BuildContext context) {
    final isDark = AppPalette.isDark(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: primaryColor.withOpacity(isDark ? 0.14 : 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: primaryColor.withOpacity(0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: primaryColor, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13.5,
                height: 1.5,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.red.shade100 : primaryDarkColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Tappable link row ("Contact us", "Return & Refund Policy", ...).
class InfoLink extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  const InfoLink({
    super.key,
    required this.label,
    required this.onTap,
    this.icon = Icons.arrow_forward_rounded,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: primaryColor.withOpacity(AppPalette.isDark(context) ? 0.14 : 0.06),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    label,
                    style: const TextStyle(
                      color: primaryColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Icon(icon, color: primaryColor, size: 18),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// "Questions?" card used at the bottom of the policy pages.
class _HelpCard extends StatelessWidget {
  const _HelpCard({this.text});
  final String? text;

  @override
  Widget build(BuildContext context) {
    return InfoCard(children: [
      const InfoSectionTitle("Questions?"),
      InfoText(text ?? "Our support team is happy to help."),
      InfoLink(
        label: "Contact us",
        icon: Icons.headset_mic_outlined,
        onTap: () => Navigator.pushNamed(context, contactUsScreenRoute),
      ),
      InfoLink(
        label: kSupportEmail,
        icon: Icons.email_outlined,
        onTap: () => _openUri(context, Uri(scheme: 'mailto', path: kSupportEmail)),
      ),
      InfoLink(
        label: kSupportPhone,
        icon: Icons.phone_outlined,
        onTap: () => _openUri(context, Uri(scheme: 'tel', path: kSupportPhone)),
      ),
    ]);
  }
}

// =============================================================================
// 3. ABOUT US
// =============================================================================
class AboutUsScreen extends StatelessWidget {
  const AboutUsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tr = AppLocalizations.of(context)!;
    return InfoPageLayout(
      title: tr.aboutUsTitle,
      children: [
        const InfoHero(
          icon: Icons.vpn_key_rounded,
          title: "About Techno Lock Keys",
          subtitle: "A creative team driving secure mobility.",
        ),
        InfoCard(children: [
          const InfoSectionTitle("Who we are"),
          const InfoText(
            "We build reliable, secure solutions for automotive locksmiths and workshops.",
          ),
          const InfoText(
            "Founded to make key programming and diagnostics simpler, faster, and more accessible.",
          ),
          const InfoText(
            "Since day one, we've focused on quality products, expert support, and fair pricing.",
          ),
          InfoLink(
            label: "Contact us",
            icon: Icons.headset_mic_outlined,
            onTap: () => Navigator.pushNamed(context, contactUsScreenRoute),
          ),
        ]),
        const InfoCard(children: [
          InfoSectionTitle("Our future goals"),
          InfoSubTitle("We aim to lead with innovation & service"),
          SizedBox(height: 6),
          InfoIconList([
            InfoIconItem(Icons.public_rounded,
                "Increase market coverage with curated products and strategic partnerships."),
            InfoIconItem(Icons.local_shipping_outlined,
                "Improve customer experience through faster delivery and localized support."),
            InfoIconItem(Icons.speed_rounded,
                "Streamline operations to reduce lead times and optimize costs."),
            InfoIconItem(Icons.eco_outlined,
                "Implement eco-friendly practices across packaging and logistics."),
            InfoIconItem(Icons.school_outlined,
                "Foster a positive culture of continuous learning and customer centricity."),
          ]),
        ]),
      ],
    );
  }
}

// =============================================================================
// 4. DELIVERY INFORMATION
// =============================================================================
class DeliveryInfoScreen extends StatelessWidget {
  const DeliveryInfoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tr = AppLocalizations.of(context)!;
    return InfoPageLayout(
      title: tr.deliveryInfoTitle,
      children: const [
        InfoHero(
          icon: Icons.local_shipping_outlined,
          title: "Delivery Information",
          subtitle: "We're committed to delivering your order safely and as quickly as possible.",
        ),
        InfoCard(children: [
          InfoSectionTitle("Delivery time"),
          InfoStatTiles([
            InfoStat(Icons.location_city_rounded, "Local delivery", "1–3 business days",
                "Major cities. Remote areas may take longer."),
            InfoStat(Icons.flight_takeoff_rounded, "International", "5–10 business days",
                "Excluding customs clearance time."),
          ]),
          InfoText("Delivery windows are estimates provided by the courier."),
        ]),
        InfoCard(children: [
          InfoSectionTitle("Ordering"),
          InfoSubTitle("Add to cart"),
          InfoText(
            "Select your products and add them to the cart. Review quantities and variants before proceeding to checkout.",
          ),
          InfoSubTitle("Order processing"),
          InfoText(
            "After payment is confirmed, orders are verified and prepared within 1–2 business days. During sales or holidays, processing may take slightly longer.",
          ),
        ]),
        InfoCard(children: [
          InfoSectionTitle("Shipping & dispatch"),
          InfoBullets([
            "Estimated shipping time depends on destination, service level, and carrier availability.",
            "You'll receive an email confirmation when your package ships.",
            "Please make sure your contact details and delivery address are accurate to avoid delays.",
            "Customs inspections or local courier backlogs can affect delivery timeframes.",
          ]),
        ]),
        InfoCard(children: [
          InfoSectionTitle("Shipping process"),
          SizedBox(height: 4),
          InfoSteps([
            InfoStep("Order confirmation",
                "Our team confirms your order details and payment, then schedules it for packing."),
            InfoStep("Packaging",
                "Items are packed securely with protective materials to prevent damage in transit."),
            InfoStep("Courier service",
                "We ship with reliable, tracked services appropriate for your region."),
            InfoStep("Shipment tracking",
                "Tracking information is shared by email once the package leaves our facility."),
            InfoStep("Receipt & delivery",
                "Please verify package condition on delivery and keep your receipt for reference."),
            InfoStep("Addressing issues",
                "If you face any delivery issues, contact us with your order number and tracking code for assistance."),
          ]),
          InfoText(
            "You will receive updates at key milestones: dispatch, out for delivery, and delivered.",
          ),
        ]),
        InfoCard(children: [
          InfoSectionTitle("Delivery fees"),
          InfoText(
            "Delivery fees are calculated at checkout based on destination, weight/volume, and selected service.",
          ),
          InfoSubTitle("Free delivery"),
          InfoText(
            "From time to time, we may offer free or discounted shipping promotions. To see current offers, check the homepage or the banner at checkout.",
          ),
        ]),
        InfoNote(
          "tlkeys.com will never request payments via email links. Only pay through our official website or app.",
          icon: Icons.shield_outlined,
        ),
        InfoNote(
          "If you don't see our emails, check your spam/junk folder and mark us as safe.",
          icon: Icons.mark_email_unread_outlined,
        ),
        _HelpCard(
          text: "If you have any questions, contact our support team. We're happy to help.",
        ),
      ],
    );
  }
}

// =============================================================================
// 5. TERMS & CONDITIONS
// =============================================================================
class TermsConditionScreen extends StatelessWidget {
  const TermsConditionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tr = AppLocalizations.of(context)!;

    return InfoPageLayout(
      title: tr.termsConditionsTitle,
      children: [
        const InfoHero(
          icon: Icons.gavel_rounded,
          title: "Terms & Conditions",
          subtitle:
          "Please read these Terms carefully before placing an order. By placing an order you confirm that you have read, understood, and accepted them.",
          lastUpdated: "2026-09-30",
        ),
        const InfoCard(children: [
          InfoSectionTitle("Who we are", number: 1),
          InfoText(
            "tlkeys.com is operated by Techno Lock Keys Trading, a company registered in the United Arab Emirates, with its address at Warehouse Shed No. 1, Maleha Road, Industrial Area 5, Sharjah, UAE.",
          ),
          InfoText(
            "In these Terms, \"we\", \"us\" and \"our\" mean Techno Lock Keys Trading. \"You\" and \"customer\" mean the person or business using the website or placing an order.",
          ),
        ]),
        const InfoCard(children: [
          InfoSectionTitle("Acceptance of these Terms", number: 2),
          InfoText(
            "By using tlkeys.com or placing an order, you agree to these Terms, our Return & Refund Policy, our Delivery Information, and our Privacy Policy.",
          ),
          InfoText(
            "At checkout you are asked to confirm your acceptance. We keep a record of that confirmation, including the date, time, and the version of these Terms in force at that moment.",
          ),
        ]),
        const InfoCard(children: [
          InfoSectionTitle("Professional and lawful use", number: 3),
          InfoText(
            "Our products and services are intended for automotive locksmiths, workshops, and other professionals, and for lawful purposes only.",
          ),
          InfoText(
            "You confirm that you will only use our products, PIN code services, calculators, and software on vehicles you own or are legally authorized to work on.",
          ),
          InfoText(
            "We may refuse or cancel any order, or suspend any account, if we reasonably suspect unlawful use. We are not responsible for any misuse of our products or services.",
          ),
        ]),
        const InfoCard(children: [
          InfoSectionTitle("Your account", number: 4),
          InfoText(
            "You are responsible for keeping your login details confidential and for all activity under your account, including the use of tokens and credits.",
          ),
          InfoText(
            "You must provide accurate and complete information, including your name, phone number, and shipping address, and keep it up to date.",
          ),
        ]),
        const InfoCard(children: [
          InfoSectionTitle("Products and compatibility", number: 5),
          InfoText(
            "We try to describe products and compatibility information accurately. However, vehicle manufacturers change systems frequently, and compatibility lists are provided as a guide only.",
          ),
          InfoText(
            "You are responsible for checking that a product is compatible with your vehicle, programming device, and software version before ordering. If you are unsure, contact us before you buy.",
          ),
          InfoText(
            "We are not responsible for orders placed with the wrong model, year, frequency, chip, or part number, or for programming failures caused by the vehicle, the programming device, its software version, or the procedure used.",
          ),
          InfoText(
            "Product images are for illustration. Minor differences in color, packaging, or appearance do not affect function and are not a defect.",
          ),
        ]),
        const InfoCard(children: [
          InfoSectionTitle("Orders, prices and payment", number: 6),
          InfoText(
            "All prices are shown in US dollars. Prices, stock, and promotions may change without notice until your order is confirmed.",
          ),
          InfoText(
            "If a product is listed at an obviously wrong price, or becomes unavailable, we may cancel the order and refund any amount you paid.",
          ),
          InfoNote(
            "Card, PayPal, and wallet payments carry a 3% processing surcharge, which is shown before you place your order.",
            icon: Icons.credit_card_rounded,
          ),
          InfoText(
            "For bank transfer and cryptocurrency (USDT) payments, your order is processed only after the payment is received and confirmed. You are responsible for any bank or network fees, and for sending the payment to the correct account or wallet address shown at checkout.",
          ),
        ]),
        InfoCard(children: [
          const InfoSectionTitle("Shipping and delivery", number: 7),
          const InfoText(
            "Delivery times shown on our website are estimates from the courier and are not guaranteed.",
          ),
          const InfoText(
            "You are responsible for giving a complete and correct shipping address and a reachable phone number. We are not responsible for delays, extra charges, or losses caused by incorrect or incomplete details.",
          ),
          const InfoText(
            "Once a shipment has been handed to the courier, its tracking record is our proof of dispatch, and the courier's delivery confirmation is our proof of delivery.",
          ),
          const InfoNote(
            "Please inspect your package on delivery. Visible damage to the package must be reported to us within 48 hours of delivery, with photos.",
            icon: Icons.inventory_2_outlined,
          ),
          InfoLink(
            label: "Delivery Information",
            onTap: () => Navigator.pushNamed(context, deliveryInfoScreenRoute),
          ),
        ]),
        const InfoCard(children: [
          InfoSectionTitle("Customs duties, taxes and import fees", number: 8),
          InfoText(
            "Product prices and shipping costs do not include customs duties, import taxes, VAT, brokerage, or clearance fees in the destination country.",
          ),
          InfoNote(
            "These charges are set by the customs authority of your country. You are fully responsible for paying all of them. Techno Lock Keys Trading is not responsible for any customs duties, taxes, or import fees.",
            icon: Icons.account_balance_outlined,
          ),
          InfoText(
            "If a shipment is refused, abandoned, or returned because these charges were not paid, the original shipping cost is non-refundable, and any return shipping, storage, or destruction costs will be deducted from any refund.",
          ),
          InfoText(
            "We are not responsible for delays caused by customs inspection, clearance, or requests for documents. You are responsible for providing any documents or permits your country requires for import.",
          ),
        ]),
        const InfoCard(children: [
          InfoSectionTitle("Declared value and insurance", number: 9),
          InfoText(
            "The declared value shown on shipping and customs documents is based on the value you confirm at checkout.",
          ),
          InfoText(
            "If a shipment is lost or damaged in transit, any claim is limited to the declared value on the shipping documents. Any consequences of the declared value, including penalties or seizure by customs, are your responsibility.",
          ),
        ]),
        const InfoCard(children: [
          InfoSectionTitle("Digital products and services", number: 10),
          InfoText(
            "Digital products include tokens, credits, PIN codes, calculator results, software, activations, and licenses.",
          ),
          InfoNote(
            "Digital products are delivered instantly or shortly after payment, and are non-refundable once delivered, activated, or used.",
            icon: Icons.bolt_rounded,
          ),
          InfoText(
            "Tokens are deducted according to the rules shown on each service page. We cannot refund tokens used because of incorrect VINs, incorrect input data, repeated requests, or page refreshes.",
          ),
          InfoText(
            "If a result is not available for a vehicle, we will not charge a token where the service page says so. Results depend on third-party data and are provided without a guarantee that they will work in every case.",
          ),
        ]),
        InfoCard(children: [
          const InfoSectionTitle("Returns and refunds", number: 11),
          const InfoText(
            "Returns and refunds are handled under our Return & Refund Policy, which forms part of these Terms.",
          ),
          const InfoText(
            "Products that have been programmed, installed, activated, or modified may not be eligible for return, except for proven manufacturing defects.",
          ),
          InfoLink(
            label: "Return & Refund Policy",
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ReturnPolicyScreen()),
            ),
          ),
        ]),
        const InfoCard(children: [
          InfoSectionTitle("Warranty", number: 12),
          InfoText(
            "Where a product has a manufacturer warranty, that warranty applies under the manufacturer's terms. We will help you with warranty claims where possible.",
          ),
          InfoText(
            "To the extent permitted by law, we give no other warranties, and we do not guarantee that any product or service will work with every vehicle, device, or software version.",
          ),
        ]),
        const InfoCard(children: [
          InfoSectionTitle("Limitation of liability", number: 13),
          InfoText(
            "To the extent permitted by law, our total liability for any claim related to an order is limited to the amount you paid for that order.",
          ),
          InfoText(
            "We are not liable for indirect or consequential losses, including lost profit, lost jobs, vehicle downtime, damage to vehicles or modules during programming, or loss of data.",
          ),
          InfoText(
            "Nothing in these Terms limits any liability that cannot be limited under applicable law.",
          ),
        ]),
        InfoCard(children: [
          const InfoSectionTitle("Problems with an order and payment disputes", number: 14),
          const InfoText(
            "If there is a problem with your order, please contact us first at $kSupportEmail or $kSupportPhone. Most issues can be solved quickly.",
          ),
          const InfoNote(
            "Please allow us at least 5 business days to respond and resolve the issue before opening a dispute or chargeback with your bank, card issuer, or PayPal.",
            icon: Icons.schedule_rounded,
          ),
          const InfoText(
            "If a dispute or chargeback is opened, we will provide the payment provider with our records, including your order details, your acceptance of these Terms, tracking and delivery confirmation, and our communication with you.",
          ),
          InfoLink(
            label: "Contact us",
            onTap: () => Navigator.pushNamed(context, contactUsScreenRoute),
          ),
        ]),
        const InfoCard(children: [
          InfoSectionTitle("Intellectual property", number: 15),
          InfoText(
            "All content on tlkeys.com, including text, images, logos, product data, and compatibility data, is owned by or licensed to Techno Lock Keys Trading.",
          ),
          InfoText(
            "You may not copy, reproduce, scrape, or commercially use this content without our prior written permission.",
          ),
        ]),
        InfoCard(children: [
          const InfoSectionTitle("Privacy", number: 16),
          const InfoText(
            "We collect and process personal data as described in our Privacy Policy.",
          ),
          InfoLink(
            label: "Privacy Policy",
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen()),
            ),
          ),
        ]),
        const InfoCard(children: [
          InfoSectionTitle("Events beyond our control", number: 17),
          InfoText(
            "We are not responsible for delays or failure to perform caused by events beyond our reasonable control, including war, regional tensions, government actions, customs or border closures, courier disruptions, natural disasters, epidemics, or outages of third-party systems.",
          ),
        ]),
        const InfoCard(children: [
          InfoSectionTitle("Changes to these Terms", number: 18),
          InfoText(
            "We may update these Terms from time to time. The version that applies to your order is the version in force when you placed it. The date of the latest update is shown at the top of this page.",
          ),
        ]),
        const InfoCard(children: [
          InfoSectionTitle("Governing law and jurisdiction", number: 19),
          InfoText(
            "These Terms and any order are governed by the laws of the United Arab Emirates, as applied in the Emirate of Sharjah.",
          ),
          InfoText(
            "Any dispute that cannot be resolved between us will be subject to the exclusive jurisdiction of the courts of Sharjah, United Arab Emirates.",
          ),
        ]),
        const _HelpCard(
          text: "If you have any questions about these Terms, contact us.",
        ),
      ],
    );
  }
}

// =============================================================================
// 6. PRIVACY POLICY (new)
// =============================================================================
class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return InfoPageLayout(
      title: "Privacy Policy",
      children: [
        const InfoHero(
          icon: Icons.privacy_tip_outlined,
          title: "Privacy Policy",
          subtitle: "We respect your privacy and are committed to protecting your personal data.",
        ),
        const InfoCard(children: [
          InfoSectionTitle("What we collect"),
          InfoText(
            "The information we collect may include contact details, order information, device data, and usage analytics to improve our services.",
          ),
          InfoNote(
            "We do not sell your personal information. We only share it with service providers for payments, shipping, support, and legal compliance.",
            icon: Icons.verified_user_outlined,
          ),
        ]),
        const InfoCard(children: [
          InfoSectionTitle("Payments & security"),
          InfoBullets([
            "Payments are processed securely and we never store full credit or debit card details on our servers.",
            "We use industry-standard measures (encryption, access controls, monitoring) to safeguard your data.",
            "At tlkeys.com, we are transparent about how your data is handled. We encourage you to read this Policy carefully to understand our practices.",
          ]),
        ]),
        const InfoCard(children: [
          InfoSectionTitle("Third parties & cookies"),
          InfoBullets([
            "Some advertisements or embedded services on tlkeys.com may be provided by third parties. These third parties may use cookies or similar technologies to collect information about your activities.",
            "We do not control third-party sites or their privacy practices. Information collected by third parties is governed by their own policies.",
            "tlkeys.com may contain links to external websites not operated by us. When you access such links, their privacy practices apply.",
            "If you choose to disable cookies in your browser, some features of our site may not function properly.",
          ]),
        ]),
        const InfoCard(children: [
          InfoSectionTitle("Customs duties, taxes & import fees"),
          InfoText(
            "Techno Lock Keys is not responsible for any customs duties, import taxes, VAT, brokerage or clearance fees, or any other charges imposed by the destination country.",
          ),
          InfoNote(
            "The customer is fully responsible for paying all such charges in full. These charges are set by local customs authorities and are not included in the product price or shipping cost.",
            icon: Icons.account_balance_outlined,
          ),
          InfoText(
            "If a shipment is refused, abandoned, or returned because these charges were not paid, the original shipping fees are non-refundable, and any return shipping or related costs will be deducted from any refund.",
          ),
          InfoText("We are not responsible for delays caused by customs inspection or clearance."),
        ]),
        InfoCard(children: [
          const InfoSectionTitle("Changes to this policy"),
          const InfoText(
            "Our website policies, including this Privacy Policy and the Terms & Conditions, may be updated from time to time. Please review them regularly. If material changes are made, we will update the date on this page.",
          ),
          InfoLink(
            label: "Terms & Conditions",
            onTap: () => Navigator.pushNamed(context, termsConditionScreenRoute),
          ),
        ]),
        const _HelpCard(
          text:
          "For requests about your data (access, correction, deletion) or any privacy question, contact us. Thank you for trusting Techno Lock Keys.",
        ),
      ],
    );
  }
}

// =============================================================================
// 7. RETURN & REFUND POLICY (new)
// =============================================================================
class ReturnPolicyScreen extends StatelessWidget {
  const ReturnPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const InfoPageLayout(
      title: "Returns & Refunds",
      children: [
        InfoHero(
          icon: Icons.assignment_return_outlined,
          title: "Return & Refund Policy",
          subtitle: "How returns, exchanges and refunds work at Techno Lock Keys.",
        ),
        InfoNote(
          "For security-related electronics and sealed components, returns may be restricted once opened or activated, except for proven defects.",
          icon: Icons.lock_outline_rounded,
        ),
        InfoCard(children: [
          InfoSectionTitle("Eligibility for returns"),
          InfoBullets([
            "Your item must be unused, in the same condition you received it, and in the original packaging.",
            "The item must include all accessories/manuals and the serial number must match our records.",
            "To complete your return, a receipt or proof of purchase (order number) is required.",
            "If you installed, programmed, or modified the item, it may not be eligible for return.",
          ]),
        ]),
        InfoCard(children: [
          InfoSectionTitle("Partial refunds (if applicable)"),
          InfoBullets([
            "Any item not in its original condition, damaged, or missing parts for reasons not due to our error.",
            "Any item returned more than 14 days after delivery (unless otherwise required by law).",
          ]),
          InfoSubTitle("After we receive your return"),
          InfoBullets([
            "Once your return is received and inspected, we will notify you of approval or rejection.",
            "Approved refunds are processed to your original payment method within 5–10 business days.",
            "If approved but not received, check with your bank or card issuer; processing times may vary.",
          ]),
        ]),
        InfoCard(children: [
          InfoSectionTitle("Late or missing refunds"),
          InfoText(
            "If you have not received a refund yet, first check your bank account, then contact your card company.",
          ),
          InfoText(
            "If you have done this and still have not received it, please contact us at $kSupportEmail.",
          ),
        ]),
        InfoCard(children: [
          InfoSectionTitle("Non-returnable / non-exchangeable items"),
          InfoBullets([
            "Items damaged due to misuse, improper installation, or customer negligence.",
            "Returns may be refused where incorrect order or compatibility information was provided by the customer.",
            "Items may be exchanged for the same model if defective on arrival, subject to inspection.",
          ]),
        ]),
        InfoCard(children: [
          InfoSectionTitle("Shipping"),
          InfoText(
            "Depending on your location, exchange delivery times may vary. Shipping fees are non-refundable unless the return is due to our error.",
          ),
        ]),
        _HelpCard(),
      ],
    );
  }
}

// =============================================================================
// 8. CONTACT US
// =============================================================================
class ContactUsScreen extends StatelessWidget {
  const ContactUsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tr = AppLocalizations.of(context)!;

    return InfoPageLayout(
      title: tr.contactUsTitle,
      bottomAction: SizedBox(
        height: 50,
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () => _openUri(context, Uri(scheme: 'mailto', path: kSupportEmail)),
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryColor,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          icon: const Icon(Icons.send_rounded, size: 18),
          label: Text(
            tr.sendMessageButton,
            style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w800),
          ),
        ),
      ),
      children: [
        InfoHero(
          icon: Icons.headset_mic_outlined,
          title: tr.getInTouchTitle,
          subtitle: tr.getInTouchText,
        ),
        InfoCard(children: [
          _ContactRow(
            icon: Icons.email_outlined,
            title: tr.emailUs,
            subtitle: kSupportEmail,
            onTap: () => _openUri(context, Uri(scheme: 'mailto', path: kSupportEmail)),
          ),
          _ContactRow(
            icon: Icons.phone_outlined,
            title: tr.callUs,
            subtitle: kSupportPhone,
            onTap: () => _openUri(context, Uri(scheme: 'tel', path: kSupportPhone)),
          ),
          _ContactRow(
            icon: Icons.chat_bubble_outline_rounded,
            title: "WhatsApp",
            subtitle: kSupportPhone,
            iconColor: const Color(0xFF1DA851),
            onTap: () => _openUri(context, Uri.parse('https://wa.me/$kWhatsAppNumber')),
          ),
          _ContactRow(
            icon: Icons.location_on_outlined,
            title: tr.visitUs,
            subtitle: tr.addressFull,
            onTap: () => _openUri(
              context,
              Uri.https('www.google.com', '/maps/search/', {
                'api': '1',
                'query': tr.addressFull,
              }),
            ),
          ),
          const SizedBox(height: 4),
        ]),
      ],
    );
  }
}

class _ContactRow extends StatelessWidget {
  const _ContactRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.iconColor = primaryColor,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    final isDark = AppPalette.isDark(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: AppPalette.cardElevated(context),
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(isDark ? 0.2 : 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: iconColor, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: AppPalette.text(context),
                          fontWeight: FontWeight.w700,
                          fontSize: 14.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: AppPalette.textMuted(context),
                          fontSize: 13,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.open_in_new_rounded,
                  size: 17,
                  color: AppPalette.textMuted(context),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}