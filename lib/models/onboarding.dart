import 'package:flutter/material.dart';

class OnboardingFeatureModel {
  final IconData icon;
  final String text;

  const OnboardingFeatureModel({
    required this.icon,
    required this.text,
  });
}

class OnboardingPageModel {
  final String imageAsset;
  final Alignment imageAlignment;
  final String title;
  final String? subtitle;
  final TextAlign textAlign;
  final CrossAxisAlignment textCrossAxisAlignment;
  final List<OnboardingFeatureModel>? features;
  final String primaryLabel;
  final bool showSkip;
  final bool showFooterLogin;

  const OnboardingPageModel({
    required this.imageAsset,
    required this.title,
    required this.textAlign,
    required this.textCrossAxisAlignment,
    required this.primaryLabel,
    required this.showSkip,
    required this.showFooterLogin,
    this.imageAlignment = const Alignment(0, -0.7),
    this.subtitle,
    this.features,
  });
}
