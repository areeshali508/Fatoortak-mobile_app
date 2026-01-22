import 'package:flutter/material.dart';

import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

import '../controllers/auth_controller.dart';
import '../controllers/customer_controller.dart';
import '../controllers/invoice_controller.dart';
import '../controllers/product_controller.dart';
import '../repositories/auth_repository.dart';
import '../repositories/credit_note_repository.dart';
import '../repositories/debit_note_repository.dart';
import '../repositories/quotation_repository.dart';
import '../repositories/customer_repository.dart';
import '../repositories/dashboard_repository.dart';
import '../repositories/onboarding_repository.dart';
import '../repositories/product_repository.dart';
import '../repositories/settings_repository.dart';

class AppProviders {
  static final List<SingleChildWidget> providers = <SingleChildWidget>[
    Provider<OnboardingRepository>(
      create: (_) => const OnboardingRepository(),
    ),
    Provider<DashboardRepository>(
      create: (_) => const DashboardRepository(),
    ),
    Provider<CreditNoteRepository>(
      create: (_) => CreditNoteRepository(),
    ),
    Provider<DebitNoteRepository>(
      create: (_) => DebitNoteRepository(),
    ),
    Provider<QuotationRepository>(
      create: (_) => QuotationRepository(),
    ),
    Provider<AuthRepository>(
      create: (_) => const AuthRepository(),
    ),
    ChangeNotifierProxyProvider<AuthRepository, AuthController>(
      create: (BuildContext ctx) => AuthController(
        repository: ctx.read<AuthRepository>(),
      ),
      update: (
        BuildContext ctx,
        AuthRepository repo,
        AuthController? prev,
      ) {
        prev?.updateRepository(repo);
        return prev ?? AuthController(repository: repo);
      },
    ),
    Provider<ProductRepository>(
      create: (_) => const ProductRepository(),
    ),
    Provider<CustomerRepository>(
      create: (_) => const CustomerRepository(),
    ),
    Provider<SettingsRepository>(
      create: (_) => const SettingsRepository(),
    ),
    ChangeNotifierProxyProvider<ProductRepository, ProductController>(
      create: (BuildContext ctx) => ProductController(
        repository: ctx.read<ProductRepository>(),
      ),
      update: (
        BuildContext ctx,
        ProductRepository repo,
        ProductController? prev,
      ) {
        prev?.updateRepository(repo);
        return prev ?? ProductController(repository: repo);
      },
    ),
    ChangeNotifierProvider<InvoiceController>(
      create: (_) => InvoiceController(),
    ),
    ChangeNotifierProxyProvider<CustomerRepository, CustomerController>(
      create: (BuildContext ctx) => CustomerController(
        repository: ctx.read<CustomerRepository>(),
      ),
      update: (
        BuildContext ctx,
        CustomerRepository repo,
        CustomerController? prev,
      ) {
        prev?.updateRepository(repo);
        return prev ?? CustomerController(repository: repo);
      },
    ),
  ];
}
