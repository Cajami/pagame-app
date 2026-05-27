import 'package:flutter/material.dart';
import 'package:pagame/theme/app_colors.dart';

class AppBackground extends StatelessWidget {
  const AppBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.surface, AppColors.surfaceHigh],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: const Stack(
          children: [
            Positioned(
              top: -140,
              right: -60,
              child: _BackgroundOrb(color: Color(0x3318C1B5), size: 240),
            ),
            Positioned(
              bottom: -180,
              left: -80,
              child: _BackgroundOrb(color: Color(0x33F2B365), size: 260),
            ),
          ],
        ),
      ),
    );
  }
}

class HeaderBackground extends StatelessWidget {
  const HeaderBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(gradient: AppColors.headerGradient),
        ),
        const Positioned(
          top: -60,
          right: -40,
          child: _BackgroundOrb(color: Color(0x29FFFFFF), size: 160),
        ),
        const Positioned(
          bottom: -80,
          left: -50,
          child: _BackgroundOrb(color: Color(0x1FFFFFFF), size: 200),
        ),
      ],
    );
  }
}

class _BackgroundOrb extends StatelessWidget {
  const _BackgroundOrb({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        boxShadow: [BoxShadow(color: color, blurRadius: 60)],
      ),
    );
  }
}
