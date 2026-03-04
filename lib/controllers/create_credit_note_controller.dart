import 'package:flutter/material.dart';

import '../models/company.dart';
import '../models/credit_note.dart';
import '../models/invoice.dart';
import '../repositories/company_repository.dart';
import '../repositories/credit_note_repository.dart';

class CreateCreditNoteController extends ChangeNotifier {
  final CompanyRepository _companyRepository;
  final CreditNoteRepository _creditNoteRepository;

  CreateCreditNoteController({
    required CompanyRepository companyRepository,
    required CreditNoteRepository creditNoteRepository,
  }) : _companyRepository = companyRepository,
       _creditNoteRepository = creditNoteRepository,
       super();

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

  bool _isLoadingCompanies = false;
  String? _errorMessage;
  List<Company> _companies = const <Company>[];

  bool get isLoadingCompanies => _isLoadingCompanies;
  String? get errorMessage => _errorMessage;
  List<Company> get companies => _companies;

  String get company => _company;
  String get currency => _currency;

  set company(String v) {
    if (v == _company) return;
    _company = v;
    _zatcaValidated = false;
    notifyListeners();
  }

  Future<void> loadCompanies({int page = 1, int limit = 50}) async {
    _isLoadingCompanies = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _companies = await _companyRepository.listCompanies(page: page, limit: limit);
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
    _companyId = companyId.trim();
    _company = companyName;
    _zatcaValidated = false;
    
    _customerId = null;
    _originalInvoiceId = null;
    _originalInvoiceCustomerType = null;
    customerController.clear();
    originalInvoiceController.clear();
    _items.clear();
    
    notifyListeners();
  }

  Future<void> loadNextNumber() async {
    final String cid = (_companyId ?? '').trim();
    if (cid.isEmpty) return;

    try {
      final String? next =
          await _creditNoteRepository.getNextCreditNoteNumber(companyId: cid);
      if (next == null || next.trim().isEmpty) return;

      creditNoteNumberController.text = next.trim();
      _zatcaValidated = false;
      notifyListeners();
    } catch (_) {
      return;
    }
  }

