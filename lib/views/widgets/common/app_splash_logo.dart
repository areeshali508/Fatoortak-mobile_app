import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';

class AppSplashLogo extends StatelessWidget {
  final double size;
  final Color accent;

  const AppSplashLogo({super.key, required this.size, required this.accent});

  @override
  Widget build(BuildContext context) {
    final double phoneW = size * 0.72;
    final double phoneH = size;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          Positioned(
            top: size * 0.10,
            child: _PhoneIllustration(
              width: phoneW,
              height: phoneH,
              accent: accent,
            ),
          ),
          Positioned(
            top: size * 0.10 + phoneH * 0.08,
            right: size * 0.14,
            child: _MiniSquares(accent: accent),
          ),
        ],
      ),
    );
  }
}

class _MiniSquares extends StatelessWidget {
  final Color accent;

  const _MiniSquares({required this.accent});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 36,
      height: 30,
      child: Stack(
        children: <Widget>[
          Positioned(
            left: 0,
            top: 12,
            child: _Square(size: 10, color: accent.withValues(alpha: 0.85)),
          ),
          Positioned(
            left: 12,
            top: 4,
            child: _Square(size: 10, color: accent.withValues(alpha: 0.85)),
          ),
          Positioned(
            left: 22,
            top: 12,
            child: _Square(size: 14, color: accent.withValues(alpha: 0.95)),
          ),
        ],
      ),
    );
  }
}

class _Square extends StatelessWidget {
  final double size;
  final Color color;

  const _Square({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(2.5),
      ),
    );
  }
}

class _PhoneIllustration extends StatelessWidget {
  final double width;
  final double height;
  final Color accent;

  const _PhoneIllustration({
    required this.width,
    required this.height,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(width * 0.25),
      ),
      child: Stack(
        children: <Widget>[
          Align(
            alignment: Alignment.topCenter,
            child: Container(
              margin: EdgeInsets.only(top: height * 0.06),
              width: width * 0.28,
              height: height * 0.09,
              decoration: BoxDecoration(
                color: const Color(0xFFE9EEF9),
                borderRadius: BorderRadius.circular(height * 0.05),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: width * 0.16,
              vertical: height * 0.18,
            ),
            child: Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: SizedBox(
                  width: width * 0.68,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      _QrPlaceholder(accent: AppColors.splashTop),
                      SizedBox(height: height * 0.08),
                      _Line(width: width * 0.55, alpha: 0.80),
                      SizedBox(height: height * 0.035),
                      _Line(width: width * 0.48, alpha: 0.55),
                      SizedBox(height: height * 0.035),
                      _Line(width: width * 0.38, alpha: 0.40),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              margin: EdgeInsets.only(bottom: height * 0.08),
              width: width * 0.14,
              height: width * 0.14,
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFD8DFF1), width: 2),
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Line extends StatelessWidget {
  final double width;
  final double alpha;

  const _Line({required this.width, required this.alpha});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: 5,
      decoration: BoxDecoration(
        color: AppColors.splashAccent.withValues(alpha: alpha),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}

class _QrPlaceholder extends StatelessWidget {
  final Color accent;

  const _QrPlaceholder({required this.accent});

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: accent, width: 2),
        ),
        padding: const EdgeInsets.all(6),
        child: Column(
          children: <Widget>[
            Expanded(
              child: Row(
                children: <Widget>[
                  Expanded(child: _QrCorner(color: accent)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: _QrDots(color: accent.withValues(alpha: 0.85)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            Expanded(
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: _QrDots(color: accent.withValues(alpha: 0.85)),
                  ),
                  const SizedBox(width: 6),
                  Expanded(child: _QrCorner(color: accent)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QrCorner extends StatelessWidget {
  final Color color;

  const _QrCorner({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: color, width: 2.5),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Center(
        child: Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
    );
  }
}

class _QrDots extends StatelessWidget {
  final Color color;

  const _QrDots({required this.color});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 4,
      mainAxisSpacing: 3,
      crossAxisSpacing: 3,
      children: List<Widget>.generate(16, (int i) {
        final bool filled = <int>{0, 3, 5, 6, 9, 10, 12, 15}.contains(i);
        return Container(
          decoration: BoxDecoration(
            color: filled ? color : Colors.transparent,
            borderRadius: BorderRadius.circular(1.8),
          ),
        );
      }),
    );
  }
}
