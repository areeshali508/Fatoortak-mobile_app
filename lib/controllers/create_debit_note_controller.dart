import 'package:flutter/material.dart';

import '../models/debit_note.dart';
import '../models/invoice.dart';

class CreateDebitNoteController extends ChangeNotifier {
  int _currentStep = 0;
  int _maxStepReached = 0;

  bool _zatcaValidated = false;
  bool get zatcaValidated => _zatcaValidated;

  int get currentStep => _currentStep;
  int get maxStepReached => _maxStepReached;

  String _company = 'Tech Solutions Ltd.';
  String _currency = 'SAR';

  String get company => _company;
  String get currency => _currency;

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
    currency = invoice.currency;

    _zatcaValidated = false;

    _items
      ..clear()
      ..addAll(
        invoice.items.map(
          (InvoiceItem it) => DebitNoteItem(
            description: it.product,
            qty: it.qty,
            price: it.price,
            discountPercent: it.discountPercent,
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
      discountPercent: cur.discountPercent,
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
      discountPercent: cur.discountPercent,
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
    return null;
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
