import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

import '../controllers/auth_controller.dart';
import '../controllers/customer_controller.dart';
import '../controllers/create_invoice_controller.dart';
import '../controllers/create_credit_note_controller.dart';
import '../controllers/create_debit_note_controller.dart';
import '../controllers/debit_notes_controller.dart';
import '../controllers/create_quotation_controller.dart';
import '../controllers/create_customer_controller.dart';
import '../controllers/create_product_controller.dart';
import '../controllers/dashboard_controller.dart';
import '../controllers/credit_notes_controller.dart';
import '../controllers/quotations_controller.dart';
import '../controllers/onboarding_controller.dart';
import '../controllers/settings_controller.dart';
import '../controllers/system_settings_controller.dart';
import '../controllers/companies_controller.dart';
import '../controllers/add_new_user_controller.dart';
import '../controllers/users_controller.dart';
import '../controllers/roles_permissions_controller.dart';
import '../models/product.dart';
import '../repositories/customer_repository.dart';
import '../repositories/invoice_repository.dart';
import '../repositories/onboarding_repository.dart';
import '../repositories/dashboard_repository.dart';
import '../repositories/credit_note_repository.dart';
import '../repositories/debit_note_repository.dart';
import '../repositories/permission_repository.dart';
import '../repositories/quotation_repository.dart';
import '../repositories/role_repository.dart';
import '../repositories/settings_repository.dart';
import '../repositories/user_repository.dart';
import '../repositories/company_repository.dart';
import '../views/screens/dashboard/dashboard_screen.dart';
import '../views/screens/auth/login_screen.dart';
import '../views/screens/auth/forgot_password_screen.dart';
import '../views/screens/auth/signup_screen.dart';
import '../views/screens/credits/credit_notes_screen.dart';
import '../views/screens/credits/create_credit_note_screen.dart';
import '../views/screens/debits/create_debit_note_wizard_screen.dart';
import '../views/screens/debits/debit_notes_screen.dart';
import '../views/screens/invoices/create_invoice_screen.dart';
import '../views/screens/invoices/invoices_screen.dart';
import '../views/screens/quotations/create_quotation_screen.dart';
import '../views/screens/quotations/quotations_screen.dart';
import '../views/screens/onboarding/onboarding_screen.dart';
import '../views/screens/customers/customers_screen.dart';
import '../views/screens/customers/add_customer_screen.dart';
import '../views/screens/products/products_screen.dart';
import '../views/screens/products/add_product_screen.dart';
import '../views/screens/settings/settings_screen.dart';
import '../views/screens/settings/zatca_setup_screen.dart';
import '../views/screens/settings/profile_settings_screen.dart';
import '../views/screens/settings/system_settings_screen.dart';
import '../views/screens/settings/subscription_screen.dart';
import '../views/screens/settings/upgrade_plan_screen.dart';
import '../views/screens/settings/company_info_screen.dart';
import '../views/screens/splash/splash_screen.dart';
import '../views/screens/reports/sales_reports_screen.dart';
import '../views/screens/reports/customer_reports_screen.dart';
import '../views/screens/reports/product_reports_screen.dart';
import '../views/screens/reports/reports_dashboard_screen.dart';
import '../views/screens/users_roles/users_roles_screen.dart';
import '../views/screens/users_roles/add_new_user_screen.dart';
import '../views/screens/users_roles/new_role_screen.dart';
import '../views/screens/users_roles/team_members_screen.dart';

