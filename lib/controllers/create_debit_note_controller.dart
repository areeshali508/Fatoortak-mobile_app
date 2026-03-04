import 'package:flutter/material.dart';

import '../models/company.dart';
import '../models/debit_note.dart';
import '../models/invoice.dart';
import '../repositories/company_repository.dart';

class CreateDebitNoteController extends ChangeNotifier {
  final CompanyRepository _companyRepository;

  CreateDebitNoteController({required CompanyRepository companyRepository})
    : _companyRepository = companyRepository;

  int _currentStep = 0;
  int _maxStepReached = 0;

  bool _zatcaValidated = false;
  bool get zatcaValidated => _zatcaValidated;

  void setZatcaValidated(bool v) {
    if (_zatcaValidated == v) return;
    _zatcaValidated = v;
    notifyListeners();
  }

  int get currentStep => _currentStep;
  int get maxStepReached => _maxStepReached;

  String _company = 'Tech Solutions Ltd.';
  String _currency = 'SAR';

  String? _companyId;
  String? _customerId;
  String? _originalInvoiceId;
  DateTime? _dueDate;
  String _paymentTerms = 'Net 15 days';
  final String _debitNoteType = 'standard';

  bool _isLoadingCompanies = false;
  List<Company> _companies = const <Company>[];
  String? _errorMessage;

  bool get isLoadingCompanies => _isLoadingCompanies;
  List<Company> get companies => _companies;
  String? get errorMessage => _errorMessage;

  String get company => _company;
  String get currency => _currency;

  String? get companyId => _companyId;
  String? get customerId => _customerId;
  String? get originalInvoiceId => _originalInvoiceId;
  DateTime? get dueDate => _dueDate;
  String get paymentTerms => _paymentTerms;
  String get debitNoteType => _debitNoteType;

