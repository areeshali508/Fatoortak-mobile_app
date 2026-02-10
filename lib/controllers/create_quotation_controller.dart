import 'package:flutter/material.dart';

import '../controllers/auth_controller.dart';
import '../models/company.dart';
import '../models/customer.dart';
import '../models/quotation.dart';
import '../repositories/company_repository.dart';
import '../repositories/customer_repository.dart';
import '../repositories/quotation_repository.dart';

class CreateQuotationController extends ChangeNotifier {
  final QuotationRepository _quotationRepository;
  final CustomerRepository _customerRepository;
  final CompanyRepository _companyRepository;
  final AuthController _auth;

  CreateQuotationController({
    required QuotationRepository quotationRepository,
    required CustomerRepository customerRepository,
    required CompanyRepository companyRepository,
    required AuthController auth,
  }) : _quotationRepository = quotationRepository,
       _customerRepository = customerRepository,
       _companyRepository = companyRepository,
       _auth = auth;

  int _currentStep = 0;
  int _maxStepReached = 0;

  int get currentStep => _currentStep;
  int get maxStepReached => _maxStepReached;

  String _company = 'Tech Solutions Ltd.';
  String _currency = 'SAR';
  String _paymentTerms = 'Due on Receipt';

  String? _companyId;
  String? _selectedCustomerId;
  List<Customer> _customers = const <Customer>[];
  List<Company> _companies = const <Company>[];
  bool _isLoadingCustomers = false;
  bool _isCreatingCustomer = false;
  bool _isSubmitting = false;
  bool _isLoadingCompanies = false;
  String? _errorMessage;

  String get company => _company;
  String get currency => _currency;
  String get paymentTerms => _paymentTerms;

  String? get companyId => _companyId;
  String? get selectedCustomerId => _selectedCustomerId;
  List<Customer> get customers => _customers;
  List<Company> get companies => _companies;

  Future<void> loadCompanies({Company? onlyCompany, int page = 1, int limit = 50}) async {
    _isLoadingCompanies = true;
    _errorMessage = null;
    notifyListeners();
    try {
      if (onlyCompany != null && onlyCompany.id.trim().isNotEmpty) {
        _companies = <Company>[onlyCompany];
      } else {
        _companies = await _companyRepository.listCompanies(page: page, limit: limit);
      }
    } catch (_) {
      _companies = const <Company>[];
    } finally {
      _isLoadingCompanies = false;
      notifyListeners();
    }
  }

  Company? companyById(String? id) {
    final String key = (id ?? '').trim();
    if (key.isEmpty) return null;
    try {
      return _companies.firstWhere((Company c) => c.id == key);
    } catch (_) {
      return null;
    }
  }
  bool get isLoadingCustomers => _isLoadingCustomers;
  bool get isCreatingCustomer => _isCreatingCustomer;
  bool get isSubmitting => _isSubmitting;
  bool get isLoadingCompanies => _isLoadingCompanies;
  String? get errorMessage => _errorMessage;

  void setCompany({required String companyId, required String companyName}) {
    _companyId = companyId.trim();
    _company = companyName;
    notifyListeners();
  }

  void selectCustomer(Customer? c) {
    if (c == null) {
      _selectedCustomerId = null;
      customerController.text = '';
      notifyListeners();
      return;
    }
    _selectedCustomerId = c.id;
    customerController.text = c.name;
    notifyListeners();
  }

  Future<void> loadNextQuotationNumber() async {
    final String id = (_companyId ?? '').trim();
    if (id.isEmpty) return;

    final String current = quotationNumberController.text.trim();
    final bool shouldPrefill =
        current.isEmpty ||
        current == 'QTN-2026-001' ||
        current.startsWith('QTN-') ||
        current == 'QUO-2026-000001' ||
        current.startsWith('QUO-');
    if (!shouldPrefill) return;

    try {
      final String? next =
          await _quotationRepository.getNextQuotationNumber(companyId: id);
      if (next != null && next.trim().isNotEmpty) {
        quotationNumberController.text = next.trim();
        notifyListeners();
      }
    } catch (_) {
      // ignore
    }
  }

