import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/auth_service.dart';
import '../services/delivery_service.dart';
import 'auth/login_screen.dart';
import 'main_shell_screen.dart';

class BadgeItem {
  final IconData icon;
  final Color bgColor;
  final Color iconColor;
  final double? top;
  final double? bottom;
  final double? left;
  final double? right;

  const BadgeItem({
    required this.icon,
    required this.bgColor,
    required this.iconColor,
    this.top,
    this.bottom,
    this.left,
    this.right,
  });
}

class SplashPageItem {
  final String title;
  final String description;
  final String imagePath;
  final bool isLogo;
  final List<BadgeItem> badges;

  const SplashPageItem({
    required this.title,
    required this.description,
    required this.imagePath,
    this.isLogo = false,
    required this.badges,
  });
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _isLoggedIn = false;

  final List<SplashPageItem> _pages = const [
    SplashPageItem(
      title: 'Fast & Smart Delivery',
      description:
          'Send and receive packages anywhere across Bale quickly, reliably, and with complete peace of mind.',
      imagePath: 'assets/logo/balera_logo.png',
      isLogo: true,
      badges: [
        BadgeItem(
          icon: Icons.local_shipping_rounded,
          bgColor: Color(0xFFEFF6FF),
          iconColor: Color(0xFF0047BA),
          top: 14,
          left: 8,
        ),
        BadgeItem(
          icon: Icons.bolt_rounded,
          bgColor: Color(0xFFFEF3C7),
          iconColor: Color(0xFFD97706),
          top: 18,
          right: 10,
        ),
        BadgeItem(
          icon: Icons.location_on_rounded,
          bgColor: Color(0xFFECFDF5),
          iconColor: Color(0xFF059669),
          bottom: 22,
          left: 6,
        ),
        BadgeItem(
          icon: Icons.verified_user_rounded,
          bgColor: Color(0xFFEEF2FF),
          iconColor: Color(0xFF4F46E5),
          bottom: 18,
          right: 12,
        ),
      ],
    ),
    SplashPageItem(
      title: 'Real-Time Tracking',
      description:
          'Track your assigned rider live on the map from pickup to your doorstep with guaranteed prompt arrival.',
      imagePath: 'assets/images/rider_delivery.jpg',
      isLogo: false,
      badges: [
        BadgeItem(
          icon: Icons.two_wheeler_rounded,
          bgColor: Color(0xFFE0F2FE),
          iconColor: Color(0xFF0284C7),
          top: 14,
          left: 8,
        ),
        BadgeItem(
          icon: Icons.timer_rounded,
          bgColor: Color(0xFFFFFBEB),
          iconColor: Color(0xFFB45309),
          top: 18,
          right: 10,
        ),
        BadgeItem(
          icon: Icons.navigation_rounded,
          bgColor: Color(0xFFEFF6FF),
          iconColor: Color(0xFF0047BA),
          bottom: 22,
          left: 6,
        ),
        BadgeItem(
          icon: Icons.electric_bolt_rounded,
          bgColor: Color(0xFFFDF4FF),
          iconColor: Color(0xFF9333EA),
          bottom: 18,
          right: 12,
        ),
      ],
    ),
    SplashPageItem(
      title: 'Secure OTP Handover',
      description:
          'Direct rider communication and instant OTP verification for a 100% safe, verified doorstep delivery.',
      imagePath: 'assets/images/delivery_handover.jpg',
      isLogo: false,
      badges: [
        BadgeItem(
          icon: Icons.phone_android_rounded,
          bgColor: Color(0xFFEFF6FF),
          iconColor: Color(0xFF0047BA),
          top: 14,
          left: 8,
        ),
        BadgeItem(
          icon: Icons.key_rounded,
          bgColor: Color(0xFFECFDF5),
          iconColor: Color(0xFF059669),
          top: 18,
          right: 10,
        ),
        BadgeItem(
          icon: Icons.inventory_2_rounded,
          bgColor: Color(0xFFFFF1F2),
          iconColor: Color(0xFFE11D48),
          bottom: 22,
          left: 6,
        ),
        BadgeItem(
          icon: Icons.star_rounded,
          bgColor: Color(0xFFFEF9C3),
          iconColor: Color(0xFFCA8A04),
          bottom: 18,
          right: 12,
        ),
      ],
    ),
  ];

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
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _finishSplash() {
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            _isLoggedIn ? const MainShellScreen() : const LoginScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 350),
      ),
    );
  }

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 380),
        curve: Curves.easeInOutCubic,
      );
    } else {
      _finishSplash();
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isShortScreen = size.height < 700;

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
              Color(0xFFFAFCFF),
              Color(0xFFF1F6FD),
              Color(0xFFE8F1FC),
            ],
            stops: [0.0, 0.35, 0.70, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Top Brand Header & Slogan Section (Centered cleanly)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // App Title with Clean, Simple Typography
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 7,
                          height: 7,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(0xFF0052CC),
                          ),
                        ),
                        const SizedBox(width: 8),
                        RichText(
                          textAlign: TextAlign.center,
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: 'BALERA ',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 19,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.5,
                                  color: const Color(0xFF003893),
                                ),
                              ),
                              TextSpan(
                                text: 'DELIVERY',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 19,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.5,
                                  color: const Color(0xFF0052CC),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          width: 7,
                          height: 7,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(0xFF0052CC),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 6),

                    // Slogan Badge Pill
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 3.5),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0047BA).withValues(alpha: 0.07),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: const Color(0xFF0047BA).withValues(alpha: 0.12),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        'From Bale, Delivered Smart.',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF0047BA),
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),

                    const SizedBox(height: 4),

                    // Afaan Oromoo Subtitle Slogan
                    Text(
                      'Baale Irraa, Sirnaan Geessina.',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF64748B),
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
              ),

              // PageView Carousel (Hero Circle + Texts)
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: _pages.length,
                  onPageChanged: (index) {
                    setState(() {
                      _currentPage = index;
                    });
                  },
                  itemBuilder: (context, index) {
                    final item = _pages[index];
                    final heroDiameter = isShortScreen ? 190.0 : 224.0;

                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Center Hero Circle with Orbiting Badges
                          SizedBox(
                            width: heroDiameter + 50,
                            height: heroDiameter + 50,
                            child: Stack(
                              alignment: Alignment.center,
                              clipBehavior: Clip.none,
                              children: [
                                // Outer Ambient Ring
                                Container(
                                  width: heroDiameter + 16,
                                  height: heroDiameter + 16,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: const Color(0xFF0047BA)
                                          .withValues(alpha: 0.12),
                                      width: 1.5,
                                    ),
                                  ),
                                ),

                                // Main Hero Circle Container
                                Container(
                                  width: heroDiameter,
                                  height: heroDiameter,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.white,
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 4.5,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFF0047BA)
                                            .withValues(alpha: 0.16),
                                        blurRadius: 28,
                                        spreadRadius: 2,
                                        offset: const Offset(0, 10),
                                      ),
                                      BoxShadow(
                                        color: Colors.black
                                            .withValues(alpha: 0.05),
                                        blurRadius: 8,
                                        offset: const Offset(0, 3),
                                      ),
                                    ],
                                  ),
                                  child: ClipOval(
                                    child: item.isLogo
                                        ? Container(
                                            color: Colors.white,
                                            padding: const EdgeInsets.all(22.0),
                                            child: Image.asset(
                                              item.imagePath,
                                              fit: BoxFit.contain,
                                              filterQuality: FilterQuality.high,
                                            ),
                                          )
                                        : Image.asset(
                                            item.imagePath,
                                            fit: BoxFit.cover,
                                            filterQuality: FilterQuality.high,
                                          ),
                                  ),
                                )
                                    .animate(key: ValueKey('hero_$index'))
                                    .fadeIn(duration: 400.ms)
                                    .scale(
                                      begin: const Offset(0.92, 0.92),
                                      end: const Offset(1, 1),
                                      curve: Curves.easeOutBack,
                                      duration: 450.ms,
                                    ),

                                // Orbiting Badges Around Hero Circle
                                ...item.badges.asMap().entries.map((entry) {
                                  final bIndex = entry.key;
                                  final badge = entry.value;

                                  return Positioned(
                                    top: badge.top,
                                    bottom: badge.bottom,
                                    left: badge.left,
                                    right: badge.right,
                                    child: Container(
                                      width: 42,
                                      height: 42,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Colors.white,
                                        border: Border.all(
                                          color: Colors.white,
                                          width: 2.5,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black
                                                .withValues(alpha: 0.10),
                                            blurRadius: 10,
                                            spreadRadius: 0,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: Container(
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: badge.bgColor,
                                        ),
                                        child: Icon(
                                          badge.icon,
                                          size: 20,
                                          color: badge.iconColor,
                                        ),
                                      ),
                                    )
                                        .animate(
                                            key: ValueKey(
                                                'badge_${index}_$bIndex'))
                                        .fadeIn(
                                            duration: 350.ms,
                                            delay: Duration(
                                                milliseconds: 150 + bIndex * 60))
                                        .scale(
                                          begin: const Offset(0.6, 0.6),
                                          end: const Offset(1, 1),
                                          curve: Curves.easeOutBack,
                                        ),
                                  );
                                }),
                              ],
                            ),
                          ),

                          SizedBox(height: isShortScreen ? 22 : 32),

                          // Text Content: Title (Clean, Simple, Professional Style)
                          Text(
                            item.title,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: isShortScreen ? 21 : 23,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF0F172A),
                              letterSpacing: -0.3,
                            ),
                            textAlign: TextAlign.center,
                          )
                              .animate(key: ValueKey('title_$index'))
                              .fadeIn(duration: 350.ms, delay: 100.ms)
                              .slideY(begin: 0.15, end: 0),

                          const SizedBox(height: 10),

                          // Text Content: Description (Simple, Normal, High Readability)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10.0),
                            child: Text(
                              item.description,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: isShortScreen ? 13.5 : 14.5,
                                fontWeight: FontWeight.w400,
                                color: const Color(0xFF64748B),
                                height: 1.5,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          )
                              .animate(key: ValueKey('desc_$index'))
                              .fadeIn(duration: 350.ms, delay: 150.ms)
                              .slideY(begin: 0.15, end: 0),
                        ],
                      ),
                    );
                  },
                ),
              ),

              // Bottom Section: Indicators & Action Buttons
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 28),
                child: AnimatedCrossFade(
                  duration: const Duration(milliseconds: 280),
                  crossFadeState: _currentPage == _pages.length - 1
                      ? CrossFadeState.showSecond
                      : CrossFadeState.showFirst,
                  firstChild: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Bottom-Left: Skip Button
                      SizedBox(
                        width: 70,
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton(
                            onPressed: _finishSplash,
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: Text(
                              'Skip',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF64748B),
                              ),
                            ),
                          ),
                        ),
                      ),

                      // Center: Smooth Animated Indicator Dots
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: List.generate(
                          _pages.length,
                          (index) => AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                            margin: const EdgeInsets.symmetric(horizontal: 3.5),
                            width: _currentPage == index ? 24 : 7,
                            height: 7,
                            decoration: BoxDecoration(
                              color: _currentPage == index
                                  ? const Color(0xFF0047BA)
                                  : const Color(0xFFCBD5E1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      ),

                      // Bottom-Right: Arrow Button
                      SizedBox(
                        width: 70,
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Color(0xFF0052CC),
                                  Color(0xFF003893),
                                ],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF0047BA)
                                      .withValues(alpha: 0.35),
                                  blurRadius: 14,
                                  spreadRadius: 1,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: _nextPage,
                                borderRadius: BorderRadius.circular(25),
                                child: const Center(
                                  child: Icon(
                                    Icons.arrow_forward_rounded,
                                    color: Colors.white,
                                    size: 22,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  secondChild: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Centered Indicator Dots for final slide
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          _pages.length,
                          (index) => AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                            margin: const EdgeInsets.symmetric(horizontal: 3.5),
                            width: _currentPage == index ? 24 : 7,
                            height: 7,
                            decoration: BoxDecoration(
                              color: _currentPage == index
                                  ? const Color(0xFF0047BA)
                                  : const Color(0xFFCBD5E1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 18),

                      // Final Slide Action: "Get Started" Full-Width Button
                      Container(
                        width: double.infinity,
                        height: 52,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(26),
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Color(0xFF0052CC),
                              Color(0xFF003893),
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF0047BA)
                                  .withValues(alpha: 0.38),
                              blurRadius: 18,
                              spreadRadius: 1,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: _finishSplash,
                            borderRadius: BorderRadius.circular(26),
                            child: Center(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'Get Started',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Icon(
                                    Icons.arrow_forward_rounded,
                                    color: Colors.white,
                                    size: 19,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
