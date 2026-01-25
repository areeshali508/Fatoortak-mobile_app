import 'package:flutter/material.dart';

import '../models/onboarding.dart';
import '../repositories/onboarding_repository.dart';

enum OnboardingActionKind { goToPage, goLogin, goSignup }

class OnboardingAction {
  final OnboardingActionKind kind;
  final int? pageIndex;

  const OnboardingAction._(this.kind, {this.pageIndex});

  const OnboardingAction.goToPage(int pageIndex)
    : this._(OnboardingActionKind.goToPage, pageIndex: pageIndex);

  const OnboardingAction.goLogin() : this._(OnboardingActionKind.goLogin);

  const OnboardingAction.goSignup() : this._(OnboardingActionKind.goSignup);
}

class OnboardingController extends ChangeNotifier {
  final OnboardingRepository _repository;
  late final List<OnboardingPageModel> _pages;
  int _currentIndex = 0;

  OnboardingController({required OnboardingRepository repository})
    : _repository = repository {
    _pages = List<OnboardingPageModel>.unmodifiable(_repository.getPages());
  }

  List<OnboardingPageModel> get pages => _pages;

  int get currentIndex => _currentIndex;

  int get pageCount => _pages.length;

  void setIndex(int i) {
    if (i < 0 || i >= _pages.length) {
      return;
    }
    if (i == _currentIndex) {
      return;
    }
    _currentIndex = i;
    notifyListeners();
  }

  OnboardingAction onPrimaryPressed() {
    if (_currentIndex < _pages.length - 1) {
      return OnboardingAction.goToPage(_currentIndex + 1);
    }
    return const OnboardingAction.goSignup();
  }

  Future<OnboardingAction> onSkipPressed() async {
    await _repository.markCompleted();
    return const OnboardingAction.goLogin();
  }

  Future<OnboardingAction> onFooterLoginPressed() async {
    await _repository.markCompleted();
    return const OnboardingAction.goLogin();
  }
}
