import 'package:flutter/material.dart';

import '../models/invoice.dart';

class CreateInvoiceController extends ChangeNotifier {
  int _currentStep = 0;
  int _maxStepReached = 0;

  int get currentStep => _currentStep;
  int get maxStepReached => _maxStepReached;

  String _company = 'Tech Solutions Ltd.';
  String _customerType = 'B2B (Business)';
  String _invoiceType = 'Tax Invoice (Standard)';
  String _currency = 'SAR';
  String _paymentTerms = 'Immediate';

  String get company => _company;
  String get customerType => _customerType;
  String get invoiceType => _invoiceType;
  String get currency => _currency;
  String get paymentTerms => _paymentTerms;

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
      product: cur.product,
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
    final InvoiceItem cur = _items[index];
    if (cur.qty <= 1) {
      removeItemAt(index);
      return;
    }
    _items[index] = InvoiceItem(
      product: cur.product,
      qty: cur.qty - 1,
      price: cur.price,
      discountPercent: cur.discountPercent,
      vatCategory: cur.vatCategory,
      taxPercent: cur.taxPercent,
    );
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
