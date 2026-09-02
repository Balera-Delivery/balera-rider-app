import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_styles.dart';
import '../services/delivery_service.dart';
import '../screens/auth/login_screen.dart';
import '../screens/delivery/delivery_details_screen.dart';
import '../screens/delivery/navigation_screen.dart';
import '../screens/delivery/pickup_confirmation_screen.dart';
import '../screens/delivery/on_the_way_screen.dart';
import '../screens/delivery/arrived_location_screen.dart';
import '../screens/delivery/otp_verification_screen.dart';
import '../screens/notifications/notifications_screen.dart';

class AppDrawer extends StatelessWidget {
  final Function(int)? onSelectTab;

  const AppDrawer({super.key, this.onSelectTab});

  @override
  Widget build(BuildContext context) {
    final deliveryService = DeliveryService();
    final profile = deliveryService.riderProfile;
    final activeOrder = deliveryService.currentDelivery ?? deliveryService.deliveries.first;

    return Drawer(
      backgroundColor: Colors.white,
      child: SafeArea(
        child: Column(
          children: [
            // Drawer Header with Rider Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Color(0xFFF8FAFC),
                border: Border(bottom: BorderSide(color: AppColors.border)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                      boxShadow: AppStyles.cardShadow,
                    ),
                    child: const Icon(Icons.person, color: Colors.white, size: 30),
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
                        Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: profile.isOnline ? AppColors.success : AppColors.textMuted,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              profile.isOnline ? 'Online (Available)' : 'Offline',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: profile.isOnline ? AppColors.successDark : AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Navigation List (Quick 12-Screen Navigator)
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Text(
                      'MAIN TABS',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textMuted),
                    ),
                  ),
                  _drawerItem(
                    context,
                    icon: Icons.dashboard_outlined,
                    title: '03. Rider Dashboard',
                    onTap: () {
                      Navigator.pop(context);
                      onSelectTab?.call(0);
                    },
                  ),
                  _drawerItem(
                    context,
                    icon: Icons.local_shipping_outlined,
                    title: '04. Assigned Deliveries',
                    onTap: () {
                      Navigator.pop(context);
                      onSelectTab?.call(1);
                    },
                  ),
                  _drawerItem(
                    context,
                    icon: Icons.history_rounded,
                    title: '12. Delivery History',
                    onTap: () {
                      Navigator.pop(context);
                      onSelectTab?.call(2);
                    },
                  ),
                  _drawerItem(
                    context,
                    icon: Icons.person_outline_rounded,
                    title: 'Rider Profile',
                    onTap: () {
                      Navigator.pop(context);
                      onSelectTab?.call(3);
                    },
                  ),
                  const Divider(height: 24),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: Text(
                      'DELIVERY WORKFLOW STEPS',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textMuted),
                    ),
                  ),
                  _drawerItem(
                    context,
                    icon: Icons.receipt_long_outlined,
                    title: '05. Delivery Details',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => DeliveryDetailsScreen(order: activeOrder),
                        ),
                      );
                    },
                  ),
                  _drawerItem(
                    context,
                    icon: Icons.navigation_outlined,
                    title: '06. Turn-by-Turn Navigation',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => NavigationScreen(order: activeOrder),
                        ),
                      );
                    },
                  ),
                  _drawerItem(
                    context,
                    icon: Icons.inventory_2_outlined,
                    title: '07. Pickup Confirmation',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PickupConfirmationScreen(order: activeOrder),
                        ),
                      );
                    },
                  ),
                  _drawerItem(
                    context,
                    icon: Icons.electric_moped_outlined,
                    title: '08. On The Way',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => OnTheWayScreen(order: activeOrder),
                        ),
                      );
                    },
                  ),
                  _drawerItem(
                    context,
                    icon: Icons.location_on_outlined,
                    title: '09. Arrived at Location',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ArrivedLocationScreen(order: activeOrder),
                        ),
                      );
                    },
                  ),
                  _drawerItem(
                    context,
                    icon: Icons.pin_outlined,
                    title: '10. OTP Verification',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => OtpVerificationScreen(order: activeOrder),
                        ),
                      );
                    },
                  ),
                  const Divider(height: 24),
                  _drawerItem(
                    context,
                    icon: Icons.notifications_none_rounded,
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
                    fontWeight: FontWeight.w600,
                  ),
                ),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (route) => false,
                  );
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
          fontWeight: FontWeight.w500,
          color: AppColors.textPrimary,
        ),
      ),
      dense: true,
      visualDensity: VisualDensity.compact,
      onTap: onTap,
    );
  }
}
