import 'package:flutter/material.dart';

import '../models/onboarding.dart';

class OnboardingRepository {
  const OnboardingRepository();

  List<OnboardingPageModel> getPages() {
    return const <OnboardingPageModel>[
      OnboardingPageModel(
        imageAsset: 'assets/images/onboarding_image_1.png',
        title: 'Welcome to Your Smart\nBusiness Platform',
        subtitle: 'Designed for modern businesses in Saudi\nArabia',
        textAlign: TextAlign.center,
        textCrossAxisAlignment: CrossAxisAlignment.center,
        primaryLabel: 'Get Started',
        showSkip: true,
        showFooterLogin: false,
      ),
      OnboardingPageModel(
        imageAsset: 'assets/images/onboarding_image_2.png',
        title: 'Manage Your Business with\nConfidence',
        subtitle:
            'Invoices, products, customers, and reports all\nmanaged from your mobile phone.',
        textAlign: TextAlign.center,
        textCrossAxisAlignment: CrossAxisAlignment.center,
        primaryLabel: 'Next',
        showSkip: true,
        showFooterLogin: false,
      ),
      OnboardingPageModel(
        imageAsset: 'assets/images/onboarding_image_3.png',
        title: 'Built for Saudi\nRegulations',
        textAlign: TextAlign.left,
        textCrossAxisAlignment: CrossAxisAlignment.start,
        primaryLabel: 'Next',
        showSkip: true,
        showFooterLogin: false,
        features: <OnboardingFeatureModel>[
          OnboardingFeatureModel(
            icon: Icons.verified,
            text: 'ZATCA-compliant e-invoicing',
          ),
          OnboardingFeatureModel(
            icon: Icons.receipt_long,
            text: 'VAT-ready system',
          ),
          OnboardingFeatureModel(
            icon: Icons.cloud_done,
            text: 'Secure cloud-based data',
          ),
        ],
      ),
      OnboardingPageModel(
        imageAsset: 'assets/images/onboarding_image_4.png',
        imageAlignment: Alignment(-0.9, -0.15),
        title: 'Our Vision',
        subtitle:
            'Empowering businesses through digital\ntransformation and supporting growth across the\nKingdom.',
        textAlign: TextAlign.left,
        textCrossAxisAlignment: CrossAxisAlignment.start,
        primaryLabel: 'Start Your Journey',
        showSkip: false,
        showFooterLogin: true,
      ),
    ];
  }

  Future<void> markCompleted() async {}
}
