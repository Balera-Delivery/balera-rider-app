import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_styles.dart';
import '../../models/delivery_order.dart';
import '../../services/delivery_service.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/route_map_painter.dart';
import '../../widgets/status_badge.dart';
import 'navigation_screen.dart';
import 'otp_verification_screen.dart';
import 'pickup_confirmation_screen.dart';
import 'on_the_way_screen.dart';

class DeliveryDetailsScreen extends StatelessWidget {
  final DeliveryOrder order;

  const DeliveryDetailsScreen({super.key, required this.order});

  static Future<void> makePhoneCall(BuildContext context, String phone) async {
    final cleanPhone = phone.replaceAll(RegExp(r'[^\d+]'), '');
    if (cleanPhone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No valid phone number to call.')),
      );
      return;
    }
    final uri = Uri.parse('tel:$cleanPhone');
    try {
      final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched) await launchUrl(uri);
    } catch (_) {
      await Clipboard.setData(ClipboardData(text: cleanPhone));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Phone $cleanPhone copied to clipboard (Dialer unavailable).'),
            backgroundColor: AppColors.successDark,
          ),
        );
      }
    }
  }

  static Future<void> sendSms(BuildContext context, String phone) async {
    final cleanPhone = phone.replaceAll(RegExp(r'[^\d+]'), '');
    if (cleanPhone.isEmpty) return;
    final uri = Uri.parse('sms:$cleanPhone');
    try {
      final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched) await launchUrl(uri);
    } catch (_) {
      await Clipboard.setData(ClipboardData(text: cleanPhone));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Phone $cleanPhone copied to clipboard.')),
        );
      }
    }
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
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // 1. Live Interactive Route Map Background
          Positioned.fill(
            child: RouteMapWidget(
              pickupLat: order.pickupLatitude,
              pickupLng: order.pickupLongitude,
              destinationLat: order.destinationLatitude,
              destinationLng: order.destinationLongitude,
            ),
          ),

          // 2. Top Navigation Bar (Back Arrow + "Track Package" + More Menu)
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Floating Back Button (from screenshot)
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.14),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF0F172A), size: 20),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),

                  // Title Pill
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.92),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Text(
                      'Track Package',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                        letterSpacing: -0.2,
                      ),
                    ),
                  ),

                  // Floating More Button (from screenshot)
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.14),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.more_vert_rounded, color: Color(0xFF0F172A), size: 20),
                      onPressed: () => _showItemDetails(context),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 3. Vertically Draggable / Scrollable Bottom Sheet (Exact screenshot design!)
          DraggableScrollableSheet(
            initialChildSize: 0.58,
            minChildSize: 0.35,
            maxChildSize: 0.92,
            snap: true,
            snapSizes: const [0.35, 0.58, 0.90],
            builder: (context, scrollController) {
              return Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.18),
                      blurRadius: 20,
                      offset: const Offset(0, -6),
                    ),
                  ],
                ),
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 28),
                  children: [
                    // Drag Handle Bar
                    Center(
                      child: Container(
                        width: 44,
                        height: 4.5,
                        decoration: BoxDecoration(
                          color: const Color(0xFFCBD5E1),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Customer Row with circular black Phone & Message buttons
                    _buildCustomerProfileRow(context),
                    const SizedBox(height: 12),

                    // Status Pill Banner
                    _buildStatusPillBanner(),
                    const SizedBox(height: 14),

                    // Screenshot Matching Booking Card
                    _buildScreenshotBookingCard(),
                    const SizedBox(height: 16),

                    // Primary Rider Action Buttons
                    _buildActionButtons(context),
                    const SizedBox(height: 16),

                    // Item Category & Instructions Details
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.inventory_2_outlined, size: 16, color: AppColors.primary),
                              SizedBox(width: 8),
                              Text(
                                'Package & Handling Info',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Item Type', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                              Text(order.itemType, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
                            ],
                          ),
                          if (order.specialInstructions.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Instructions', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    order.specialInstructions,
                                    textAlign: TextAlign.end,
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Direct Dispatch Support Link
                    Center(
                      child: TextButton.icon(
                        icon: const Icon(Icons.headset_mic_rounded, size: 16, color: AppColors.primary),
                        label: const Text(
                          'Need Dispatch Assistance? (+251 911 000 000)',
                          style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.primary),
                        ),
                        onPressed: () => makePhoneCall(context, '+251911000000'),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // A. Customer Row
  Widget _buildCustomerProfileRow(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.border, width: 1.5),
          ),
          child: ClipOval(
            child: Container(
              color: const Color(0xFF1E293B),
              child: const Icon(Icons.person, color: Colors.white, size: 26),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text(
                    'Delivery',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.star_rounded, size: 14, color: Color(0xFFF59E0B)),
                  const SizedBox(width: 2),
                  const Text(
                    '4.8',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                order.customerName,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                  letterSpacing: -0.2,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        // Black Phone Button
        InkWell(
          onTap: () => makePhoneCall(context, order.customerPhone),
          borderRadius: BorderRadius.circular(24),
          child: Container(
            width: 42,
            height: 42,
            decoration: const BoxDecoration(
              color: Color(0xFF1E293B),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.phone, color: Colors.white, size: 18),
          ),
        ),
        const SizedBox(width: 10),
        // Black Message Button
        InkWell(
          onTap: () => sendSms(context, order.customerPhone),
          borderRadius: BorderRadius.circular(24),
          child: Container(
            width: 42,
            height: 42,
            decoration: const BoxDecoration(
              color: Color(0xFF1E293B),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.chat_bubble_rounded, color: Colors.white, size: 18),
          ),
        ),
      ],
    );
  }

  // B. Status Banner
  Widget _buildStatusPillBanner() {
    Color bg = const Color(0xFFDCFCE7);
    Color dot = const Color(0xFF16A34A);
    String title = 'Delivered to ${order.receiverName.isNotEmpty ? order.receiverName : order.customerName}';
    String trailing = 'Signed for';

    if (order.status == DeliveryStatus.assigned) {
      bg = const Color(0xFFFEF3C7);
      dot = const Color(0xFFD97706);
      title = 'Assigned for Pickup';
      trailing = order.distance;
    } else if (order.status == DeliveryStatus.accepted || order.status == DeliveryStatus.arrivedAtPickup) {
      bg = const Color(0xFFEFF6FF);
      dot = const Color(0xFF2563EB);
      title = 'Ready for Pickup';
      trailing = order.eta;
    } else if (order.status == DeliveryStatus.pickedUp || order.status == DeliveryStatus.onTheWay) {
      bg = const Color(0xFFEFF6FF);
      dot = const Color(0xFF2563EB);
      title = 'On the way to recipient';
      trailing = 'In Transit';
    } else if (order.status == DeliveryStatus.delivered || order.status == DeliveryStatus.arrivedAtLocation) {
      bg = const Color(0xFFDCFCE7);
      dot = const Color(0xFF16A34A);
      title = 'Arrived at Drop-off';
      trailing = 'OTP Required';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: dot,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            trailing,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: dot.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }

  // C. Booking Card
  Widget _buildScreenshotBookingCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border),
        boxShadow: AppStyles.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Booking',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    order.displayId,
                    style: const TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF0F172A),
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  order.status.displayName,
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Dashed Orange Stepper
          _buildDashedStepper(order.status),
          const SizedBox(height: 16),

          // Details Grid + 3D Package Box Graphic
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'From',
                                style: TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                order.pickupLocation,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF0F172A),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'To',
                                style: TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                order.dropoffLocation,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF0F172A),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Order Cost',
                                style: TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'ETB ${order.paymentAmount.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Customer',
                                style: TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                order.customerName,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF0F172A),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),

              // 3D Box Illustration
              _buildPackage3DGraphic(),
            ],
          ),
        ],
      ),
    );
  }

  // D. Dashed Stepper
  Widget _buildDashedStepper(DeliveryStatus status) {
    int currentStep = 1;
    if (status == DeliveryStatus.arrivedAtPickup || status == DeliveryStatus.pickedUp) {
      currentStep = 2;
    } else if (status == DeliveryStatus.onTheWay || status == DeliveryStatus.arrivedAtLocation) {
      currentStep = 3;
    } else if (status == DeliveryStatus.delivered || status == DeliveryStatus.completed) {
      currentStep = 4;
    }

    return Row(
      children: [
        _stepperDot(isActive: currentStep >= 1),
        Expanded(child: _stepperDashedLine(isActive: currentStep >= 2)),
        _stepperDot(isActive: currentStep >= 2),
        Expanded(child: _stepperDashedLine(isActive: currentStep >= 3)),
        _stepperDot(isActive: currentStep >= 3),
        Expanded(child: _stepperDashedLine(isActive: currentStep >= 4)),
        _stepperDot(isActive: currentStep >= 4),
      ],
    );
  }

  Widget _stepperDot({required bool isActive}) {
    return Container(
      width: 16,
      height: 16,
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFFEA580C) : const Color(0xFFE2E8F0),
        shape: BoxShape.circle,
        border: Border.all(
          color: isActive ? const Color(0xFFC2410C) : const Color(0xFFCBD5E1),
          width: 2,
        ),
      ),
      child: isActive
          ? const Center(
              child: Icon(Icons.check, size: 9, color: Colors.white),
            )
          : null,
    );
  }

  Widget _stepperDashedLine({required bool isActive}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(
        5,
        (_) => Container(
          width: 3.5,
          height: 3.5,
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFFEA580C) : const Color(0xFFCBD5E1),
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }

  // E. 3D Delivery Box Illustration
  Widget _buildPackage3DGraphic() {
    return Container(
      width: 68,
      height: 56,
      decoration: BoxDecoration(
        color: const Color(0xFFFEF3C7),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFDE68A), width: 1.5),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            bottom: 4,
            right: 6,
            child: Container(
              width: 32,
              height: 28,
              decoration: BoxDecoration(
                color: const Color(0xFFD97706),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(Icons.inventory_2_rounded, color: Colors.white, size: 17),
            ),
          ),
          Positioned(
            top: 4,
            left: 6,
            child: Container(
              width: 36,
              height: 30,
              decoration: BoxDecoration(
                color: const Color(0xFFF59E0B),
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.14),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(Icons.all_inbox_rounded, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  // F. Action Buttons
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
                  fontSize: 14.5,
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
                  fontSize: 14.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      );
    } else if (order.status == DeliveryStatus.delivered ||
        order.status == DeliveryStatus.arrivedAtLocation) {
      return CustomButton(
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
      );
    } else if (order.status == DeliveryStatus.arrivedAtPickup) {
      return CustomButton(
        text: 'Confirm Package Pickup',
        icon: Icons.inventory_2_outlined,
        backgroundColor: AppColors.primary,
        height: 50,
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
        height: 50,
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
        height: 50,
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
