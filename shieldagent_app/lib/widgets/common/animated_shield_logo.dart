import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// The shield mark used on splash/welcome. Pulses gently so the
/// splash screen doesn't feel static while the session check runs.
class AnimatedShieldLogo extends StatefulWidget {
  final double size;
  const AnimatedShieldLogo({super.key, this.size = 96});

  @override
  State<AnimatedShieldLogo> createState() => _AnimatedShieldLogoState();
}

class _AnimatedShieldLogoState extends State<AnimatedShieldLogo>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 2),
  )..repeat(reverse: true);

  late final Animation<double> _glow =
      Tween<double>(begin: 0.55, end: 1.0).animate(
    CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _glow,
      builder: (context, child) {
        return Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: AppColors.primaryGradient,
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.35 * _glow.value),
                blurRadius: 40,
                spreadRadius: 6,
              ),
            ],
          ),
          child: Icon(
            Icons.shield_rounded,
            color: Colors.white,
            size: widget.size * 0.52,
          ),
        );
      },
    );
  }
}
