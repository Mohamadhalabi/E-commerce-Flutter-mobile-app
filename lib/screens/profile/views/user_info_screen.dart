import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shop/constants.dart';
import 'package:shop/providers/auth_provider.dart';
import 'package:shop/services/api_service.dart';
import 'package:shop/components/common/CustomBottomNavigationBar.dart';
import 'package:shop/route/route_constants.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:shop/services/notification_service.dart'; // ✅ Import your NotificationService

class UserInfoScreen extends StatefulWidget {
  const UserInfoScreen({super.key});

  @override
  State<UserInfoScreen> createState() => _UserInfoScreenState();
}

class _UserInfoScreenState extends State<UserInfoScreen> {
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;

  final TextEditingController _currentPassController = TextEditingController();
  final TextEditingController _newPassController = TextEditingController();
  final TextEditingController _confirmPassController = TextEditingController();

  bool _isProfileLoading = false;
  bool _isPasswordLoading = false;

  int _currentIndex = 4;

  @override
  void initState() {
    super.initState();
    final user = Provider.of<AuthProvider>(context, listen: false).user;
    _nameController = TextEditingController(text: user?['name'] ?? '');
    _phoneController = TextEditingController(text: user?['phone'] ?? '');
    _emailController = TextEditingController(text: user?['email'] ?? '');
  }

  void _onBottomNavTap(int index) {
    if (_currentIndex == index) return;
    setState(() => _currentIndex = index);

    switch (index) {
      case 0:
        Navigator.pushNamedAndRemoveUntil(context, entryPointScreenRoute, (route) => false);
        break;
      case 1:
        Navigator.pushNamed(context, searchScreenRoute);
        break;
      case 2:
        break;
      case 3:
        Navigator.pushNamed(context, cartScreenRoute);
        break;
      case 4:
        Navigator.popUntil(context, ModalRoute.withName(entryPointScreenRoute));
        break;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _currentPassController.dispose();
    _newPassController.dispose();
    _confirmPassController.dispose();
    super.dispose();
  }

  Future<void> _updateProfile(AppLocalizations tr) async {
    setState(() => _isProfileLoading = true);
    final auth = Provider.of<AuthProvider>(context, listen: false);

    bool success = await ApiService.updateProfile(
      _nameController.text.trim(),
      _phoneController.text.trim(),
      auth.token ?? '',
    );

    if (mounted) {
      if (success) {
        await auth.fetchUserProfile();
        // ✅ Custom Success Alert
        NotificationService.show(
          context: context,
          title: tr.success ?? "Success",
          message: tr.profileUpdatedSuccess ?? "Profile updated successfully",
          isError: false,
        );
      } else {
        // ✅ Custom Error Alert
        NotificationService.show(
          context: context,
          title: tr.error ?? "Error",
          message: tr.profileUpdateFailed ?? "Failed to update profile",
          isError: true,
        );
      }
      setState(() => _isProfileLoading = false);
    }
  }

  Future<void> _updatePassword(AppLocalizations tr) async {
    if (_newPassController.text != _confirmPassController.text) {
      NotificationService.show(
        context: context,
        title: tr.error ?? "Error",
        message: tr.passwordsDoNotMatch ?? "New passwords do not match",
        isError: true,
      );
      return;
    }

    setState(() => _isPasswordLoading = true);
    final auth = Provider.of<AuthProvider>(context, listen: false);

    bool success = await ApiService.updatePassword(
      _currentPassController.text,
      _newPassController.text,
      _confirmPassController.text,
      auth.token ?? '',
    );

    if (mounted) {
      if (success) {
        _currentPassController.clear();
        _newPassController.clear();
        _confirmPassController.clear();

        NotificationService.show(
          context: context,
          title: tr.success ?? "Success",
          message: tr.passwordUpdatedSuccess ?? "Password updated successfully",
          isError: false,
        );
      } else {
        NotificationService.show(
          context: context,
          title: tr.error ?? "Error",
          message: tr.passwordUpdateFailed ?? "Failed to update password",
          isError: true,
        );
      }
      setState(() => _isPasswordLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tr = AppLocalizations.of(context)!; // Safe force unwrap if your app is localized correctly

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(tr.accountDetails ?? "Account Details"),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: const TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      bottomNavigationBar: CustomBottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onBottomNavTap,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(tr.profileDetails ?? "Profile details", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),

            _buildLabel(tr.fullName ?? "Full name"),
            _buildTextField(_nameController, "Name"),
            const SizedBox(height: 16),

            _buildLabel(tr.phone ?? "Phone"),
            _buildTextField(_phoneController, "Phone"),
            const SizedBox(height: 16),

            _buildLabel(tr.email ?? "Email"),
            TextField(
              controller: _emailController,
              readOnly: true,
              style: TextStyle(color: Colors.grey[600]),
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
            const SizedBox(height: 20),

            SizedBox(
              width: 160,
              child: ElevatedButton(
                onPressed: _isProfileLoading ? null : () => _updateProfile(tr),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE84C0F),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: _isProfileLoading
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Text(tr.saveChanges ?? "Save changes", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),

            const SizedBox(height: 40),
            const Divider(),
            const SizedBox(height: 30),

            Text(tr.changePassword ?? "Change password", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),

            _buildLabel(tr.currentPassword ?? "Current password"),
            _buildTextField(_currentPassController, "........", isPassword: true),
            const SizedBox(height: 16),

            _buildLabel(tr.newPassword ?? "New password"),
            _buildTextField(_newPassController, "", isPassword: true),
            const SizedBox(height: 16),

            _buildLabel(tr.confirmNewPassword ?? "Confirm new password"),
            _buildTextField(_confirmPassController, "", isPassword: true),
            const SizedBox(height: 20),

            SizedBox(
              width: 180,
              child: ElevatedButton(
                onPressed: _isPasswordLoading ? null : () => _updatePassword(tr),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A1A2E),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: _isPasswordLoading
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Text(tr.updatePassword ?? "Update password", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text, style: TextStyle(color: Colors.grey[700], fontSize: 14, fontWeight: FontWeight.w500)),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint, {bool isPassword = false}) {
    return TextField(
      controller: controller,
      obscureText: isPassword,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey[400]),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Colors.blue)),
      ),
    );
  }
}