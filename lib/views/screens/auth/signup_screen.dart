import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/app_routes.dart';
import '../../../controllers/auth_controller.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_responsive.dart';
import '../../widgets/common/app_splash_logo.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  bool _obscure = true;
  bool _obscureConfirm = true;
  bool _acceptedTerms = false;

  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Color bgTop = AppColors.splashBottom;
    const Color surface = Color(0xFFF7FAFF);

    return Scaffold(
      body: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final double topInset = MediaQuery.paddingOf(context).top;
          final double bottomInset = MediaQuery.paddingOf(context).bottom;

          final double logoSize = AppResponsive.clamp(
            AppResponsive.vw(constraints, 22),
            86,
            112,
          );

          final double cardRadius = AppResponsive.clamp(
            AppResponsive.scaledByHeight(constraints, 34),
            26,
            44,
          );

          final double cardMargin = AppResponsive.clamp(
            AppResponsive.vw(constraints, 6),
            16,
            22,
          );

          final double sectionGap = AppResponsive.clamp(
            AppResponsive.scaledByHeight(constraints, 18),
            12,
            24,
          );

          final double fieldGap = AppResponsive.clamp(
            AppResponsive.scaledByHeight(constraints, 14),
            10,
            18,
          );

          final double btnH = AppResponsive.clamp(
            AppResponsive.scaledByHeight(constraints, 56),
            48,
            64,
          );

          final double headerTopGap = AppResponsive.clamp(
            AppResponsive.scaledByHeight(constraints, 16),
            10,
            22,
          );

          final double headerBottomGap = AppResponsive.clamp(
            AppResponsive.scaledByHeight(constraints, 18),
            12,
            24,
          );

          return Column(
            children: <Widget>[
              Container(
                width: double.infinity,
                color: bgTop,
                padding: EdgeInsets.only(
                  top: topInset + headerTopGap,
                  bottom: headerBottomGap,
                ),
                child: _AuthHeader(
                  constraints: constraints,
                  logoSize: logoSize,
                ),
              ),
              Expanded(
                child: ColoredBox(
                  color: surface,
                  child: SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(
                      cardMargin,
                      AppResponsive.clamp(
                        AppResponsive.scaledByHeight(constraints, 18),
                        12,
                        22,
                      ),
                      cardMargin,
                      AppResponsive.clamp(
                        AppResponsive.scaledByHeight(constraints, 18),
                        12,
                        26,
                      ) +
                          bottomInset,
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(cardRadius),
                      ),
                      padding: EdgeInsets.fromLTRB(
                        AppResponsive.clamp(
                          AppResponsive.vw(constraints, 6),
                          16,
                          26,
                        ),
                        AppResponsive.clamp(
                          AppResponsive.scaledByHeight(constraints, 18),
                          14,
                          24,
                        ),
                        AppResponsive.clamp(
                          AppResponsive.vw(constraints, 6),
                          16,
                          26,
                        ),
                        AppResponsive.clamp(
                          AppResponsive.scaledByHeight(constraints, 18),
                          14,
                          24,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          Text(
                            'Create Account',
                            style: TextStyle(
                              fontSize: AppResponsive.clamp(
                                AppResponsive.sp(constraints, 22),
                                18,
                                26,
                              ),
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF0B1B4B),
                              height: 1.1,
                            ),
                          ),
                          SizedBox(
                            height: AppResponsive.clamp(
                              AppResponsive.scaledByHeight(constraints, 8),
                              6,
                              12,
                            ),
                          ),
                          Text(
                            'Join Fatoortak to start invoicing',
                            style: TextStyle(
                              fontSize: AppResponsive.clamp(
                                AppResponsive.sp(constraints, 13),
                                12,
                                14,
                              ),
                              color: const Color(0xFF6B7895),
                            ),
                          ),
                          SizedBox(height: sectionGap),
                          _FieldLabel(
                            constraints: constraints,
                            text: 'Full Name',
                          ),
                          SizedBox(
                            height: AppResponsive.clamp(
                              AppResponsive.scaledByHeight(constraints, 8),
                              6,
                              12,
                            ),
                          ),
                          _SignupTextField(
                            constraints: constraints,
                            hintText: 'e.g. Ahmed Ali',
                            prefixIcon: Icons.person_outline,
                            obscureText: false,
                            controller: _fullNameController,
                          ),
                          SizedBox(height: fieldGap),
                          _FieldLabel(
                            constraints: constraints,
                            text: 'Email Address',
                          ),
                          SizedBox(
                            height: AppResponsive.clamp(
                              AppResponsive.scaledByHeight(constraints, 8),
                              6,
                              12,
                            ),
                          ),
                          _SignupTextField(
                            constraints: constraints,
                            hintText: 'name@company.com',
                            prefixIcon: Icons.mail_outline,
                            obscureText: false,
                            controller: _emailController,
                          ),
                          SizedBox(height: fieldGap),
                          _FieldLabel(
                            constraints: constraints,
                            text: 'Phone Number',
                          ),
                          SizedBox(
                            height: AppResponsive.clamp(
                              AppResponsive.scaledByHeight(constraints, 8),
                              6,
                              12,
                            ),
                          ),
                          Row(
                            children: <Widget>[
                              _CountryCodeField(
                                constraints: constraints,
                                codeText: '+966',
                              ),
                              SizedBox(
                                width: AppResponsive.clamp(
                                  AppResponsive.vw(constraints, 3),
                                  10,
                                  16,
                                ),
                              ),
                              Expanded(
                                child: _SignupTextField(
                                  constraints: constraints,
                                  hintText: '5X XXX XXXX',
                                  prefixIcon: Icons.phone_outlined,
                                  obscureText: false,
                                  controller: _phoneController,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: fieldGap),
                          _FieldLabel(
                            constraints: constraints,
                            text: 'Password',
                          ),
                          SizedBox(
                            height: AppResponsive.clamp(
                              AppResponsive.scaledByHeight(constraints, 8),
                              6,
                              12,
                            ),
                          ),
                          _SignupTextField(
                            constraints: constraints,
                            hintText: '••••••••',
                            prefixIcon: Icons.lock_outline,
                            obscureText: _obscure,
                            controller: _passwordController,
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
                          SizedBox(
                            height: AppResponsive.clamp(
                              AppResponsive.scaledByHeight(constraints, 10),
                              8,
                              14,
                            ),
                          ),
                          _PasswordStrength(
                            constraints: constraints,
                            level: _StrengthLevel.medium,
                          ),
                          SizedBox(height: fieldGap),
                          _FieldLabel(
                            constraints: constraints,
                            text: 'Confirm Password',
                          ),
                          SizedBox(
                            height: AppResponsive.clamp(
                              AppResponsive.scaledByHeight(constraints, 8),
                              6,
                              12,
                            ),
                          ),
                          _SignupTextField(
                            constraints: constraints,
                            hintText: '••••••••',
                            prefixIcon: Icons.lock_reset_outlined,
                            obscureText: _obscureConfirm,
                            controller: _confirmPasswordController,
                            suffix: IconButton(
                              onPressed: () => setState(() {
                                _obscureConfirm = !_obscureConfirm;
                              }),
                              icon: Icon(
                                _obscureConfirm
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                color: const Color(0xFF9AA5B6),
                              ),
                            ),
                          ),
                          SizedBox(height: sectionGap),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              SizedBox(
                                width: 22,
                                height: 22,
                                child: Checkbox(
                                  visualDensity: VisualDensity.compact,
                                  materialTapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                  value: _acceptedTerms,
                                  onChanged: (bool? value) => setState(() {
                                    _acceptedTerms =
                                        value ?? _acceptedTerms;
                                  }),
                                ),
                              ),
                              SizedBox(
                                width: AppResponsive.clamp(
                                  AppResponsive.vw(constraints, 2.5),
                                  8,
                                  12,
                                ),
                              ),
                              Expanded(
                                child: GestureDetector(
                                  onTap: () {},
                                  behavior: HitTestBehavior.opaque,
                                  child: RichText(
                                    text: TextSpan(
                                      style: TextStyle(
                                        fontSize: AppResponsive.clamp(
                                          AppResponsive.sp(constraints, 12),
                                          11,
                                          13,
                                        ),
                                        color: const Color(0xFF0B1B4B),
                                        height: 1.3,
                                      ),
                                      children: const <TextSpan>[
                                        TextSpan(text: 'I agree to the '),
                                        TextSpan(
                                          text: 'Terms of Service',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w800,
                                            color: AppColors.primary,
                                          ),
                                        ),
                                        TextSpan(text: ' and '),
                                        TextSpan(
                                          text: 'Privacy Policy',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w800,
                                            color: AppColors.primary,
                                          ),
                                        ),
                                        TextSpan(text: '.'),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: sectionGap),
                          SizedBox(
                            height: btnH,
                            child: ElevatedButton(
                              onPressed: () async {
                                final AuthController auth =
                                    context.read<AuthController>();
                                final bool ok = await auth.signUp(
                                  fullName: _fullNameController.text.trim(),
                                  email: _emailController.text.trim(),
                                  phone: _phoneController.text.trim(),
                                  password: _passwordController.text,
                                );
                                if (!context.mounted || !ok) return;
                                Navigator.of(context).pushReplacementNamed(
                                  AppRoutes.dashboard,
                                );
                              },
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: <Widget>[
                                  Text(
                                    'Sign Up',
                                    style: TextStyle(
                                      fontSize: AppResponsive.clamp(
                                        AppResponsive.sp(constraints, 16),
                                        14,
                                        18,
                                      ),
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  const Icon(Icons.arrow_forward, size: 18),
                                ],
                              ),
                            ),
                          ),
                          SizedBox(
                            height: AppResponsive.clamp(
                              AppResponsive.scaledByHeight(constraints, 14),
                              10,
                              18,
                            ),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget>[
                              Text(
                                'Already have an account? ',
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
                                  Navigator.of(context).pushReplacementNamed(
                                    AppRoutes.login,
                                  );
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
              ),
            ],
          );
        },
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

class _FieldLabel extends StatelessWidget {
  final BoxConstraints constraints;
  final String text;

  const _FieldLabel({required this.constraints, required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: AppResponsive.clamp(
          AppResponsive.sp(constraints, 12),
          11,
          13,
        ),
        fontWeight: FontWeight.w700,
        color: const Color(0xFF0B1B4B),
      ),
    );
  }
}

class _SignupTextField extends StatelessWidget {
  final BoxConstraints constraints;
  final String hintText;
  final IconData prefixIcon;
  final bool obscureText;
  final Widget? suffix;
  final TextEditingController? controller;

  const _SignupTextField({
    required this.constraints,
    required this.hintText,
    required this.prefixIcon,
    required this.obscureText,
    this.suffix,
    this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final double radius = AppResponsive.clamp(
      AppResponsive.scaledByHeight(constraints, 16),
      12,
      18,
    );

    final double fieldH = AppResponsive.clamp(
      AppResponsive.scaledByHeight(constraints, 56),
      50,
      64,
    );

    final double vPad = AppResponsive.clamp(
      AppResponsive.scaledByHeight(constraints, 16),
      12,
      18,
    );

    return SizedBox(
      height: fieldH,
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        textAlignVertical: TextAlignVertical.center,
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: const TextStyle(color: Color(0xFF9AA5B6)),
          prefixIcon: Icon(prefixIcon, color: const Color(0xFF9AA5B6)),
          suffixIcon: suffix,
          filled: true,
          fillColor: const Color(0xFFF7FAFF),
          contentPadding: EdgeInsets.symmetric(vertical: vPad),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(radius),
            borderSide: const BorderSide(color: Color(0xFFE2EAF6)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(radius),
            borderSide: const BorderSide(color: AppColors.primary, width: 1.4),
          ),
        ),
      ),
    );
  }
}

class _CountryCodeField extends StatelessWidget {
  final BoxConstraints constraints;
  final String codeText;

  const _CountryCodeField({
    required this.constraints,
    required this.codeText,
  });

  @override
  Widget build(BuildContext context) {
    final double radius = AppResponsive.clamp(
      AppResponsive.scaledByHeight(constraints, 16),
      12,
      18,
    );

    final double fieldH = AppResponsive.clamp(
      AppResponsive.scaledByHeight(constraints, 56),
      50,
      64,
    );

    return Container(
      height: fieldH,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF7FAFF),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: const Color(0xFFE2EAF6)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const Text('🇸🇦', style: TextStyle(fontSize: 16)),
          const SizedBox(width: 8),
          Text(
            codeText,
            style: const TextStyle(
              color: Color(0xFF0B1B4B),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 6),
          const Icon(
            Icons.keyboard_arrow_down,
            size: 20,
            color: Color(0xFF6B7895),
          ),
        ],
      ),
    );
  }
}

enum _StrengthLevel { weak, medium, strong }

class _PasswordStrength extends StatelessWidget {
  final BoxConstraints constraints;
  final _StrengthLevel level;

  const _PasswordStrength({
    required this.constraints,
    required this.level,
  });

  @override
  Widget build(BuildContext context) {
    final int activeCount = switch (level) {
      _StrengthLevel.weak => 1,
      _StrengthLevel.medium => 2,
      _StrengthLevel.strong => 3,
    };

    final Color active = level == _StrengthLevel.medium
        ? const Color(0xFFFFB300)
        : (level == _StrengthLevel.strong
            ? const Color(0xFF1DB954)
            : const Color(0xFFFF5252));

    final String label = switch (level) {
      _StrengthLevel.weak => 'Weak strength',
      _StrengthLevel.medium => 'Medium strength',
      _StrengthLevel.strong => 'Strong strength',
    };

    return Row(
      children: <Widget>[
        Expanded(
          child: Row(
            children: List<Widget>.generate(4, (int i) {
              final bool on = i < activeCount;
              return Expanded(
                child: Container(
                  height: 5,
                  margin: EdgeInsets.only(right: i == 3 ? 0 : 8),
                  decoration: BoxDecoration(
                    color: on ? active : const Color(0xFFE9EEF5),
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              );
            }),
          ),
        ),
        SizedBox(width: AppResponsive.clamp(
          AppResponsive.vw(constraints, 3),
          10,
          16,
        )),
        Text(
          label,
          style: TextStyle(
            fontSize: AppResponsive.clamp(
              AppResponsive.sp(constraints, 11),
              10,
              12,
            ),
            fontWeight: FontWeight.w700,
            color: active,
          ),
        ),
      ],
    );
  }
}
