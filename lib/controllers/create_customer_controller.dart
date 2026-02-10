import 'package:flutter/material.dart';

import '../controllers/auth_controller.dart';
import '../controllers/customer_controller.dart';
import '../models/customer.dart';
import '../repositories/customer_repository.dart';

class CustomerContactPerson {
  final String name;
  final String email;
  final String phone;

  const CustomerContactPerson({
    required this.name,
    required this.email,
    required this.phone,
  });
}

class CustomerBankAccount {
  final String bankName;
  final String iban;
  final String accountNumber;
  final String accountType;
  final String swiftBic;
  final String currency;
  final bool isPrimary;

  const CustomerBankAccount({
    required this.bankName,
    required this.iban,
    required this.accountNumber,
    this.accountType = 'Checking Account',
    this.swiftBic = '',
    this.currency = 'Saudi Riyal (SAR)',
    this.isPrimary = false,
  });
}

class CreateCustomerController extends ChangeNotifier {
  final CustomerRepository _customerRepository;
  final AuthController _auth;
  final CustomerController _customerController;

  CreateCustomerController({
    required CustomerRepository customerRepository,
    required AuthController auth,
    required CustomerController customerController,
  }) : _customerRepository = customerRepository,
       _auth = auth,
       _customerController = customerController;

  int _currentStep = 0;
  int _maxStepReached = 0;

  int get currentStep => _currentStep;
  int get maxStepReached => _maxStepReached;

  bool _isSubmitting = false;
  String? _errorMessage;

  bool get isSubmitting => _isSubmitting;
  String? get errorMessage => _errorMessage;

  bool _isBusiness = true;
  bool get isBusiness => _isBusiness;

  final TextEditingController companyNameController = TextEditingController();
  final TextEditingController commercialRegistrationController =
      TextEditingController();
  final TextEditingController crNumberController = TextEditingController();
  final TextEditingController vatNumberController = TextEditingController();
  final TextEditingController taxIdController = TextEditingController();
  final TextEditingController industryController = TextEditingController();

  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController contactPersonController = TextEditingController();
  final TextEditingController websiteController = TextEditingController();
  final TextEditingController customerGroupController = TextEditingController();

  final TextEditingController address1Controller = TextEditingController();
  final TextEditingController address2Controller = TextEditingController();
  final TextEditingController cityController = TextEditingController();
  final TextEditingController districtController = TextEditingController();
  final TextEditingController zipController = TextEditingController();
  final TextEditingController countryController = TextEditingController();
  final TextEditingController buildingNumberController = TextEditingController();
  final TextEditingController additionalNumberController = TextEditingController();

  final TextEditingController dailyLimitController = TextEditingController();
  final TextEditingController monthlyLimitController = TextEditingController();
  final TextEditingController perTransactionLimitController =
      TextEditingController();

  String _riskRating = 'Medium Risk';
  String get riskRating => _riskRating;

  String _status = 'Active';
  String get status => _status;

  String _verificationStatus = 'Pending';
  String get verificationStatus => _verificationStatus;

  bool _sanctionScreened = false;
  bool get sanctionScreened => _sanctionScreened;

  bool _accountActive = true;
  bool get accountActive => _accountActive;

  bool _consentToProcessing = false;
  bool get consentToProcessing => _consentToProcessing;

  bool _acceptTermsOfService = false;
  bool get acceptTermsOfService => _acceptTermsOfService;

  bool _acceptPrivacyPolicy = false;
  bool get acceptPrivacyPolicy => _acceptPrivacyPolicy;

  final List<CustomerContactPerson> _contactPersons =
      <CustomerContactPerson>[];
  List<CustomerContactPerson> get contactPersons =>
      List<CustomerContactPerson>.unmodifiable(_contactPersons);

  final List<CustomerBankAccount> _bankAccounts = <CustomerBankAccount>[];
  List<CustomerBankAccount> get bankAccounts =>
      List<CustomerBankAccount>.unmodifiable(_bankAccounts);

  void init() {
    _errorMessage = null;
    if (countryController.text.trim().isEmpty) {
      countryController.text = 'Saudi Arabia';
    }
  }

  void setCustomerKind({required bool business}) {
    if (_isBusiness == business) return;
    _isBusiness = business;
    notifyListeners();
  }

  void setIndustry(String v) {
    industryController.text = v.trim();
    notifyListeners();
  }

  void setCustomerGroup(String v) {
    customerGroupController.text = v.trim();
    notifyListeners();
  }

  void setRiskRating(String v) {
    final String next = v.trim();
    if (next.isEmpty || next == _riskRating) return;
    _riskRating = next;
    notifyListeners();
  }

  void setStatus(String v) {
    final String next = v.trim();
    if (next.isEmpty || next == _status) return;
    _status = next;
    notifyListeners();
  }

  void setVerificationStatus(String v) {
    final String next = v.trim();
    if (next.isEmpty || next == _verificationStatus) return;
    _verificationStatus = next;
    notifyListeners();
  }

