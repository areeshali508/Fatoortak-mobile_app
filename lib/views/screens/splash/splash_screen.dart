import 'dart:async';

import 'package:flutter/material.dart';

import '../../../app/app_routes.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_durations.dart';
import '../../../core/constants/app_responsive.dart';
import '../../widgets/common/app_splash_logo.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  Timer? _navTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _navTimer?.cancel();
      _navTimer = Timer(Duration(milliseconds: AppDurations.splashDelayMs), () {
        if (!mounted) return;
        Navigator.of(context).pushReplacementNamed(AppRoutes.onboarding);
      });
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
    final Color bgTop = AppColors.splashTop;
    final Color bgBottom = AppColors.splashBottom;
    final Color accent = AppColors.splashAccent;

    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: <Color>[bgTop, bgBottom],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              final double logoSize = AppResponsive.clamp(
                AppResponsive.vw(constraints, 42),
                140,
                220,
              );
              final double titleSize = AppResponsive.clamp(
                AppResponsive.vw(constraints, 12),
                40,
                54,
              );

              return Stack(
                children: <Widget>[
                  Align(
                    alignment: Alignment.center,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        AppSplashLogo(
                          size: logoSize,
                          accent: accent,
                        ),
                        SizedBox(
                          height: AppResponsive.clamp(
                            AppResponsive.vh(constraints, 4.5),
                            24,
                            40,
                          ),
                        ),
                        Text(
                          'فاتورتك',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: titleSize,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            height: 1.0,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'SMART INVOICING SOLUTIONS',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: AppResponsive.clamp(
                              AppResponsive.vw(constraints, 3.5),
                              12,
                              16,
                            ),
                            letterSpacing: 2.2,
                            color: Colors.white.withValues(alpha: 0.70),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Align(
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
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
