import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_colors.dart';

class RiderPermissionPromptService {
  static const String _promptedKey = 'has_prompted_rider_permissions_v1';

  /// Call once when RiderDashboard mounts.
  /// Shows a clean, professional native permission prompt on initial install/launch.
  static Future<void> checkAndPromptPermissions(BuildContext context) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final hasPrompted = prefs.getBool(_promptedKey) ?? false;
      if (hasPrompted) return;

      if (!context.mounted) return;

      // Show friendly bottom sheet explaining why permissions are needed
      final bool? proceed = await showModalBottomSheet<bool>(
        context: context,
        isDismissible: false,
        enableDrag: false,
        backgroundColor: Colors.transparent,
        builder: (ctx) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
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
              const SizedBox(height: 20),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.two_wheeler_rounded, color: AppColors.primary, size: 26),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Text(
                      'Rider Essential Permissions',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                'To receive and fulfill delivery orders across Bale, Balera Rider needs:',
                style: TextStyle(fontSize: 13.5, color: AppColors.textSecondary, height: 1.4),
              ),
              const SizedBox(height: 16),
              _buildFeatureRow(
                Icons.location_on_rounded,
                'Background & Live GPS Location',
                'Enables customers and admin dispatchers to match you with nearby pickups and track delivery navigation.',
              ),
              const SizedBox(height: 12),
              _buildFeatureRow(
                Icons.notifications_active_rounded,
                'Order & Dispatch Notifications',
                'Immediate alert banners when new customer delivery orders are available for pickup.',
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text(
                    'Allow in Settings',
                    style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Center(
                child: TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text(
                    'Dismiss',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                ),
              ),
            ],
          ),
        ),
      );

      // Save preference so rider is not repeatedly prompted
      await prefs.setBool(_promptedKey, true);

      if (proceed == true) {
        // 1. Request in-app location permission
        LocationPermission permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
        }
        // 2. Open Settings directly so rider can toggle Location & Notifications
        await Geolocator.openAppSettings();
      }
    } catch (_) {}
  }

  static Widget _buildFeatureRow(IconData icon, String title, String subtitle) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppColors.primary, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.3),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
