import 'package:flutter/material.dart';

import '../models/quotation.dart';

class CreateQuotationController extends ChangeNotifier {
  int _currentStep = 0;
  int _maxStepReached = 0;

  int get currentStep => _currentStep;
  int get maxStepReached => _maxStepReached;

  String _company = 'Tech Solutions Ltd.';
  String _currency = 'SAR';

  String get company => _company;
  String get currency => _currency;

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

  final TextEditingController quotationNumberController =
      TextEditingController(text: 'QTN-2026-001');
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

  void incrementQtyAt(int index) {
    if (index < 0 || index >= _items.length) return;
    final QuotationItem cur = _items[index];
    _items[index] = QuotationItem(
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

  double get vatAmount => _items.fold<double>(
        0,
        (double p, QuotationItem e) => p + e.taxAmount,
      );

  double get total => _items.fold<double>(
        0,
        (double p, QuotationItem e) => p + e.total,
      );

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
    if (quotationNumberController.text.trim().isEmpty ||
        customerController.text.trim().isEmpty ||
        _issueDate == null) {
      return 'Please complete required fields before saving';
    }
    return null;
  }

  Quotation buildQuotation({QuotationStatus status = QuotationStatus.draft}) {
    return Quotation(
      id: quotationNumberController.text.trim(),
      customer: customerController.text.trim(),
      issueDate: _issueDate ?? DateTime.now(),
      validUntil: _validUntil,
      currency: _currency,
      amount: total,
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
