import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_styles.dart';
import '../../models/delivery_order.dart';
import '../../services/delivery_service.dart';
import '../../widgets/custom_button.dart';
import 'on_the_way_screen.dart';

class PickupConfirmationScreen extends StatefulWidget {
  final DeliveryOrder order;

  const PickupConfirmationScreen({super.key, required this.order});

  @override
  State<PickupConfirmationScreen> createState() =>
      _PickupConfirmationScreenState();
}

class _PickupConfirmationScreenState extends State<PickupConfirmationScreen> {
  final DeliveryService _deliveryService = DeliveryService();
  bool _isProcessing = false;

  void _confirmPickup() async {
    setState(() => _isProcessing = true);
    try {
      await _deliveryService.updateDeliveryStatus(
        widget.order.id,
        DeliveryStatus.pickedUp,
        notes: 'Package successfully collected from sender',
      );
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => OnTheWayScreen(order: widget.order),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update status: $e'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
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
          'Pickup Confirmation',
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

              // Illustration: Package Box with Green Checkmark
              Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.border, width: 1.5),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFF59E0B).withValues(alpha: 0.25),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.inventory_2_rounded,
                      size: 54,
                      color: Color(0xFFD97706),
                    ),
                  ),
                  Positioned(
                    top: 10,
                    right: 15,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_rounded,
                        size: 20,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),

              // Headline & Subtitle
              const Text(
                'Confirm Pickup',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Have you picked up the package\nfrom the customer?',
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
                      widget.order.id,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 16),

                    _infoRow(
                      label: 'Pickup',
                      value: widget.order.pickupLocation,
                      icon: Icons.location_on_outlined,
                    ),
                    const SizedBox(height: 12),
                    _infoRow(
                      label: 'Customer',
                      value: widget.order.customerName,
                      icon: Icons.person_outline_rounded,
                    ),
                    const SizedBox(height: 12),
                    _infoRow(
                      label: 'Item',
                      value: widget.order.itemType,
                      icon: Icons.inventory_2_outlined,
                    ),
                  ],
                ),
              ),

              const Spacer(flex: 2),

              // Primary Action Button
              CustomButton(
                text: 'Confirm Pickup',
                backgroundColor: AppColors.primary,
                isLoading: _isProcessing,
                onPressed: _confirmPickup,
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoRow({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppColors.textSecondary),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
