import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/app_routes.dart';
import '../../../controllers/onboarding_controller.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_responsive.dart';
import '../../../models/onboarding.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();

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

  void _handleAction(OnboardingAction action) {
    switch (action.kind) {
      case OnboardingActionKind.goToPage:
        _goTo(action.pageIndex ?? 0);
        return;
      case OnboardingActionKind.goLogin:
        Navigator.of(context).pushReplacementNamed(AppRoutes.login);
        return;
      case OnboardingActionKind.goSignup:
        Navigator.of(context).pushReplacementNamed(AppRoutes.signup);
        return;
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final OnboardingController ctrl = context.watch<OnboardingController>();
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
                onPageChanged: ctrl.setIndex,
                children: ctrl.pages.map((OnboardingPageModel page) {
                  final bool lastPage =
                      ctrl.pages.isNotEmpty && page == ctrl.pages.last;
                  final MainAxisAlignment dotsAlign = lastPage
                      ? MainAxisAlignment.start
                      : MainAxisAlignment.center;
                  final Color dotsActiveColor =
                      lastPage ? Colors.white : AppColors.primary;
                  final Color dotsInactiveColor = AppColors.dotInactive;
                  final double activeWidthMultiplier = lastPage ? 3.4 : 3.0;
                  final double dotHorizontalMargin = lastPage ? 4 : 5;

                  return _OnboardingPage(
                    constraints: constraints,
                    imageAsset: page.imageAsset,
                    imageAlignment: page.imageAlignment,
                    title: page.title,
                    subtitle: page.subtitle,
                    textAlign: page.textAlign,
                    textCrossAxisAlignment: page.textCrossAxisAlignment,
                    listItems: page.features
                        ?.map((OnboardingFeatureModel f) => _FeatureItemData(
                              icon: f.icon,
                              text: f.text,
                            ))
                        .toList(),
                    bottom: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        SizedBox(
                          height: lastPage
                              ? AppResponsive.clamp(
                                  AppResponsive.scaledByHeight(constraints, 14),
                                  10,
                                  22,
                                )
                              : dotsBottomGap,
                        ),
                        _PageDots(
                          index: ctrl.currentIndex,
                          count: ctrl.pageCount,
                          constraints: constraints,
                          mainAxisAlignment: dotsAlign,
                          activeColor: dotsActiveColor,
                          inactiveColor: dotsInactiveColor,
                          activeWidthMultiplier: activeWidthMultiplier,
                          dotHorizontalMargin: dotHorizontalMargin,
                        ),
                        SizedBox(
                          height: lastPage
                              ? AppResponsive.clamp(
                                  AppResponsive.scaledByHeight(constraints, 16),
                                  12,
                                  22,
                                )
                              : dotsToButtonGap,
                        ),
                        _BottomActions(
                          constraints: constraints,
                          primaryLabel: page.primaryLabel,
                          onPrimary: () =>
                              _handleAction(ctrl.onPrimaryPressed()),
                          onSkip: page.showSkip
                              ? () async {
                                  final OnboardingAction action =
                                      await ctrl.onSkipPressed();
                                  if (!context.mounted) return;
                                  _handleAction(action);
                                }
                              : null,
                          footer: page.showFooterLogin
                              ? Padding(
                                  padding: EdgeInsets.only(
                                    top: AppResponsive.clamp(
                                      AppResponsive.scaledByHeight(
                                          constraints, 14),
                                      10,
                                      18,
                                    ),
                                  ),
                                  child: GestureDetector(
                                    onTap: () async {
                                      final OnboardingAction action =
                                          await ctrl.onFooterLoginPressed();
                                      if (!context.mounted) return;
                                      _handleAction(action);
                                    },
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
                                          TextSpan(
                                              text: 'Already have an account? '),
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
                                )
                              : null,
                        ),
                      ],
                    ),
                  );
                }).toList(),
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
