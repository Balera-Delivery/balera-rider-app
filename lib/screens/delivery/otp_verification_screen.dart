import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
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
  // 0: Scan QR Code (Primary), 1: Enter OTP Code (Secondary fallback)
  int _selectedMethodIndex = 0;

  // Controllers for 6-digit OTP
  final List<TextEditingController> _otpControllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _otpFocusNodes = List.generate(6, (_) => FocusNode());

  // Controller for manual QR code text entry
  final TextEditingController _manualQrController = TextEditingController();

  // Mobile scanner controller
  MobileScannerController? _scannerController;

  final DeliveryService _deliveryService = DeliveryService();
  bool _isLoading = false;
  bool _isProcessingScan = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _scannerController = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
      facing: CameraFacing.back,
      torchEnabled: false,
    );

    // Default prefill order's OTP digits if available
    final digits = widget.order.otpCode.split('');
    for (int i = 0; i < 6 && i < digits.length; i++) {
      _otpControllers[i].text = digits[i];
    }
  }

  @override
  void dispose() {
    _scannerController?.dispose();
    _manualQrController.dispose();
    for (var c in _otpControllers) {
      c.dispose();
    }
    for (var f in _otpFocusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  String get _enteredOtp => _otpControllers.map((c) => c.text.trim()).join();

  void _onQrDetected(BarcodeCapture capture) {
    if (_isProcessingScan || _isLoading) return;

    for (final barcode in capture.barcodes) {
      final code = barcode.rawValue?.trim();
      if (code != null && code.isNotEmpty) {
        _verifyQrToken(code);
        break;
      }
    }
  }

  void _verifyQrToken(String token) async {
    setState(() {
      _isLoading = true;
      _isProcessingScan = true;
      _errorMessage = null;
    });

    try {
      final success = await _deliveryService.verifyQrCode(widget.order.id, token);
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isProcessingScan = false;
        });

        if (success) {
          _navigateToCompleted();
        } else {
          setState(() {
            _errorMessage = 'Invalid QR code. Please scan the customer’s active delivery QR.';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isProcessingScan = false;
          _errorMessage = e.toString().replaceAll('ApiException: ', '');
        });
      }
    }
  }

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
          _navigateToCompleted();
        } else {
          setState(() {
            _errorMessage = 'Incorrect OTP code. Please ask customer to re-check their app.';
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

  void _navigateToCompleted() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => DeliveryCompletedScreen(order: widget.order),
      ),
    );
  }

  void _showManualQrDialog() {
    _manualQrController.text = '';
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Enter QR Code Token', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'If the camera cannot read the code, type or paste the QR code token displayed on the customer app:',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _manualQrController,
              decoration: InputDecoration(
                hintText: 'e.g. BALERA-DLV-1234',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              final text = _manualQrController.text.trim();
              Navigator.pop(ctx);
              if (text.isNotEmpty) {
                _verifyQrToken(text);
              }
            },
            child: const Text('Verify Token', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
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
              'If the customer cannot present the QR code or OTP, contact the Balera dispatch administrator:',
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

  Widget _buildMethodSelector() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // Option 1: Scan QR Code (Primary)
          Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedMethodIndex = 0;
                  _errorMessage = null;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: _selectedMethodIndex == 0 ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: _selectedMethodIndex == 0
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.06),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.qr_code_scanner_rounded,
                      size: 18,
                      color: _selectedMethodIndex == 0 ? AppColors.primary : AppColors.textSecondary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Scan QR (Primary)',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: _selectedMethodIndex == 0 ? FontWeight.w700 : FontWeight.w500,
                        color: _selectedMethodIndex == 0 ? AppColors.primary : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),

          // Option 2: 6-Digit OTP (Secondary)
          Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedMethodIndex = 1;
                  _errorMessage = null;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: _selectedMethodIndex == 1 ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: _selectedMethodIndex == 1
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.06),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.pin_rounded,
                      size: 18,
                      color: _selectedMethodIndex == 1 ? AppColors.primary : AppColors.textSecondary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Enter OTP (Option 2)',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: _selectedMethodIndex == 1 ? FontWeight.w700 : FontWeight.w500,
                        color: _selectedMethodIndex == 1 ? AppColors.primary : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // View A: Real Camera QR Scanner
  Widget _buildQrScannerView() {
    return Column(
      children: [
        const SizedBox(height: 12),
        const Text(
          'Scan Customer QR Code',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Point camera at the QR code displayed on customer app.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 18),

        // Live Camera Viewfinder
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Container(
            height: 270,
            width: double.infinity,
            color: Colors.black,
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (_scannerController != null)
                  MobileScanner(
                    controller: _scannerController!,
                    onDetect: _onQrDetected,
                    errorBuilder: (context, error, child) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.videocam_off_rounded, color: Colors.white70, size: 40),
                              const SizedBox(height: 10),
                              const Text(
                                'Camera unavailable or permission denied',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.white, fontSize: 13),
                              ),
                              const SizedBox(height: 12),
                              ElevatedButton(
                                onPressed: _showManualQrDialog,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                ),
                                child: const Text('Enter Code Manually', style: TextStyle(color: Colors.white)),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),

                // Viewfinder Target Frame
                Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.primary, width: 3),
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),

                // Scanner Controls (Torch & Camera Switch)
                Positioned(
                  bottom: 12,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        color: Colors.white,
                        icon: const Icon(Icons.flash_on_rounded),
                        onPressed: () => _scannerController?.toggleTorch(),
                      ),
                      const SizedBox(width: 16),
                      IconButton(
                        color: Colors.white,
                        icon: const Icon(Icons.cameraswitch_rounded),
                        onPressed: () => _scannerController?.switchCamera(),
                      ),
                    ],
                  ),
                ),

                if (_isLoading)
                  Container(
                    color: Colors.black.withValues(alpha: 0.6),
                    child: const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    ),
                  ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 14),

        // Manual text entry fallback button
        OutlinedButton.icon(
          onPressed: _showManualQrDialog,
          icon: const Icon(Icons.keyboard_alt_outlined, size: 18),
          label: const Text('Type QR Code Manually'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.textPrimary,
            side: const BorderSide(color: Color(0xFFCBD5E1)),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),

        const SizedBox(height: 8),

        // Switch to OTP link
        TextButton(
          onPressed: () {
            setState(() {
              _selectedMethodIndex = 1;
              _errorMessage = null;
            });
          },
          child: const Text(
            'Customer doesn\'t have QR? Use 6-Digit OTP instead →',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
        ),
      ],
    );
  }

  // View B: 6-Digit OTP Entry
  Widget _buildOtpView() {
    return Column(
      children: [
        const SizedBox(height: 12),

        // Shield Security Graphic
        Container(
          height: 90,
          width: 90,
          decoration: BoxDecoration(
            color: AppColors.primaryLight,
            shape: BoxShape.circle,
          ),
          child: const Center(
            child: Icon(
              Icons.shield_rounded,
              size: 44,
              color: AppColors.primary,
            ),
          ),
        ),
        const SizedBox(height: 16),

        const Text(
          'Enter Delivery OTP',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Ask the customer for their 6-digit delivery OTP code.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 24),

        // 6 PIN Input Boxes
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(6, (index) {
            return SizedBox(
              width: 48,
              height: 54,
              child: TextField(
                controller: _otpControllers[index],
                focusNode: _otpFocusNodes[index],
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                maxLength: 1,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
                decoration: InputDecoration(
                  counterText: '',
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.border, width: 1.5),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.primary, width: 2.0),
                  ),
                ),
                onChanged: (value) {
                  if (value.isNotEmpty && index < 5) {
                    _otpFocusNodes[index + 1].requestFocus();
                  } else if (value.isEmpty && index > 0) {
                    _otpFocusNodes[index - 1].requestFocus();
                  }
                  if (_enteredOtp.length == 6) {
                    _verifyOtp();
                  }
                },
              ),
            );
          }),
        ),
        const SizedBox(height: 24),

        CustomButton(
          text: 'Verify OTP & Complete Delivery',
          backgroundColor: AppColors.primary,
          isLoading: _isLoading,
          onPressed: _verifyOtp,
        ),
      ],
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
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Verify Delivery',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
          child: Column(
            children: [
              // Segment Switcher: QR Scan (Primary) vs OTP (Secondary)
              _buildMethodSelector(),
              const SizedBox(height: 12),

              if (_errorMessage != null)
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.dangerLight,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.danger.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    _errorMessage!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.danger,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),

              if (_selectedMethodIndex == 0)
                _buildQrScannerView()
              else
                _buildOtpView(),

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
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
