import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/create_invoice_controller.dart';
import '../controllers/create_credit_note_controller.dart';
import '../controllers/dashboard_controller.dart';
import '../controllers/credit_notes_controller.dart';
import '../controllers/onboarding_controller.dart';
import '../controllers/settings_controller.dart';
import '../repositories/onboarding_repository.dart';
import '../repositories/dashboard_repository.dart';
import '../repositories/credit_note_repository.dart';
import '../repositories/settings_repository.dart';
import '../views/screens/dashboard/dashboard_screen.dart';
import '../views/screens/auth/login_screen.dart';
import '../views/screens/auth/forgot_password_screen.dart';
import '../views/screens/auth/signup_screen.dart';
import '../views/screens/credits/credit_notes_screen.dart';
import '../views/screens/credits/create_credit_note_screen.dart';
import '../views/screens/invoices/create_invoice_screen.dart';
import '../views/screens/invoices/invoices_screen.dart';
import '../views/screens/onboarding/onboarding_screen.dart';
import '../views/screens/settings/settings_screen.dart';
import '../views/screens/splash/splash_screen.dart';

class AppRoutes {
  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String dashboard = '/dashboard';
  static const String invoices = '/invoices';
  static const String createInvoice = '/create-invoice';
  static const String creditNotes = '/credit-notes';
  static const String createCreditNote = '/create-credit-note';
  static const String login = '/login';
  static const String forgotPassword = '/forgot-password';
  static const String signup = '/signup';
  static const String settings = '/settings';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case splash:
        return MaterialPageRoute<void>(
          builder: (_) => const SplashScreen(),
          settings: settings,
        );
      case onboarding:
        return MaterialPageRoute<void>(
          builder: (_) => ChangeNotifierProvider<OnboardingController>(
            create: (BuildContext ctx) => OnboardingController(
              repository: ctx.read<OnboardingRepository>(),
            ),
            child: const OnboardingScreen(),
          ),
          settings: settings,
        );
      case dashboard:
        return MaterialPageRoute<void>(
          builder: (_) => ChangeNotifierProvider<DashboardController>(
            create: (BuildContext ctx) => DashboardController(
              repository: ctx.read<DashboardRepository>(),
            ),
            child: const DashboardScreen(),
          ),
          settings: settings,
        );
      case AppRoutes.invoices:
        return MaterialPageRoute<void>(
          builder: (_) => const InvoicesScreen(),
          settings: settings,
        );
      case AppRoutes.createInvoice:
        return MaterialPageRoute<void>(
          builder: (_) => ChangeNotifierProvider<CreateInvoiceController>(
            create: (_) => CreateInvoiceController(),
            child: const CreateInvoiceScreen(),
          ),
          settings: settings,
        );
      case AppRoutes.creditNotes:
        return MaterialPageRoute<void>(
          builder: (_) => ChangeNotifierProvider<CreditNotesController>(
            create: (BuildContext ctx) => CreditNotesController(
              repository: ctx.read<CreditNoteRepository>(),
            ),
            child: const CreditNotesScreen(),
          ),
          settings: settings,
        );
      case AppRoutes.createCreditNote:
        return MaterialPageRoute<void>(
          builder: (_) => ChangeNotifierProvider<CreateCreditNoteController>(
            create: (_) => CreateCreditNoteController(),
            child: const CreateCreditNoteScreen(),
          ),
          settings: settings,
        );
      case login:
        return MaterialPageRoute<void>(
          builder: (_) => const LoginScreen(),
          settings: settings,
        );
      case AppRoutes.forgotPassword:
        return MaterialPageRoute<void>(
          builder: (_) => const ForgotPasswordScreen(),
          settings: settings,
        );
      case signup:
        return MaterialPageRoute<void>(
          builder: (_) => const SignUpScreen(),
          settings: settings,
        );
      case AppRoutes.settings:
        return MaterialPageRoute<void>(
          builder: (_) => ChangeNotifierProvider<SettingsController>(
            create: (BuildContext ctx) => SettingsController(
              repository: ctx.read<SettingsRepository>(),
            )..load(),
            child: const SettingsScreen(),
          ),
          settings: settings,
        );
      default:
        return MaterialPageRoute<void>(
          builder: (_) => const SplashScreen(),
          settings: settings,
        );
    }
  }
}
