import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_styles.dart';
import '../../models/delivery_order.dart';
import '../../services/delivery_service.dart';
import '../../widgets/custom_button.dart';
import 'delivery_completed_screen.dart';

class OtpVerificationScreen extends StatefulWidget {
  final DeliveryOrder order;

  const OtpVerificationScreen({super.key, required this.order});

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final List<TextEditingController> _controllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  final DeliveryService _deliveryService = DeliveryService();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // Default prefill order's OTP digits for smooth demonstration (482913)
    final digits = widget.order.otpCode.split('');
    for (int i = 0; i < 6 && i < digits.length; i++) {
      _controllers[i].text = digits[i];
    }
  }

  @override
  void dispose() {
    for (var c in _controllers) {
      c.dispose();
    }
    for (var f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  String get _enteredOtp => _controllers.map((c) => c.text.trim()).join();

  void _verifyOtp() async {
    final otp = _enteredOtp;
    if (otp.length < 6) {
      setState(() {
        _errorMessage = 'Please enter the complete 6-digit OTP code.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final success = await _deliveryService.verifyOtp(widget.order.id, otp);
      if (mounted) {
        setState(() => _isLoading = false);
        if (success) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => DeliveryCompletedScreen(order: widget.order),
            ),
          );
        } else {
          setState(() {
            _errorMessage =
                'Incorrect OTP code. Please ask customer to re-check their app.';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString().replaceAll('ApiException: ', '');
        });
      }
    }
  }

  void _showSupportDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Contact Support Desk', style: AppStyles.headingMedium),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'If the recipient did not receive the OTP or cannot access their app, contact Dispatch Administrator:',
              style: AppStyles.bodyMedium,
            ),
            const SizedBox(height: 12),
            const Text(
              '📞 Hotline: +251 900 112 233',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
            ),
            const SizedBox(height: 4),
            Text(
              'Order Reference: ${widget.order.displayId}',
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close', style: TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
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
          'OTP Verification',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            children: [
              const SizedBox(height: 20),

              // Shield Security Graphic
              Container(
                height: 130,
                width: 130,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.35),
                          blurRadius: 18,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.shield_rounded,
                      size: 48,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 28),

              // Headline & Subtitle
              const Text(
                'Enter Delivery OTP',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Ask the customer for the OTP\nand enter it below.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 36),

              // Label
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Delivery OTP',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // 6 PIN Input Boxes
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(6, (index) {
                  return SizedBox(
                    width: 48,
                    height: 54,
                    child: TextField(
                      controller: _controllers[index],
                      focusNode: _focusNodes[index],
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      maxLength: 1,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                      decoration: InputDecoration(
                        counterText: '',
                        filled: true,
                        fillColor: Colors.white,
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                              color: AppColors.border, width: 1.5),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                              color: AppColors.primary, width: 2.0),
                        ),
                      ),
                      onChanged: (value) {
                        if (value.isNotEmpty && index < 5) {
                          _focusNodes[index + 1].requestFocus();
                        } else if (value.isEmpty && index > 0) {
                          _focusNodes[index - 1].requestFocus();
                        }
                      },
                    ),
                  );
                }),
              ),

              if (_errorMessage != null) ...[
                const SizedBox(height: 14),
                Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.danger,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],

              const SizedBox(height: 36),

              // Verify OTP Action Button
              CustomButton(
                text: 'Verify OTP',
                backgroundColor: AppColors.primary,
                isLoading: _isLoading,
                onPressed: _verifyOtp,
              ),
              const SizedBox(height: 24),

              // Can't verify link
              GestureDetector(
                onTap: _showSupportDialog,
                child: const Text(
                  "Can't verify? Contact Support",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