class AppRoutes {
  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String dashboard = '/dashboard';
  static const String invoices = '/invoices';
  static const String createInvoice = '/create-invoice';
  static const String creditNotes = '/credit-notes';
  static const String createCreditNote = '/create-credit-note';
  static const String debitNotes = '/debit-notes';
  static const String createDebitNote = '/create-debit-note';
  static const String quotations = '/quotations';
  static const String createQuotation = '/create-quotation';
  static const String customers = '/customers';
  static const String addCustomer = '/add-customer';
  static const String products = '/products';
  static const String addProduct = '/add-product';
  static const String usersRoles = '/users-roles';
  static const String teamMembers = '/team-members';
  static const String addNewUser = '/add-new-user';
  static const String newRole = '/new-role';
  static const String login = '/login';
  static const String forgotPassword = '/forgot-password';
  static const String signup = '/signup';
  static const String settings = '/settings';
  static const String zatcaSetup = '/zatca-setup';
  static const String profileSettings = '/profile-settings';
  static const String systemSettings = '/system-settings';
  static const String subscription = '/subscription';
  static const String upgradePlan = '/upgrade-plan';
  static const String companyInfo = '/company-info';
  static const String salesReports = '/sales-reports';
  static const String customerReports = '/customer-reports';
  static const String productReports = '/product-reports';
  static const String reportsDashboard = '/reports-dashboard';

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
            create: (BuildContext ctx) => CreateInvoiceController(
              invoiceRepository: ctx.read<InvoiceRepository>(),
              customerRepository: ctx.read<CustomerRepository>(),
              companyRepository: ctx.read<CompanyRepository>(),
            ),
            child: const CreateInvoiceScreen(),
          ),
          settings: settings,
        );
      case AppRoutes.creditNotes:
        return MaterialPageRoute<void>(
          builder: (_) => ChangeNotifierProvider<CreditNotesController>(
            create: (BuildContext ctx) => CreditNotesController(
              repository: ctx.read<CreditNoteRepository>(),
              companyRepository: ctx.read<CompanyRepository>(),
            ),
            child: const CreditNotesScreen(),
          ),
          settings: settings,
        );
      case AppRoutes.createCreditNote:
        return MaterialPageRoute<void>(
          builder: (_) => ChangeNotifierProvider<CreateCreditNoteController>(
            create: (BuildContext ctx) => CreateCreditNoteController(
              companyRepository: ctx.read<CompanyRepository>(),
              creditNoteRepository: ctx.read<CreditNoteRepository>(),
            ),
            child: const CreateCreditNoteScreen(),
          ),
          settings: settings,
        );
      case AppRoutes.debitNotes:
        return MaterialPageRoute<void>(
          builder: (_) => ChangeNotifierProvider<DebitNotesController>(
            create: (BuildContext ctx) => DebitNotesController(
              repository: ctx.read<DebitNoteRepository>(),
              auth: ctx.read<AuthController>(),
            ),
            child: const DebitNotesScreen(),
          ),
          settings: settings,
        );
      case AppRoutes.createDebitNote:
        return MaterialPageRoute<void>(
          builder: (_) => ChangeNotifierProvider<CreateDebitNoteController>(
            create: (BuildContext ctx) => CreateDebitNoteController(
              companyRepository: ctx.read<CompanyRepository>(),
            ),
            child: const CreateDebitNoteWizardScreen(),
          ),
          settings: settings,
        );
      case AppRoutes.quotations:
        return MaterialPageRoute<void>(
          builder: (_) => ChangeNotifierProvider<QuotationsController>(
            create: (BuildContext ctx) => QuotationsController(
              repository: ctx.read<QuotationRepository>(),
              auth: ctx.read<AuthController>(),
            ),
            child: const QuotationsScreen(),
          ),
          settings: settings,
        );
      case AppRoutes.createQuotation:
        return MaterialPageRoute<void>(
          builder: (_) => ChangeNotifierProvider<CreateQuotationController>(
            create: (BuildContext ctx) => CreateQuotationController(
              quotationRepository: ctx.read<QuotationRepository>(),
              customerRepository: ctx.read<CustomerRepository>(),
              companyRepository: ctx.read<CompanyRepository>(),
              auth: ctx.read<AuthController>(),
            ),
            child: const CreateQuotationScreen(),
          ),
          settings: settings,
        );
      case AppRoutes.customers:
        return MaterialPageRoute<void>(
          builder: (_) => const CustomersScreen(),
          settings: settings,
        );
      case AppRoutes.addCustomer:
        return MaterialPageRoute<void>(
          builder: (_) => ChangeNotifierProvider<CreateCustomerController>(
            create: (BuildContext ctx) => CreateCustomerController(
              customerRepository: ctx.read<CustomerRepository>(),
              auth: ctx.read<AuthController>(),
              customerController: ctx.read<CustomerController>(),
            )..init(),
            child: const AddCustomerScreen(),
          ),
          settings: settings,
        );
      case AppRoutes.products:
        return MaterialPageRoute<void>(
          builder: (_) => const ProductsScreen(),
          settings: settings,
        );
      case AppRoutes.addProduct:
        return MaterialPageRoute<Product>(
          builder: (_) => ChangeNotifierProvider<CreateProductController>(
            create: (_) => CreateProductController(),
            child: const AddProductScreen(),
          ),
          settings: settings,
        );
      case AppRoutes.usersRoles:
        return MaterialPageRoute<void>(
          builder: (_) => MultiProvider(
            providers: <SingleChildWidget>[
              ChangeNotifierProvider<RolesPermissionsController>(
                create: (BuildContext ctx) => RolesPermissionsController(
                  roleRepository: ctx.read<RoleRepository>(),
                  permissionRepository: ctx.read<PermissionRepository>(),
                )..loadInitial(),
              ),
            ],
            child: const UsersRolesScreen(),
          ),
          settings: settings,
        );
      case AppRoutes.teamMembers:
        return MaterialPageRoute<void>(
          builder: (_) => ChangeNotifierProvider<UsersController>(
            create: (BuildContext ctx) => UsersController(
              repository: ctx.read<UserRepository>(),
            )..load(),
            child: const TeamMembersScreen(),
          ),
          settings: settings,
        );
      case AppRoutes.addNewUser:
        return MaterialPageRoute<void>(
          builder: (_) => ChangeNotifierProvider<AddNewUserController>(
            create: (BuildContext ctx) => AddNewUserController(
              roleRepository: ctx.read<RoleRepository>(),
              permissionRepository: ctx.read<PermissionRepository>(),
              companyRepository: ctx.read<CompanyRepository>(),
              userRepository: ctx.read<UserRepository>(),
            )..loadInitial(),
            child: const AddNewUserScreen(),
          ),
          settings: settings,
        );
      case AppRoutes.newRole:
        return MaterialPageRoute<void>(
          builder: (_) => const NewRoleScreen(),
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
            create: (BuildContext ctx) =>
                SettingsController(repository: ctx.read<SettingsRepository>())
                  ..load(),
            child: const SettingsScreen(),
          ),
          settings: settings,
        );
      case AppRoutes.profileSettings:
        return MaterialPageRoute<void>(
          builder: (_) => const ProfileSettingsScreen(),
          settings: settings,
        );
      case AppRoutes.systemSettings:
        return MaterialPageRoute<void>(
          builder: (_) => ChangeNotifierProvider<SystemSettingsController>(
            create: (BuildContext ctx) => SystemSettingsController(
              repository: ctx.read<SettingsRepository>(),
            )..load(),
            child: const SystemSettingsScreen(),
          ),
          settings: settings,
        );
      case AppRoutes.subscription:
        return MaterialPageRoute<void>(
          builder: (_) => const SubscriptionScreen(),
          settings: settings,
        );
      case AppRoutes.upgradePlan:
        return MaterialPageRoute<void>(
          builder: (_) => const UpgradePlanScreen(),
          settings: settings,
        );
      case AppRoutes.companyInfo:
        return MaterialPageRoute<void>(
          builder: (_) => ChangeNotifierProvider<CompaniesController>(
            create: (BuildContext ctx) => CompaniesController(
              repository: ctx.read<CompanyRepository>(),
            )..load(),
            child: const CompanyInfoScreen(),
          ),
          settings: settings,
        );
      case AppRoutes.zatcaSetup:
        return MaterialPageRoute<void>(
          builder: (_) => const ZatcaSetupScreen(),
          settings: settings,
        );
      case AppRoutes.salesReports:
        return MaterialPageRoute<void>(
          builder: (_) => const SalesReportsScreen(),
          settings: settings,
        );
      case AppRoutes.customerReports:
        return MaterialPageRoute<void>(
          builder: (_) => const CustomerReportsScreen(),
          settings: settings,
        );
      case AppRoutes.productReports:
        return MaterialPageRoute<void>(
          builder: (_) => const ProductReportsScreen(),
          settings: settings,
        );
      case AppRoutes.reportsDashboard:
        return MaterialPageRoute<void>(
          builder: (_) => const ReportsDashboardScreen(),
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
