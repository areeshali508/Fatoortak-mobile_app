import 'package:flutter/material.dart';

import '../models/company.dart';
import '../models/customer.dart';
import '../models/invoice.dart';
import '../repositories/company_repository.dart';
import '../repositories/customer_repository.dart';
import '../repositories/invoice_repository.dart';

class CreateInvoiceController extends ChangeNotifier {
  final InvoiceRepository _invoiceRepository;
  final CustomerRepository _customerRepository;
  final CompanyRepository _companyRepository;

  CreateInvoiceController({
    required InvoiceRepository invoiceRepository,
    required CustomerRepository customerRepository,
    required CompanyRepository companyRepository,
  }) : _invoiceRepository = invoiceRepository,
       _customerRepository = customerRepository,
       _companyRepository = companyRepository;

  int _currentStep = 0;
  int _maxStepReached = 0;

  int get currentStep => _currentStep;
  int get maxStepReached => _maxStepReached;

  bool _isLoadingCustomers = false;
  bool _isSubmitting = false;
  bool _isLoadingCompanies = false;
  String? _errorMessage;

  bool get isLoadingCustomers => _isLoadingCustomers;
  bool get isSubmitting => _isSubmitting;
  bool get isLoadingCompanies => _isLoadingCompanies;
  String? get errorMessage => _errorMessage;

