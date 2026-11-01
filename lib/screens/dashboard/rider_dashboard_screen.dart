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

class _RiderDashboardScreenState extends State<RiderDashboardScreen>
    with SingleTickerProviderStateMixin {
  final DeliveryService _deliveryService = DeliveryService();
  late final PageController _pageController;
  late final AnimationController _radarController;
  late final Animation<double> _radarAnimation;
  Timer? _gpsTimer;
  Timer? _syncTimer;
  bool _isAccepting = false;
  int _selectedPageIndex = 0; // 0: Active Task, 1: Shift & Earnings, 2: Services
  int _currentOrderIndex = 0; // Cycle multiple active orders with Prev/Next

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);

    // Radar pulse animation for online idle state
    _radarController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat();
    _radarAnimation = Tween<double>(begin: 0.2, end: 1.0).animate(
      CurvedAnimation(parent: _radarController, curve: Curves.easeOut),
    );

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
    _radarController.dispose();
    _pageController.dispose();
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

  Future<void> _sendSms(String phone) async {
    final cleanPhone = phone.replaceAll(RegExp(r'[^\d+]'), '');
    if (cleanPhone.isEmpty) return;
    final uri = Uri.parse('sms:$cleanPhone');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      }
    } catch (_) {}
  }

  void _showSupportModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
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
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.headset_mic_rounded, color: AppColors.primary, size: 24),
                ),
                const SizedBox(width: 14),
                const Text(
                  'Bale Dispatch Hotline',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            const Text(
              'Need immediate help with route, pickup or active delivery? Contact the dispatch team:',
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
              backgroundColor: Colors.white,
              textColor: AppColors.textPrimary,
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

  void _switchPage(int page) {
    setState(() => _selectedPageIndex = page);
    _pageController.animateToPage(
      page,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final profile = _deliveryService.riderProfile;
    final activeList = _deliveryService.activeDeliveries;
    final currentDelivery = _deliveryService.currentDelivery;
    final unreadNotifs = _deliveryService.unreadNotificationCount;
    final riderFirstName = profile.fullName.split(' ').first;

    // Resolve list of active orders
    final List<DeliveryOrder> displayOrders = [];
    if (currentDelivery != null) {
      displayOrders.add(currentDelivery);
    }
    for (final o in activeList) {
      if (!displayOrders.any((item) => item.id == o.id)) {
        displayOrders.add(o);
      }
    }

    if (_currentOrderIndex >= displayOrders.length && displayOrders.isNotEmpty) {
      _currentOrderIndex = displayOrders.length - 1;
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // 1. TOP ROYAL BLUE HERO HEADER
            _buildTopHeroHeader(profile, riderFirstName, unreadNotifs),

            // 2. SEGMENTED GLANCE SWITCHER (Active Task | Shift Stats | Services)
            _buildSegmentedSwitcher(displayOrders.length),

            // 3. FIT-PAGE CONTENT (PageView)
            Expanded(
              child: RefreshIndicator(
                color: AppColors.primary,
                onRefresh: () async {
                  await _deliveryService.refreshAll();
                },
                child: PageView(
                  controller: _pageController,
                  onPageChanged: (idx) {
                    setState(() => _selectedPageIndex = idx);
                  },
                  children: [
                    // PAGE 0: ACTIVE MISSION (LIVE MAP + DYNAMIC IDLE RADAR OR BOOKING SHEET)
                    _buildActiveTaskPage(displayOrders, profile),

                    // PAGE 1: SHIFT & EARNINGS
                    _buildShiftAndEarningsPage(profile),

                    // PAGE 2: QUICK SERVICES & DISPATCH
                    _buildQuickServicesPage(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 1. TOP HERO HEADER
  // ---------------------------------------------------------------------------
  Widget _buildTopHeroHeader(dynamic profile, String riderFirstName, int unreadNotifs) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
        gradient: LinearGradient(
          colors: [
            Color(0xFF003893), // Deep royal navy
            Color(0xFF0047BA), // Balera primary blue
            Color(0xFF0D6EFD), // Electric blue accent
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x2A0047BA),
            blurRadius: 14,
            offset: Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(18.0, 10.0, 18.0, 14.0),
      child: Column(
        children: [
          // Row 1: Logo (drawer) + Greeting + Notification Bell
          Row(
            children: [
              // Balera Logo / Drawer Trigger
              Builder(
                builder: (ctx) => InkWell(
                  onTap: () => Scaffold.of(ctx).openDrawer(),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white.withValues(alpha: 0.8), width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.12),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: Image.asset(
                        'assets/logo/balera_logo.png',
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.person,
                          color: AppColors.primary,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // Greeting
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Good afternoon,',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                    ),
                    Text(
                      riderFirstName,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ],
                ),
              ),
              // Today quick earnings pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.account_balance_wallet_rounded, color: Colors.white, size: 14),
                    const SizedBox(width: 5),
                    Text(
                      'ETB ${profile.todayEarnings.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Notification Glass Bell
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.20),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    IconButton(
                      padding: EdgeInsets.zero,
                      icon: const Icon(Icons.notifications_outlined, color: Colors.white, size: 19),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const NotificationsScreen()),
                        );
                      },
                    ),
                    if (unreadNotifs > 0)
                      Positioned(
                        top: 7,
                        right: 7,
                        child: Container(
                          width: 7,
                          height: 7,
                          decoration: const BoxDecoration(
                            color: AppColors.danger,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Row 2: Online / Offline Toggle Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: profile.isOnline ? const Color(0xFF4ADE80) : const Color(0xFFF87171),
                        shape: BoxShape.circle,
                        boxShadow: [
                          if (profile.isOnline)
                            BoxShadow(
                              color: const Color(0xFF4ADE80).withValues(alpha: 0.6),
                              blurRadius: 6,
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      profile.isOnline ? 'Online & Ready for Orders' : 'Offline (Shift Paused)',
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                Transform.scale(
                  scale: 0.75,
                  child: Switch.adaptive(
                    value: profile.isOnline,
                    activeColor: Colors.white,
                    activeTrackColor: const Color(0xFF10B981),
                    inactiveThumbColor: Colors.white70,
                    inactiveTrackColor: Colors.white24,
                    onChanged: (val) async {
                      try {
                        await _deliveryService.toggleOnlineStatus(val);
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Status update error: $e')),
                          );
                        }
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 2. SEGMENTED GLANCE SWITCHER
  // ---------------------------------------------------------------------------
  Widget _buildSegmentedSwitcher(int activeOrdersCount) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            _buildTabPill(
              title: activeOrdersCount > 0 ? 'Active ($activeOrdersCount)' : 'Active Task',
              icon: Icons.two_wheeler_rounded,
              index: 0,
            ),
            _buildTabPill(
              title: 'Shift Stats',
              icon: Icons.bar_chart_rounded,
              index: 1,
            ),
            _buildTabPill(
              title: 'Services',
              icon: Icons.grid_view_rounded,
              index: 2,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabPill({required String title, required IconData icon, required int index}) {
    final isSelected = _selectedPageIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => _switchPage(index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 7),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 15,
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
              ),
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected ? AppColors.primary : AppColors.textSecondary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 3. PAGE 0: ACTIVE MISSION (DYNAMIC: RADAR WHEN IDLE, BOOKING SHEET WHEN ACTIVE)
  // ---------------------------------------------------------------------------
  Widget _buildActiveTaskPage(List<DeliveryOrder> displayOrders, dynamic profile) {
    // -------------------------------------------------------------------------
    // A. NO ACTIVE DELIVERY (IDLE STATE): RADAR / SEARCHING / STANDBY MODE
    // -------------------------------------------------------------------------
    if (displayOrders.isEmpty) {
      final isOnline = profile.isOnline;

      return Stack(
        alignment: Alignment.center,
        children: [
          // Background Live Map
          const Positioned.fill(
            child: RouteMapWidget(isInteractive: true),
          ),

          // If Offline: Soft Dimmed Overlay
          if (!isOnline)
            Positioned.fill(
              child: Container(
                color: Colors.black.withValues(alpha: 0.28),
              ),
            ),

          // Center Animated Radar Pulse (When Online & Searching)
          if (isOnline) ...[
            AnimatedBuilder(
              animation: _radarAnimation,
              builder: (context, child) {
                final size = 180.0 * _radarAnimation.value;
                return Container(
                  width: size,
                  height: size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primary.withValues(alpha: 0.18 * (1.0 - _radarAnimation.value)),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.55 * (1.0 - _radarAnimation.value)),
                      width: 2,
                    ),
                  ),
                );
              },
            ),
            // Center Bike Marker
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.45),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(Icons.two_wheeler_rounded, color: Colors.white, size: 26),
            ),
          ] else ...[
            // Center Standby Icon (When Offline)
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: const Color(0xFF475569),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 3),
                boxShadow: const [
                  BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 4)),
                ],
              ),
              child: const Icon(Icons.power_settings_new_rounded, color: Colors.white, size: 28),
            ),
          ],

          // Top Floating Radar Pill Tag over Map
          Positioned(
            top: 14,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.94),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.10),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: isOnline ? const Color(0xFF10B981) : const Color(0xFFF43F5E),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isOnline ? '📍 GPS Active • Bale Robe Zone' : '📍 GPS Standby (Offline)',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Bottom Floating Status Card (Clean, modern, informative)
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.border),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.16),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status Header Pill
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: isOnline ? const Color(0xFFDCFCE7) : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 7,
                              height: 7,
                              decoration: BoxDecoration(
                                color: isOnline ? const Color(0xFF16A34A) : const Color(0xFF64748B),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              isOnline ? "YOU'RE ONLINE" : "YOU'RE OFFLINE",
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: isOnline ? const Color(0xFF15803D) : const Color(0xFF475569),
                                letterSpacing: 0.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      // Today Quick Snapshot
                      Text(
                        'Today: ETB ${profile.todayEarnings.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Headline
                  Text(
                    isOnline ? 'Searching for nearby requests...' : 'Shift is Currently Paused',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF0F172A),
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 4),

                  // Subtitle
                  Text(
                    isOnline
                        ? 'Stay in high-demand zones around Robe central market to receive incoming orders faster.'
                        : 'Switch online whenever you are ready to receive delivery assignments and earn in Bale.',
                    style: const TextStyle(fontSize: 12.5, color: Color(0xFF64748B), height: 1.35),
                  ),
                  const SizedBox(height: 16),

                  // Action Button(s)
                  if (isOnline) ...[
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Color(0xFFCBD5E1)),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              padding: const EdgeInsets.symmetric(vertical: 13),
                            ),
                            onPressed: () async {
                              await _deliveryService.toggleOnlineStatus(false);
                            },
                            child: const Text(
                              'Pause Shift',
                              style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w700, fontSize: 13.5),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.bar_chart_rounded, size: 16, color: Colors.white),
                            label: const Text('Shift Stats', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13.5)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              padding: const EdgeInsets.symmetric(vertical: 13),
                            ),
                            onPressed: () => _switchPage(1),
                          ),
                        ),
                      ],
                    ),
                  ] else ...[
                    CustomButton(
                      text: 'GO ONLINE TO RECEIVE ORDERS',
                      icon: Icons.power_settings_new_rounded,
                      backgroundColor: const Color(0xFF10B981),
                      height: 48,
                      onPressed: () async {
                        await _deliveryService.toggleOnlineStatus(true);
                      },
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      );
    }

    // -------------------------------------------------------------------------
    // B. ACTIVE DELIVERY IN PROGRESS: LIVE ROUTE MAP + VERTICAL BOTTOM SHEET
    // -------------------------------------------------------------------------
    final currentOrder = displayOrders[_currentOrderIndex];

    return Stack(
      children: [
        // 1. Live Interactive Route Map
        Positioned.fill(
          child: RouteMapWidget(
            pickupLat: currentOrder.pickupLatitude,
            pickupLng: currentOrder.pickupLongitude,
            destinationLat: currentOrder.destinationLatitude,
            destinationLng: currentOrder.destinationLongitude,
          ),
        ),

        // 2. Vertically Draggable / Scrollable Bottom Sheet
        DraggableScrollableSheet(
          initialChildSize: 0.58,
          minChildSize: 0.35,
          maxChildSize: 0.95,
          snap: true,
          snapSizes: const [0.35, 0.58, 0.90],
          builder: (context, scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.16),
                    blurRadius: 18,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(18, 10, 18, 24),
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

                  // Multi-Order Switcher Bar (If multiple active orders exist)
                  if (displayOrders.length > 1) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back_ios_rounded, size: 15),
                            color: _currentOrderIndex > 0 ? AppColors.primary : AppColors.textMuted,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: _currentOrderIndex > 0
                                ? () => setState(() => _currentOrderIndex--)
                                : null,
                          ),
                          Row(
                            children: [
                              const Icon(Icons.layers_outlined, size: 14, color: AppColors.primary),
                              const SizedBox(width: 5),
                              Text(
                                'Active Order ${_currentOrderIndex + 1} of ${displayOrders.length}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                          IconButton(
                            icon: const Icon(Icons.arrow_forward_ios_rounded, size: 15),
                            color: _currentOrderIndex < displayOrders.length - 1
                                ? AppColors.primary
                                : AppColors.textMuted,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: _currentOrderIndex < displayOrders.length - 1
                                ? () => setState(() => _currentOrderIndex++)
                                : null,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  // 1. Customer Profile Row with circular Phone & SMS buttons
                  _buildCustomerProfileRow(currentOrder),
                  const SizedBox(height: 12),

                  // 2. Status Banner Strip
                  _buildStatusPillBanner(currentOrder),
                  const SizedBox(height: 14),

                  // 3. The Iconic Booking Card (Matching Screenshot)
                  _buildScreenshotBookingCard(currentOrder),
                  const SizedBox(height: 16),

                  // 4. Primary Rider Action Button
                  _buildActionButton(currentOrder),
                  const SizedBox(height: 16),

                  // 5. Special Notes / Items (Scrollable content)
                  if (currentOrder.itemDescription.isNotEmpty || currentOrder.specialInstructions.isNotEmpty) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.notes_rounded, size: 16, color: AppColors.primary),
                              SizedBox(width: 6),
                              Text(
                                'Order Instructions & Note',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            currentOrder.specialInstructions.isNotEmpty
                                ? currentOrder.specialInstructions
                                : currentOrder.itemDescription,
                            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.35),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],

                  // 6. Other Active Orders in Vertical Scroll
                  if (displayOrders.length > 1) ...[
                    const Divider(height: 24, color: AppColors.border),
                    const Text(
                      'All Active Orders in Queue',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 10),
                    ...displayOrders.asMap().entries.map((entry) {
                      final order = entry.value;
                      final isSelected = entry.key == _currentOrderIndex;
                      return _buildCompactQueueCard(order, entry.key, isSelected);
                    }),
                  ],
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // SCREENSHOT MATCHING WIDGETS
  // ---------------------------------------------------------------------------

  // A. Customer / Receiver Row with circular black Phone & Message buttons
  Widget _buildCustomerProfileRow(DeliveryOrder order) {
    return Row(
      children: [
        // Avatar with stylish border
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
        // Customer Name & Rating
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text(
                    'Customer',
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
                    '4.9',
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
        // Circular Black Phone Button
        InkWell(
          onTap: () => _makePhoneCall(order.customerPhone),
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
        // Circular Black Chat / SMS Button
        InkWell(
          onTap: () => _sendSms(order.customerPhone),
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

  // B. Status Banner Strip (Matching Screenshot)
  Widget _buildStatusPillBanner(DeliveryOrder order) {
    Color bg = const Color(0xFFEFF6FF);
    Color dot = const Color(0xFF2563EB);
    String title = 'En route to destination';
    String trailing = 'ETA: ${order.eta}';

    if (order.status == DeliveryStatus.assigned) {
      bg = const Color(0xFFFEF3C7);
      dot = const Color(0xFFD97706);
      title = 'Assigned for Pickup';
      trailing = order.distance;
    } else if (order.status == DeliveryStatus.arrivedAtPickup || order.status == DeliveryStatus.pickedUp) {
      bg = const Color(0xFFEFF6FF);
      dot = const Color(0xFF2563EB);
      title = 'Package Picked Up';
      trailing = 'Heading to Drop-off';
    } else if (order.status == DeliveryStatus.arrivedAtLocation || order.status == DeliveryStatus.delivered) {
      bg = const Color(0xFFDCFCE7);
      dot = const Color(0xFF16A34A);
      title = 'Arrived at Location';
      trailing = 'OTP Required';
    } else if (order.status == DeliveryStatus.completed) {
      bg = const Color(0xFFDCFCE7);
      dot = const Color(0xFF16A34A);
      title = 'Delivered to ${order.receiverName.isNotEmpty ? order.receiverName : order.customerName}';
      trailing = 'Signed for';
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

  // C. Booking Card (Exact layout from user screenshot)
  Widget _buildScreenshotBookingCard(DeliveryOrder order) {
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
          // Row 1: Booking Label + Display ID + Dark Status Badge
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
              // Dark Status Chip (from screenshot)
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

          // Row 2: Orange Dotted Stepper (from screenshot)
          _buildDashedStepper(order.status),
          const SizedBox(height: 16),

          // Row 3: Details Grid + 3D Package Box Illustration
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // From -> To Row
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

                    // Order Cost -> Customer Row
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

              // Stacked 3D Delivery Parcel Boxes (from screenshot)
              _buildPackage3DGraphic(),
            ],
          ),
        ],
      ),
    );
  }

  // D. Orange Dashed Stepper (4 dots with dotted lines connecting them)
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

  // E. 3D Delivery Box Illustration (Matching bottom right corner of screenshot)
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

  // F. Big Rider Action Button
  Widget _buildActionButton(DeliveryOrder order) {
    if (order.status == DeliveryStatus.assigned) {
      return CustomButton(
        text: 'ACCEPT DELIVERY',
        icon: Icons.check_circle_rounded,
        backgroundColor: AppColors.success,
        isLoading: _isAccepting,
        height: 50,
        onPressed: () => _acceptOrder(order),
      );
    } else if (order.status == DeliveryStatus.accepted ||
        order.status == DeliveryStatus.arrivedAtPickup) {
      return CustomButton(
        text: 'CONFIRM PICKUP',
        icon: Icons.inventory_2_rounded,
        backgroundColor: AppColors.primary,
        height: 50,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => PickupConfirmationScreen(order: order)),
          );
        },
      );
    } else if (order.status == DeliveryStatus.pickedUp ||
        order.status == DeliveryStatus.onTheWay) {
      return CustomButton(
        text: 'CONTINUE / ON THE WAY',
        icon: Icons.navigation_rounded,
        backgroundColor: AppColors.primary,
        height: 50,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => OnTheWayScreen(order: order)),
          );
        },
      );
    } else if (order.status == DeliveryStatus.delivered ||
        order.status == DeliveryStatus.arrivedAtLocation) {
      return CustomButton(
        text: 'ENTER CUSTOMER OTP',
        icon: Icons.pin_outlined,
        backgroundColor: AppColors.success,
        height: 50,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => OtpVerificationScreen(order: order)),
          );
        },
      );
    }
    return const SizedBox.shrink();
  }

  // G. Compact Card for Other Active Orders in Queue
  Widget _buildCompactQueueCard(DeliveryOrder order, int index, bool isSelected) {
    return GestureDetector(
      onTap: () => setState(() => _currentOrderIndex = index),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFEFF6FF) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : Colors.white,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.two_wheeler_rounded,
                color: isSelected ? Colors.white : AppColors.primary,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    order.displayId,
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    '${order.pickupLocation} ➔ ${order.dropoffLocation}',
                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            StatusBadge(status: order.status),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 4. PAGE 1: SHIFT & EARNINGS
  // ---------------------------------------------------------------------------
  Widget _buildShiftAndEarningsPage(dynamic profile) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      child: Column(
        children: [
          // Total Earnings Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.border),
              boxShadow: AppStyles.cardShadow,
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCFCE7),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.account_balance_wallet_rounded,
                    color: Color(0xFF15803D),
                    size: 26,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Today's Shift Earnings",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'ETB ${profile.todayEarnings.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: () => widget.onNavigateTab?.call(2),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  ),
                  child: const Text('Payouts', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Two-Column Grid: Parcels Sent + Rating
          Row(
            children: [
              // Parcels Sent
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppColors.border),
                    boxShadow: AppStyles.cardShadow,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEFF6FF),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Icon(Icons.inventory_2_rounded, size: 14, color: AppColors.primary),
                          ),
                          const SizedBox(width: 6),
                          const Text(
                            'Parcels sent',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Text(
                            '${profile.todayCompleted}',
                            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AppColors.textPrimary),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFDCFCE7),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              '+18%',
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF16A34A)),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: List.generate(
                          6,
                          (i) => Container(
                            width: 6,
                            height: i == 3 ? 18 : 10,
                            decoration: BoxDecoration(
                              color: i == 3 ? AppColors.primary : const Color(0xFFE2E8F0),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Rating
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppColors.border),
                    boxShadow: AppStyles.cardShadow,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEF3C7),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Icon(Icons.bolt_rounded, size: 14, color: Color(0xFFD97706)),
                          ),
                          const SizedBox(width: 6),
                          const Text(
                            'Rating',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        '${(profile.rating * 20).toInt()}%',
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AppColors.textPrimary),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'On-time dispatch verified',
                        style: TextStyle(fontSize: 10.5, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Recent Deliveries Link
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
              boxShadow: AppStyles.cardShadow,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.history_rounded, color: AppColors.primary, size: 18),
                    SizedBox(width: 10),
                    Text(
                      'Delivery History',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                    ),
                  ],
                ),
                GestureDetector(
                  onTap: () => widget.onNavigateTab?.call(2),
                  child: const Text('View Full History >', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primary)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Pager Navigation
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton.icon(
                icon: const Icon(Icons.arrow_back_rounded, size: 14, color: AppColors.primary),
                label: const Text('Active Task', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primary)),
                onPressed: () => _switchPage(0),
              ),
              const SizedBox(width: 16),
              TextButton.icon(
                icon: const Text('Services', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primary)),
                label: const Icon(Icons.arrow_forward_rounded, size: 14, color: AppColors.primary),
                onPressed: () => _switchPage(2),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 5. PAGE 2: QUICK SERVICES & DISPATCH
  // ---------------------------------------------------------------------------
  Widget _buildQuickServicesPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 5 Pastel Tiles Row
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.border),
              boxShadow: AppStyles.cardShadow,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Quick Shortcuts',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildServiceTile(
                      icon: Icons.inventory_2_rounded,
                      iconColor: const Color(0xFFD97706),
                      bgColor: const Color(0xFFFEF3C7),
                      label: 'Assigned',
                      onTap: () => widget.onNavigateTab?.call(1),
                    ),
                    _buildServiceTile(
                      icon: Icons.two_wheeler_rounded,
                      iconColor: const Color(0xFF2563EB),
                      bgColor: const Color(0xFFDBEAFE),
                      label: 'Deliveries',
                      onTap: () => widget.onNavigateTab?.call(1),
                    ),
                    _buildServiceTile(
                      icon: Icons.receipt_long_rounded,
                      iconColor: const Color(0xFF059669),
                      bgColor: const Color(0xFFD1FAE5),
                      label: 'History',
                      onTap: () => widget.onNavigateTab?.call(2),
                    ),
                    _buildServiceTile(
                      icon: Icons.account_balance_wallet_rounded,
                      iconColor: const Color(0xFF7C3AED),
                      bgColor: const Color(0xFFEDE9FE),
                      label: 'Earnings',
                      onTap: () => widget.onNavigateTab?.call(2),
                    ),
                    _buildServiceTile(
                      icon: Icons.headset_mic_rounded,
                      iconColor: const Color(0xFFDC2626),
                      bgColor: const Color(0xFFFEE2E2),
                      label: 'Support',
                      onTap: _showSupportModal,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Dispatch Hotline Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.border),
              boxShadow: AppStyles.cardShadow,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: Color(0xFFDCFCE7),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.phone_in_talk_rounded, color: Color(0xFF15803D), size: 20),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Dispatch Hotline Desk',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                          ),
                          Text(
                            '+251 911 000 000 • 24/7 Bale Rider Desk',
                            style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                CustomButton(
                  text: 'CALL DISPATCH TEAM',
                  icon: Icons.phone_rounded,
                  backgroundColor: AppColors.success,
                  height: 44,
                  onPressed: () => _makePhoneCall('+251911000000'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Pager Navigation Back
          Center(
            child: TextButton.icon(
              icon: const Icon(Icons.arrow_back_rounded, size: 14, color: AppColors.primary),
              label: const Text('Back to Active Task', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primary)),
              onPressed: () => _switchPage(0),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceTile({
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