  Future<void> loadCompanies({int page = 1, int limit = 50}) async {
    _isLoadingCompanies = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _companies = await _companyRepository.listCompanies(page: page, limit: limit);

      final String curId = (_companyId ?? '').trim();
      if (curId.isEmpty && _companies.isNotEmpty) {
        final Company first = _companies.first;
        if (first.id.trim().isNotEmpty) {
          setCompany(companyId: first.id, companyName: first.name);
        }
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

  void setCompany({required String companyId, required String companyName}) {
    final String nextCompanyId = companyId.trim();
    final bool companyChanged = (_companyId ?? '').trim() != nextCompanyId;

    _companyId = nextCompanyId;
    _company = companyName;

    if (companyChanged) {
      _customerId = null;
      _originalInvoiceId = null;
      _originalInvoiceCustomerType = null;
      _dueDate = null;
      _paymentTerms = 'Net 15 days';

      originalInvoiceController.clear();
      customerController.clear();
      termsController.clear();

      _items.clear();
    }

    _zatcaValidated = false;
    notifyListeners();
  }

  set company(String v) {
    if (v == _company) return;
    _company = v;
    _zatcaValidated = false;
    notifyListeners();
  }

  set currency(String v) {
    if (v == _currency) return;
    _currency = v;
    _zatcaValidated = false;
    notifyListeners();
  }

  DateTime? _issueDate;

  DateTime? get issueDate => _issueDate;

  void setIssueDate(DateTime? d) {
    _issueDate = d;
    _zatcaValidated = false;
    notifyListeners();
  }

  void setDueDate(DateTime? d) {
    _dueDate = d;
    _zatcaValidated = false;
    notifyListeners();
  }

  void setPaymentTerms(String v) {
    final String next = v.trim();
    if (next == _paymentTerms) return;
    _paymentTerms = next;
    _zatcaValidated = false;
    notifyListeners();
  }

  final TextEditingController debitNoteNumberController = TextEditingController(
    text: 'DN-2024-001',
  );
  final TextEditingController originalInvoiceController =
      TextEditingController();
  final TextEditingController customerController = TextEditingController();
  final TextEditingController reasonDescriptionController =
      TextEditingController();
  final TextEditingController termsController = TextEditingController();

  String? _originalInvoiceCustomerType;
  String? get originalInvoiceCustomerType => _originalInvoiceCustomerType;

  String get customerType {
    final String src = (_originalInvoiceCustomerType ?? '').toLowerCase();
    if (src.contains('b2b')) {
      return 'B2B';
    }
    if (src.contains('b2c')) {
      return 'B2C';
    }
    return 'B2C';
  }

  String _reasonType = 'Select Reason';
  String get reasonType => _reasonType;

  set reasonType(String v) {
    if (v == _reasonType) return;
    _reasonType = v;
    _zatcaValidated = false;
    notifyListeners();
  }

  final List<DebitNoteItem> _items = <DebitNoteItem>[];
  List<DebitNoteItem> get items => List<DebitNoteItem>.unmodifiable(_items);

  void loadFromInvoice(Invoice invoice) {
    originalInvoiceController.text = invoice.invoiceNo;
    customerController.text = invoice.customer;
    _originalInvoiceCustomerType = invoice.customerType;
    _company = invoice.company;
    currency = invoice.currency;

    _originalInvoiceId = invoice.id;
    _companyId = invoice.companyId;
    _customerId = invoice.customerId;
    _paymentTerms = invoice.paymentTerms;
    _dueDate = invoice.dueDate;
    termsController.text = invoice.terms;

    _zatcaValidated = false;

    _items
      ..clear()
      ..addAll(
        invoice.items.map(
          (InvoiceItem it) => DebitNoteItem(
            description: it.product,
            qty: it.qty,
            price: it.price,
            discount: it.discount,
            vatCategory: it.vatCategory,
            taxPercent: it.taxPercent,
          ),
        ),
      );
    notifyListeners();
  }

  void addItem(DebitNoteItem item) {
    _items.add(item);
    _zatcaValidated = false;
    notifyListeners();
  }

  void removeItemAt(int index) {
    if (index < 0 || index >= _items.length) return;
    _items.removeAt(index);
    _zatcaValidated = false;
    notifyListeners();
  }

  void updateItemAt(int index, DebitNoteItem item) {
    if (index < 0 || index >= _items.length) return;
    _items[index] = item;
    _zatcaValidated = false;
    notifyListeners();
  }

  void incrementQtyAt(int index) {
    if (index < 0 || index >= _items.length) return;
    final DebitNoteItem cur = _items[index];
    _items[index] = DebitNoteItem(
      description: cur.description,
      qty: cur.qty + 1,
      price: cur.price,
      discount: cur.discount,
      vatCategory: cur.vatCategory,
      taxPercent: cur.taxPercent,
    );
    _zatcaValidated = false;
    notifyListeners();
  }

  void decrementQtyAt(int index) {
    if (index < 0 || index >= _items.length) return;
    final DebitNoteItem cur = _items[index];
    if (cur.qty <= 1) {
      removeItemAt(index);
      return;
    }
    _items[index] = DebitNoteItem(
      description: cur.description,
      qty: cur.qty - 1,
      price: cur.price,
      discount: cur.discount,
      vatCategory: cur.vatCategory,
      taxPercent: cur.taxPercent,
    );
    _zatcaValidated = false;
    notifyListeners();
  }

  void resetZatcaValidation() {
    if (!_zatcaValidated) return;
    _zatcaValidated = false;
    notifyListeners();
  }

  String? validateZatcaDummy() {
    final String? msg = validateSubmit();
    if (msg != null) {
      return msg;
    }
    if (_items.isEmpty) {
      return 'Please add at least one item before validation';
    }
    _zatcaValidated = true;
    notifyListeners();
    return null;
  }

  double get subtotal => _items.fold<double>(
    0,
    (double p, DebitNoteItem e) => p + e.taxableAmount,
  );

  double get vatAmount =>
      _items.fold<double>(0, (double p, DebitNoteItem e) => p + e.taxAmount);

  double get total =>
      _items.fold<double>(0, (double p, DebitNoteItem e) => p + e.total);

  bool isStepValid(int step) {
    switch (step) {
      case 0:
        return debitNoteNumberController.text.trim().isNotEmpty &&
            _issueDate != null &&
            originalInvoiceController.text.trim().isNotEmpty &&
            customerController.text.trim().isNotEmpty;
      case 1:
        return _items.isNotEmpty;
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
    if (debitNoteNumberController.text.trim().isEmpty ||
        customerController.text.trim().isEmpty ||
        originalInvoiceController.text.trim().isEmpty ||
        _issueDate == null) {
      return 'Please complete required fields before saving';
    }

    if ((_companyId ?? '').trim().isEmpty) {
      return 'Company is required';
    }
    if ((_customerId ?? '').trim().isEmpty) {
      return 'Customer is required';
    }
    if ((_originalInvoiceId ?? '').trim().isEmpty) {
      return 'Original invoice is required';
    }
    if (_items.isEmpty) {
      return 'Please add at least one item';
    }
    return null;
  }

  String _fmtYmd(DateTime d) {
    final String yy = d.year.toString().padLeft(4, '0');
    final String mm = d.month.toString().padLeft(2, '0');
    final String dd = d.day.toString().padLeft(2, '0');
    return '$yy-$mm-$dd';
  }

  String _mapReasonCode(String label) {
    final String s = label.toLowerCase().trim();
    if (s.contains('price')) return 'price_adjustment';
    if (s.contains('service')) return 'service_fee';
    if (s.contains('other')) return 'other';
    if (s.contains('correction')) return 'invoice_correction';
    if (s.contains('additional')) return 'additional_charge';
    return 'additional_charge';
  }

  String _normalizePaymentTerms(String v) {
    final String s = v.trim();
    if (s.isEmpty) return s;
    final RegExp netDays = RegExp(r'^net\s+(\d+)$', caseSensitive: false);
    final RegExpMatch? m = netDays.firstMatch(s);
    if (m != null) {
      return 'Net ${m.group(1)} days';
    }
    return s;
  }

  Map<String, dynamic> buildCreatePayload({String status = 'draft'}) {
    final DateTime issue = _issueDate ?? DateTime.now();
    final DateTime due = _dueDate ?? issue.add(const Duration(days: 30));

    return <String, dynamic>{
      'companyId': (_companyId ?? '').trim(),
      'customerId': (_customerId ?? '').trim(),
      'originalInvoiceId': (_originalInvoiceId ?? '').trim(),
      'debitNoteNumber': debitNoteNumberController.text.trim(),
      'debitNoteType': _debitNoteType,
      'currency': _currency,
      'issueDate': _fmtYmd(issue),
      'dueDate': _fmtYmd(due),
      'paymentTerms': _normalizePaymentTerms(_paymentTerms),
      'reason': _mapReasonCode(_reasonType),
      'reasonDescription': reasonDescriptionController.text.trim(),
      'notes': '',
      'termsAndConditions': termsController.text.trim(),
      'status': status,
      'items': _items
          .map(
            (DebitNoteItem it) => <String, dynamic>{
              'description': it.description,
              'quantity': it.qty,
              'unitPrice': it.price,
              'taxRate': it.taxPercent,
              'discount': it.discount,
            },
          )
          .toList(),
    };
  }

  DebitNote buildDebitNote({DebitNoteStatus status = DebitNoteStatus.draft}) {
    return DebitNote(
      id: debitNoteNumberController.text.trim(),
      customer: customerController.text.trim(),
      customerType: customerType,
      issueDate: _issueDate ?? DateTime.now(),
      currency: _currency,
      amount: total,
      status: status,
      items: List<DebitNoteItem>.unmodifiable(_items),
      originalInvoiceNo: originalInvoiceController.text.trim(),
      originalInvoiceCustomerType: _originalInvoiceCustomerType,
    );
  }

  DebitNote buildSubmitted({required String uuid, required String hash}) {
    final DebitNoteStatus finalStatus =
        (_originalInvoiceCustomerType ?? '').toLowerCase().contains('b2b')
        ? DebitNoteStatus.cleared
        : DebitNoteStatus.reported;

    return DebitNote(
      id: debitNoteNumberController.text.trim(),
      customer: customerController.text.trim(),
      customerType: customerType,
      issueDate: _issueDate ?? DateTime.now(),
      currency: _currency,
      amount: total,
      status: finalStatus,
      items: List<DebitNoteItem>.unmodifiable(_items),
      originalInvoiceNo: originalInvoiceController.text.trim(),
      originalInvoiceCustomerType: _originalInvoiceCustomerType,
      zatcaUuid: uuid,
      zatcaHash: hash,
    );
  }

  @override
  void dispose() {
    debitNoteNumberController.dispose();
    originalInvoiceController.dispose();
    customerController.dispose();
    reasonDescriptionController.dispose();
    termsController.dispose();
    super.dispose();
  }
}
