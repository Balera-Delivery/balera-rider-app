import 'dart:async';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
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

  Future<void> _makePhoneCall(String phone) async {
    final cleanPhone = phone.replaceAll(RegExp(r'[^\d+]'), '');
    if (cleanPhone.isEmpty) return;
    final uri = Uri.parse('tel:$cleanPhone');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      }
    } catch (_) {}
  }

  void _showSupportModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(22.0),
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
                  'Bale Dispatch Hotline',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            const Text(
              'Need immediate help with your delivery or location? Tap below to call the dispatch manager.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.4),
            ),
            const SizedBox(height: 18),
            CustomButton(
              text: 'Call Dispatch (+251 911 000 000)',
              icon: Icons.phone_in_talk_rounded,
              backgroundColor: AppColors.success,
              onPressed: () {
                Navigator.pop(ctx);
                _makePhoneCall('+251911000000');
              },
            ),
            const SizedBox(height: 10),
            CustomButton(
              text: 'Close',
              isOutlined: true,
              backgroundColor: AppColors.surface,
              textColor: Colors.white,
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
            content: Text('Delivery ${order.displayId} accepted! 🚀'),
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
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.border),
                ),
                child: const Icon(Icons.menu_rounded, color: Colors.white, size: 22),
              ),
            ),
          ),
        ),
        titleSpacing: 0,
        title: Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  profile.fullName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
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
                    const SizedBox(width: 5),
                    Text(
                      profile.isOnline ? 'Online' : 'Offline',
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
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.headset_mic_outlined, color: AppColors.neonCyan, size: 22),
            onPressed: _showSupportModal,
            tooltip: 'Dispatch Support',
          ),
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_none_rounded, color: Colors.white, size: 24),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const NotificationsScreen()),
                  );
                },
              ),
              if (unreadNotifs > 0)
                Positioned(
                  top: 10,
                  right: 12,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppColors.danger,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 6),
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
              // 1. SIMPLE & CLEAR: Online / Offline Master Switch Card
              _buildOnlineStatusCard(profile.isOnline),
              const SizedBox(height: 16),

              // 2. SIMPLE & CLEAR: Big Glanceable Numbers (Earnings + Completed)
              Row(
                children: [
                  // Earnings Box
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border),
                        boxShadow: AppStyles.cardShadow,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: const [
                              Icon(Icons.account_balance_wallet_outlined, size: 16, color: AppColors.success),
                              SizedBox(width: 6),
                              Text(
                                "Today's Earnings",
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'ETB ${profile.todayEarnings.toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Completed Orders Box
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border),
                        boxShadow: AppStyles.cardShadow,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: const [
                              Icon(Icons.check_circle_outline_rounded, size: 16, color: AppColors.neonCyan),
                              SizedBox(width: 6),
                              Text(
                                'Completed',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(
                                '${profile.todayCompleted}',
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '/ ${profile.todayAssigned} orders',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // 3. HERO SECTION: Current Active Delivery or Simple Waiting State
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Current Order',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  if (activeList.isNotEmpty)
                    TextButton(
                      onPressed: () => widget.onNavigateTab?.call(1),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        'All Orders (${activeList.length})',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.neonCyan,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),

              if (currentDelivery != null) ...[
                // Big, Clean, Actionable Delivery Card
                _buildHeroOrderCard(currentDelivery),
              ] else ...[
                // Simple Waiting State Card
                _buildEmptyOrderState(profile.isOnline),
              ],
              const SizedBox(height: 20),

              // 4. Quick Simple Shortcuts (Only 2 essential buttons)
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => widget.onNavigateTab?.call(1),
                      icon: const Icon(Icons.two_wheeler_rounded, size: 18, color: AppColors.neonCyan),
                      label: Text(
                        'My Deliveries (${activeList.length})',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: const BorderSide(color: AppColors.border),
                        backgroundColor: AppColors.surface,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => widget.onNavigateTab?.call(2),
                      icon: const Icon(Icons.receipt_long_rounded, size: 18, color: AppColors.warning),
                      label: const Text(
                        'Trip History',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: const BorderSide(color: AppColors.border),
                        backgroundColor: AppColors.surface,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  /// Big, clear Online / Offline master status banner
  Widget _buildOnlineStatusCard(bool isOnline) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: isOnline ? const Color(0xFF0C2A1E) : AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isOnline ? AppColors.success : AppColors.border,
          width: isOnline ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: isOnline
                  ? AppColors.success.withValues(alpha: 0.2)
                  : AppColors.card,
              shape: BoxShape.circle,
            ),
            child: Icon(
              isOnline ? Icons.power_settings_new_rounded : Icons.power_off_rounded,
              color: isOnline ? AppColors.success : AppColors.textMuted,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isOnline ? 'YOU ARE ONLINE' : 'YOU ARE OFFLINE',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                    color: isOnline ? const Color(0xFF34D399) : Colors.white70,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isOnline
                      ? 'Ready to receive orders in Bale'
                      : 'Go online to start receiving orders',
                  style: TextStyle(
                    fontSize: 12,
                    color: isOnline ? Colors.white70 : AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          Transform.scale(
            scale: 0.95,
            child: Switch.adaptive(
              value: isOnline,
              activeColor: Colors.white,
              activeTrackColor: AppColors.success,
              inactiveThumbColor: Colors.white70,
              inactiveTrackColor: AppColors.card,
              onChanged: (val) async {
                try {
                  await _deliveryService.toggleOnlineStatus(val);
                } catch (e) {
                  if (mounted) {
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
    );
  }

  /// Big, focused Hero Card for the currently active delivery
  Widget _buildHeroOrderCard(DeliveryOrder order) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: order.status == DeliveryStatus.assigned ? AppColors.neonCyan : AppColors.border,
          width: order.status == DeliveryStatus.assigned ? 1.5 : 1,
        ),
        boxShadow: AppStyles.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: Order ID + Status
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                order.displayId,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              StatusBadge(status: order.status),
            ],
          ),
          const SizedBox(height: 16),

          // Row 2: Customer Name + 1-Tap Call Button
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                const Icon(Icons.person, color: AppColors.neonCyan, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        order.customerName,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        order.customerPhone,
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.phone_rounded, color: AppColors.success, size: 24),
                  onPressed: () => _makePhoneCall(order.customerPhone),
                  tooltip: 'Call Customer',
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Row 3: Pickup & Dropoff Simple Addresses
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  const Icon(Icons.circle, color: AppColors.success, size: 12),
                  Container(
                    width: 2,
                    height: 28,
                    color: AppColors.border,
                  ),
                  const Icon(Icons.location_pin, color: AppColors.neonCyan, size: 16),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Pickup From',
                      style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                    ),
                    Text(
                      order.pickupLocation,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Deliver To',
                      style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                    ),
                    Text(
                      order.dropoffLocation,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Row 4: Single, Big, Obvious Action Button (What rider needs to do right now)
          if (order.status == DeliveryStatus.assigned) ...[
            CustomButton(
              text: 'ACCEPT DELIVERY',
              icon: Icons.check_circle_rounded,
              backgroundColor: AppColors.success,
              isLoading: _isAccepting,
              height: 52,
              onPressed: () => _acceptOrder(order),
            ),
          ] else if (order.status == DeliveryStatus.accepted ||
              order.status == DeliveryStatus.arrivedAtPickup) ...[
            CustomButton(
              text: 'CONFIRM PICKUP',
              icon: Icons.inventory_2_rounded,
              backgroundColor: AppColors.primary,
              height: 52,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PickupConfirmationScreen(order: order),
                  ),
                );
              },
            ),
          ] else if (order.status == DeliveryStatus.pickedUp ||
              order.status == DeliveryStatus.onTheWay) ...[
            CustomButton(
              text: 'ON THE WAY / NAVIGATE',
              icon: Icons.navigation_rounded,
              backgroundColor: AppColors.primary,
              height: 52,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => OnTheWayScreen(order: order),
                  ),
                );
              },
            ),
          ] else if (order.status == DeliveryStatus.delivered ||
              order.status == DeliveryStatus.arrivedAtLocation) ...[
            CustomButton(
              text: 'ENTER CUSTOMER OTP',
              icon: Icons.pin_outlined,
              backgroundColor: AppColors.success,
              height: 52,
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
          const SizedBox(height: 10),

          // Secondary Details button
          CustomButton(
            text: 'View Map & Order Details',
            isOutlined: true,
            backgroundColor: AppColors.surface,
            textColor: Colors.white,
            height: 44,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => DeliveryDetailsScreen(order: order),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  /// Clean, simple state when no delivery is currently active
  Widget _buildEmptyOrderState(bool isOnline) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: isOnline ? AppColors.neonCyan.withValues(alpha: 0.15) : AppColors.card,
              shape: BoxShape.circle,
            ),
            child: Icon(
              isOnline ? Icons.radar_rounded : Icons.moped_rounded,
              size: 40,
              color: isOnline ? AppColors.neonCyan : AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            isOnline ? 'Waiting for New Orders...' : 'You are Offline',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            isOnline
                ? 'Stay online. New delivery requests from Bale will automatically appear here!'
                : 'Turn your status to Online above to start receiving delivery requests.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
