import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../services/auth_service.dart';
import '../services/delivery_service.dart';
import '../widgets/custom_button.dart';
import 'auth/login_screen.dart';
import 'main_shell_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _isCheckingAuth = true;
  bool _isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    _checkInitialAuth();
  }

  Future<void> _checkInitialAuth() async {
    try {
      await AuthService().init();
      _isLoggedIn = AuthService().isLoggedIn;
      if (_isLoggedIn) {
        DeliveryService().refreshAll().catchError((_) {});
      }
    } catch (_) {
      _isLoggedIn = false;
    } finally {
      if (mounted) {
        setState(() => _isCheckingAuth = false);
      }
    }
  }

  void _onGetStarted() {
    if (_isLoggedIn) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MainShellScreen()),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          color: Colors.white,
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.white,
              Colors.white,
              Color(0xFFF4F8FD),
              Color(0xFFEAF2FA),
              Color(0xFFEFF5FB),
            ],
            stops: [0.0, 0.30, 0.55, 0.80, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 16),

              // Top Section: Balera Logo & Bold Stylish Slogans
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  children: [
                    Image.asset(
                      'assets/logo/balera_logo.png',
                      height: 104,
                      fit: BoxFit.contain,
                      filterQuality: FilterQuality.high,
                      isAntiAlias: true,
                      errorBuilder: (context, error, stackTrace) => Image.asset(
                        'assets/images/logo.png',
                        height: 104,
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // English Slogan
                    const Text(
                      'From Bale, Delivered Smart.',
                      style: TextStyle(
                        fontSize: 16.5,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF003893),
                        letterSpacing: 0.3,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 5),

                    // Afaan Oromoo Slogan
                    const Text(
                      'Balee Iraaa. Sirnaan Geessiine.',
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0047BA),
                        letterSpacing: 0.3,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              // Center Illustration: Full-width Edge-to-Edge Background
              Expanded(
                child: Container(
                  width: double.infinity,
                  alignment: Alignment.center,
                  child: Image.asset(
                    'assets/images/rider_illustration.png',
                    width: double.infinity,
                    fit: BoxFit.fitWidth,
                    alignment: Alignment.center,
                    filterQuality: FilterQuality.high,
                    isAntiAlias: true,
                  ),
                ),
              ),

              // Bottom Section: Get Started Button
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                child: CustomButton(
                  text: _isLoggedIn ? 'Continue to Dashboard' : 'Get Started',
                  height: 52,
                  isLoading: _isCheckingAuth,
                  backgroundColor: AppColors.primary,
                  onPressed: _isCheckingAuth ? null : _onGetStarted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
