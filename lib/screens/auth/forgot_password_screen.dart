import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../constants/app_colors.dart';
import '../../services/auth_service.dart';
import '../../widgets/custom_button.dart';

class ForgotPasswordScreen extends StatefulWidget {
  final String? initialPhone;

  const ForgotPasswordScreen({super.key, this.initialPhone});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController _phoneController = TextEditingController();
  final List<TextEditingController> _otpControllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _otpFocusNodes = List.generate(6, (_) => FocusNode());

  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  int _step = 1; // 1 = Enter Phone, 2 = Verify OTP & Set New Password
  bool _isLoading = false;
  bool _isResending = false;
  bool _obscureNewPass = true;
  bool _obscureConfirmPass = true;
  String? _errorMessage;
  String? _devOtp;

  int _resendCountdown = 60;
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    if (widget.initialPhone != null && widget.initialPhone!.trim().isNotEmpty) {
      _phoneController.text = widget.initialPhone!.trim();
    }
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _phoneController.dispose();
    for (var c in _otpControllers) {
      c.dispose();
    }
    for (var f in _otpFocusNodes) {
      f.dispose();
    }
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _startCountdown() {
    _resendCountdown = 60;
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_resendCountdown > 0) {
        setState(() => _resendCountdown--);
      } else {
        timer.cancel();
      }
    });
  }

  String get _enteredOtp => _otpControllers.map((c) => c.text.trim()).join();

  Future<void> _handleSendOtp() async {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty || phone.length < 9) {
      setState(() {
        _errorMessage = 'Please enter a valid phone number (e.g. +251 911 000 001).';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final res = await AuthService().sendPhoneOtp(phone);
      if (mounted) {
        final devCode = res['devOtp']?.toString();
        setState(() {
          _isLoading = false;
          _step = 2;
          _devOtp = devCode;
        });

        if (devCode != null && devCode.length == 6) {
          final digits = devCode.split('');
          for (int i = 0; i < 6; i++) {
            _otpControllers[i].text = digits[i];
          }
        }

        _startCountdown();
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

  Future<void> _handleResendOtp() async {
    if (_resendCountdown > 0 || _isResending) return;

    setState(() {
      _isResending = true;
      _errorMessage = null;
    });

    try {
      final res = await AuthService().sendPhoneOtp(_phoneController.text.trim());
      if (mounted) {
        final devCode = res['devOtp']?.toString();
        setState(() {
          _isResending = false;
          _devOtp = devCode;
        });

        if (devCode != null && devCode.length == 6) {
          final digits = devCode.split('');
          for (int i = 0; i < 6; i++) {
            _otpControllers[i].text = digits[i];
          }
        }

        _startCountdown();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('A fresh verification code has been sent!'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isResending = false;
          _errorMessage = e.toString().replaceAll('ApiException: ', '');
        });
      }
    }
  }

  Future<void> _handleResetPassword() async {
    final code = _enteredOtp;
    final newPass = _newPasswordController.text.trim();
    final confirmPass = _confirmPasswordController.text.trim();

    if (code.length < 6) {
      setState(() {
        _errorMessage = 'Please enter the complete 6-digit verification code.';
      });
      return;
    }

    if (newPass.length < 6) {
      setState(() {
        _errorMessage = 'Password must be at least 6 characters.';
      });
      return;
    }

    if (newPass != confirmPass) {
      setState(() {
        _errorMessage = 'New password and confirm password do not match.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final res = await AuthService().resetPasswordWithOtp(
        phoneNumber: _phoneController.text.trim(),
        code: code,
        newPassword: newPass,
      );

      if (mounted) {
        setState(() => _isLoading = false);

        // Show success alert
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Row(
              children: [
                Icon(Icons.check_circle_rounded, color: AppColors.success, size: 28),
                SizedBox(width: 10),
                Text('Password Restored!', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
              ],
            ),
            content: Text(
              res['message']?.toString() ??
                  'Your password has been successfully reset. You can now log in with your new password.',
              style: const TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.4),
            ),
            actions: [
              CustomButton(
                text: 'Log In Now',
                onPressed: () {
                  Navigator.pop(ctx); // Close dialog
                  Navigator.pop(context, _phoneController.text.trim()); // Return to login with phone
                },
              ),
            ],
          ),
        );
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Restore Password',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Icon & Title
              Center(
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.lock_reset_rounded,
                    size: 42,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              Center(
                child: Text(
                  _step == 1 ? 'Forgot Your Password?' : 'Enter OTP & Set New Password',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  _step == 1
                      ? 'Enter your registered rider phone number to receive a 6-digit SMS verification code.'
                      : 'We sent a 6-digit verification code to ${_phoneController.text.trim()}.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.4),
                ),
              ),
              const SizedBox(height: 24),

              // Error Message
              if (_errorMessage != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 18),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.dangerLight,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.danger.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline_rounded, color: AppColors.danger, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(color: AppColors.danger, fontSize: 13, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                ),

              if (_step == 1) ...[
                // Phone Number input
                const Text(
                  'Phone Number',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 6),
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: TextField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                    decoration: const InputDecoration(
                      hintText: 'e.g. +251 911 000 001',
                      hintStyle: TextStyle(color: AppColors.textMuted, fontSize: 14),
                      prefixIcon: Icon(Icons.phone_outlined, color: AppColors.primary, size: 20),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(height: 28),

                CustomButton(
                  text: 'Send Verification Code',
                  isLoading: _isLoading,
                  backgroundColor: AppColors.primary,
                  onPressed: _isLoading ? null : _handleSendOtp,
                ),
              ] else ...[
                // Dev OTP helper banner
                if (_devOtp != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 18),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.info_outline_rounded, color: AppColors.primary, size: 18),
                            const SizedBox(width: 8),
                            Text(
                              'Dev Mode OTP: $_devOtp',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                        InkWell(
                          onTap: () {
                            final digits = _devOtp!.split('');
                            for (int i = 0; i < 6; i++) {
                              _otpControllers[i].text = digits[i];
                            }
                          },
                          child: const Text(
                            'Auto-Fill',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                // OTP digits input
                const Text(
                  'Verification Code (OTP)',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(6, (index) {
                    return SizedBox(
                      width: 46,
                      height: 52,
                      child: TextField(
                        controller: _otpControllers[index],
                        focusNode: _otpFocusNodes[index],
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        maxLength: 1,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                        decoration: InputDecoration(
                          counterText: '',
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          contentPadding: EdgeInsets.zero,
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: AppColors.border),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: AppColors.primary, width: 2),
                          ),
                        ),
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        onChanged: (value) {
                          if (value.isNotEmpty && index < 5) {
                            _otpFocusNodes[index + 1].requestFocus();
                          } else if (value.isEmpty && index > 0) {
                            _otpFocusNodes[index - 1].requestFocus();
                          }
                        },
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 10),

                // Resend OTP row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _step = 1;
                        });
                      },
                      child: const Text('Change Phone Number', style: TextStyle(fontSize: 12)),
                    ),
                    _resendCountdown > 0
                        ? Text(
                            'Resend in ${_resendCountdown}s',
                            style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                          )
                        : TextButton(
                            onPressed: _isResending ? null : _handleResendOtp,
                            child: const Text(
                              'Resend Code',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                  ],
                ),
                const SizedBox(height: 16),

                // New Password Input
                const Text(
                  'New Password',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 6),
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: TextField(
                    controller: _newPasswordController,
                    obscureText: _obscureNewPass,
                    enableSuggestions: false,
                    autocorrect: false,
                    cursorColor: AppColors.primary,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                    decoration: InputDecoration(
                      hintText: 'Enter new password (min. 6 chars)',
                      hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 14),
                      prefixIcon: const Icon(Icons.lock_outline_rounded, color: AppColors.primary, size: 20),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureNewPass ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                          color: AppColors.textSecondary,
                          size: 20,
                        ),
                        onPressed: () => setState(() => _obscureNewPass = !_obscureNewPass),
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // Confirm Password Input
                const Text(
                  'Confirm New Password',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 6),
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: TextField(
                    controller: _confirmPasswordController,
                    obscureText: _obscureConfirmPass,
                    enableSuggestions: false,
                    autocorrect: false,
                    cursorColor: AppColors.primary,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                    decoration: InputDecoration(
                      hintText: 'Re-enter your new password',
                      hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 14),
                      prefixIcon: const Icon(Icons.lock_outline_rounded, color: AppColors.primary, size: 20),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureConfirmPass ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                          color: AppColors.textSecondary,
                          size: 20,
                        ),
                        onPressed: () => setState(() => _obscureConfirmPass = !_obscureConfirmPass),
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(height: 28),

                CustomButton(
                  text: 'Reset Password & Restore Access',
                  isLoading: _isLoading,
                  backgroundColor: AppColors.primary,
                  onPressed: _isLoading ? null : _handleResetPassword,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
