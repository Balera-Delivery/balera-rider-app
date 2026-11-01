import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../models/delivery_order.dart';

class StatusBadge extends StatelessWidget {
  final DeliveryStatus status;
  final String? customLabel;

  const StatusBadge({
    super.key,
    required this.status,
    this.customLabel,
  });

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    Color textColor;

    switch (status) {
      case DeliveryStatus.assigned:
      case DeliveryStatus.accepted:
      case DeliveryStatus.completed:
        bgColor = AppColors.success.withValues(alpha: 0.16);
        textColor = const Color(0xFF34D399);
        break;
      case DeliveryStatus.arrivedAtPickup:
      case DeliveryStatus.pickedUp:
      case DeliveryStatus.onTheWay:
      case DeliveryStatus.arrivedAtLocation:
      case DeliveryStatus.delivered:
        bgColor = AppColors.neonCyan.withValues(alpha: 0.16);
        textColor = AppColors.neonCyan;
        break;
      case DeliveryStatus.cancelled:
        bgColor = AppColors.danger.withValues(alpha: 0.16);
        textColor = const Color(0xFFF87171);
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: textColor.withValues(alpha: 0.3), width: 1),
      ),
      child: Text(
        customLabel ?? status.displayName,
        style: TextStyle(
          color: textColor,
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
