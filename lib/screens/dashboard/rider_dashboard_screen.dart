import 'dart:async';
import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_styles.dart';
import '../../models/delivery_order.dart';
import '../../services/delivery_service.dart';
import '../../services/permission_prompt_service.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/route_map_painter.dart';
import '../../widgets/status_badge.dart';
import '../delivery/delivery_details_screen.dart';
import '../delivery/otp_verification_screen.dart';
import '../delivery/pickup_confirmation_screen.dart';
import '../delivery/on_the_way_screen.dart';
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
  Timer? _syncTimer;
  bool _isAccepting = false;

  @override
  void initState() {
    super.initState();
    _deliveryService.addListener(_onServiceUpdate);
    _deliveryService.refreshAll().catchError((_) {});
    _startGpsHeartbeat();
    _startPeriodicSync();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      RiderPermissionPromptService.checkAndPromptPermissions(context);
    });
  }

  void _startGpsHeartbeat() {
    _gpsTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (_deliveryService.riderProfile.isOnline) {
        // Send periodic GPS coordinates to PUT /api/v1/rider/location
        _deliveryService.updateLocation(9.0105, 38.7612, heading: 120.0);
      }
    });
  }

  void _startPeriodicSync() {
    _syncTimer = Timer.periodic(const Duration(seconds: 8), (_) {
      if (mounted && _deliveryService.riderProfile.isOnline) {
        _deliveryService.fetchAssignedDeliveries(silent: true).catchError((_) {});
        _deliveryService.fetchActiveDelivery().catchError((_) {});
      }
    });
  }

  @override
  void dispose() {
    _gpsTimer?.cancel();
    _syncTimer?.cancel();
    _deliveryService.removeListener(_onServiceUpdate);
    super.dispose();
  }

  void _onServiceUpdate() {
    if (mounted) setState(() {});
  }

  Future<void> _manualUpdateLocation() async {
    try {
      await _deliveryService.updateLocation(9.0105, 38.7612, heading: 120.0);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('GPS coordinates synchronized with dispatch server! 📍'),
            backgroundColor: AppColors.success,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update GPS: $e'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  void _showSupportModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.neonCyan.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.headset_mic_rounded, color: AppColors.neonCyan, size: 24),
                ),
                const SizedBox(width: 14),
                const Text(
                  'Rider Dispatch Support',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Need assistance with your route, pickup, or active delivery? Contact the 24/7 Bale dispatch team immediately.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.4),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: const Row(
                children: [
                  Icon(Icons.phone_in_talk_rounded, color: AppColors.success, size: 22),
                  SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Dispatch Hotline', style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                      Text('+251 911 000 000 / 9200', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            CustomButton(
              text: 'Close',
              backgroundColor: AppColors.primary,
              onPressed: () => Navigator.pop(ctx),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _acceptOrder(DeliveryOrder order) async {
    if (_isAccepting) return;
    setState(() => _isAccepting = true);
    try {
      final success = await _deliveryService.acceptDelivery(order.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Delivery ${order.displayId} accepted successfully! 🎉'),
            backgroundColor: AppColors.success,
          ),
        );
        if (success) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => PickupConfirmationScreen(order: order),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to accept: ${e.toString().replaceAll('ApiException: ', '')}'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isAccepting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = _deliveryService.riderProfile;
    final currentDelivery = _deliveryService.currentDelivery;
    final activeList = _deliveryService.activeDeliveries;
    final unreadNotifs = _deliveryService.unreadNotificationCount;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: Builder(
          builder: (ctx) => InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => Scaffold.of(ctx).openDrawer(),
            child: Padding(
              padding: const EdgeInsets.all(10.0),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.border),
                    ),
                    child: ClipOval(
                      child: Image.asset(
                        'assets/logo/balera_logo.png',
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) => const Icon(
                          Icons.person,
                          color: AppColors.neonCyan,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 11,
                      height: 11,
                      decoration: BoxDecoration(
                        color: profile.isOnline ? AppColors.success : AppColors.textMuted,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.background, width: 2),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        titleSpacing: 4,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Welcome Back!',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
            Row(
              children: [
                Flexible(
                  child: Text(
                    profile.fullName,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: -0.2,
                    ),
                    overflow: TextOverflow.ellipsis,
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
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.border),
                ),
                child: IconButton(
                  icon: const Icon(
                    Icons.notifications_none_rounded,
                    color: Colors.white,
                    size: 22,
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
              ),
              if (unreadNotifs > 0)
                Positioned(
                  top: 8,
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
        color: AppColors.neonCyan,
        backgroundColor: AppColors.surface,
        onRefresh: () async {
          await _deliveryService.refreshAll();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Top 3 Stat Cards (Deliveries, ETB Earnings, Rating)
              Row(
                children: [
                  // Stat Card 1: Deliveries
                  Expanded(
                    child: _buildGlassStatCard(
                      icon: Icons.inventory_2_rounded,
                      iconColor: AppColors.accentBlue,
                      iconBg: const Color(0xFF10284D),
                      value: '${profile.todayCompleted}',
                      label: "Today's Orders",
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Stat Card 2: Today's Earnings
                  Expanded(
                    child: _buildGlassStatCard(
                      icon: Icons.account_balance_wallet_rounded,
                      iconColor: AppColors.success,
                      iconBg: const Color(0xFF0C382A),
                      value: 'ETB ${profile.todayEarnings.toStringAsFixed(0)}',
                      label: "Today's Earnings",
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Stat Card 3: Rating
                  Expanded(
                    child: _buildGlassStatCard(
                      icon: Icons.star_rounded,
                      iconColor: AppColors.warning,
                      iconBg: const Color(0xFF38260B),
                      value: '${profile.rating.toStringAsFixed(1)} ★',
                      label: 'Rating',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 2. Go Online / Offline Master Radiant Banner
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF1B64F8),
                      Color(0xFF0D50E8),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF1B64F8).withValues(alpha: 0.35),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.3),
                          width: 1.5,
                        ),
                      ),
                      child: const Icon(
                        Icons.sync_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            profile.isOnline ? 'You are Online' : 'Go Online',
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            profile.isOnline
                                ? 'Ready to receive delivery requests'
                                : 'Start receiving delivery requests',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white.withValues(alpha: 0.85),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Transform.scale(
                      scale: 0.9,
                      child: Switch.adaptive(
                        value: profile.isOnline,
                        activeColor: Colors.white,
                        activeTrackColor: AppColors.success,
                        inactiveThumbColor: Colors.white,
                        inactiveTrackColor: Colors.white.withValues(alpha: 0.3),
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
              const SizedBox(height: 18),

              // 3. Today's Overview Performance Wave Chart Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.border),
                  boxShadow: AppStyles.cardShadow,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Today's Overview",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.card,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.calendar_today_rounded, size: 11, color: AppColors.neonCyan),
                              SizedBox(width: 5),
                              Text(
                                'Today',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.neonCyan,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    // Wave Canvas with Glowing Neon Line, Fill, and Tooltip
                    SizedBox(
                      height: 130,
                      width: double.infinity,
                      child: CustomPaint(
                        painter: OverviewWaveChartPainter(
                          lineColor: AppColors.neonCyan,
                          gradientStart: AppColors.neonCyan.withValues(alpha: 0.35),
                          gradientEnd: AppColors.neonCyan.withValues(alpha: 0.0),
                          tooltipText: profile.todayEarnings > 0
                              ? 'ETB ${profile.todayEarnings.toStringAsFixed(0)}  ↑ +12%'
                              : 'ETB 1,850  ↑ +12%',
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Time axis labels
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('8 AM', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                        Text('12 PM', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                        Text('4 PM', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                        Text('8 PM', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // 4. Quick Actions
              const Text(
                'Quick Actions',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildQuickActionTile(
                    title: 'View Orders',
                    icon: Icons.inventory_2_outlined,
                    iconColor: AppColors.neonCyan,
                    badgeCount: activeList.isNotEmpty ? activeList.length : null,
                    onTap: () => widget.onNavigateTab?.call(1),
                  ),
                  const SizedBox(width: 10),
                  _buildQuickActionTile(
                    title: 'Update GPS',
                    icon: Icons.my_location_rounded,
                    iconColor: AppColors.accentBlue,
                    onTap: _manualUpdateLocation,
                  ),
                  const SizedBox(width: 10),
                  _buildQuickActionTile(
                    title: 'Earnings',
                    icon: Icons.receipt_long_rounded,
                    iconColor: AppColors.warning,
                    onTap: () => widget.onNavigateTab?.call(2),
                  ),
                  const SizedBox(width: 10),
                  _buildQuickActionTile(
                    title: 'Support',
                    icon: Icons.headset_mic_rounded,
                    iconColor: AppColors.success,
                    onTap: _showSupportModal,
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // 5. Current Deliveries Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Text(
                        'Active Deliveries',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      if (activeList.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.neonCyan.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppColors.neonCyan.withValues(alpha: 0.4)),
                          ),
                          child: Text(
                            '${activeList.length}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.neonCyan,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (activeList.isNotEmpty)
                    GestureDetector(
                      onTap: () => widget.onNavigateTab?.call(1),
                      child: const Text(
                        'View All',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.neonCyan,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),

              // 6. Current Delivery Card or Empty State
              if (currentDelivery != null) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: currentDelivery.status == DeliveryStatus.assigned
                          ? AppColors.neonCyan
                          : AppColors.border,
                      width: currentDelivery.status == DeliveryStatus.assigned ? 1.5 : 1,
                    ),
                    boxShadow: AppStyles.cardShadow,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Alert banner if newly assigned
                      if (currentDelivery.status == DeliveryStatus.assigned) ...[
                        Container(
                          width: double.infinity,
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppColors.primary.withValues(alpha: 0.4)),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.assignment_ind_rounded, color: AppColors.neonCyan, size: 18),
                              SizedBox(width: 8),
                              Text(
                                'New Delivery Assigned by Admin',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.neonCyan,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      // Order ID & Status Badge
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            currentDelivery.displayId,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                          StatusBadge(status: currentDelivery.status),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Customer Info
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: AppColors.card,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Row(
                                children: [
                                  const Icon(Icons.person_outline_rounded, size: 16, color: AppColors.neonCyan),
                                  const SizedBox(width: 6),
                                  Flexible(
                                    child: Text(
                                      currentDelivery.customerName,
                                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              currentDelivery.customerPhone,
                              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Route Stepper
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Column(
                            children: [
                              const Icon(Icons.circle, color: AppColors.success, size: 12),
                              Container(
                                width: 2,
                                height: 32,
                                color: AppColors.border,
                              ),
                              const Icon(Icons.location_pin, color: AppColors.neonCyan, size: 15),
                            ],
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
                                  currentDelivery.pickupLocation,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 12),
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
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Real OpenStreetMap Route Preview
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: SizedBox(
                          height: 190,
                          width: double.infinity,
                          child: RouteMapWidget(
                            pickupLat: currentDelivery.pickupLatitude,
                            pickupLng: currentDelivery.pickupLongitude,
                            destinationLat: currentDelivery.destinationLatitude,
                            destinationLng: currentDelivery.destinationLongitude,
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),

                      // Action Buttons Based on Status
                      if (currentDelivery.status == DeliveryStatus.assigned) ...[
                        CustomButton(
                          text: 'Accept Delivery',
                          icon: Icons.check_circle_outline_rounded,
                          backgroundColor: AppColors.success,
                          isLoading: _isAccepting,
                          height: 48,
                          onPressed: () => _acceptOrder(currentDelivery),
                        ),
                        const SizedBox(height: 10),
                      ] else if (currentDelivery.status == DeliveryStatus.accepted ||
                          currentDelivery.status == DeliveryStatus.arrivedAtPickup) ...[
                        CustomButton(
                          text: 'Confirm Item Pickup',
                          icon: Icons.inventory_2_outlined,
                          backgroundColor: AppColors.primary,
                          height: 48,
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => PickupConfirmationScreen(order: currentDelivery),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 10),
                      ] else if (currentDelivery.status == DeliveryStatus.pickedUp ||
                          currentDelivery.status == DeliveryStatus.onTheWay) ...[
                        CustomButton(
                          text: 'Continue Delivery / On The Way',
                          icon: Icons.navigation_rounded,
                          backgroundColor: AppColors.primary,
                          height: 48,
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => OnTheWayScreen(order: currentDelivery),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 10),
                      ] else if (currentDelivery.status == DeliveryStatus.delivered ||
                          currentDelivery.status == DeliveryStatus.arrivedAtLocation) ...[
                        CustomButton(
                          text: 'Enter Customer OTP to Complete',
                          icon: Icons.pin_outlined,
                          backgroundColor: AppColors.success,
                          height: 48,
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => OtpVerificationScreen(order: currentDelivery),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 10),
                      ],

                      CustomButton(
                        text: 'View Details',
                        isOutlined: true,
                        backgroundColor: AppColors.surface,
                        borderColor: AppColors.border,
                        textColor: Colors.white,
                        height: 46,
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => DeliveryDetailsScreen(order: currentDelivery),
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
                  padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.card,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.border),
                        ),
                        child: const Icon(
                          Icons.moped_rounded,
                          size: 34,
                          color: AppColors.neonCyan,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'No Active Delivery',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'You are ready to accept new orders. Stay online to receive incoming delivery requests from Bale customers.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 18),
                      // Live Bale Robe Coverage Map
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: const SizedBox(
                          height: 180,
                          width: double.infinity,
                          child: RouteMapWidget(),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 20),

              // 7. Other Active Deliveries Queue (if more than 1)
              if (activeList.length > 1) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Other Active Deliveries',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      '${activeList.length - 1} more',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                ...activeList.skip(1).map(
                  (order) => Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                      boxShadow: AppStyles.cardShadow,
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
                              color: AppColors.card,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.inventory_2_outlined,
                              color: AppColors.neonCyan,
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
                                      order.displayId,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 14,
                                        color: Colors.white,
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
              ],
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGlassStatCard({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String value,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: AppStyles.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(height: 10),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionTile({
    required String title,
    required IconData icon,
    required Color iconColor,
    int? badgeCount,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
            boxShadow: AppStyles.cardShadow,
          ),
          child: Column(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Icon(icon, color: iconColor, size: 20),
                  ),
                  if (badgeCount != null && badgeCount > 0)
                    Positioned(
                      top: -4,
                      right: -4,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: AppColors.danger,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                        child: Text(
                          '$badgeCount',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Custom painter for the glowing Neon Cyan wave chart with gradient fill and floating peak tooltip
class OverviewWaveChartPainter extends CustomPainter {
  final Color lineColor;
  final Color gradientStart;
  final Color gradientEnd;
  final String tooltipText;

  OverviewWaveChartPainter({
    required this.lineColor,
    required this.gradientStart,
    required this.gradientEnd,
    required this.tooltipText,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;

    // 1. Draw horizontal subtle background grid lines
    final gridPaint = Paint()
      ..color = AppColors.border.withValues(alpha: 0.5)
      ..strokeWidth = 1.0;

    for (int i = 1; i <= 3; i++) {
      final y = h * (i / 4.0);
      canvas.drawLine(Offset(0, y), Offset(w, y), gridPaint);
    }

    // 2. Control points for smooth wave: (0, 0.7h), (0.22w, 0.55h), (0.50w, 0.28h), (0.75w, 0.60h), (w, 0.40h)
    final p0 = Offset(0, h * 0.72);
    final p1 = Offset(w * 0.22, h * 0.55);
    final pPeak = Offset(w * 0.50, h * 0.26);
    final p3 = Offset(w * 0.75, h * 0.58);
    final p4 = Offset(w, h * 0.38);

    final path = Path();
    path.moveTo(p0.dx, p0.dy);

    // Curve 1: p0 to p1
    path.quadraticBezierTo(w * 0.10, h * 0.72, p1.dx, p1.dy);
    // Curve 2: p1 to pPeak
    path.quadraticBezierTo(w * 0.35, h * 0.38, pPeak.dx, pPeak.dy);
    // Curve 3: pPeak to p3
    path.quadraticBezierTo(w * 0.62, h * 0.16, p3.dx, p3.dy);
    // Curve 4: p3 to p4
    path.quadraticBezierTo(w * 0.88, h * 0.65, p4.dx, p4.dy);

    // 3. Draw gradient fill under wave
    final fillPath = Path.from(path)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [gradientStart, gradientEnd],
      ).createShader(Rect.fromLTWH(0, 0, w, h))
      ..style = PaintingStyle.fill;

    canvas.drawPath(fillPath, fillPaint);

    // 4. Draw glowing neon cyan wave stroke
    final strokePaint = Paint()
      ..color = lineColor
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Outer glow
    final glowPaint = Paint()
      ..color = lineColor.withValues(alpha: 0.35)
      ..strokeWidth = 6.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0);

    canvas.drawPath(path, glowPaint);
    canvas.drawPath(path, strokePaint);

    // 5. Draw glowing peak indicator circle
    final peakDotPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    final peakRingPaint = Paint()
      ..color = lineColor
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    canvas.drawCircle(pPeak, 5.0, peakDotPaint);
    canvas.drawCircle(pPeak, 5.0, peakRingPaint);

    // 6. Draw floating tooltip pill over peak
    final textPainter = TextPainter(
      text: TextSpan(
        text: tooltipText,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.2,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final pillWidth = textPainter.width + 16;
    final pillHeight = 24.0;
    final pillRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(pPeak.dx, pPeak.dy - 20),
        width: pillWidth,
        height: pillHeight,
      ),
      const Radius.circular(12),
    );

    final tooltipBgPaint = Paint()
      ..color = const Color(0xFF0C1938)
      ..style = PaintingStyle.fill;

    final tooltipBorderPaint = Paint()
      ..color = lineColor.withValues(alpha: 0.6)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    canvas.drawRRect(pillRect, tooltipBgPaint);
    canvas.drawRRect(pillRect, tooltipBorderPaint);

    textPainter.paint(
      canvas,
      Offset(pPeak.dx - (textPainter.width / 2), pPeak.dy - 20 - (textPainter.height / 2)),
    );
  }

  @override
  bool shouldRepaint(covariant OverviewWaveChartPainter oldDelegate) {
    return oldDelegate.tooltipText != tooltipText ||
        oldDelegate.lineColor != lineColor;
  }
}
