import 'package:flutter/material.dart';

import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

import '../controllers/auth_controller.dart';
import '../controllers/customer_controller.dart';
import '../controllers/invoice_controller.dart';
import '../controllers/product_controller.dart';
import '../controllers/zatca_controller.dart';
import '../core/services/api_client.dart';
import '../repositories/auth_repository.dart';
import '../repositories/credit_note_repository.dart';
import '../repositories/debit_note_repository.dart';
import '../repositories/company_repository.dart';
import '../repositories/invoice_repository.dart';
import '../repositories/zatca_repository.dart';
import '../repositories/quotation_repository.dart';
import '../repositories/customer_repository.dart';
import '../repositories/dashboard_repository.dart';
import '../repositories/onboarding_repository.dart';
import '../repositories/product_repository.dart';
import '../repositories/settings_repository.dart';

class AppProviders {
  static final List<SingleChildWidget> providers = <SingleChildWidget>[
    Provider<OnboardingRepository>(create: (_) => const OnboardingRepository()),
    Provider<DashboardRepository>(create: (_) => const DashboardRepository()),
    Provider<CreditNoteRepository>(create: (_) => CreditNoteRepository()),
    Provider<DebitNoteRepository>(create: (_) => DebitNoteRepository()),
    Provider<AuthRepository>(create: (_) => const AuthRepository()),
    Provider<ApiClient>(
      create: (BuildContext ctx) => ApiClient(
        baseUrl: 'https://e-invoicing-solution-backend.vercel.app',
        tokenProvider: () => ctx.read<AuthRepository>().getToken(),
      ),
    ),
    ProxyProvider<ApiClient, QuotationRepository>(
      update: (BuildContext ctx, ApiClient api, QuotationRepository? prev) {
        if (prev == null) {
          return QuotationRepository(api: api);
        }
        prev.updateApi(api);
        return prev;
      },
    ),
    ChangeNotifierProxyProvider<AuthRepository, AuthController>(
      create: (BuildContext ctx) =>
          AuthController(repository: ctx.read<AuthRepository>()),
      update: (BuildContext ctx, AuthRepository repo, AuthController? prev) {
        prev?.updateRepository(repo);
        return prev ?? AuthController(repository: repo);
      },
    ),
    ProxyProvider<ApiClient, InvoiceRepository>(
      update: (BuildContext ctx, ApiClient api, InvoiceRepository? prev) {
        if (prev == null) {
          return InvoiceRepository(api: api);
        }
        prev.updateApi(api);
        return prev;
      },
    ),
    ProxyProvider<ApiClient, CompanyRepository>(
      update: (BuildContext ctx, ApiClient api, CompanyRepository? prev) {
        if (prev == null) {
          return CompanyRepository(api: api);
        }
        prev.updateApi(api);
        return prev;
      },
    ),
    ProxyProvider<ApiClient, ProductRepository>(
      update: (BuildContext ctx, ApiClient api, ProductRepository? prev) {
        if (prev == null) {
          return ProductRepository(api: api);
        }
        prev.updateApi(api);
        return prev;
      },
    ),
    ProxyProvider<ApiClient, CustomerRepository>(
      update: (BuildContext ctx, ApiClient api, CustomerRepository? prev) {
        if (prev == null) {
          return CustomerRepository(api: api);
        }
        prev.updateApi(api);
        return prev;
      },
    ),
    ProxyProvider<ApiClient, ZatcaRepository>(
      update: (BuildContext ctx, ApiClient api, ZatcaRepository? prev) {
        if (prev == null) {
          return ZatcaRepository(api: api);
        }
        prev.updateApi(api);
        return prev;
      },
    ),
    Provider<SettingsRepository>(create: (_) => const SettingsRepository()),
    ChangeNotifierProxyProvider<ProductRepository, ProductController>(
      create: (BuildContext ctx) =>
          ProductController(repository: ctx.read<ProductRepository>()),
      update:
          (BuildContext ctx, ProductRepository repo, ProductController? prev) {
            prev?.updateRepository(repo);
            return prev ?? ProductController(repository: repo);
          },
    ),
    ChangeNotifierProxyProvider<InvoiceRepository, InvoiceController>(
      create: (BuildContext ctx) => InvoiceController(
        repository: ctx.read<InvoiceRepository>(),
      ),
      update:
          (BuildContext ctx, InvoiceRepository repo, InvoiceController? prev) {
            prev?.updateRepository(repo);
            return prev ?? InvoiceController(repository: repo);
          },
    ),
    ChangeNotifierProxyProvider<CustomerRepository, CustomerController>(
      create: (BuildContext ctx) =>
          CustomerController(repository: ctx.read<CustomerRepository>()),
      update:
          (
            BuildContext ctx,
            CustomerRepository repo,
            CustomerController? prev,
          ) {
            prev?.updateRepository(repo);
            return prev ?? CustomerController(repository: repo);
          },
    ),
    ChangeNotifierProxyProvider2<ZatcaRepository, AuthController, ZatcaController>(
      create: (BuildContext ctx) => ZatcaController(
        repository: ctx.read<ZatcaRepository>(),
        auth: ctx.read<AuthController>(),
      ),
      update: (
        BuildContext ctx,
        ZatcaRepository repo,
        AuthController auth,
        ZatcaController? prev,
      ) {
        return prev ?? ZatcaController(repository: repo, auth: auth);
      },
    ),
  ];
}
