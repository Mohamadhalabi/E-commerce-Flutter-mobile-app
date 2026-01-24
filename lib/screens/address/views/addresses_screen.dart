import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shop/constants.dart';
import 'package:shop/models/address_model.dart';
import 'package:shop/providers/auth_provider.dart';
import 'package:shop/services/api_service.dart';
import 'package:shop/services/notification_service.dart';
import 'package:shop/components/common/CustomBottomNavigationBar.dart';
import 'package:shop/route/route_constants.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import 'add_address_screen.dart';

class AddressesScreen extends StatefulWidget {
  const AddressesScreen({super.key});

  @override
  State<AddressesScreen> createState() => _AddressesScreenState();
}

class _AddressesScreenState extends State<AddressesScreen> {
  List<AddressModel> _addresses = [];
  bool _isLoading = true;
  int _currentIndex = 4; // Profile Tab

  @override
  void initState() {
    super.initState();
    _fetchAddresses();
  }

  void _onBottomNavTap(int index) {
    if (_currentIndex == index) return;
    setState(() => _currentIndex = index);
    switch (index) {
      case 0: Navigator.pushNamedAndRemoveUntil(context, entryPointScreenRoute, (r) => false); break;
      case 1: Navigator.pushNamed(context, searchScreenRoute); break;
      case 3: Navigator.pushNamed(context, cartScreenRoute); break;
      case 4: Navigator.popUntil(context, ModalRoute.withName(entryPointScreenRoute)); break;
    }
  }

