import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_styles.dart';
import '../../models/delivery_order.dart';
import '../../services/delivery_service.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/route_map_painter.dart';
import 'pickup_confirmation_screen.dart';

class NavigationScreen extends StatefulWidget {
  final DeliveryOrder order;

  const NavigationScreen({super.key, required this.order});

  @override
  State<NavigationScreen> createState() => _NavigationScreenState();
}

class _NavigationScreenState extends State<NavigationScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // 1. Simulated Interactive Map Canvas
          Positioned.fill(
            child: RouteMapWidget(
              onEndTrip: () => _goToPickupConfirmation(),
            ),
          ),

          // 2. Top Status Bar & Back Button
          Positioned(
            top: 48,
            left: 16,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: AppStyles.cardShadow,
              ),
              child: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded,
                    color: AppColors.textPrimary, size: 20),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),

          // 3. Turn-by-Turn Top Navigation Banner
          Positioned(
            top: 104,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
              decoration: BoxDecoration(
                color: AppColors.navigationBanner,
                borderRadius: AppStyles.radiusLarge,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.35),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.turn_right_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '300 m',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Turn right on Bole Road',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.white.withValues(alpha: 0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'In 1 min',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 4. Floating Quick Action: Compass / Center Location Button
          Positioned(
            bottom: 180,
            right: 16,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: AppStyles.cardShadow,
              ),
              child: IconButton(
                icon: const Icon(Icons.my_location_rounded,
                    color: AppColors.primary, size: 24),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('GPS Centered to Rider position'),
                      duration: Duration(seconds: 1),
                    ),
                  );
                },
              ),
            ),
          ),

          // 5. Bottom Navigation Details Floating Card
          Positioned(
            bottom: 24,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: AppStyles.radiusLarge,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0F172A).withValues(alpha: 0.12),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // ETA
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                '12',
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.successDark,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Text(
                                'min',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.successDark,
                                ),
                              ),
                            ],
                          ),
                          const Text(
                            'ETA',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),

                      // Distance
                      Column(
                        children: const [
                          Text(
                            '5.2 km',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Distance',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),

                      // Time
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: const [
                          Text(
                            '10:45 AM',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Arrival',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),

                      // Red End Trip Button
                      SizedBox(
                        height: 40,
                        child: OutlinedButton(
                          onPressed: _goToPickupConfirmation,
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppColors.danger, width: 1.5),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                          ),
                          child: const Text(
                            'End Trip',
                            style: TextStyle(
                              color: AppColors.danger,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  CustomButton(
                    text: 'Arrived at Pickup',
                    icon: Icons.check_circle_outline_rounded,
                    backgroundColor: AppColors.primary,
                    height: 46,
                    onPressed: _goToPickupConfirmation,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _goToPickupConfirmation() async {
    try {
      await DeliveryService().updateDeliveryStatus(
        widget.order.id,
        DeliveryStatus.arrivedAtPickup,
        notes: 'Rider arrived at pickup location',
      );
    } catch (_) {}

    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PickupConfirmationScreen(order: widget.order),
        ),
      );
    }
  }
}
