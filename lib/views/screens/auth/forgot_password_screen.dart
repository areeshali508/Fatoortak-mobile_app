import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/app_routes.dart';
import '../../../controllers/auth_controller.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_responsive.dart';
import '../../widgets/common/app_splash_logo.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Color bgTop = AppColors.splashTop;
    final Color bgBottom = AppColors.splashBottom;

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
                AppResponsive.vw(constraints, 22),
                86,
                112,
              );

              final double cardTopRadius = AppResponsive.clamp(
                AppResponsive.scaledByHeight(constraints, 34),
                26,
                44,
              );

              final double hPad = AppResponsive.clamp(
                AppResponsive.vw(constraints, 8),
                18,
                34,
              );

              final double headerTopGap = AppResponsive.clamp(
                AppResponsive.scaledByHeight(constraints, 18),
                10,
                22,
              );

              final double headerToCardGap = AppResponsive.clamp(
                AppResponsive.scaledByHeight(constraints, 18),
                12,
                22,
              );

              final double btnH = AppResponsive.clamp(
                AppResponsive.scaledByHeight(constraints, 56),
                48,
                64,
              );

              return Column(
                children: <Widget>[
                  SizedBox(height: headerTopGap),
                  _AuthHeader(
                    constraints: constraints,
                    logoSize: logoSize,
                  ),
                  SizedBox(height: headerToCardGap),
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(cardTopRadius),
                          topRight: Radius.circular(cardTopRadius),
                        ),
                      ),
                      child: SingleChildScrollView(
                        padding: EdgeInsets.fromLTRB(
                          hPad,
                          AppResponsive.clamp(
                            AppResponsive.scaledByHeight(constraints, 22),
                            16,
                            28,
                          ),
                          hPad,
                          AppResponsive.clamp(
                            AppResponsive.scaledByHeight(constraints, 18),
                            14,
                            26,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: <Widget>[
                            Text(
                              'Forgot Password',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: AppResponsive.clamp(
                                  AppResponsive.sp(constraints, 26),
                                  20,
                                  30,
                                ),
                                fontWeight: FontWeight.w800,
                                color: AppColors.splashBottom,
                                height: 1.1,
                              ),
                            ),
                            SizedBox(height: AppResponsive.clamp(
                              AppResponsive.scaledByHeight(constraints, 10),
                              8,
                              14,
                            )),
                            Text(
                              'Enter your email to receive a password reset link.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: AppResponsive.clamp(
                                  AppResponsive.sp(constraints, 14),
                                  12,
                                  16,
                                ),
                                color: const Color(0xFF6B7895),
                                height: 1.35,
                              ),
                            ),
                            SizedBox(height: AppResponsive.clamp(
                              AppResponsive.scaledByHeight(constraints, 22),
                              16,
                              28,
                            )),
                            _Field(
                              constraints: constraints,
                              hintText: 'Email Address',
                              icon: Icons.mail_outline,
                              controller: _emailController,
                            ),
                            SizedBox(height: AppResponsive.clamp(
                              AppResponsive.scaledByHeight(constraints, 18),
                              12,
                              22,
                            )),
                            SizedBox(
                              height: btnH,
                              child: ElevatedButton(
                                onPressed: () async {
                                  final AuthController auth =
                                      context.read<AuthController>();
                                  await auth.sendPasswordResetLink(
                                    email: _emailController.text.trim(),
                                  );
                                  if (!context.mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'If this email exists, a reset link will be sent.',
                                      ),
                                    ),
                                  );
                                },
                                child: Text(
                                  'Send Reset Link',
                                  style: TextStyle(
                                    fontSize: AppResponsive.clamp(
                                      AppResponsive.sp(constraints, 16),
                                      14,
                                      18,
                                    ),
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(height: AppResponsive.clamp(
                              AppResponsive.scaledByHeight(constraints, 18),
                              12,
                              22,
                            )),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: <Widget>[
                                Text(
                                  'Remember your password? ',
                                  style: TextStyle(
                                    color: const Color(0xFF6B7895),
                                    fontSize: AppResponsive.clamp(
                                      AppResponsive.sp(constraints, 13),
                                      12,
                                      14,
                                    ),
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () {
                                    Navigator.of(context)
                                        .pushReplacementNamed(AppRoutes.login);
                                  },
                                  child: Text(
                                    'Login',
                                    style: TextStyle(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w800,
                                      fontSize: AppResponsive.clamp(
                                        AppResponsive.sp(constraints, 13),
                                        12,
                                        14,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
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

class _AuthHeader extends StatelessWidget {
  final BoxConstraints constraints;
  final double logoSize;

  const _AuthHeader({
    required this.constraints,
    required this.logoSize,
  });

  @override
  Widget build(BuildContext context) {
    final double brandSize = AppResponsive.clamp(
      AppResponsive.sp(constraints, 26),
      22,
      30,
    );

    final double arabicSize = AppResponsive.clamp(
      AppResponsive.sp(constraints, 14),
      12,
      16,
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        AppSplashLogo(
          size: logoSize,
          accent: AppColors.splashAccent,
        ),
        SizedBox(height: AppResponsive.clamp(
          AppResponsive.scaledByHeight(constraints, 16),
          10,
          18,
        )),
        Text(
          'Fatoortak',
          style: TextStyle(
            color: Colors.white,
            fontSize: brandSize,
            fontWeight: FontWeight.w800,
            height: 1.0,
          ),
        ),
        SizedBox(height: AppResponsive.clamp(
          AppResponsive.scaledByHeight(constraints, 6),
          4,
          10,
        )),
        Text(
          'فاتورتك',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.85),
            fontSize: arabicSize,
            fontWeight: FontWeight.w600,
            height: 1.0,
          ),
        ),
      ],
    );
  }
}

class _Field extends StatelessWidget {
  final BoxConstraints constraints;
  final String hintText;
  final IconData icon;
  final TextEditingController? controller;

  const _Field({
    required this.constraints,
    required this.hintText,
    required this.icon,
    this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final double radius = AppResponsive.clamp(
      AppResponsive.scaledByHeight(constraints, 16),
      12,
      18,
    );

    return TextField(
      controller: controller,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(color: Color(0xFF9AA5B6)),
        prefixIcon: Icon(icon, color: const Color(0xFF9AA5B6)),
        filled: true,
        fillColor: const Color(0xFFF7FAFF),
        contentPadding: const EdgeInsets.symmetric(vertical: 16),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius),
          borderSide: const BorderSide(color: Color(0xFFE2EAF6)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.4),
        ),
      ),
    );
  }
}