  Future<void> _fetchAddresses() async {
    setState(() => _isLoading = true);
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final data = await ApiService.fetchAddresses(auth.token ?? '');
    if (mounted) {
      setState(() {
        _addresses = data;
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteAddress(int id) async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    bool success = await ApiService.deleteAddress(id, auth.token ?? '');
    if (success) {
      _fetchAddresses();
      if(mounted) {
        NotificationService.show(
            context: context,
            title: AppLocalizations.of(context)!.success,
            message: AppLocalizations.of(context)!.addressDeleted
        );
      }
    } else {
      if(mounted) {
        NotificationService.show(
            context: context,
            title: AppLocalizations.of(context)!.error,
            message: AppLocalizations.of(context)!.failedToDeleteAddress,
            isError: true
        );
      }
    }
  }

  Future<void> _setDefault(int id) async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    bool success = await ApiService.setDefaultAddress(id, auth.token ?? '');
    if (success) _fetchAddresses();
  }

  @override
  Widget build(BuildContext context) {
    // ✅ Dark Mode Colors
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final Color scaffoldBg = Theme.of(context).scaffoldBackgroundColor;
    final Color appBarBg = isDark ? const Color(0xFF1C1C23) : Colors.white;
    final Color textColor = isDark ? Colors.white : Colors.black87;
    final Color iconColor = isDark ? Colors.white : Colors.black87;

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.myAddresses),
        backgroundColor: appBarBg,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
        titleTextStyle: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 18),
        iconTheme: IconThemeData(color: iconColor),
        actions: [
          if (!_isLoading)
            IconButton(
              icon: const Icon(Icons.add, color: primaryColor),
              onPressed: () => _navigateToAddAddress(),
            )
        ],
      ),
      bottomNavigationBar: CustomBottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onBottomNavTap,
      ),
      body: RefreshIndicator(
        onRefresh: _fetchAddresses,
        color: primaryColor,
        backgroundColor: appBarBg,
        child: _isLoading
            ? _buildSkeletonLoader(isDark)
            : _addresses.isEmpty
            ? _buildEmptyState(isDark)
            : ListView.separated(
          padding: const EdgeInsets.all(16),
          physics: const AlwaysScrollableScrollPhysics(),
          itemCount: _addresses.length,
          separatorBuilder: (_, __) => const SizedBox(height: 16),
          itemBuilder: (context, index) => _buildAddressCard(_addresses[index], isDark),
        ),
      ),
    );
  }

  // ✅ Skeleton Loader Implementation
  Widget _buildSkeletonLoader(bool isDark) {
    final Color cardBg = isDark ? const Color(0xFF1C1C23) : Colors.white;
    final Color shimmerBase = isDark ? Colors.white10 : Colors.grey[300]!;
    final Color shimmerHighlight = isDark ? Colors.white12 : Colors.grey[200]!;

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: 5,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        return Container(
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              if (!isDark)
                BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
            ],
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(width: 24, height: 24, color: shimmerBase),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(width: 100, height: 16, color: shimmerBase),
                        const SizedBox(height: 8),
                        Container(width: double.infinity, height: 12, color: shimmerHighlight),
                        const SizedBox(height: 4),
                        Container(width: 150, height: 12, color: shimmerHighlight),
                      ],
                    ),
                  )
                ],
              ),
              const SizedBox(height: 16),
              Divider(height: 1, color: isDark ? Colors.white12 : Colors.grey[300]),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(width: 60, height: 20, color: shimmerHighlight),
                  Container(width: 60, height: 20, color: shimmerHighlight),
                  Container(width: 60, height: 20, color: shimmerHighlight),
                ],
              )
            ],
          ),
        );
      },
    );
  }

  Future<void> _navigateToAddAddress([AddressModel? address]) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => AddAddressScreen(address: address)),
    );
    if (result == true) _fetchAddresses();
  }

  Widget _buildEmptyState(bool isDark) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.8,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 100, height: 100,
                decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1C1C23) : Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20)]
                ),
                padding: const EdgeInsets.all(20),
                child: SvgPicture.asset("assets/icons/Location.svg", colorFilter: const ColorFilter.mode(primaryColor, BlendMode.srcIn)),
              ),
              const SizedBox(height: 24),
              Text(
                AppLocalizations.of(context)!.noAddressesYet,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: 180,
                child: ElevatedButton(
                  onPressed: () => _navigateToAddAddress(),
                  style: ElevatedButton.styleFrom(backgroundColor: primaryColor, shape: const StadiumBorder()),
                  child: Text(
                    AppLocalizations.of(context)!.addAddress,
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAddressCard(AddressModel address, bool isDark) {
    // Dynamic Colors
    final Color cardBg = isDark ? const Color(0xFF1C1C23) : Colors.white;
    final Color textColor = isDark ? Colors.white : Colors.black87;
    final Color subTextColor = isDark ? Colors.white70 : Colors.grey[600]!;
    final Color phoneColor = isDark ? Colors.white70 : Colors.grey[800]!;
    final Color dividerColor = isDark ? Colors.white12 : const Color(0xFFEEEEEE);

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
        ],
        border: address.isDefault
            ? Border.all(color: primaryColor, width: 1.5)
            : Border.all(color: isDark ? Colors.white10 : Colors.transparent),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.location_on_outlined, color: textColor),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(address.city,
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16, color: textColor)),
                          const Spacer(),
                          if (address.isDefault)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                  color: primaryColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(4)),
                              child: Text(
                                AppLocalizations.of(context)!.defaultLabel,
                                style: const TextStyle(
                                    color: primaryColor,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                          "${address.address}\n${address.city} - ${address.postalCode}",
                          style: TextStyle(color: subTextColor, fontSize: 13)),
                      const SizedBox(height: 8),
                      Text(address.phone,
                          style: TextStyle(
                              color: phoneColor,
                              fontSize: 13,
                              fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: dividerColor),
          Row(
            children: [
              if (!address.isDefault)
                Expanded(
                    child: TextButton(
                        onPressed: () => _setDefault(address.id),
                        child: Text(
                            AppLocalizations.of(context)!.setDefault,
                            style: TextStyle(color: subTextColor)))),
              Expanded(
                  child: TextButton(
                      onPressed: () => _navigateToAddAddress(address),
                      child: Text(AppLocalizations.of(context)!.edit,
                          style: TextStyle(color: textColor)))),
              Expanded(
                  child: TextButton(
                      onPressed: () => _deleteAddress(address.id),
                      child: Text(AppLocalizations.of(context)!.delete,
                          style: const TextStyle(color: Colors.red)))),
            ],
          )
        ],
      ),
    );
  }
}