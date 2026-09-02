import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_styles.dart';
import '../../models/delivery_order.dart';
import '../../services/delivery_service.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/status_badge.dart';
import 'navigation_screen.dart';
import 'otp_verification_screen.dart';
import 'pickup_confirmation_screen.dart';
import 'on_the_way_screen.dart';

class DeliveryDetailsScreen extends StatelessWidget {
  final DeliveryOrder order;

  const DeliveryDetailsScreen({super.key, required this.order});

  void _showCallOptions(BuildContext context, String name, String phone) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Contact $name', style: AppStyles.headingMedium),
            const SizedBox(height: 8),
            Text('Phone: $phone', style: AppStyles.bodyMedium),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: CustomButton(
                    text: 'Call Phone',
                    icon: Icons.phone_rounded,
                    backgroundColor: AppColors.successDark,
                    onPressed: () {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Calling $name ($phone)...'),
                          backgroundColor: AppColors.successDark,
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: CustomButton(
                    text: 'Send SMS',
                    icon: Icons.message_rounded,
                    backgroundColor: AppColors.primary,
                    onPressed: () {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Opening SMS to $phone...'),
                          backgroundColor: AppColors.primary,
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showItemDetails(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(order.itemType, style: AppStyles.headingMedium),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Description:', style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text(order.itemDescription, style: AppStyles.bodyMedium),
            const SizedBox(height: 12),
            const Text('Special Instructions:', style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text(order.specialInstructions, style: AppStyles.bodyMedium),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close', style: TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
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
          'Delivery Details',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert_rounded,
                color: AppColors.textPrimary),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Top Order Banner
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: AppStyles.radiusLarge,
                border: Border.all(color: AppColors.border),
                boxShadow: AppStyles.cardShadow,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        order.displayId,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Assigned at: ${order.assignedTime}',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  StatusBadge(status: order.status),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Pickup Location Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: AppStyles.radiusLarge,
                border: Border.all(color: AppColors.border),
                boxShadow: AppStyles.cardShadow,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.location_on_rounded,
                        color: AppColors.textPrimary, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Pickup Location',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textMuted,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          order.pickupLocation,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          order.pickupAddressDetails,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
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
                    onPressed: () => _showCallOptions(
                        context, 'Sender', order.pickupPhone),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Drop-off Location Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: AppStyles.radiusLarge,
                border: Border.all(color: AppColors.border),
                boxShadow: AppStyles.cardShadow,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.successLight,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.location_on_rounded,
                        color: AppColors.successDark, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Drop-off Location',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textMuted,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          order.dropoffLocation,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          order.dropoffAddressDetails,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
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
                    onPressed: () => _showCallOptions(
                        context, order.receiverName, order.dropoffPhone),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Item Details Row
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: AppStyles.radiusLarge,
                border: Border.all(color: AppColors.border),
              ),
              child: InkWell(
                onTap: () => _showItemDetails(context),
                child: Row(
                  children: [
                    const Icon(Icons.inventory_2_outlined,
                        color: AppColors.textSecondary, size: 22),
                    const SizedBox(width: 14),
                    const Text(
                      'Item',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      order.itemType,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(Icons.chevron_right_rounded,
                        color: AppColors.textMuted, size: 20),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Customer Details Row
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: AppStyles.radiusLarge,
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  const Icon(Icons.person_outline_rounded,
                      color: AppColors.textSecondary, size: 22),
                  const SizedBox(width: 14),
                  const Text(
                    'Customer',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    order.customerName,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  InkWell(
                    onTap: () => _showCallOptions(
                        context, order.customerName, order.customerPhone),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: AppColors.primaryLight,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.phone_rounded,
                          color: AppColors.primary, size: 16),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Payment Amount Row
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: AppStyles.radiusLarge,
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  const Icon(Icons.payments_outlined,
                      color: AppColors.textSecondary, size: 22),
                  const SizedBox(width: 14),
                  const Text(
                    'Payment',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'ETB ${order.paymentAmount.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Dynamic Action Buttons based on Delivery Status
            _buildActionButtons(context),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    if (order.status == DeliveryStatus.assigned) {
      return Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => _showRejectDialog(context),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.danger, width: 1.5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Text(
                'Reject Order',
                style: TextStyle(
                  color: AppColors.danger,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: ElevatedButton(
              onPressed: () => _handleAccept(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Text(
                'Accept Order',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      );
    } else if (order.status == DeliveryStatus.completed) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.successLight,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.check_circle_rounded, color: AppColors.success, size: 20),
            SizedBox(width: 8),
            Text(
              'Delivery Completed',
              style: TextStyle(
                color: AppColors.successDark,
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
          ],
        ),
      );
    } else if (order.status == DeliveryStatus.delivered ||
        order.status == DeliveryStatus.arrivedAtLocation) {
      // Must submit OTP to complete delivery
      return Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF3C7),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.4)),
            ),
            child: Row(
              children: const [
                Icon(Icons.shield_rounded, color: Color(0xFFD97706), size: 20),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'OTP Required: You must submit the customer 6-digit OTP code to finalize and complete this delivery.',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF92400E),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          CustomButton(
            text: 'Enter Customer OTP to Complete',
            icon: Icons.pin_outlined,
            backgroundColor: AppColors.success,
            height: 50,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => OtpVerificationScreen(order: order),
                ),
              );
            },
          ),
        ],
      );
    } else if (order.status == DeliveryStatus.arrivedAtPickup) {
      return CustomButton(
        text: 'Confirm Package Pickup',
        icon: Icons.inventory_2_outlined,
        backgroundColor: AppColors.primary,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => PickupConfirmationScreen(order: order),
            ),
          );
        },
      );
    } else if (order.status == DeliveryStatus.pickedUp ||
        order.status == DeliveryStatus.onTheWay) {
      return CustomButton(
        text: 'Continue to Customer Location',
        icon: Icons.navigation_rounded,
        backgroundColor: AppColors.primary,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => OnTheWayScreen(order: order),
            ),
          );
        },
      );
    } else {
      return CustomButton(
        text: 'Start Navigation to Pickup',
        icon: Icons.navigation_rounded,
        backgroundColor: AppColors.primary,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => NavigationScreen(order: order),
            ),
          );
        },
      );
    }
  }

  void _handleAccept(BuildContext context) async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Accepting delivery...'), duration: Duration(seconds: 1)),
      );
      await DeliveryService().acceptDelivery(order.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Delivery assignment accepted! Head to pickup location.'), backgroundColor: AppColors.success),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => NavigationScreen(order: order)),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to accept: $e'), backgroundColor: AppColors.danger),
        );
      }
    }
  }

  void _showRejectDialog(BuildContext context) {
    String selectedReason = 'Motorcycle maintenance';
    final reasons = [
      'Motorcycle maintenance',
      'Heavy traffic in pickup zone',
      'Exceeded working shift hours',
      'Other emergency',
    ];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Reject Assignment', style: AppStyles.headingMedium),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Please select a reason for rejecting this order so dispatch can reassign it:',
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 12),
              ...reasons.map(
                (r) => RadioListTile<String>(
                  value: r,
                  groupValue: selectedReason,
                  title: Text(r, style: const TextStyle(fontSize: 13.5)),
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  onChanged: (val) => setDialogState(() => selectedReason = val!),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
              onPressed: () async {
                Navigator.pop(ctx);
                try {
                  await DeliveryService().rejectDelivery(order.id, reason: selectedReason);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Order rejected and returned to dispatch queue.')),
                    );
                    Navigator.pop(context);
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to reject: $e'), backgroundColor: AppColors.danger),
                    );
                  }
                }
              },
              child: const Text('Confirm Reject', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}
