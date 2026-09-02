import 'package:intl/intl.dart';

enum NotificationType {
  assignment,
  statusUpdate,
  payout,
  announcement,
}

class NotificationItem {
  final String id;
  final String title;
  final String message;
  final String timestamp;
  final NotificationType type;
  bool isRead;
  final String? relatedDeliveryId;

  NotificationItem({
    required this.id,
    required this.title,
    required this.message,
    required this.timestamp,
    required this.type,
    this.isRead = false,
    this.relatedDeliveryId,
  });

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    DateTime createdAt = DateTime.now();
    if (json['createdAt'] != null) {
      try {
        createdAt = DateTime.parse(json['createdAt'].toString()).toLocal();
      } catch (_) {}
    }

    final diff = DateTime.now().difference(createdAt);
    String timeAgo;
    if (diff.inMinutes < 1) {
      timeAgo = 'Just now';
    } else if (diff.inMinutes < 60) {
      timeAgo = '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      timeAgo = '${diff.inHours}h ago';
    } else {
      timeAgo = DateFormat('MMM dd, hh:mm a').format(createdAt);
    }

    final titleLower = (json['title']?.toString() ?? '').toLowerCase();
    NotificationType nType = NotificationType.announcement;
    if (titleLower.contains('assign')) {
      nType = NotificationType.assignment;
    } else if (titleLower.contains('status') || titleLower.contains('order') || titleLower.contains('pickup') || titleLower.contains('delivered')) {
      nType = NotificationType.statusUpdate;
    } else if (titleLower.contains('payout') || titleLower.contains('payment') || titleLower.contains('earning')) {
      nType = NotificationType.payout;
    }

    final metadata = json['metadata'] is Map ? json['metadata'] as Map<String, dynamic> : null;
    final relId = metadata?['trackingCode']?.toString() ?? metadata?['deliveryId']?.toString();

    return NotificationItem(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Notification',
      message: json['message']?.toString() ?? '',
      timestamp: timeAgo,
      type: nType,
      isRead: json['isRead'] == true,
      relatedDeliveryId: relId,
    );
  }
}
