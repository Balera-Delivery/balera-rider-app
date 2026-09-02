import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_styles.dart';

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isOutlined;
  final Color? backgroundColor;
  final Color? textColor;
  final Color? borderColor;
  final IconData? icon;
  final double height;
  final double? width;
  final BorderRadius? borderRadius;

  const CustomButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.isOutlined = false,
    this.backgroundColor,
    this.textColor,
    this.borderColor,
    this.icon,
    this.height = 52,
    this.width = double.infinity,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveBorderRadius = borderRadius ?? AppStyles.radiusMedium;
    final effectiveBgColor = isOutlined
        ? Colors.transparent
        : (backgroundColor ?? AppColors.primary);
    final effectiveTextColor = isOutlined
        ? (textColor ?? AppColors.primary)
        : (textColor ?? Colors.white);
    final effectiveBorderColor =
        borderColor ?? (isOutlined ? (textColor ?? AppColors.primary) : Colors.transparent);

    return SizedBox(
      width: width,
      height: height,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: effectiveBgColor,
          foregroundColor: effectiveTextColor,
          elevation: isOutlined ? 0 : 0,
          shadowColor: Colors.transparent,
          side: isOutlined ? BorderSide(color: effectiveBorderColor, width: 1.5) : BorderSide.none,
          shape: RoundedRectangleBorder(borderRadius: effectiveBorderRadius),
          padding: const EdgeInsets.symmetric(horizontal: 20),
        ),
        child: isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 20, color: effectiveTextColor),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    text,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: effectiveTextColor,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
