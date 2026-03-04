import 'dart:async';

import 'package:flutter/material.dart';

import '../../../app/app_routes.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_durations.dart';
import '../../widgets/common/app_splash_logo.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  Timer? _navTimer;
  static const AssetImage _bg = AssetImage('assets/images/logo_fb.png');
  bool _bgReady = false;

  @override
  void initState() {
    super.initState();
    _navTimer?.cancel();
    _navTimer = Timer(Duration(milliseconds: AppDurations.splashDelayMs), () {
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed(AppRoutes.onboarding);
    });

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      try {
        await precacheImage(_bg, context);
        if (!mounted) return;
        setState(() {
          _bgReady = true;
        });
      } catch (_) {
        if (!mounted) return;
        setState(() {
          _bgReady = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _navTimer?.cancel();
    _navTimer = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final double shortest = constraints.maxWidth < constraints.maxHeight
              ? constraints.maxWidth
              : constraints.maxHeight;
          final double logoSize = shortest.clamp(280, 520) * 0.28;

          return Stack(
            children: <Widget>[
              const Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: <Color>[
                        AppColors.splashTop,
                        AppColors.splashBottom,
                      ],
                    ),
                  ),
                ),
              ),
              Positioned.fill(
                child: AnimatedOpacity(
                  opacity: _bgReady ? 1 : 0,
                  duration: const Duration(milliseconds: 220),
                  child: Image(
                    image: _bg,
                    fit: BoxFit.contain,
                    filterQuality: FilterQuality.low,
                    gaplessPlayback: true,
                  ),
                ),
              ),
              if (!_bgReady)
                Center(
                  child: AppSplashLogo(
                    size: logoSize,
                    accent: AppColors.splashAccent,
                  ),
                ),
              SafeArea(
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: Text(
                      'v1.0.2',
                      style: TextStyle(
                        fontSize: 12,
                        letterSpacing: 1.2,
                        color: Colors.white.withValues(alpha: 0.45),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
