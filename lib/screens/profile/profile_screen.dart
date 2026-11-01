import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_styles.dart';
import '../../services/auth_service.dart';
import '../../services/delivery_service.dart';
import '../../widgets/custom_button.dart';
import '../auth/login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final DeliveryService _deliveryService = DeliveryService();

  @override
  void initState() {
    super.initState();
    _deliveryService.addListener(_onUpdate);
    _deliveryService.fetchProfile().catchError((_) {});
  }

  @override
  void dispose() {
    _deliveryService.removeListener(_onUpdate);
    super.dispose();
  }

  void _onUpdate() {
    if (mounted) setState(() {});
  }

  Future<void> _makePhoneCall(String phone) async {
    final cleanPhone = phone.replaceAll(RegExp(r'[^\d+]'), '');
    if (cleanPhone.isEmpty) return;
    final uri = Uri.parse('tel:$cleanPhone');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      }
    } catch (_) {}
  }

  void _showHelpSupportSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(22, 16, 22, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.headset_mic_rounded, color: AppColors.primary, size: 24),
                ),
                const SizedBox(width: 14),
                const Text(
                  'Rider Help & Support',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'Facing issues with package pickup, customer location, OTP verification, or payments in Bale?',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.4),
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.support_agent_rounded, color: AppColors.primary, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Bale Dispatch Hotline',
                          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.textPrimary),
                        ),
                        SizedBox(height: 2),
                        Text(
                          '+251 911 000 000 • 24/7 Dedicated Support',
                          style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            CustomButton(
              text: 'Call Dispatch (+251 911 000 000)',
              icon: Icons.phone_in_talk_rounded,
              backgroundColor: AppColors.success,
              onPressed: () {
                Navigator.pop(ctx);
                _makePhoneCall('+251911000000');
              },
            ),
            const SizedBox(height: 10),
            CustomButton(
              text: 'Close',
              isOutlined: true,
              onPressed: () => Navigator.pop(ctx),
            ),
          ],
        ),
      ),
    );
  }

  void _showSafetyGuidelinesDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: const [
            Icon(Icons.shield_outlined, color: AppColors.primary),
            SizedBox(width: 10),
            Text('Safety & Guidelines', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text('1. Always wear your helmet and reflective gear while delivering.', style: TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4)),
            SizedBox(height: 8),
            Text('2. Verify the 4-digit OTP code before releasing any order to the recipient.', style: TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4)),
            SizedBox(height: 8),
            Text('3. Check package integrity and parcel sealing at sender pickup.', style: TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4)),
            SizedBox(height: 8),
            Text('4. In case of customer unreachable or address mismatch, call Bale Dispatch directly from your Account.', style: TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4)),
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Understood', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showEditProfileDialog() {
    final profile = _deliveryService.riderProfile;
    final nameController = TextEditingController(text: profile.fullName);
    final phoneController = TextEditingController(text: profile.phoneNumber);
    final vehicleController = TextEditingController(text: profile.vehicleType);
    final plateController = TextEditingController(text: profile.plateNumber);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Edit Profile', style: AppStyles.headingMedium),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Full Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: phoneController,
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: vehicleController,
                decoration: const InputDecoration(
                  labelText: 'Vehicle Model',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: plateController,
                decoration: const InputDecoration(
                  labelText: 'Plate Number',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await _deliveryService.updateProfile(
                  fullName: nameController.text.trim(),
                  phoneNumber: phoneController.text.trim(),
                  vehicleType: vehicleController.text.trim(),
                  plateNumber: plateController.text.trim(),
                );
                if (ctx.mounted) Navigator.pop(ctx);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Profile updated successfully'), backgroundColor: AppColors.success),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to update profile: $e'), backgroundColor: AppColors.danger),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Save Changes', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showChangePasswordDialog() {
    final currentPassController = TextEditingController();
    final newPassController = TextEditingController();
    final confirmPassController = TextEditingController();
    bool obscureCurrent = true;
    bool obscureNew = true;
    bool obscureConfirm = true;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Change Password', style: AppStyles.headingMedium),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: currentPassController,
                  obscureText: obscureCurrent,
                  enableSuggestions: false,
                  autocorrect: false,
                  cursorColor: AppColors.primary,
                  decoration: InputDecoration(
                    labelText: 'Current Password',
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscureCurrent ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                        size: 20,
                      ),
                      onPressed: () => setDialogState(() => obscureCurrent = !obscureCurrent),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: newPassController,
                  obscureText: obscureNew,
                  enableSuggestions: false,
                  autocorrect: false,
                  cursorColor: AppColors.primary,
                  decoration: InputDecoration(
                    labelText: 'New Password',
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscureNew ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                        size: 20,
                      ),
                      onPressed: () => setDialogState(() => obscureNew = !obscureNew),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: confirmPassController,
                  obscureText: obscureConfirm,
                  enableSuggestions: false,
                  autocorrect: false,
                  cursorColor: AppColors.primary,
                  decoration: InputDecoration(
                    labelText: 'Confirm New Password',
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscureConfirm ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                        size: 20,
                      ),
                      onPressed: () => setDialogState(() => obscureConfirm = !obscureConfirm),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (newPassController.text.isEmpty ||
                  newPassController.text != confirmPassController.text) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Passwords do not match or cannot be empty'),
                    backgroundColor: AppColors.danger,
                  ),
                );
                return;
              }
              try {
                await AuthService().changePassword(
                  currentPassController.text.trim(),
                  newPassController.text.trim(),
                );
                if (ctx.mounted) Navigator.pop(ctx);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Password changed successfully!'), backgroundColor: AppColors.success),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to change password: $e'), backgroundColor: AppColors.danger),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Update Password', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    ),
  );
}

  @override
  Widget build(BuildContext context) {
    final profile = _deliveryService.riderProfile;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text(
          'Rider Profile',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: AppColors.primary),
            onPressed: _showEditProfileDialog,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
        child: Column(
          children: [
            // Rider Avatar & Header
            Center(
              child: Column(
                children: [
                  Stack(
                    children: [
                      Container(
                        width: 90,
                        height: 90,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.25),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: const Icon(Icons.person,
                            size: 52, color: Colors.white),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: Container(
                            width: 14,
                            height: 14,
                            decoration: BoxDecoration(
                              color: profile.isOnline
                                  ? AppColors.success
                                  : AppColors.textMuted,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    profile.fullName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    profile.phoneNumber,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Text(
                      'ID: ${profile.id}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Performance Cards (Rating, Deliveries, Total Earned)
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    title: 'Rating',
                    value: '${profile.rating} ★',
                    color: const Color(0xFFF59E0B),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMetricCard(
                    title: 'Total Trips',
                    value: '${profile.totalDeliveries}',
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMetricCard(
                    title: 'Total Earned',
                    value: 'ETB ${(profile.totalEarnings / 1000).toStringAsFixed(1)}k',
                    color: AppColors.success,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Vehicle Information Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: AppStyles.radiusLarge,
                border: Border.all(color: AppColors.border),
                boxShadow: AppStyles.cardShadow,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Vehicle Details',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const Icon(Icons.two_wheeler_rounded,
                          color: AppColors.primary, size: 20),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Vehicle Model',
                          style: TextStyle(
                              color: AppColors.textSecondary, fontSize: 13)),
                      Text(profile.vehicleType,
                          style: const TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.textPrimary)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Plate Number',
                          style: TextStyle(
                              color: AppColors.textSecondary, fontSize: 13)),
                      Text(profile.plateNumber,
                          style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                              color: AppColors.primary)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Settings & Actions
            Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: AppStyles.radiusLarge,
                border: Border.all(color: AppColors.border),
                boxShadow: AppStyles.cardShadow,
              ),
              child: Column(
                children: [
                  _settingTile(
                    icon: Icons.lock_outline_rounded,
                    title: 'Change Password',
                    onTap: _showChangePasswordDialog,
                  ),
                  const Divider(height: 1, color: AppColors.divider),
                  _settingTile(
                    icon: Icons.headset_mic_rounded,
                    title: 'Help & Dispatch Support (24/7)',
                    subtitle: 'Direct hotline +251 911 000 000',
                    onTap: _showHelpSupportSheet,
                  ),
                  const Divider(height: 1, color: AppColors.divider),
                  _settingTile(
                    icon: Icons.shield_outlined,
                    title: 'Rider Safety & Delivery Guidelines',
                    onTap: _showSafetyGuidelinesDialog,
                  ),
                  const Divider(height: 1, color: AppColors.divider),
                  _settingTile(
                    icon: Icons.info_outline_rounded,
                    title: 'About Balera Delivery',
                    onTap: () {
                      showAboutDialog(
                        context: context,
                        applicationName: 'Balera Rider App',
                        applicationVersion: '1.0.0 (Build 1)',
                        applicationLegalese: '© 2026 Balera Delivery Management Platform',
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Logout Button
            CustomButton(
              text: 'Logout',
              icon: Icons.logout_rounded,
              isOutlined: true,
              textColor: AppColors.danger,
              borderColor: AppColors.danger,
              onPressed: () async {
                await AuthService().logout();
                if (context.mounted) {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (route) => false,
                  );
                }
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppStyles.radiusLarge,
        border: Border.all(color: AppColors.border),
        boxShadow: AppStyles.cardShadow,
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _settingTile({
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primary, size: 22),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            )
          : null,
      trailing: const Icon(Icons.chevron_right_rounded,
          color: AppColors.textMuted, size: 20),
      onTap: onTap,
    );
  }
}