  void setSanctionScreened(bool v) {
    if (_sanctionScreened == v) return;
    _sanctionScreened = v;
    notifyListeners();
  }

  void setAccountActive(bool v) {
    if (_accountActive == v) return;
    _accountActive = v;
    notifyListeners();
  }

  void setConsentToProcessing(bool v) {
    if (_consentToProcessing == v) return;
    _consentToProcessing = v;
    notifyListeners();
  }

  void setAcceptTermsOfService(bool v) {
    if (_acceptTermsOfService == v) return;
    _acceptTermsOfService = v;
    notifyListeners();
  }

  void setAcceptPrivacyPolicy(bool v) {
    if (_acceptPrivacyPolicy == v) return;
    _acceptPrivacyPolicy = v;
    notifyListeners();
  }

  void addContactPerson(CustomerContactPerson p) {
    _contactPersons.add(p);
    notifyListeners();
  }

  void removeContactPersonAt(int index) {
    if (index < 0 || index >= _contactPersons.length) return;
    _contactPersons.removeAt(index);
    notifyListeners();
  }

  void addBankAccount(CustomerBankAccount a) {
    if (a.isPrimary) {
      for (int i = 0; i < _bankAccounts.length; i++) {
        final CustomerBankAccount prev = _bankAccounts[i];
        if (!prev.isPrimary) continue;
        _bankAccounts[i] = CustomerBankAccount(
          bankName: prev.bankName,
          iban: prev.iban,
          accountNumber: prev.accountNumber,
          accountType: prev.accountType,
          swiftBic: prev.swiftBic,
          currency: prev.currency,
          isPrimary: false,
        );
      }
    }

    _bankAccounts.add(a);
    notifyListeners();
  }

  void removeBankAccountAt(int index) {
    if (index < 0 || index >= _bankAccounts.length) return;
    _bankAccounts.removeAt(index);
    notifyListeners();
  }

  void goToStep(int step) {
    if (step < 0 || step > 2) return;
    if (step > _maxStepReached) return;
    if (step == _currentStep) return;
    _currentStep = step;
    notifyListeners();
  }

  void prevStep() {
    if (_currentStep == 0) return;
    _currentStep--;
    notifyListeners();
  }

  bool nextStep() {
    if (!isStepValid(_currentStep)) {
      return false;
    }
    if (_currentStep >= 2) {
      return false;
    }
    _currentStep++;
    if (_currentStep > _maxStepReached) {
      _maxStepReached = _currentStep;
    }
    notifyListeners();
    return true;
  }

  bool isStepValid(int step) {
    switch (step) {
      case 0:
        final bool hasTax = vatNumberController.text.trim().isNotEmpty ||
            taxIdController.text.trim().isNotEmpty;
        final bool ok = companyNameController.text.trim().isNotEmpty &&
            hasTax &&
            emailController.text.trim().isNotEmpty &&
            phoneController.text.trim().isNotEmpty;
        if (!ok) {
          _errorMessage = 'Please complete required fields';
        }
        return ok;
      case 1:
        final bool ok = address1Controller.text.trim().isNotEmpty &&
            cityController.text.trim().isNotEmpty &&
            districtController.text.trim().isNotEmpty &&
            zipController.text.trim().isNotEmpty &&
            countryController.text.trim().isNotEmpty;
        if (!ok) {
          _errorMessage = 'Please complete required fields';
        }
        return ok;
      case 2:
        final bool ok = acceptTermsOfService && acceptPrivacyPolicy;
        if (!ok) {
          _errorMessage = 'Please accept required policies';
        }
        return ok;
      default:
        return false;
    }
  }

  String? _resolveCompanyId() {
    final String? id = _auth.activeCompanyId;
    if (id != null && id.trim().isNotEmpty) return id.trim();
    return null;
  }

  Future<Customer?> submit() async {
    final String? companyId = _resolveCompanyId();
    if (companyId == null) {
      _errorMessage = 'Company not loaded';
      notifyListeners();
      return null;
    }

    final String name = companyNameController.text.trim();
    final String taxId = vatNumberController.text.trim().isNotEmpty
        ? vatNumberController.text.trim()
        : taxIdController.text.trim();
    final String email = emailController.text.trim();
    final String phone = phoneController.text.trim();

    if (name.isEmpty || taxId.isEmpty || email.isEmpty || phone.isEmpty) {
      _errorMessage = 'Please complete required fields';
      notifyListeners();
      return null;
    }

    if (!acceptTermsOfService || !acceptPrivacyPolicy) {
      _errorMessage = 'Please accept required policies';
      notifyListeners();
      return null;
    }

    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final Customer created = await _customerRepository.createCustomer(
        companyId: companyId,
        customerName: name,
        customerType: _isBusiness ? 'company' : 'individual',
        email: email,
        phone: phone,
        taxId: taxId,
      );

      await _customerController.refresh(companyId: companyId);
      return created;
    } catch (e) {
      _errorMessage = e.toString();
      return null;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }
}
