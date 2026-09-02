import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_styles.dart';
import '../../models/notification_model.dart';
import '../../services/delivery_service.dart';
import '../delivery/delivery_details_screen.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final DeliveryService _deliveryService = DeliveryService();

  @override
  void initState() {
    super.initState();
    _deliveryService.addListener(_onUpdate);
    _deliveryService.fetchNotifications().catchError((_) {});
  }

  @override
  void dispose() {
    _deliveryService.removeListener(_onUpdate);
    super.dispose();
  }

  void _onUpdate() {
    if (mounted) setState(() {});
  }

  IconData _getIconForType(NotificationType type) {
    switch (type) {
      case NotificationType.assignment:
        return Icons.local_shipping_rounded;
      case NotificationType.statusUpdate:
        return Icons.check_circle_outline_rounded;
      case NotificationType.payout:
        return Icons.account_balance_wallet_outlined;
      case NotificationType.announcement:
        return Icons.campaign_rounded;
    }
  }

  Color _getColorForType(NotificationType type) {
    switch (type) {
      case NotificationType.assignment:
        return AppColors.primary;
      case NotificationType.statusUpdate:
        return AppColors.successDark;
      case NotificationType.payout:
        return const Color(0xFF8B5CF6);
      case NotificationType.announcement:
        return const Color(0xFFF59E0B);
    }
  }

  @override
  Widget build(BuildContext context) {
    final notifications = _deliveryService.notifications;

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
          'Notifications',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: () {
              _deliveryService.markAllNotificationsAsRead();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('All notifications marked as read'),
                  duration: Duration(seconds: 1),
                ),
              );
            },
            child: const Text(
              'Mark all read',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await _deliveryService.fetchNotifications();
        },
        child: notifications.isEmpty
            ? ListView(
                children: [
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.5,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.notifications_off_outlined,
                              size: 64, color: AppColors.textMuted),
                          SizedBox(height: 12),
                          Text(
                            'No notifications yet',
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
                padding: const EdgeInsets.all(16),
                itemCount: notifications.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final notif = notifications[index];
                final iconColor = _getColorForType(notif.type);

                return Container(
                  decoration: BoxDecoration(
                    color: notif.isRead ? Colors.white : const Color(0xFFF0F7FF),
                    borderRadius: AppStyles.radiusLarge,
                    border: Border.all(
                      color: notif.isRead
                          ? AppColors.border
                          : AppColors.primary.withValues(alpha: 0.3),
                    ),
                    boxShadow: AppStyles.cardShadow,
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: AppStyles.radiusLarge,
                      onTap: () {
                        _deliveryService.markNotificationAsRead(notif.id);
                        if (notif.relatedDeliveryId != null) {
                          final order = _deliveryService
                              .getDeliveryById(notif.relatedDeliveryId!);
                          if (order != null) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    DeliveryDetailsScreen(order: order),
                              ),
                            );
                          }
                        }
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: iconColor.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                _getIconForType(notif.type),
                                color: iconColor,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          notif.title,
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: notif.isRead
                                                ? FontWeight.w600
                                                : FontWeight.w800,
                                            color: AppColors.textPrimary,
                                          ),
                                        ),
                                      ),
                                      if (!notif.isRead)
                                        Container(
                                          width: 8,
                                          height: 8,
                                          decoration: const BoxDecoration(
                                            color: AppColors.primary,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    notif.message,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: AppColors.textSecondary,
                                      height: 1.3,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    notif.timestamp,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: AppColors.textMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
      ),
    );
  }
}