  Future<Customer?> createCustomerQuick({
    required String customerName,
    required String customerType,
    String email = '',
    String phone = '',
    String taxId = '',
  }) async {
    String? companyId = _companyId;
    if (companyId == null || companyId.trim().isEmpty) {
      Map<String, dynamic>? company = _auth.activeCompany;
      String? id = (company?['_id'] ?? company?['id'])?.toString().trim();
      if (id == null || id.isEmpty) {
        await _auth.refreshMyCompany();
        company = _auth.activeCompany;
        id = (company?['_id'] ?? company?['id'])?.toString().trim();
      }
      if (id != null && id.trim().isNotEmpty) {
        companyId = id.trim();
        final String name = (company?['companyName'] ?? company?['name'])
                ?.toString()
                .trim() ??
            '';
        setCompany(
          companyId: companyId,
          companyName: name.isNotEmpty ? name : _company,
        );
      }
    }

    if (companyId == null || companyId.trim().isEmpty) {
      _errorMessage = 'Company not loaded';
      notifyListeners();
      return null;
    }

    _isCreatingCustomer = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final Customer created = await _customerRepository.createCustomer(
        companyId: companyId.trim(),
        customerName: customerName,
        customerType: customerType,
        email: email,
        phone: phone,
        taxId: taxId,
      );

      await loadCustomers();
      final Customer? resolved = _customers
          .cast<Customer?>()
          .firstWhere((Customer? c) => c?.id == created.id, orElse: () => null);
      selectCustomer(resolved ?? created);
      return resolved ?? created;
    } catch (e) {
      _errorMessage = e.toString();
      return null;
    } finally {
      _isCreatingCustomer = false;
      notifyListeners();
    }
  }

  Future<void> loadCustomers({String? companyId}) async {
    String? resolvedCompanyId = (companyId ?? _companyId)?.trim();
    if (resolvedCompanyId == null || resolvedCompanyId.isEmpty) {
      Map<String, dynamic>? company = _auth.activeCompany;
      String? id = (company?['_id'] ?? company?['id'])?.toString().trim();
      if (id == null || id.isEmpty) {
        await _auth.refreshMyCompany();
        company = _auth.activeCompany;
        id = (company?['_id'] ?? company?['id'])?.toString().trim();
      }
      if (id != null && id.trim().isNotEmpty) {
        resolvedCompanyId = id.trim();
        final String name = (company?['companyName'] ?? company?['name'])
                ?.toString()
                .trim() ??
            '';
        setCompany(
          companyId: resolvedCompanyId,
          companyName: name.isNotEmpty ? name : _company,
        );
      }
    }

    await loadNextQuotationNumber();

    if (resolvedCompanyId == null || resolvedCompanyId.isEmpty) {
      _errorMessage = 'Company not loaded';
      notifyListeners();
      return;
    }

    _isLoadingCustomers = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _customers = await _customerRepository.listCustomers(
        companyId: resolvedCompanyId.trim(),
        page: 1,
        limit: 50,
      );

      final String sel = (_selectedCustomerId ?? '').trim();
      if (sel.isNotEmpty) {
        final bool exists = _customers.any((Customer c) => c.id == sel);
        if (!exists) {
          _selectedCustomerId = null;
          customerController.text = '';
        }
      }
    } catch (e) {
      _customers = const <Customer>[];
      _errorMessage = e.toString();
    } finally {
      _isLoadingCustomers = false;
      notifyListeners();
    }
  }

  set company(String v) {
    if (v == _company) return;
    _company = v;
    notifyListeners();
  }

  set currency(String v) {
    if (v == _currency) return;
    _currency = v;
    notifyListeners();
  }

  set paymentTerms(String v) {
    if (v == _paymentTerms) return;
    _paymentTerms = v;
    notifyListeners();
  }

  DateTime? _issueDate;
  DateTime? _validUntil;

  DateTime? get issueDate => _issueDate;
  DateTime? get validUntil => _validUntil;

  void setIssueDate(DateTime? d) {
    _issueDate = d;
    notifyListeners();
  }

  void setValidUntil(DateTime? d) {
    _validUntil = d;
    notifyListeners();
  }

  final TextEditingController quotationNumberController = TextEditingController(
    text: 'QUO-2026-000001',
  );
  final TextEditingController customerController = TextEditingController();
  final TextEditingController notesController = TextEditingController();
  final TextEditingController termsController = TextEditingController();

  final List<QuotationItem> _items = <QuotationItem>[];
  List<QuotationItem> get items => List<QuotationItem>.unmodifiable(_items);

  void addItem(QuotationItem item) {
    _items.add(item);
    notifyListeners();
  }

  void removeItemAt(int index) {
    if (index < 0 || index >= _items.length) return;
    _items.removeAt(index);
    notifyListeners();
  }

  void updateItemAt(int index, QuotationItem item) {
    if (index < 0 || index >= _items.length) return;
    _items[index] = item;
    notifyListeners();
  }

  void incrementQtyAt(int index) {
    if (index < 0 || index >= _items.length) return;
    final QuotationItem cur = _items[index];
    _items[index] = QuotationItem(
      productId: cur.productId,
      description: cur.description,
      qty: cur.qty + 1,
      price: cur.price,
      discountPercent: cur.discountPercent,
      vatCategory: cur.vatCategory,
      taxPercent: cur.taxPercent,
    );
    notifyListeners();
  }

  void decrementQtyAt(int index) {
    if (index < 0 || index >= _items.length) return;
    final QuotationItem cur = _items[index];
    if (cur.qty <= 1) {
      removeItemAt(index);
      return;
    }
    _items[index] = QuotationItem(
      productId: cur.productId,
      description: cur.description,
      qty: cur.qty - 1,
      price: cur.price,
      discountPercent: cur.discountPercent,
      vatCategory: cur.vatCategory,
      taxPercent: cur.taxPercent,
    );
    notifyListeners();
  }

  double get subtotal => _items.fold<double>(
    0,
    (double p, QuotationItem e) => p + e.taxableAmount,
  );

  double get vatAmount =>
      _items.fold<double>(0, (double p, QuotationItem e) => p + e.taxAmount);

  double get total =>
      _items.fold<double>(0, (double p, QuotationItem e) => p + e.total);

  bool isStepValid(int step) {
    switch (step) {
      case 0:
        return quotationNumberController.text.trim().isNotEmpty &&
            customerController.text.trim().isNotEmpty &&
            _issueDate != null;
      case 1:
        return true;
      case 2:
        return true;
      default:
        return false;
    }
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

  void prevStep() {
    if (_currentStep == 0) return;
    _currentStep--;
    notifyListeners();
  }

  void goToStep(int step) {
    if (step < 0 || step > 2) return;
    if (step > _maxStepReached) return;
    _currentStep = step;
    notifyListeners();
  }

  String? validateSubmit() {
    if ((_companyId ?? '').trim().isEmpty) {
      return 'Company not loaded';
    }
    if ((_selectedCustomerId ?? '').trim().isEmpty) {
      return 'Please select a customer';
    }

    final String sel = _selectedCustomerId!.trim();
    final bool exists = _customers.any((Customer c) => c.id == sel);
    if (!exists) {
      return 'Please select a valid customer';
    }

    if (quotationNumberController.text.trim().isEmpty || _issueDate == null) {
      return 'Please complete required fields before saving';
    }
    if (_items.isEmpty) {
      return 'Please add at least one item';
    }
    return null;
  }

  Future<Quotation?> submit() async {
    final String? msg = validateSubmit();
    if (msg != null) {
      _errorMessage = msg;
      notifyListeners();
      return null;
    }

    final String companyId = _companyId!.trim();
    final String customerId = _selectedCustomerId!.trim();
    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final Quotation created = await _quotationRepository.createQuotation(
        companyId: companyId,
        customerId: customerId,
        items: List<QuotationItem>.unmodifiable(_items),
        quoteNumber: quotationNumberController.text.trim(),
        issueDate: _issueDate,
        currency: _currency,
        paymentTerms: _paymentTerms,
        terms: termsController.text.trim(),
        validUntil: _validUntil,
        notes: notesController.text.trim(),
      );
      return created;
    } catch (e) {
      final String msg = e.toString();
      final String lower = msg.toLowerCase();
      if (lower.contains('customer not found') || lower.contains('not accessible')) {
        _errorMessage =
            'Customer or selected product is not accessible for this company. Try creating a new customer (B2B/B2C) and/or submit the quotation item without selecting a product.';
      } else if (lower.contains('e11000') &&
          lower.contains('quote') &&
          lower.contains('number')) {
        _errorMessage =
            'Quotation numbering conflict on the server. Please contact support/admin to reset quotation numbering for your company.';
      } else if (lower.contains('quotation number conflict')) {
        _errorMessage =
            'Quotation numbering conflict on the server. Please contact support/admin to reset quotation numbering for your company.';
      } else {
        _errorMessage = msg;
      }
      return null;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  Quotation buildQuotation({QuotationStatus status = QuotationStatus.draft}) {
    return Quotation(
      id: quotationNumberController.text.trim(),
      customer: customerController.text.trim(),
      issueDate: _issueDate ?? DateTime.now(),
      validUntil: _validUntil,
      currency: _currency,
      amount: total,
      paymentTerms: _paymentTerms,
      status: status,
      items: List<QuotationItem>.unmodifiable(_items),
      notes: notesController.text.trim(),
      terms: termsController.text.trim(),
    );
  }

  @override
  void dispose() {
    quotationNumberController.dispose();
    customerController.dispose();
    notesController.dispose();
    termsController.dispose();
    super.dispose();
  }
}
