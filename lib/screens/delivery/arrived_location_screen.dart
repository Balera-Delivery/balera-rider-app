import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_styles.dart';
import '../../models/delivery_order.dart';
import '../../services/delivery_service.dart';
import '../../widgets/custom_button.dart';
import 'otp_verification_screen.dart';

class ArrivedLocationScreen extends StatelessWidget {
  final DeliveryOrder order;

  const ArrivedLocationScreen({super.key, required this.order});

  void _showCallingDialog(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Calling customer ${order.receiverName} (${order.dropoffPhone})...'),
        backgroundColor: AppColors.successDark,
      ),
    );
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
          'Arrived at Location',
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

              // Arrived Map Pin Illustration
              Container(
                height: 170,
                width: 170,
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.border, width: 2),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Grid lines
                    Positioned.fill(
                      child: CustomPaint(
                        painter: _MiniGridPainter(),
                      ),
                    ),
                    // Large Drop Pin
                    Container(
                      padding: const EdgeInsets.all(20),
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
                        Icons.location_on_rounded,
                        size: 48,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // Headline & Subtitle
              const Text(
                "You've arrived!",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Please inform the customer\nand proceed with delivery.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
              ),
              const Spacer(flex: 1),

              // Order Summary Card
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
                      order.id,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 16),

                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.location_on_outlined,
                            size: 18, color: AppColors.textSecondary),
                        const SizedBox(width: 10),
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
                              const SizedBox(height: 2),
                              Text(
                                order.dropoffLocation,
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
                    const SizedBox(height: 14),

                    Row(
                      children: [
                        const Icon(Icons.person_outline_rounded,
                            size: 18, color: AppColors.textSecondary),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Customer',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.textMuted,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                order.customerName,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(
                              color: AppColors.primaryLight,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.phone_rounded,
                                color: AppColors.primary, size: 18),
                          ),
                          onPressed: () => _showCallingDialog(context),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const Spacer(flex: 2),

              // Action Buttons
              CustomButton(
                text: 'Notify Customer & Verify OTP',
                backgroundColor: AppColors.primary,
                onPressed: () async {
                  try {
                    await DeliveryService().updateDeliveryStatus(
                      order.id,
                      DeliveryStatus.delivered,
                      notes: 'Rider arrived at destination dropoff',
                    );
                  } catch (_) {}

                  if (context.mounted) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => OtpVerificationScreen(order: order),
                      ),
                    );
                  }
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = const Color(0xFFE2E8F0)
      ..strokeWidth = 1.5;

    for (double i = 20; i < size.width; i += 24) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), linePaint);
    }
    for (double i = 20; i < size.height; i += 24) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), linePaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
