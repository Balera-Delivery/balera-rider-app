import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_styles.dart';
import '../../models/delivery_order.dart';
import '../../services/delivery_service.dart';
import '../../widgets/status_badge.dart';

class DeliveryHistoryScreen extends StatefulWidget {
  final bool showBackButton;

  const DeliveryHistoryScreen({
    super.key,
    this.showBackButton = false,
  });

  @override
  State<DeliveryHistoryScreen> createState() => _DeliveryHistoryScreenState();
}

class _DeliveryHistoryScreenState extends State<DeliveryHistoryScreen> {
  final DeliveryService _deliveryService = DeliveryService();
  int _selectedFilterIndex = 0; // 0: All, 1: Completed, 2: Cancelled

  @override
  void initState() {
    super.initState();
    _deliveryService.addListener(_onUpdate);
    _deliveryService.fetchDeliveryHistory().catchError((_) {});
  }

  @override
  void dispose() {
    _deliveryService.removeListener(_onUpdate);
    super.dispose();
  }

  void _onUpdate() {
    if (mounted) setState(() {});
  }

  void _showHistoryDetails(DeliveryOrder order) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  order.displayId,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                StatusBadge(status: order.status),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(height: 1, color: AppColors.divider),
            const SizedBox(height: 16),

            _receiptRow('Date & Time', order.date),
            _receiptRow('Customer', order.customerName),
            _receiptRow('Recipient', order.receiverName),
            _receiptRow('Item Category', order.itemType),
            _receiptRow('Pickup Address', order.pickupLocation),
            _receiptRow('Drop-off Address', order.dropoffLocation),
            _receiptRow('Distance', order.distance),
            _receiptRow(
              'Rider Fee Earned',
              'ETB ${order.paymentAmount.toStringAsFixed(2)}',
              isBold: true,
            ),

            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: AppStyles.radiusMedium,
                  ),
                ),
                child: const Text(
                  'Close Receipt',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _receiptRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
                color: isBold ? AppColors.primary : AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final allDeliveries = _deliveryService.deliveries
        .where((d) =>
            d.status == DeliveryStatus.completed ||
            d.status == DeliveryStatus.cancelled)
        .toList();

    List<DeliveryOrder> filteredOrders;
    if (_selectedFilterIndex == 1) {
      filteredOrders = _deliveryService.completedDeliveries;
    } else if (_selectedFilterIndex == 2) {
      filteredOrders = _deliveryService.cancelledDeliveries;
    } else {
      filteredOrders = allDeliveries;
    }

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
          'Delivery History',
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

          // Segmented Filter Tabs: All | Completed | Cancelled
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
                  _filterTabItem('All', 0),
                  _filterTabItem('Completed', 1),
                  _filterTabItem('Cancelled', 2),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Orders List
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                await _deliveryService.fetchDeliveryHistory();
              },
              child: filteredOrders.isEmpty
                  ? ListView(
                      children: [
                        SizedBox(
                          height: MediaQuery.of(context).size.height * 0.4,
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Icon(
                                  Icons.history_toggle_off_rounded,
                                  size: 64,
                                  color: AppColors.textMuted,
                                ),
                                SizedBox(height: 12),
                                Text(
                                  'No deliveries in this filter',
                                  style: TextStyle(
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
                      itemCount: filteredOrders.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final order = filteredOrders[index];
                        return _buildHistoryCard(order);
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterTabItem(String label, int index) {
    final isSelected = _selectedFilterIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedFilterIndex = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: isSelected
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
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHistoryCard(DeliveryOrder order) {
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
          onTap: () => _showHistoryDetails(order),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row: ID, Earnings, Status Badge
                Row(
                  children: [
                    Text(
                      order.displayId,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      'ETB ${order.paymentAmount.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Destination Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        order.dropoffLocation,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    StatusBadge(status: order.status),
                  ],
                ),
                const SizedBox(height: 8),

                // Date & Time
                Text(
                  order.date,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
