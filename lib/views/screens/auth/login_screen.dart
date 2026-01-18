import 'package:flutter/material.dart';

import '../../../app/app_routes.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_responsive.dart';
import '../../widgets/common/app_splash_logo.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _obscure = true;
  bool _isEnglish = true;

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

              final double fieldGap = AppResponsive.clamp(
                AppResponsive.scaledByHeight(constraints, 16),
                12,
                20,
              );

              final double sectionGap = AppResponsive.clamp(
                AppResponsive.scaledByHeight(constraints, 22),
                16,
                28,
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
                  _LoginHeader(
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
                      child: Column(
                        children: <Widget>[
                          Expanded(
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
                                  AppResponsive.scaledByHeight(constraints, 10),
                                  8,
                                  16,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: <Widget>[
                                  Text(
                                    'Welcome Back',
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
                                    AppResponsive.scaledByHeight(constraints, 8),
                                    6,
                                    12,
                                  )),
                                  Text(
                                    'Sign in to manage your invoices',
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
                                  SizedBox(height: sectionGap),
                                  _LoginTextField(
                                    constraints: constraints,
                                    hintText: 'Email or Username',
                                    prefixIcon: Icons.mail_outline,
                                    obscureText: false,
                                  ),
                                  SizedBox(height: fieldGap),
                                  _LoginTextField(
                                    constraints: constraints,
                                    hintText: 'Password',
                                    prefixIcon: Icons.lock_outline,
                                    obscureText: _obscure,
                                    suffix: IconButton(
                                      onPressed: () => setState(() {
                                        _obscure = !_obscure;
                                      }),
                                      icon: Icon(
                                        _obscure
                                            ? Icons.visibility_off_outlined
                                            : Icons.visibility_outlined,
                                        color: const Color(0xFF9AA5B6),
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: AppResponsive.clamp(
                                    AppResponsive.scaledByHeight(constraints, 8),
                                    6,
                                    12,
                                  )),
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: TextButton(
                                      onPressed: () {
                                        Navigator.of(context).pushNamed(
                                          AppRoutes.forgotPassword,
                                        );
                                      },
                                      child: Text(
                                        'Forgot Password?',
                                        style: TextStyle(
                                          fontSize: AppResponsive.clamp(
                                            AppResponsive.sp(constraints, 13),
                                            12,
                                            14,
                                          ),
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: AppResponsive.clamp(
                                    AppResponsive.scaledByHeight(constraints, 10),
                                    8,
                                    14,
                                  )),
                                  SizedBox(
                                    height: btnH,
                                    child: ElevatedButton(
                                      onPressed: () {
                                        Navigator.of(context)
                                            .pushReplacementNamed(
                                          AppRoutes.dashboard,
                                        );
                                      },
                                      child: Text(
                                        'Sign In',
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
                                    AppResponsive.scaledByHeight(constraints, 14),
                                    10,
                                    18,
                                  )),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: <Widget>[
                                      Text(
                                        "Don't have an account? ",
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
                                              .pushReplacementNamed(
                                            AppRoutes.signup,
                                          );
                                        },
                                        child: Text(
                                          'Sign Up',
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
                          Padding(
                            padding: EdgeInsets.fromLTRB(
                              hPad,
                              0,
                              hPad,
                              AppResponsive.clamp(
                                AppResponsive.scaledByHeight(constraints, 14),
                                10,
                                18,
                              ),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                SizedBox(height: AppResponsive.clamp(
                                  AppResponsive.scaledByHeight(constraints, 14),
                                  10,
                                  18,
                                )),
                                const Divider(
                                  height: 1,
                                  color: Color(0xFFE9EEF5),
                                  thickness: 1,
                                ),
                                SizedBox(height: AppResponsive.clamp(
                                  AppResponsive.scaledByHeight(constraints, 12),
                                  10,
                                  18,
                                )),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: <Widget>[
                                    _BottomLoginShortcut(
                                      constraints: constraints,
                                    ),
                                    _LanguageToggle(
                                      constraints: constraints,
                                      isEnglish: _isEnglish,
                                      onChanged: (bool value) => setState(() {
                                        _isEnglish = value;
                                      }),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
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

class _LoginHeader extends StatelessWidget {
  final BoxConstraints constraints;
  final double logoSize;

  const _LoginHeader({
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

class _LoginTextField extends StatelessWidget {
  final BoxConstraints constraints;
  final String hintText;
  final IconData prefixIcon;
  final bool obscureText;
  final Widget? suffix;

  const _LoginTextField({
    required this.constraints,
    required this.hintText,
    required this.prefixIcon,
    required this.obscureText,
    this.suffix,
  });

  @override
  Widget build(BuildContext context) {
    final double radius = AppResponsive.clamp(
      AppResponsive.scaledByHeight(constraints, 16),
      12,
      18,
    );

    return TextField(
      obscureText: obscureText,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(color: Color(0xFF9AA5B6)),
        prefixIcon: Icon(prefixIcon, color: const Color(0xFF9AA5B6)),
        suffixIcon: suffix,
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

class _BottomLoginShortcut extends StatelessWidget {
  final BoxConstraints constraints;

  const _BottomLoginShortcut({required this.constraints});

  @override
  Widget build(BuildContext context) {
    final double iconSize = AppResponsive.clamp(
      AppResponsive.scaledByHeight(constraints, 24),
      18,
      28,
    );

    final double labelSize = AppResponsive.clamp(
      AppResponsive.sp(constraints, 11),
      10,
      12,
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Icon(Icons.fingerprint, color: AppColors.primary, size: iconSize),
        SizedBox(height: AppResponsive.clamp(
          AppResponsive.scaledByHeight(constraints, 6),
          4,
          10,
        )),
        Text(
          'LOGIN',
          style: TextStyle(
            fontSize: labelSize,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF6B7895),
            letterSpacing: 1.0,
          ),
        ),
      ],
    );
  }
}

class _LanguageToggle extends StatelessWidget {
  final BoxConstraints constraints;
  final bool isEnglish;
  final ValueChanged<bool> onChanged;

  const _LanguageToggle({
    required this.constraints,
    required this.isEnglish,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final double radius = AppResponsive.clamp(
      AppResponsive.scaledByHeight(constraints, 14),
      12,
      16,
    );

    final double pillH = AppResponsive.clamp(
      AppResponsive.scaledByHeight(constraints, 36),
      32,
      40,
    );

    final double textSize = AppResponsive.clamp(
      AppResponsive.sp(constraints, 12),
      11,
      13,
    );

    final Color bg = const Color(0xFFF2F4F8);

    return Container(
      height: pillH,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(radius),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          _LangChip(
            label: 'EN',
            selected: isEnglish,
            radius: radius - 2,
            textSize: textSize,
            onTap: () => onChanged(true),
          ),
          const SizedBox(width: 4),
          _LangChip(
            label: 'عربي',
            selected: !isEnglish,
            radius: radius - 2,
            textSize: textSize,
            onTap: () => onChanged(false),
          ),
        ],
      ),
    );
  }
}

class _LangChip extends StatelessWidget {
  final String label;
  final bool selected;
  final double radius;
  final double textSize;
  final VoidCallback onTap;

  const _LangChip({
    required this.label,
    required this.selected,
    required this.radius,
    required this.textSize,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(radius),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontSize: textSize,
            fontWeight: FontWeight.w800,
            color: selected ? AppColors.primary : const Color(0xFF6B7895),
          ),
        ),
      ),
    );
  }
}

