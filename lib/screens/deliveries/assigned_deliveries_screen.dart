import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_styles.dart';
import '../../models/delivery_order.dart';
import '../../services/delivery_service.dart';
import '../../widgets/status_badge.dart';
import '../delivery/delivery_details_screen.dart';

class AssignedDeliveriesScreen extends StatefulWidget {
  final bool showBackButton;

  const AssignedDeliveriesScreen({
    super.key,
    this.showBackButton = false,
  });

  @override
  State<AssignedDeliveriesScreen> createState() =>
      _AssignedDeliveriesScreenState();
}

class _AssignedDeliveriesScreenState extends State<AssignedDeliveriesScreen> {
  final DeliveryService _deliveryService = DeliveryService();
  int _selectedTabIndex = 0; // 0: Active, 1: Upcoming

  @override
  void initState() {
    super.initState();
    _deliveryService.addListener(_onUpdate);
    _deliveryService.fetchAssignedDeliveries().catchError((_) {});
  }

  @override
  void dispose() {
    _deliveryService.removeListener(_onUpdate);
    super.dispose();
  }

  void _onUpdate() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final activeOrders = _deliveryService.activeDeliveries;
    final upcomingOrders = _deliveryService.upcomingDeliveries;
    final displayedOrders =
        _selectedTabIndex == 0 ? activeOrders : upcomingOrders;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: widget.showBackButton
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded,
                    color: AppColors.textPrimary, size: 20),
                onPressed: () => Navigator.pop(context),
              )
            : null,
        title: const Text(
          'Assigned Deliveries',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          const SizedBox(height: 12),

          // Segmented Tabs: Active (3) | Upcoming (1)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedTabIndex = 0),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: _selectedTabIndex == 0
                              ? Colors.white
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: _selectedTabIndex == 0
                              ? [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.05),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  )
                                ]
                              : null,
                        ),
                        child: Center(
                          child: Text(
                            'Active (${activeOrders.length})',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: _selectedTabIndex == 0
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: _selectedTabIndex == 0
                                  ? AppColors.primary
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedTabIndex = 1),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: _selectedTabIndex == 1
                              ? Colors.white
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: _selectedTabIndex == 1
                              ? [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.05),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  )
                                ]
                              : null,
                        ),
                        child: Center(
                          child: Text(
                            'Upcoming (${upcomingOrders.length})',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: _selectedTabIndex == 1
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: _selectedTabIndex == 1
                                  ? AppColors.primary
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Orders List
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                await _deliveryService.fetchAssignedDeliveries();
              },
              child: displayedOrders.isEmpty
                  ? ListView(
                      children: [
                        SizedBox(
                          height: MediaQuery.of(context).size.height * 0.4,
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.inbox_outlined,
                                  size: 64,
                                  color: AppColors.textMuted.withValues(alpha: 0.5),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  _selectedTabIndex == 0
                                      ? 'No active deliveries'
                                      : 'No upcoming deliveries',
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16.0, vertical: 8.0),
                      itemCount: displayedOrders.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 14),
                      itemBuilder: (context, index) {
                        final order = displayedOrders[index];
                        return _buildOrderCard(order);
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderCard(DeliveryOrder order) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppStyles.radiusLarge,
        border: Border.all(color: AppColors.border),
        boxShadow: AppStyles.cardShadow,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: AppStyles.radiusLarge,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => DeliveryDetailsScreen(order: order),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row: ID + Status Badge
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      order.displayId,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    StatusBadge(status: order.status),
                  ],
                ),
                const SizedBox(height: 14),

                // Route Row with Location Dots
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppColors.textPrimary,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        order.pickupLocation,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppColors.success,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        order.dropoffLocation,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                const Divider(height: 1, color: AppColors.divider),
                const SizedBox(height: 12),

                // Bottom Row: ETA & Distance
                Row(
                  children: [
                    const Icon(Icons.access_time_rounded,
                        size: 16, color: AppColors.textSecondary),
                    const SizedBox(width: 6),
                    Text(
                      'ETA: ${order.eta}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const Spacer(),
                    const Icon(Icons.route_outlined,
                        size: 16, color: AppColors.textSecondary),
                    const SizedBox(width: 6),
                    Text(
                      order.distance,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
