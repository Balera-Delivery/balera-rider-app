import 'dart:async';
import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_styles.dart';
import '../../models/delivery_order.dart';
import '../../services/delivery_service.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/status_badge.dart';
import '../delivery/delivery_details_screen.dart';
import '../delivery/otp_verification_screen.dart';
import '../notifications/notifications_screen.dart';

class RiderDashboardScreen extends StatefulWidget {
  final Function(int)? onNavigateTab;

  const RiderDashboardScreen({super.key, this.onNavigateTab});

  @override
  State<RiderDashboardScreen> createState() => _RiderDashboardScreenState();
}

class _RiderDashboardScreenState extends State<RiderDashboardScreen> {
  final DeliveryService _deliveryService = DeliveryService();
  Timer? _gpsTimer;

  @override
  void initState() {
    super.initState();
    _deliveryService.addListener(_onServiceUpdate);
    _deliveryService.refreshAll().catchError((_) {});
    _startGpsHeartbeat();
  }

  void _startGpsHeartbeat() {
    _gpsTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (_deliveryService.riderProfile.isOnline) {
        // Send periodic GPS coordinates to PUT /api/v1/rider/location
        _deliveryService.updateLocation(9.0105, 38.7612, heading: 120.0);
      }
    });
  }

  @override
  void dispose() {
    _gpsTimer?.cancel();
    _deliveryService.removeListener(_onServiceUpdate);
    super.dispose();
  }

  void _onServiceUpdate() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final profile = _deliveryService.riderProfile;
    final currentDelivery = _deliveryService.currentDelivery;
    final unreadNotifs = _deliveryService.unreadNotificationCount;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: Builder(
          builder: (ctx) => IconButton(
            icon: const Icon(Icons.menu_rounded, color: AppColors.textPrimary),
            onPressed: () => Scaffold.of(ctx).openDrawer(),
          ),
        ),
        titleSpacing: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Good Morning,',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            Row(
              children: [
                Text(
                  profile.fullName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(width: 4),
                const Text('👋', style: TextStyle(fontSize: 14)),
              ],
            ),
          ],
        ),
        actions: [
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(
                  Icons.notifications_none_rounded,
                  color: AppColors.textPrimary,
                  size: 26,
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const NotificationsScreen(),
                    ),
                  );
                },
              ),
              if (unreadNotifs > 0)
                Positioned(
                  top: 10,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: AppColors.danger,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(minWidth: 8, minHeight: 8),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await _deliveryService.refreshAll();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Online / Offline Toggle Card
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: AppStyles.radiusLarge,
                  border: Border.all(color: AppColors.border),
                  boxShadow: AppStyles.cardShadow,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: profile.isOnline ? AppColors.success : AppColors.textMuted,
                        shape: BoxShape.circle,
                        boxShadow: profile.isOnline
                            ? [
                                BoxShadow(
                                  color: AppColors.success.withValues(alpha: 0.4),
                                  blurRadius: 6,
                                  spreadRadius: 1,
                                ),
                              ]
                            : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            profile.isOnline ? 'You are Online' : 'You are Offline',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            profile.isOnline
                                ? 'Ready to receive deliveries'
                                : 'Offline - Not receiving orders',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Transform.scale(
                      scale: 0.85,
                      child: Switch(
                        value: profile.isOnline,
                        activeColor: Colors.white,
                        activeTrackColor: AppColors.success,
                        inactiveThumbColor: Colors.white,
                        inactiveTrackColor: const Color(0xFFCBD5E1),
                        onChanged: (val) async {
                          try {
                            await _deliveryService.toggleOnlineStatus(val);
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Failed to update status: $e'),
                                  backgroundColor: AppColors.danger,
                                ),
                              );
                            }
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 2. Today's Summary Royal Blue Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF0062FF),
                      Color(0xFF004FD9),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: AppStyles.radiusLarge,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Today's Summary",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        // Metric 1: Assigned
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${profile.todayAssigned}',
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Assigned',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          width: 1,
                          height: 36,
                          color: Colors.white24,
                        ),
                        const SizedBox(width: 16),
                        // Metric 2: Completed
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${profile.todayCompleted}',
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Completed',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          width: 1,
                          height: 36,
                          color: Colors.white24,
                        ),
                        const SizedBox(width: 16),
                        // Metric 3: Earnings
                        Expanded(
                          flex: 2,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'ETB ${profile.todayEarnings.toStringAsFixed(0)}',
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Earnings',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white70,
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
              const SizedBox(height: 24),

              // 3. Current Delivery Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Current Delivery',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  if (currentDelivery != null)
                    GestureDetector(
                      onTap: () => widget.onNavigateTab?.call(1),
                      child: const Text(
                        'View All',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),

              if (currentDelivery != null) ...[
                // Current Delivery Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: AppStyles.radiusLarge,
                    border: Border.all(color: AppColors.border),
                    boxShadow: AppStyles.cardShadow,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header: Order ID + Status Badge
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            currentDelivery.displayId,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          StatusBadge(status: currentDelivery.status),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Route Timeline
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Dots indicator
                          Column(
                            children: [
                              const Icon(Icons.circle, color: AppColors.success, size: 12),
                              Container(
                                width: 2,
                                height: 32,
                                color: const Color(0xFFCBD5E1),
                              ),
                              const Icon(Icons.location_pin, color: AppColors.primary, size: 14),
                            ],
                          ),
                          const SizedBox(width: 12),
                          // Locations text
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
                                  currentDelivery.pickupLocation,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                  'Drop-off',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.textMuted,
                                  ),
                                ),
                                Text(
                                  currentDelivery.dropoffLocation,
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
                      const SizedBox(height: 18),

                      // Action Buttons
                      if (currentDelivery.status == DeliveryStatus.delivered ||
                          currentDelivery.status ==
                              DeliveryStatus.arrivedAtLocation) ...[
                        CustomButton(
                          text: 'Enter Customer OTP to Complete',
                          icon: Icons.pin_outlined,
                          backgroundColor: AppColors.success,
                          height: 48,
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => OtpVerificationScreen(
                                    order: currentDelivery),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 10),
                      ],
                      CustomButton(
                        text: 'View Details',
                        isOutlined:
                            currentDelivery.status == DeliveryStatus.delivered ||
                                currentDelivery.status ==
                                    DeliveryStatus.arrivedAtLocation,
                        backgroundColor: AppColors.primary,
                        height: 48,
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  DeliveryDetailsScreen(order: currentDelivery),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ] else ...[
                // Empty state card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: AppStyles.radiusLarge,
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.moped_rounded,
                          size: 36,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'No Active Delivery',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'You are ready to accept new orders. Keep your status online.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 24),

              // Recent Assigned Jobs Preview
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Assigned Deliveries Queue',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    '${_deliveryService.activeDeliveries.length} active',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              ..._deliveryService.activeDeliveries.skip(1).map(
                (order) => Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: AppStyles.radiusMedium,
                    border: Border.all(color: AppColors.border),
                  ),
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => DeliveryDetailsScreen(order: order),
                        ),
                      );
                    },
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.primaryLight,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.inventory_2_outlined,
                            color: AppColors.primary,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    order.id,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  StatusBadge(status: order.status),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${order.pickupLocation} → ${order.dropoffLocation}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.chevron_right_rounded,
                          color: AppColors.textMuted,
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
