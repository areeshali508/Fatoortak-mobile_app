import 'package:flutter/material.dart';

import '../../../app/app_routes.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_responsive.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _index = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goTo(int i) {
    _pageController.animateToPage(
      i,
      duration: const Duration(milliseconds: 520),
      curve: Curves.easeInOutCubic,
    );
  }

  void _next() {
    if (_index < 3) {
      _goTo(_index + 1);
      return;
    }
    _finish();
  }

  void _finish() {
    Navigator.of(context).pushReplacementNamed(AppRoutes.login);
  }

  void _goLogin() {
    Navigator.of(context).pushReplacementNamed(AppRoutes.login);
  }

  void _goSignup() {
    Navigator.of(context).pushReplacementNamed(AppRoutes.signup);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double dotsToButtonGap = AppResponsive.clamp(
          AppResponsive.scaledByHeight(constraints, 10),
          8,
          14,
        );

        final double dotsBottomGap = AppResponsive.clamp(
          AppResponsive.scaledByHeight(constraints, 10),
          8,
          16,
        );

        return Scaffold(
          body: Stack(
            children: <Widget>[
              PageView(
                controller: _pageController,
                onPageChanged: (int i) => setState(() => _index = i),
                children: <Widget>[
                  _OnboardingPage(
                    constraints: constraints,
                    imageAsset: 'assets/images/onboarding_image_1.png',
                    title: 'Welcome to Your Smart\nBusiness Platform',
                    subtitle: 'Designed for modern businesses in Saudi\nArabia',
                    textAlign: TextAlign.center,
                    textCrossAxisAlignment: CrossAxisAlignment.center,
                    bottom: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        SizedBox(height: dotsBottomGap),
                        _PageDots(
                          index: _index,
                          count: 4,
                          constraints: constraints,
                          mainAxisAlignment: MainAxisAlignment.center,
                        ),
                        SizedBox(height: dotsToButtonGap),
                        _BottomActions(
                          constraints: constraints,
                          primaryLabel: 'Get Started',
                          onPrimary: _next,
                          onSkip: _finish,
                        ),
                      ],
                    ),
                  ),
                  _OnboardingPage(
                    constraints: constraints,
                    imageAsset: 'assets/images/onboarding_image_2.png',
                    title: 'Manage Your Business with\nConfidence',
                    subtitle:
                        'Invoices, products, customers, and reports all\nmanaged from your mobile phone.',
                    textAlign: TextAlign.center,
                    textCrossAxisAlignment: CrossAxisAlignment.center,
                    bottom: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        SizedBox(height: dotsBottomGap),
                        _PageDots(
                          index: _index,
                          count: 4,
                          constraints: constraints,
                          mainAxisAlignment: MainAxisAlignment.center,
                        ),
                        SizedBox(height: dotsToButtonGap),
                        _BottomActions(
                          constraints: constraints,
                          primaryLabel: 'Next',
                          onPrimary: _next,
                          onSkip: _finish,
                        ),
                      ],
                    ),
                  ),
                  _OnboardingPage(
                    constraints: constraints,
                    imageAsset: 'assets/images/onboarding_image_3.png',
                    title: 'Built for Saudi\nRegulations',
                    subtitle: null,
                    textAlign: TextAlign.left,
                    textCrossAxisAlignment: CrossAxisAlignment.start,
                    listItems: const <_FeatureItemData>[
                      _FeatureItemData(
                        icon: Icons.verified,
                        text: 'ZATCA-compliant e-invoicing',
                      ),
                      _FeatureItemData(
                        icon: Icons.receipt_long,
                        text: 'VAT-ready system',
                      ),
                      _FeatureItemData(
                        icon: Icons.cloud_done,
                        text: 'Secure cloud-based data',
                      ),
                    ],
                    bottom: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        SizedBox(height: dotsBottomGap),
                        _PageDots(
                          index: _index,
                          count: 4,
                          constraints: constraints,
                          mainAxisAlignment: MainAxisAlignment.center,
                        ),
                        SizedBox(height: dotsToButtonGap),
                        _BottomActions(
                          constraints: constraints,
                          primaryLabel: 'Next',
                          onPrimary: _next,
                          onSkip: _finish,
                        ),
                      ],
                    ),
                  ),
                  _OnboardingPage(
                    constraints: constraints,
                    imageAsset: 'assets/images/onboarding_image_4.png',
                    imageAlignment: const Alignment(-0.9, -0.15),
                    title: 'Our Vision',
                    subtitle:
                        'Empowering businesses through digital\ntransformation and supporting growth across the\nKingdom.',
                    textAlign: TextAlign.left,
                    textCrossAxisAlignment: CrossAxisAlignment.start,
                    bottom: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        SizedBox(height: AppResponsive.clamp(
                          AppResponsive.scaledByHeight(constraints, 14),
                          10,
                          22,
                        )),
                        _PageDots(
                          index: _index,
                          count: 4,
                          constraints: constraints,
                          mainAxisAlignment: MainAxisAlignment.start,
                          activeColor: Colors.white,
                          inactiveColor: AppColors.dotInactive,
                          activeWidthMultiplier: 3.4,
                          dotHorizontalMargin: 4,
                        ),
                        SizedBox(height: AppResponsive.clamp(
                          AppResponsive.scaledByHeight(constraints, 16),
                          12,
                          22,
                        )),
                        _BottomActions(
                          constraints: constraints,
                          primaryLabel: 'Start Your Journey',
                          onPrimary: _goSignup,
                          onSkip: null,
                          footer: Padding(
                            padding: EdgeInsets.only(top: AppResponsive.clamp(
                              AppResponsive.scaledByHeight(constraints, 14),
                              10,
                              18,
                            )),
                            child: GestureDetector(
                              onTap: _goLogin,
                              behavior: HitTestBehavior.opaque,
                              child: RichText(
                                textAlign: TextAlign.center,
                                text: TextSpan(
                                  style: TextStyle(
                                    color: AppColors.textSecondaryOnDark,
                                    fontSize: AppResponsive.clamp(
                                      AppResponsive.sp(constraints, 14),
                                      12,
                                      16,
                                    ),
                                    height: 1.35,
                                  ),
                                  children: const <TextSpan>[
                                    TextSpan(text: 'Already have an account? '),
                                    TextSpan(
                                      text: 'Sign In',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _OnboardingPage extends StatelessWidget {
  final BoxConstraints constraints;
  final String imageAsset;
  final Alignment imageAlignment;
  final String title;
  final String? subtitle;
  final TextAlign textAlign;
  final CrossAxisAlignment textCrossAxisAlignment;
  final List<_FeatureItemData>? listItems;
  final Widget bottom;

  const _OnboardingPage({
    required this.constraints,
    required this.imageAsset,
    this.imageAlignment = const Alignment(0, -0.7),
    required this.title,
    required this.bottom,
    required this.textAlign,
    required this.textCrossAxisAlignment,
    this.subtitle,
    this.listItems,
  });

  @override
  Widget build(BuildContext context) {
    final double hPad = AppResponsive.clamp(
      AppResponsive.vw(constraints, 8),
      18,
      34,
    );

    return Stack(
      children: <Widget>[
        Positioned.fill(
          child: Image.asset(
            imageAsset,
            fit: BoxFit.cover,
            alignment: imageAlignment,
            errorBuilder: (
              BuildContext context,
              Object error,
              StackTrace? stackTrace,
            ) {
              return Container(color: const Color(0xFF0E1A2A));
            },
          ),
        ),
        Positioned.fill(
          child: DecoratedBox(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: <double>[0.0, 0.55, 1.0],
                colors: <Color>[
                  AppColors.onboardingOverlayTop,
                  Color(0x66000000),
                  AppColors.onboardingOverlayBottom,
                ],
              ),
            ),
          ),
        ),
        SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: hPad),
            child: Column(
              children: <Widget>[
                const Spacer(),
                _OnboardingTextBlock(
                  constraints: constraints,
                  title: title,
                  subtitle: subtitle,
                  listItems: listItems,
                  textAlign: textAlign,
                  crossAxisAlignment: textCrossAxisAlignment,
                ),
                SizedBox(height: AppResponsive.clamp(
                  AppResponsive.scaledByHeight(constraints, 6),
                  4,
                  10,
                )),
                bottom,
                SizedBox(height: AppResponsive.clamp(
                  AppResponsive.scaledByHeight(constraints, 6),
                  4,
                  12,
                )),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _OnboardingTextBlock extends StatelessWidget {
  final BoxConstraints constraints;
  final String title;
  final String? subtitle;
  final List<_FeatureItemData>? listItems;
  final TextAlign textAlign;
  final CrossAxisAlignment crossAxisAlignment;

  const _OnboardingTextBlock({
    required this.constraints,
    required this.title,
    required this.textAlign,
    required this.crossAxisAlignment,
    this.subtitle,
    this.listItems,
  });

  @override
  Widget build(BuildContext context) {
    final double titleSp = AppResponsive.clamp(
      AppResponsive.sp(constraints, 34),
      26,
      40,
    );

    final double subtitleSp = AppResponsive.clamp(
      AppResponsive.sp(constraints, 16),
      13,
      18,
    );

    return Align(
      alignment: textAlign == TextAlign.center
          ? Alignment.bottomCenter
          : Alignment.bottomLeft,
      child: Column(
        crossAxisAlignment: crossAxisAlignment,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            title,
            textAlign: textAlign,
            style: TextStyle(
              color: AppColors.textPrimaryOnDark,
              fontSize: titleSp,
              fontWeight: FontWeight.w800,
              height: 1.12,
            ),
          ),
          if (subtitle != null) ...<Widget>[
            SizedBox(height: AppResponsive.clamp(
              AppResponsive.scaledByHeight(constraints, 14),
              10,
              18,
            )),
            Text(
              subtitle!,
              textAlign: textAlign,
              style: TextStyle(
                color: AppColors.textSecondaryOnDark,
                fontSize: subtitleSp,
                height: 1.35,
              ),
            ),
          ],
          if (listItems != null) ...<Widget>[
            SizedBox(height: AppResponsive.clamp(
              AppResponsive.scaledByHeight(constraints, 18),
              14,
              22,
            )),
            ...listItems!.map((item) => _FeatureItem(
                  constraints: constraints,
                  data: item,
                )),
          ],
        ],
      ),
    );
  }
}

class _BottomActions extends StatelessWidget {
  final BoxConstraints constraints;
  final String primaryLabel;
  final VoidCallback onPrimary;
  final VoidCallback? onSkip;
  final Widget? footer;

  const _BottomActions({
    required this.constraints,
    required this.primaryLabel,
    required this.onPrimary,
    required this.onSkip,
    this.footer,
  });

  @override
  Widget build(BuildContext context) {
    final double btnH = AppResponsive.clamp(
      AppResponsive.scaledByHeight(constraints, 56),
      48,
      64,
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        SizedBox(
          width: double.infinity,
          height: btnH,
          child: ElevatedButton(
            onPressed: onPrimary,
            child: Text(
              primaryLabel,
              style: TextStyle(
                fontSize: AppResponsive.clamp(
                  AppResponsive.sp(constraints, 16),
                  14,
                  18,
                ),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        if (onSkip != null) ...<Widget>[
          SizedBox(height: AppResponsive.clamp(
            AppResponsive.scaledByHeight(constraints, 10),
            8,
            14,
          )),
          TextButton(
            onPressed: onSkip,
            child: Text(
              'Skip',
              style: TextStyle(
                color: AppColors.textSecondaryOnDark,
                fontSize: AppResponsive.clamp(
                  AppResponsive.sp(constraints, 14),
                  12,
                  16,
                ),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
        if (footer != null) footer!,
      ],
    );
  }
}

class _PageDots extends StatelessWidget {
  final int index;
  final int count;
  final BoxConstraints constraints;
  final MainAxisAlignment mainAxisAlignment;
  final Color activeColor;
  final Color inactiveColor;
  final double activeWidthMultiplier;
  final double dotHorizontalMargin;

  const _PageDots({
    required this.index,
    required this.count,
    required this.constraints,
    required this.mainAxisAlignment,
    this.activeColor = AppColors.primary,
    this.inactiveColor = AppColors.dotInactive,
    this.activeWidthMultiplier = 3.0,
    this.dotHorizontalMargin = 5,
  });

  @override
  Widget build(BuildContext context) {
    final double dotH = AppResponsive.clamp(
      AppResponsive.scaledByHeight(constraints, 8),
      6,
      10,
    );

    final double dotWInactive = dotH;
    final double dotWActive = AppResponsive.clamp(
      dotH * activeWidthMultiplier,
      18,
      30,
    );

    return Row(
      mainAxisAlignment: mainAxisAlignment,
      children: List<Widget>.generate(count, (int i) {
        final bool active = i == index;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          margin: EdgeInsets.symmetric(horizontal: dotHorizontalMargin),
          width: active ? dotWActive : dotWInactive,
          height: dotH,
          decoration: BoxDecoration(
            color: active ? activeColor : inactiveColor,
            borderRadius: BorderRadius.circular(99),
          ),
        );
      }),
    );
  }
}

class _FeatureItemData {
  final IconData icon;
  final String text;

  const _FeatureItemData({
    required this.icon,
    required this.text,
  });
}

class _FeatureItem extends StatelessWidget {
  final BoxConstraints constraints;
  final _FeatureItemData data;

  const _FeatureItem({
    required this.constraints,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    final double iconSize = AppResponsive.clamp(
      AppResponsive.sp(constraints, 18),
      16,
      22,
    );

    final double textSp = AppResponsive.clamp(
      AppResponsive.sp(constraints, 16),
      13,
      18,
    );

    return Padding(
      padding: EdgeInsets.only(bottom: AppResponsive.clamp(
        AppResponsive.scaledByHeight(constraints, 14),
        10,
        18,
      )),
      child: Row(
        children: <Widget>[
          Container(
            width: iconSize + 14,
            height: iconSize + 14,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Icon(
              data.icon,
              color: Colors.white,
              size: iconSize,
            ),
          ),
          SizedBox(width: AppResponsive.clamp(
            AppResponsive.vw(constraints, 3),
            10,
            16,
          )),
          Expanded(
            child: Text(
              data.text,
              style: TextStyle(
                color: AppColors.textPrimaryOnDark,
                fontSize: textSp,
                fontWeight: FontWeight.w600,
                height: 1.2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
