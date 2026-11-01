import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../constants/app_colors.dart';
import '../services/delivery_service.dart';
import '../services/auth_service.dart';
import '../screens/auth/login_screen.dart';
import '../screens/notifications/notifications_screen.dart';

class AppDrawer extends StatelessWidget {
  final Function(int)? onSelectTab;

  const AppDrawer({super.key, this.onSelectTab});

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

  void _showSupportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: const [
            Icon(Icons.headset_mic_rounded, color: AppColors.primary),
            SizedBox(width: 10),
            Text('Dispatch Hotline', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'Need immediate assistance with routes, customer phone numbers, or active deliveries in Bale?',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.35),
            ),
            SizedBox(height: 12),
            Text(
              '📞 Hotline: +251 911 000 000',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
            ),
            Text(
              'Available 24/7 for all Balera registered riders.',
              style: TextStyle(fontSize: 11.5, color: AppColors.textMuted),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.phone, size: 16, color: Colors.white),
            label: const Text('Call Dispatch', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              _makePhoneCall('+251911000000');
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final deliveryService = DeliveryService();
    final profile = deliveryService.riderProfile;

    return Drawer(
      backgroundColor: Colors.white,
      child: SafeArea(
        child: Column(
          children: [
            // Rider Profile Header Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF003893), Color(0xFF0047BA)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.person, color: AppColors.primary, size: 30),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          profile.fullName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          profile.phoneNumber,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.white70,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 7,
                                height: 7,
                                decoration: BoxDecoration(
                                  color: profile.isOnline ? const Color(0xFF4ADE80) : const Color(0xFFF87171),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                profile.isOnline ? 'Online & Active' : 'Offline',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Production Rider Navigation Menu (All developer numbered items removed!)
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 10),
                children: [
                  _drawerItem(
                    context,
                    icon: Icons.home_rounded,
                    title: 'Home Dashboard',
                    onTap: () {
                      Navigator.pop(context);
                      onSelectTab?.call(0);
                    },
                  ),
                  _drawerItem(
                    context,
                    icon: Icons.inventory_2_rounded,
                    title: 'My Deliveries (Queue)',
                    onTap: () {
                      Navigator.pop(context);
                      onSelectTab?.call(1);
                    },
                  ),
                  _drawerItem(
                    context,
                    icon: Icons.account_balance_wallet_rounded,
                    title: 'Shift & Earnings',
                    onTap: () {
                      Navigator.pop(context);
                      onSelectTab?.call(2);
                    },
                  ),
                  _drawerItem(
                    context,
                    icon: Icons.history_rounded,
                    title: 'Delivery History',
                    onTap: () {
                      Navigator.pop(context);
                      onSelectTab?.call(2);
                    },
                  ),
                  _drawerItem(
                    context,
                    icon: Icons.notifications_outlined,
                    title: 'Notifications',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const NotificationsScreen(),
                        ),
                      );
                    },
                  ),
                  const Divider(height: 20, color: Color(0xFFF1F5F9)),
                  _drawerItem(
                    context,
                    icon: Icons.headset_mic_rounded,
                    title: 'Bale Dispatch Support',
                    onTap: () {
                      Navigator.pop(context);
                      _showSupportDialog(context);
                    },
                  ),
                  _drawerItem(
                    context,
                    icon: Icons.person_outline_rounded,
                    title: 'Rider Profile & Settings',
                    onTap: () {
                      Navigator.pop(context);
                      onSelectTab?.call(3);
                    },
                  ),
                ],
              ),
            ),

            // Logout at bottom
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: AppColors.border)),
              ),
              child: ListTile(
                leading: const Icon(Icons.logout_rounded, color: AppColors.danger),
                title: const Text(
                  'Logout',
                  style: TextStyle(
                    color: AppColors.danger,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                onTap: () async {
                  Navigator.pop(context);
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
            ),
          ],
        ),
      ),
    );
  }

  Widget _drawerItem(
    BuildContext context, {
    required IconData icon,
    required String title,
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
      dense: true,
      onTap: onTap,
    );
  }
}
