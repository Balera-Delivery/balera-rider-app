import 'package:flutter/material.dart';
import '../../constants/api_constants.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_styles.dart';
import '../../services/api_client.dart';
import '../../services/auth_service.dart';
import '../../services/delivery_service.dart';
import '../../widgets/custom_button.dart';
import '../main_shell_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController =
      TextEditingController(text: 'kebede@rider.com');
  final TextEditingController _passwordController =
      TextEditingController(text: 'RiderPass@123');

  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter your email and password';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final success = await AuthService().login(email, password);
      if (success && mounted) {
        // Refresh deliveries and profile with live data
        DeliveryService().refreshAll().catchError((_) {});

        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const MainShellScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll('ApiException: ', '');
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showRegisterModal() {
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final phoneCtrl = TextEditingController(text: '+251');
    final vehicleCtrl = TextEditingController(text: 'TVS Motorcycle Plate AA-');
    final passCtrl = TextEditingController();
    bool isRegistering = false;
    String? modalError;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Rider Registration',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const Text(
                  'Register as a new Balerra delivery rider. Your application will start with PENDING_APPROVAL status.',
                  style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 16),
                if (modalError != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.dangerLight,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.danger.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      modalError!,
                      style: const TextStyle(color: AppColors.danger, fontSize: 13),
                    ),
                  ),
                TextField(
                  controller: nameCtrl,
                  decoration: InputDecoration(
                    labelText: 'Full Name',
                    prefixIcon: const Icon(Icons.person_outline_rounded),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: 'Email Address',
                    prefixIcon: const Icon(Icons.email_outlined),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: phoneCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: 'Phone Number',
                    prefixIcon: const Icon(Icons.phone_outlined),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: vehicleCtrl,
                  decoration: InputDecoration(
                    labelText: 'Vehicle Info (Model & Plate)',
                    prefixIcon: const Icon(Icons.two_wheeler_rounded),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: passCtrl,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: const Icon(Icons.lock_outline_rounded),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 20),
                CustomButton(
                  text: 'Submit Application',
                  isLoading: isRegistering,
                  onPressed: isRegistering
                      ? null
                      : () async {
                          if (nameCtrl.text.trim().isEmpty ||
                              emailCtrl.text.trim().isEmpty ||
                              phoneCtrl.text.trim().isEmpty ||
                              passCtrl.text.trim().isEmpty) {
                            setModalState(() {
                              modalError = 'Please fill in all required fields.';
                            });
                            return;
                          }

                          setModalState(() {
                            isRegistering = true;
                            modalError = null;
                          });

                          try {
                            final res = await AuthService().registerRider(
                              fullName: nameCtrl.text.trim(),
                              email: emailCtrl.text.trim(),
                              phoneNumber: phoneCtrl.text.trim(),
                              password: passCtrl.text.trim(),
                              vehicleInfo: vehicleCtrl.text.trim(),
                            );
                            if (context.mounted) {
                              Navigator.pop(ctx);
                              _showRegistrationSuccessDialog(
                                res['message']?.toString() ??
                                    'Registration submitted! Please wait for admin approval before logging in.',
                              );
                            }
                          } catch (err) {
                            setModalState(() {
                              modalError = err.toString().replaceAll('ApiException: ', '');
                              isRegistering = false;
                            });
                          }
                        },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showRegistrationSuccessDialog(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: const [
            Icon(Icons.check_circle_outline_rounded, color: AppColors.success, size: 28),
            SizedBox(width: 8),
            Text('Application Received', style: AppStyles.headingMedium),
          ],
        ),
        content: Text(message, style: AppStyles.bodyMedium),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showServerConfigDialog() {
    final customUrlController =
        TextEditingController(text: ApiConstants.activeBaseUrl);

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: const [
              Icon(Icons.dns_rounded, color: AppColors.primary),
              SizedBox(width: 8),
              Text('Server Connection', style: AppStyles.headingMedium),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Choose where your Balerra backend server is running:',
                  style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 16),
                _buildServerOption(
                  title: 'USB Cable (Fastest)',
                  subtitle:
                      'http://127.0.0.1:5000\n(Requires: adb reverse tcp:5000 tcp:5000)',
                  url: 'http://127.0.0.1:5000',
                  isSelected:
                      customUrlController.text == 'http://127.0.0.1:5000',
                  onSelect: () => setDialogState(
                      () => customUrlController.text = 'http://127.0.0.1:5000'),
                ),
                const SizedBox(height: 10),
                _buildServerOption(
                  title: 'Local Wi-Fi Network',
                  subtitle:
                      'http://192.168.0.135:5000\n(No USB needed if PC & phone share Wi-Fi)',
                  url: 'http://192.168.0.135:5000',
                  isSelected:
                      customUrlController.text == 'http://192.168.0.135:5000',
                  onSelect: () => setDialogState(() =>
                      customUrlController.text = 'http://192.168.0.135:5000'),
                ),
                const SizedBox(height: 14),
                const Text('Or Custom URL:',
                    style:
                        TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                TextField(
                  controller: customUrlController,
                  decoration: InputDecoration(
                    hintText: 'http://192.168.x.x:5000',
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final messenger = ScaffoldMessenger.of(context);
                final newUrl = customUrlController.text.trim();
                if (newUrl.isNotEmpty) {
                  await ApiClient().updateBaseUrl(newUrl);
                  if (mounted) setState(() {});
                }
                if (ctx.mounted) Navigator.pop(ctx);
                messenger.showSnackBar(
                  SnackBar(
                    content:
                        Text('Server set to ${ApiConstants.activeBaseUrl}'),
                    backgroundColor: AppColors.success,
                  ),
                );
              },
              style:
                  ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              child: const Text('Save & Apply',
                  style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServerOption({
    required String title,
    required String subtitle,
    required String url,
    required bool isSelected,
    required VoidCallback onSelect,
  }) {
    return InkWell(
      onTap: onSelect,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryLight : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: isSelected ? AppColors.primary : AppColors.textMuted,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.textSecondary)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Top Bar: Server Config Badge
              Align(
                alignment: Alignment.topRight,
                child: TextButton.icon(
                  onPressed: _showServerConfigDialog,
                  icon: const Icon(Icons.dns_outlined,
                      size: 15, color: AppColors.primary),
                  label: Text(
                    ApiConstants.activeBaseUrl.replaceAll('http://', ''),
                    style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600),
                  ),
                  style: TextButton.styleFrom(
                    backgroundColor: AppColors.primaryLight,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // Balera Logo
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipOval(
                  child: Image.asset(
                    'assets/images/logo.png',
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: AppColors.primaryLight,
                      child: const Icon(
                        Icons.delivery_dining_rounded,
                        size: 50,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Headings
              const Text(
                'Welcome Back',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Rider Login',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 24),

              // Error Message Banner
              if (_errorMessage != null)
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 20),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.dangerLight,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.danger.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.error_outline_rounded, color: AppColors.danger, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(
                            color: AppColors.danger,
                            fontSize: 13.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              // Email Input
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Rider Email',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary.withValues(alpha: 0.8),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                  decoration: const InputDecoration(
                    hintText: 'e.g. kebede@rider.com',
                    hintStyle: TextStyle(color: AppColors.textMuted, fontSize: 14),
                    prefixIcon: Icon(Icons.email_outlined, color: AppColors.primary, size: 20),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                ),
              ),
              const SizedBox(height: 18),

              // Password Input
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Password',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary.withValues(alpha: 0.8),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: TextField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Enter your password',
                    hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 14),
                    prefixIcon: const Icon(Icons.lock_outline_rounded, color: AppColors.primary, size: 20),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                        color: AppColors.textSecondary,
                        size: 20,
                      ),
                      onPressed: () {
                        setState(() => _obscurePassword = !_obscurePassword);
                      },
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                ),
              ),
              const SizedBox(height: 28),

              // Login Button
              CustomButton(
                text: 'Log In',
                isLoading: _isLoading,
                backgroundColor: AppColors.primary,
                onPressed: _isLoading ? null : _handleLogin,
              ),
              const SizedBox(height: 20),

              // Register Link
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'New Rider? ',
                    style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
                  ),
                  GestureDetector(
                    onTap: _showRegisterModal,
                    child: const Text(
                      'Apply for Account',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
