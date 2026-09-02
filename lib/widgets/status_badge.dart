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
        bgColor = AppColors.successLight;
        textColor = AppColors.successDark;
        break;
      case DeliveryStatus.arrivedAtPickup:
      case DeliveryStatus.pickedUp:
      case DeliveryStatus.onTheWay:
      case DeliveryStatus.arrivedAtLocation:
      case DeliveryStatus.delivered:
        bgColor = AppColors.primaryLight;
        textColor = AppColors.primary;
        break;
      case DeliveryStatus.cancelled:
        bgColor = AppColors.dangerLight;
        textColor = AppColors.danger;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        customLabel ?? status.displayName,
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