  String? _companyId;
  String? _selectedCustomerId;
  List<Customer> _customers = const <Customer>[];
  List<Company> _companies = const <Company>[];

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
    } catch (e) {
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

  void setCompany({required String companyId, required String companyName}) {
    _companyId = companyId;
    company = companyName;
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

  Future<void> loadCustomers({required String companyId}) async {
    if (companyId.trim().isEmpty) {
      _errorMessage = 'Company not loaded';
      notifyListeners();
      return;
    }
    _isLoadingCustomers = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _customers = await _customerRepository.listCustomers(
        companyId: companyId.trim(),
        page: 1,
        limit: 50,
      );
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoadingCustomers = false;
      notifyListeners();
    }
  }

  Future<Invoice?> submit({required bool draft}) async {
    final String? companyId = _companyId;
    final String? customerId = _selectedCustomerId;
    final DateTime? issue = _issueDate;
    final DateTime? due = _dueDate;

    if (companyId == null || companyId.trim().isEmpty) {
      _errorMessage = 'Company not loaded';
      notifyListeners();
      return null;
    }
    if (customerId == null || customerId.trim().isEmpty) {
      _errorMessage = 'Please select a customer';
      notifyListeners();
      return null;
    }
    if (issue == null || due == null) {
      _errorMessage = 'Please select issue date and due date';
      notifyListeners();
      return null;
    }
    if (_items.isEmpty) {
      _errorMessage = 'Please add at least one item';
      notifyListeners();
      return null;
    }

    final bool hasInvalidProduct = _items.any(
      (InvoiceItem it) => it.productId.trim().isEmpty,
    );
    if (hasInvalidProduct) {
      _errorMessage = 'Please select a valid product for each item';
      notifyListeners();
      return null;
    }

    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final String invoiceType = _apiInvoiceType(_invoiceType);
      final String paymentTerms = _apiPaymentTerms(_paymentTerms);

      Invoice created = await _invoiceRepository.createInvoice(
        companyId: companyId.trim(),
        customerId: customerId.trim(),
        invoiceDate: issue,
        dueDate: due,
        items: List<InvoiceItem>.unmodifiable(_items),
        currency: _currency,
        invoiceType: invoiceType,
        paymentTerms: paymentTerms,
        notes: notesController.text.trim(),
        discount: 0,
      );

      if (!draft) {
        final String id = created.invoiceNo;
        if (id.trim().isNotEmpty) {
          created = await _invoiceRepository.updateInvoiceStatus(
            invoiceId: id,
            status: 'sent',
          );
        }
      }

      return created;
    } catch (e) {
      _errorMessage = e.toString();
      return null;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  String _company = 'Tech Solutions Ltd.';
  String _customerType = 'B2B (Business)';
  String _invoiceType = 'CI-Tax invoice (B2B)';
  String _currency = 'SAR';
  String _paymentTerms = 'Immediate';

  String get company => _company;
  String get customerType => _customerType;
  String get invoiceType => _invoiceType;
  String get currency => _currency;
  String get paymentTerms => _paymentTerms;

  List<String> get zatcaInvoiceTypeOptions {
    final String lower = _customerType.toLowerCase();
    final bool isB2c = lower.contains('b2c');
    if (isB2c) {
      return const <String>[
        'SI-Simplified Tax invoice(B2C)',
        'SP-Simplified Prepayment(B2C)',
        'SD-Simplified Debit Note(B2C)',
        'SN-Simplified Credit Note(B2C)',
      ];
    }
    return const <String>[
      'CI-Tax invoice (B2B)',
      'CP-Prepayment(B2B)',
      'CD-Tax Debit Note(B2B)',
      'CN-Tax Credit Note(B2B)',
    ];
  }

  void refresh() {
    notifyListeners();
  }

  set company(String v) {
    if (v == _company) return;
    _company = v;
    notifyListeners();
  }

  set customerType(String v) {
    if (v == _customerType) return;
    _customerType = v;

    final List<String> options = zatcaInvoiceTypeOptions;
    if (!options.contains(_invoiceType)) {
      _invoiceType = options.isNotEmpty ? options.first : _invoiceType;
    }
    notifyListeners();
  }

  set invoiceType(String v) {
    if (v == _invoiceType) return;
    _invoiceType = v;
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

  String _apiInvoiceType(String label) {
    final String trimmed = label.trim();
    final String lower = trimmed.toLowerCase();
    if (lower.contains('(b2c)') || trimmed.startsWith('S')) {
      return 'simplified';
    }
    return 'standard';
  }

  String _apiPaymentTerms(String label) {
    final String lower = label.toLowerCase();
    if (lower.contains('immediate')) return '0';
    if (lower.contains('net 7')) return '7';
    if (lower.contains('net 15')) return '15';
    if (lower.contains('net 30')) return '30';
    return label;
  }

  DateTime? _issueDate;
  DateTime? _dueDate;

  DateTime? get issueDate => _issueDate;
  DateTime? get dueDate => _dueDate;

  void setIssueDate(DateTime? d) {
    _issueDate = d;
    notifyListeners();
  }

  void setDueDate(DateTime? d) {
    _dueDate = d;
    notifyListeners();
  }

  final TextEditingController invoiceNumberController = TextEditingController(
    text: 'INV-2023-001',
  );
  final TextEditingController customerController = TextEditingController();
  final TextEditingController notesController = TextEditingController();
  final TextEditingController termsController = TextEditingController();

  final List<InvoiceItem> _items = <InvoiceItem>[];

  List<InvoiceItem> get items => List<InvoiceItem>.unmodifiable(_items);

  void addItem(InvoiceItem item) {
    _items.add(item);
    notifyListeners();
  }

  void removeItemAt(int index) {
    if (index < 0 || index >= _items.length) return;
    _items.removeAt(index);
    notifyListeners();
  }

  void incrementQtyAt(int index) {
    if (index < 0 || index >= _items.length) return;
    final InvoiceItem cur = _items[index];
    _items[index] = InvoiceItem(
      productId: cur.productId,
      product: cur.product,
      qty: cur.qty + 1,
      price: cur.price,
      discount: cur.discount,
      vatCategory: cur.vatCategory,
      taxPercent: cur.taxPercent,
    );
    notifyListeners();
  }

  void decrementQtyAt(int index) {
    if (index < 0 || index >= _items.length) return;
    final InvoiceItem cur = _items[index];
    if (cur.qty <= 1) {
      removeItemAt(index);
      return;
    }
    _items[index] = InvoiceItem(
      productId: cur.productId,
      product: cur.product,
      qty: cur.qty - 1,
      price: cur.price,
      discount: cur.discount,
      vatCategory: cur.vatCategory,
      taxPercent: cur.taxPercent,
    );
    notifyListeners();
  }

  void updateItemAt(int index, InvoiceItem item) {
    if (index < 0 || index >= _items.length) return;
    _items[index] = item;
    notifyListeners();
  }

  bool isStepValid(int step) {
    switch (step) {
      case 0:
        return invoiceNumberController.text.trim().isNotEmpty &&
            _issueDate != null &&
            _dueDate != null;
      case 1:
        return customerController.text.trim().isNotEmpty;
      case 2:
        return true;
      case 3:
        return true;
      default:
        return false;
    }
  }

  bool nextStep() {
    if (!isStepValid(_currentStep)) {
      return false;
    }
    if (_currentStep >= 3) {
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
    if (_currentStep == 0) {
      return;
    }
    _currentStep--;
    notifyListeners();
  }

  void goToStep(int step) {
    if (step < 0 || step > 3) {
      return;
    }
    if (step > _maxStepReached) {
      return;
    }
    _currentStep = step;
    notifyListeners();
  }

  double get subtotal {
    return _items.fold<double>(
      0,
      (double p, InvoiceItem e) => p + e.taxableAmount,
    );
  }

  double get vatAmount {
    return _items.fold<double>(0, (double p, InvoiceItem e) => p + e.taxAmount);
  }

  double get total {
    return _items.fold<double>(0, (double p, InvoiceItem e) => p + e.total);
  }

  String? validateSubmit({required bool draft}) {
    if (invoiceNumberController.text.trim().isEmpty) {
      return draft
          ? 'Please enter invoice number and customer to save draft'
          : 'Please complete invoice number, customer, and add at least one item';
    }
    if (customerController.text.trim().isEmpty) {
      return draft
          ? 'Please enter invoice number and customer to save draft'
          : 'Please complete invoice number, customer, and add at least one item';
    }
    if (!draft && _items.isEmpty) {
      return 'Please complete invoice number, customer, and add at least one item';
    }
    return null;
  }

  Invoice buildInvoice({required InvoiceStatus status}) {
    return Invoice(
      id: invoiceNumberController.text.trim(),
      invoiceNo: invoiceNumberController.text.trim(),
      customer: customerController.text.trim(),
      issueDate: _issueDate ?? DateTime.now(),
      dueDate: _dueDate,
      currency: _currency,
      status: status,
      company: _company,
      customerType: _customerType,
      invoiceType: _invoiceType,
      paymentTerms: _paymentTerms,
      items: List<InvoiceItem>.unmodifiable(_items),
      notes: notesController.text.trim(),
      terms: termsController.text.trim(),
    );
  }

  @override
  void dispose() {
    invoiceNumberController.dispose();
    customerController.dispose();
    notesController.dispose();
    termsController.dispose();
    super.dispose();
  }
}
