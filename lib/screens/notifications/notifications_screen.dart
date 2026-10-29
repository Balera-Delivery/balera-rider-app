import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
  bool _notificationsEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadNotificationSetting();
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

  Future<void> _loadNotificationSetting() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _notificationsEnabled = prefs.getBool('rider_notifications_enabled') ?? true;
      });
    }
  }

  Future<void> _toggleNotifications(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('rider_notifications_enabled', value);
    if (mounted) {
      setState(() => _notificationsEnabled = value);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(value ? 'Notification alerts turned ON' : 'Notification alerts muted (turned OFF)'),
          backgroundColor: value ? AppColors.success : AppColors.textSecondary,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _confirmClearAll() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Clear All Notifications?', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
        content: const Text(
          'Are you sure you want to delete all notifications? This action cannot be undone.',
          style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              _deliveryService.clearAllNotifications();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('All notifications cleared'), backgroundColor: AppColors.danger),
              );
            },
            child: const Text('Delete All', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
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
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary, size: 20),
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
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded, color: AppColors.textPrimary),
            onSelected: (val) {
              if (val == 'mark_read') {
                _deliveryService.markAllNotificationsAsRead();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('All notifications marked as read'), duration: Duration(seconds: 1)),
                );
              } else if (val == 'clear_all') {
                _confirmClearAll();
              }
            },
            itemBuilder: (ctx) => [
              const PopupMenuItem(
                value: 'mark_read',
                child: Row(
                  children: [
                    Icon(Icons.done_all_rounded, size: 18, color: AppColors.primary),
                    SizedBox(width: 8),
                    Text('Mark all read'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'clear_all',
                child: Row(
                  children: [
                    Icon(Icons.delete_sweep_rounded, size: 18, color: AppColors.danger),
                    SizedBox(width: 8),
                    Text('Clear all notifications', style: TextStyle(color: AppColors.danger)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Top Notification Toggle Switch Card
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            color: Colors.white,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      _notificationsEnabled ? Icons.notifications_active_outlined : Icons.notifications_off_outlined,
                      size: 20,
                      color: _notificationsEnabled ? AppColors.primary : AppColors.textMuted,
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Notification Alerts',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                        ),
                        Text(
                          _notificationsEnabled ? 'Active (Sound & Alerts enabled)' : 'Muted (Notifications paused)',
                          style: TextStyle(fontSize: 11, color: _notificationsEnabled ? AppColors.successDark : AppColors.textMuted),
                        ),
                      ],
                    ),
                  ],
                ),
                Switch(
                  value: _notificationsEnabled,
                  activeColor: AppColors.primary,
                  onChanged: _toggleNotifications,
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.divider),

          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                await _deliveryService.fetchNotifications();
              },
              child: notifications.isEmpty
                  ? ListView(
                      children: [
                        SizedBox(
                          height: MediaQuery.of(context).size.height * 0.45,
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Icon(Icons.notifications_off_outlined, size: 64, color: AppColors.textMuted),
                                SizedBox(height: 12),
                                Text(
                                  'No notifications yet',
                                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
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
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final notif = notifications[index];
                        final iconColor = _getColorForType(notif.type);

                        return Dismissible(
                          key: Key('notif_${notif.id}'),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            decoration: BoxDecoration(
                              color: AppColors.danger,
                              borderRadius: AppStyles.radiusLarge,
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text('Delete', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                                SizedBox(width: 8),
                                Icon(Icons.delete_outline_rounded, color: Colors.white, size: 24),
                              ],
                            ),
                          ),
                          onDismissed: (_) {
                            _deliveryService.deleteNotification(notif.id);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text('Notification deleted'),
                                duration: const Duration(seconds: 1),
                                action: SnackBarAction(
                                  label: 'OK',
                                  onPressed: () {},
                                ),
                              ),
                            );
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: notif.isRead ? Colors.white : const Color(0xFFF0F7FF),
                              borderRadius: AppStyles.radiusLarge,
                              border: Border.all(
                                color: notif.isRead ? AppColors.border : AppColors.primary.withValues(alpha: 0.3),
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
                                    final order = _deliveryService.getDeliveryById(notif.relatedDeliveryId!);
                                    if (order != null) {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => DeliveryDetailsScreen(order: order),
                                        ),
                                      );
                                    }
                                  }
                                },
                                child: Padding(
                                  padding: const EdgeInsets.all(14.0),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(9),
                                        decoration: BoxDecoration(
                                          color: iconColor.withValues(alpha: 0.12),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Icon(_getIconForType(notif.type), color: iconColor, size: 20),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    notif.title,
                                                    style: TextStyle(
                                                      fontSize: 14,
                                                      fontWeight: notif.isRead ? FontWeight.w600 : FontWeight.w800,
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
                                              style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary, height: 1.3),
                                            ),
                                            const SizedBox(height: 6),
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Text(
                                                  notif.timestamp,
                                                  style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                                                ),
                                                InkWell(
                                                  onTap: () => _deliveryService.deleteNotification(notif.id),
                                                  child: const Padding(
                                                    padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                                    child: Icon(Icons.close_rounded, size: 16, color: AppColors.textMuted),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
