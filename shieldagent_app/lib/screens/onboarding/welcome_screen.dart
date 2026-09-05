import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../widgets/common/primary_button.dart';
import '../../widgets/common/animated_shield_logo.dart';
import '../auth/role_select_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            children: [
              const Spacer(flex: 2),
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: const Duration(milliseconds: 600),
                curve: Curves.easeOutBack,
                builder: (context, value, child) => Transform.scale(
                  scale: value,
                  child: child,
                ),
                child: const AnimatedShieldLogo(size: 88),
              ),
              const SizedBox(height: 36),
              _FadeSlideIn(
                delay: 150,
                child: const Text(
                  "Trust, structured.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 30,
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              _FadeSlideIn(
                delay: 300,
                child: const Text(
                  "ShieldAgent sits between your buyer agents and vendors — "
                  "scoring risk, gating spend, and structuring escrow before "
                  "a single rupee moves.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14.5,
                    height: 1.5,
                  ),
                ),
              ),
              const Spacer(flex: 3),
              _FadeSlideIn(
                delay: 450,
                child: PrimaryButton(
                  label: "Get Started",
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const RoleSelectScreen(),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}

/// Small helper for staggered fade+slide-up entrance animations.
class _FadeSlideIn extends StatelessWidget {
  final Widget child;
  final int delay;
  const _FadeSlideIn({required this.child, this.delay = 0});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 500 + delay),
      curve: Curves.easeOut,
      builder: (context, value, _) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, (1 - value) * 16),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}
