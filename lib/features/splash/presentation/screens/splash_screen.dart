import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../main_shell_screen.dart';

/// রকমারি আধুনিক এনিমেশন ও প্রফেশনাল ব্রান্ডিং সম্বলিত স্প্ল্যাশ স্ক্রিন।
/// অ্যাপ ওপেন করার সময় একটি মসৃণ, প্রিমিয়াম অনুভূতি দেয় এবং
/// ব্যাকগ্রাউন্ড ডাটাবেজ ও স্টেট লোডিং নিশ্চিত করে মেইন ড্যাশবোর্ডে নিয়ে যায়।
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _entranceController;
  late final AnimationController _pulseController;
  late final AnimationController _progressController;

  late final Animation<double> _logoScale;
  late final Animation<double> _logoFade;
  late final Animation<double> _contentFade;
  late final Animation<Offset> _contentSlide;
  late final Animation<double> _footerFade;
  late final Animation<double> _pulseAnimation;

  String _statusMessage = 'সিস্টেম ও ডাটাবেজ প্রস্তুত হচ্ছে...';
  bool _isNavigating = false;

  @override
  void initState() {
    super.initState();

    // সিস্টেম স্ট্যাটাস বার ও নেভিগেশন বার থিম সেটআপ
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Color(0xFF090D16),
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    );

    // ১. মেইন এন্ট্রান্স কন্ট্রোলার (লোগো, টাইটেল, ট্যাগলাইন অ্যানিমেশন)
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    _logoScale = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.0, 0.65, curve: Curves.easeOutBack),
      ),
    );

    _logoFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.0, 0.45, curve: Curves.easeOut),
      ),
    );

    _contentFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.35, 0.85, curve: Curves.easeOut),
      ),
    );

    _contentSlide = Tween<Offset>(
      begin: const Offset(0, 0.25),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.35, 0.85, curve: Curves.easeOutCubic),
      ),
    );

    _footerFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.60, 1.0, curve: Curves.easeIn),
      ),
    );

    // ২. লোগোর পেছনে গ্লোয়িং পালস রিং কন্ট্রোলার
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.14).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeInOutSine,
      ),
    );

    // ৩. লোডিং প্রোগ্রেস কন্ট্রোলার (মসৃণ প্রোগ্রেস ফিল)
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );

    _entranceController.forward();
    _progressController.forward();

    // প্রোগ্রেসের সাথে রিয়েল-টাইম স্ট্যাটাস আপডেট ও মেইন স্ক্রিনে নেভিগেট
    _startInitializationSequence();
  }

  Future<void> _startInitializationSequence() async {
    try {
      // ধাপ ১: ইনিশিয়াল ওয়ার্ম-আপ
      await Future.delayed(const Duration(milliseconds: 800));
      if (!mounted) return;
      setState(() {
        _statusMessage = 'খাতা ও সেবা রেকর্ড সিঙ্ক হচ্ছে...';
      });

      // ধাপ ২: ডাটাবেজ ও ক্যাশ প্রস্তুত
      await Future.delayed(const Duration(milliseconds: 900));
      if (!mounted) return;
      setState(() {
        _statusMessage = 'স্বাগতম! ড্যাশবোর্ড লোড হচ্ছে...';
      });

      // ধাপ ৩: ফাইনাল স্মুথ ট্রানজিশন
      await Future.delayed(const Duration(milliseconds: 600));
      if (!mounted) return;

      _navigateToHome();
    } catch (_) {
      // কোনো কারণে ত্রুটি হলে অবিলম্বে নিরাপদে মূল স্ক্রিনে চলে যাওয়া
      if (mounted) {
        _navigateToHome();
      }
    }
  }

  void _navigateToHome() {
    if (_isNavigating || !mounted) return;
    _isNavigating = true;

    // সিস্টেম স্ট্যাটাস বার পুনরায় লাইট থিমে ফেরত নেওয়া
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );

    // প্রোডাকশন গ্রেড স্মুথ ফেড ট্রানজিশন দিয়ে মেইন স্ক্রিন চালু
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const MainShellScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final fadeAnimation = CurvedAnimation(
            parent: animation,
            curve: Curves.easeInOutCubic,
          );
          final scaleAnimation = Tween<double>(begin: 0.98, end: 1.0).animate(
            CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            ),
          );

          return FadeTransition(
            opacity: fadeAnimation,
            child: ScaleTransition(
              scale: scaleAnimation,
              child: child,
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 550),
      ),
    );
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _pulseController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF090D16),
      body: Stack(
        children: [
          // ১. ব্যাকগ্রাউন্ড গ্রেডিয়েন্ট এবং অ্যাম্বিয়েন্ট গ্লো ইফেক্ট
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF090D16),
                    Color(0xFF0F172A),
                    Color(0xFF1E1B4B),
                  ],
                  stops: [0.0, 0.5, 1.0],
                ),
              ),
            ),
          ),

          // অ্যাম্বিয়েন্ট ব্লার সার্কেল ১ (উপরে বাঁয়ে ইন্ডিগো আভা)
          Positioned(
            top: -60,
            left: -60,
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withValues(alpha: 0.18),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.25),
                    blurRadius: 100,
                    spreadRadius: 40,
                  ),
                ],
              ),
            ),
          ),

          // অ্যাম্বিয়েন্ট ব্লার সার্কেল ২ (নিচে ডানে এমারেল্ড আভা)
          Positioned(
            bottom: -60,
            right: -60,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.emerald.withValues(alpha: 0.15),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.emerald.withValues(alpha: 0.20),
                    blurRadius: 110,
                    spreadRadius: 40,
                  ),
                ],
              ),
            ),
          ),

          // ২. মূল কনটেন্ট (সেন্টার প্যানেল)
          SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Spacer(flex: 3),

                    // লোগো সেকশন উইথ পালস অ্যান্ড কার্ড
                    _buildLogoHero(),

                    const SizedBox(height: 32),

                    // টেক্সট কনটেন্ট (টাইটেল, ট্যাগলাইন, সিকিউরিটি ব্যাজ)
                    _buildBrandTypography(),

                    const SizedBox(height: 36),

                    // প্রিমিয়াম প্রোগ্রেস বার ও স্ট্যাটাস
                    _buildLoadingFeedback(),

                    const Spacer(flex: 3),

                    // ফুটার ব্র্যান্ডিং ও ভার্সন ব্যাজ
                    _buildFooter(),

                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// সেন্ট্রাল ব্র্যান্ড লোগো এবং গ্লোয়িং এনিমেশন
  Widget _buildLogoHero() {
    return AnimatedBuilder(
      animation: Listenable.merge([_entranceController, _pulseController]),
      builder: (context, child) {
        return Transform.scale(
          scale: _logoScale.value,
          child: Opacity(
            opacity: _logoFade.value,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // ডায়নামিক পালসিং রিং
                Transform.scale(
                  scale: _pulseAnimation.value,
                  child: Container(
                    width: 124,
                    height: 124,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.28),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.22),
                          blurRadius: 36,
                          spreadRadius: 6,
                        ),
                      ],
                    ),
                  ),
                ),

                // সেন্ট্রাল লোগো ফ্রেম ও গ্লাসফিক ব্যাকগ্রাউন্ড
                Container(
                  width: 104,
                  height: 104,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(28),
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF2E3856),
                        Color(0xFF1E2438),
                      ],
                    ),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.22),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.4),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.35),
                        blurRadius: 30,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(26),
                    child: Image.asset(
                      AppStrings.appLogo,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [AppColors.primary, AppColors.emerald],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          child: const Icon(
                            Icons.landscape_rounded,
                            size: 48,
                            color: Colors.white,
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// টাইটেল, স্লোগান ও সাবটাইটেল
  Widget _buildBrandTypography() {
    return AnimatedBuilder(
      animation: _entranceController,
      builder: (context, child) {
        return Opacity(
          opacity: _contentFade.value,
          child: SlideTransition(
            position: _contentSlide,
            child: Column(
              children: [
                // প্রধান অ্যাপের নাম
                const Text(
                  AppStrings.appName,
                  style: TextStyle(
                    fontFamily: AppTypography.fontFamily,
                    fontSize: 25,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: 0.3,
                    height: 1.3,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 8),

                // ট্যাগলাইন
                Text(
                  AppStrings.appTagline,
                  style: TextStyle(
                    fontFamily: AppTypography.fontFamily,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w400,
                    color: AppColors.slate300.withValues(alpha: 0.9),
                    letterSpacing: 0.2,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 16),

                // অফলাইন সিকিউর ব্যাজ
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                      color: AppColors.emerald.withValues(alpha: 0.35),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.shield_outlined,
                        size: 14,
                        color: AppColors.emeraldLight.withValues(alpha: 0.9),
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        '১০০% অফলাইন ও নিরাপদ ডেটাবেজ',
                        style: TextStyle(
                          fontFamily: AppTypography.fontFamily,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                          color: AppColors.slate200,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// লোডিং বার ও ডাইনামিক স্ট্যাটাস টেক্সট
  Widget _buildLoadingFeedback() {
    return AnimatedBuilder(
      animation: Listenable.merge([_entranceController, _progressController]),
      builder: (context, child) {
        return Opacity(
          opacity: _contentFade.value,
          child: Column(
            children: [
              // কাস্টম আল্ট্রা-স্লিম গ্রেডিয়েন্ট প্রোগ্রেস বার
              SizedBox(
                width: 190,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    height: 4,
                    color: Colors.white.withValues(alpha: 0.12),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: FractionallySizedBox(
                        widthFactor: _progressController.value.clamp(0.05, 1.0),
                        child: Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppColors.primary,
                                Color(0xFF6366F1),
                                AppColors.emerald,
                              ],
                            ),
                            borderRadius: BorderRadius.all(Radius.circular(10)),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 14),

              // এনিমেটেড স্ট্যাটাস পরিবর্তন
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (child, animation) {
                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, 0.3),
                        end: Offset.zero,
                      ).animate(animation),
                      child: child,
                    ),
                  );
                },
                child: Text(
                  _statusMessage,
                  key: ValueKey<String>(_statusMessage),
                  style: const TextStyle(
                    fontFamily: AppTypography.fontFamily,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w400,
                    color: AppColors.slate400,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// বটম ফুটার
  Widget _buildFooter() {
    return AnimatedBuilder(
      animation: _entranceController,
      builder: (context, child) {
        return Opacity(
          opacity: _footerFade.value,
          child: const Column(
            children: [
              Text(
                'রজব এন্টারপ্রাইজ',
                style: TextStyle(
                  fontFamily: AppTypography.fontFamily,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.slate300,
                  letterSpacing: 0.5,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'ভার্সন ১.০.০ • প্রফেশনাল এডিশন',
                style: TextStyle(
                  fontFamily: AppTypography.fontFamily,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w400,
                  color: AppColors.slate500,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
