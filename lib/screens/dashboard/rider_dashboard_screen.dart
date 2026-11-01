import 'dart:async';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_styles.dart';
import '../../models/delivery_order.dart';
import '../../services/delivery_service.dart';
import '../../services/permission_prompt_service.dart';
import '../../widgets/custom_button.dart';
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
  late final PageController _pageController;
  Timer? _gpsTimer;
  Timer? _syncTimer;
  bool _isAccepting = false;
  int _selectedPageIndex = 0; // 0: Active Task, 1: Shift & Earnings, 2: Services
  int _currentOrderIndex = 0; // Cycle multiple active orders with Prev/Next

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
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

            // 3. FAST, LIGHTWEIGHT DASHBOARD CONTENT (PageView with zero battery drain)
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
                    // PAGE 0: CLEAN ACTIVE TASK CARD SUMMARY (With "Track on Map" button)
                    _buildActiveTaskSummaryPage(displayOrders, profile),

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
              // Balera Logo / Profile Shortcut
              InkWell(
                onTap: () => widget.onNavigateTab?.call(3),
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
  // 3. PAGE 0: CLEAN ACTIVE TASK SUMMARY (With "Track on Map" button)
  // ---------------------------------------------------------------------------
  Widget _buildActiveTaskSummaryPage(List<DeliveryOrder> displayOrders, dynamic profile) {
    // A. Idle State (No Active Deliveries)
    if (displayOrders.isEmpty) {
      final isOnline = profile.isOnline;

      return SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 16),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: AppColors.border),
                boxShadow: AppStyles.cardShadow,
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isOnline ? const Color(0xFFDCFCE7) : const Color(0xFFF1F5F9),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isOnline ? Icons.two_wheeler_rounded : Icons.power_settings_new_rounded,
                      color: isOnline ? const Color(0xFF15803D) : const Color(0xFF64748B),
                      size: 38,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    isOnline ? "You're Online & Ready" : "Shift is Paused (Offline)",
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    isOnline
                        ? 'Stay online to receive requests from Bale customers. Assignments will appear here.'
                        : 'Switch online whenever you are ready to receive delivery assignments and earn.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4),
                  ),
                  const SizedBox(height: 20),
                  if (isOnline) ...[
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.inventory_2_outlined, size: 16),
                            label: const Text('Assigned Queue'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.primary,
                              side: const BorderSide(color: AppColors.primary),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            onPressed: () => widget.onNavigateTab?.call(1),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.arrow_forward_rounded, size: 16, color: Colors.white),
                            label: const Text('Shift Stats', style: TextStyle(color: Colors.white)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            onPressed: () => _switchPage(1),
                          ),
                        ),
                      ],
                    ),
                  ] else ...[
                    CustomButton(
                      text: 'GO ONLINE TO EARN',
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
          ],
        ),
      );
    }

    // B. Active Delivery Card Summary (Clean text/card with "Track on Map" button)
    final currentOrder = displayOrders[_currentOrderIndex];

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
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
                // Top Switcher if multiple orders
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
                        Text(
                          'Active Order ${_currentOrderIndex + 1} of ${displayOrders.length}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
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
                  const SizedBox(height: 14),
                ],

                // Row 1: Booking ID + Status Badge
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Current Mission',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Color(0xFF64748B)),
                        ),
                        Text(
                          currentOrder.displayId,
                          style: const TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF0F172A),
                            letterSpacing: -0.3,
                          ),
                        ),
                      ],
                    ),
                    StatusBadge(status: currentOrder.status),
                  ],
                ),
                const SizedBox(height: 14),

                // Customer Info Row + Direct Call Button
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(color: Color(0xFFEFF6FF), shape: BoxShape.circle),
                        child: const Icon(Icons.person, color: AppColors.primary, size: 18),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              currentOrder.customerName,
                              style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                            ),
                            Text(
                              currentOrder.itemType,
                              style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.phone_rounded, size: 14, color: Colors.white),
                        label: const Text('Call', style: TextStyle(fontSize: 12, color: Colors.white)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.success,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        onPressed: () => _makePhoneCall(currentOrder.customerPhone),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Route Details (Pickup -> Drop-off)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      children: [
                        Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle)),
                        Container(width: 2, height: 26, color: const Color(0xFFE2E8F0)),
                        Container(width: 8, height: 8, decoration: const BoxDecoration(color: Color(0xFF10B981), shape: BoxShape.circle)),
                      ],
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            currentOrder.pickupLocation,
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 14),
                          Text(
                            currentOrder.dropoffLocation,
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // PRIMARY BUTTON: TRACK ON LIVE MAP (Opens dedicated Track Package Screen)
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.map_rounded, color: Colors.white, size: 18),
                    label: const Text(
                      'TRACK ON LIVE MAP',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13.5, letterSpacing: 0.3),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0F172A), // Dark slate premium button
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => DeliveryDetailsScreen(order: currentOrder),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 10),

                // SECONDARY ACTION: Advance Delivery Step
                _buildActionButton(currentOrder),
              ],
            ),
          ),
          const SizedBox(height: 10),

          Center(
            child: TextButton.icon(
              icon: const Text('View Shift Stats', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primary)),
              label: const Icon(Icons.arrow_forward_rounded, size: 14, color: AppColors.primary),
              onPressed: () => _switchPage(1),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(DeliveryOrder order) {
    if (order.status == DeliveryStatus.assigned) {
      return CustomButton(
        text: 'ACCEPT DELIVERY',
        icon: Icons.check_circle_rounded,
        backgroundColor: AppColors.success,
        isLoading: _isAccepting,
        height: 46,
        onPressed: () => _acceptOrder(order),
      );
    } else if (order.status == DeliveryStatus.accepted ||
        order.status == DeliveryStatus.arrivedAtPickup) {
      return CustomButton(
        text: 'CONFIRM PICKUP',
        icon: Icons.inventory_2_rounded,
        backgroundColor: AppColors.primary,
        height: 46,
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
        height: 46,
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
        height: 46,
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

              // Success Rate
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
                              color: const Color(0xFFDCFCE7),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Icon(Icons.verified_rounded, size: 14, color: Color(0xFF16A34A)),
                          ),
                          const SizedBox(width: 6),
                          const Text(
                            'Success Rate',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        '100%',
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AppColors.textPrimary),
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