  Map<String, dynamic> buildCreatePayload({required String status}) {
    final String? msg = validateSubmit();
    if (msg != null) {
      throw ArgumentError(msg);
    }

    final String cId = (_companyId ?? '').trim();
    if (cId.isEmpty) {
      throw ArgumentError('Company id is required');
    }
    final String custId = (_customerId ?? '').trim();
    if (custId.isEmpty) {
      throw ArgumentError('Customer id is required');
    }
    final String invId = (_originalInvoiceId ?? '').trim();
    if (invId.isEmpty) {
      throw ArgumentError('Original invoice id is required');
    }

    final DateTime d = _issueDate ?? DateTime.now();
    final String yyyy = d.year.toString().padLeft(4, '0');
    final String mm = d.month.toString().padLeft(2, '0');
    final String dd = d.day.toString().padLeft(2, '0');
    final String dateOnly = '$yyyy-$mm-$dd';

    final List<Map<String, dynamic>> apiItems = _items.map((CreditNoteItem it) {
      return <String, dynamic>{
        'description': it.description,
        'quantity': it.qty,
        'unitPrice': it.price,
        'taxRate': it.taxPercent,
        'discount': it.discount,
      };
    }).toList();

    final String reasonApi = (_reasonType == 'Product Return')
        ? 'return'
        : (_reasonType == 'Discount Adjustment')
            ? 'return'
            : (_reasonType == 'Invoice Correction')
                ? 'return'
                : (_reasonType == 'Cancellation')
                    ? 'return'
                    : (_reasonType == 'Other')
                        ? 'return'
                        : 'return';

    return <String, dynamic>{
      'companyId': cId,
      'customerId': custId,
      'creditNoteNumber': creditNoteNumberController.text.trim(),
      'currency': _currency,
      'issueDate': dateOnly,
      'items': apiItems,
      'notes': '',
      'originalInvoiceId': invId,
      'reason': reasonApi,
      'reasonDescription': reasonDescriptionController.text.trim(),
      'status': status,
      'termsAndConditions': termsController.text.trim(),
    };
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

  final TextEditingController creditNoteNumberController =
      TextEditingController(text: 'HNV-2024-001');
  final TextEditingController originalInvoiceController =
      TextEditingController();
  final TextEditingController customerController = TextEditingController();
  final TextEditingController reasonDescriptionController =
      TextEditingController();
  final TextEditingController termsController = TextEditingController();

  String? _companyId;
  String? _customerId;
  String? _originalInvoiceId;

  String? get companyId => _companyId;
  String? get customerId => _customerId;
  String? get originalInvoiceId => _originalInvoiceId;

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

  final List<CreditNoteItem> _items = <CreditNoteItem>[];
  List<CreditNoteItem> get items => List<CreditNoteItem>.unmodifiable(_items);

  void loadFromInvoice(Invoice invoice) {
    originalInvoiceController.text = invoice.invoiceNo;
    customerController.text = invoice.customer;
    _originalInvoiceCustomerType = invoice.customerType;
    currency = invoice.currency;

    _originalInvoiceId = invoice.id;
    _companyId = invoice.companyId;
    _customerId = invoice.customerId;

    final String invCompanyName = invoice.company.trim();
    if (invCompanyName.isNotEmpty) {
      _company = invCompanyName;
    }

    _zatcaValidated = false;

    _items
      ..clear()
      ..addAll(
        invoice.items.map(
          (InvoiceItem it) => CreditNoteItem(
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

  void addItem(CreditNoteItem item) {
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

  void updateItemAt(int index, CreditNoteItem item) {
    if (index < 0 || index >= _items.length) return;
    _items[index] = item;
    _zatcaValidated = false;
    notifyListeners();
  }

  void incrementQtyAt(int index) {
    if (index < 0 || index >= _items.length) return;
    final CreditNoteItem cur = _items[index];
    _items[index] = CreditNoteItem(
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
    final CreditNoteItem cur = _items[index];
    if (cur.qty <= 1) {
      removeItemAt(index);
      return;
    }
    _items[index] = CreditNoteItem(
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

  double get subtotal => -_items.fold<double>(
    0,
    (double p, CreditNoteItem e) => p + e.taxableAmount,
  );

  double get vatAmount =>
      -_items.fold<double>(0, (double p, CreditNoteItem e) => p + e.taxAmount);

  double get total =>
      -_items.fold<double>(0, (double p, CreditNoteItem e) => p + e.total);

  bool isStepValid(int step) {
    switch (step) {
      case 0:
        return creditNoteNumberController.text.trim().isNotEmpty &&
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
    if (creditNoteNumberController.text.trim().isEmpty ||
        customerController.text.trim().isEmpty ||
        originalInvoiceController.text.trim().isEmpty ||
        _issueDate == null) {
      return 'Please complete required fields before saving';
    }
    return null;
  }

  CreditNote buildCreditNote({
    CreditNoteStatus status = CreditNoteStatus.draft,
  }) {
    return CreditNote(
      id: creditNoteNumberController.text.trim(),
      customer: customerController.text.trim(),
      customerType: customerType,
      issueDate: _issueDate ?? DateTime.now(),
      currency: _currency,
      amount: total,
      status: status,
      items: List<CreditNoteItem>.unmodifiable(_items),
      originalInvoiceNo: originalInvoiceController.text.trim(),
      originalInvoiceCustomerType: _originalInvoiceCustomerType,
    );
  }

  CreditNote buildSubmitted({required String uuid, required String hash}) {
    final CreditNoteStatus finalStatus =
        (_originalInvoiceCustomerType ?? '').toLowerCase().contains('b2b')
        ? CreditNoteStatus.cleared
        : CreditNoteStatus.reported;

    return CreditNote(
      id: creditNoteNumberController.text.trim(),
      customer: customerController.text.trim(),
      customerType: customerType,
      issueDate: _issueDate ?? DateTime.now(),
      currency: _currency,
      amount: total,
      status: finalStatus,
      items: List<CreditNoteItem>.unmodifiable(_items),
      originalInvoiceNo: originalInvoiceController.text.trim(),
      originalInvoiceCustomerType: _originalInvoiceCustomerType,
      zatcaUuid: uuid,
      zatcaHash: hash,
    );
  }

  @override
  void dispose() {
    creditNoteNumberController.dispose();
    originalInvoiceController.dispose();
    customerController.dispose();
    reasonDescriptionController.dispose();
    termsController.dispose();
    super.dispose();
  }
}
