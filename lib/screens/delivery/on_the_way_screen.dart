import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_styles.dart';
import '../../models/delivery_order.dart';
import '../../services/delivery_service.dart';
import '../../widgets/custom_button.dart';
import 'arrived_location_screen.dart';

class OnTheWayScreen extends StatefulWidget {
  final DeliveryOrder order;

  const OnTheWayScreen({super.key, required this.order});

  @override
  State<OnTheWayScreen> createState() => _OnTheWayScreenState();
}

class _OnTheWayScreenState extends State<OnTheWayScreen> {
  final DeliveryService _deliveryService = DeliveryService();

  void _onReached() async {
    try {
      await _deliveryService.updateDeliveryStatus(
        widget.order.id,
        DeliveryStatus.onTheWay,
        notes: 'Rider arriving near destination',
      );
    } catch (_) {}

    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ArrivedLocationScreen(order: widget.order),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppColors.textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'On The Way',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            children: [
              const Spacer(flex: 1),

              // Scooter Rider Illustration
              Container(
                height: 180,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9).withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Dotted road route
                    Positioned(
                      bottom: 40,
                      left: 30,
                      right: 30,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: List.generate(
                          12,
                          (index) => Container(
                            width: 12,
                            height: 3,
                            color: AppColors.primary.withValues(alpha: 0.4),
                          ),
                        ),
                      ),
                    ),
                    // Destination flag pin
                    const Positioned(
                      right: 35,
                      top: 40,
                      child: Icon(
                        Icons.flag_circle_rounded,
                        color: AppColors.primary,
                        size: 34,
                      ),
                    ),
                    // Scooter icon center
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.35),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.moped_rounded,
                        size: 52,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // Headline & Subtitle
              const Text(
                "You're on the way",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'to the drop-off location.',
                style: TextStyle(
                  fontSize: 15,
                  color: AppColors.textSecondary,
                ),
              ),
              const Spacer(flex: 1),

              // Progress Location Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: AppStyles.radiusLarge,
                  border: Border.all(color: AppColors.border),
                  boxShadow: AppStyles.cardShadow,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.order.id,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Pickup (Completed checkmark)
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: AppColors.successLight,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.check,
                              color: AppColors.successDark, size: 16),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Pickup',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.textMuted,
                                ),
                              ),
                              Text(
                                widget.order.pickupLocation,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 11),
                      child: Container(
                        width: 2,
                        height: 24,
                        color: const Color(0xFFCBD5E1),
                      ),
                    ),

                    // Drop-off (Active destination)
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: AppColors.primaryLight,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.location_on_rounded,
                              color: AppColors.primary, size: 16),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Drop-off',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.textMuted,
                                ),
                              ),
                              Text(
                                widget.order.dropoffLocation,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const Spacer(flex: 2),

              // Primary Action Button
              CustomButton(
                text: "I've Reached",
                backgroundColor: AppColors.primary,
                onPressed: _onReached,
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
