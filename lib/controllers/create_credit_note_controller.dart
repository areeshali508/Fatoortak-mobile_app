import 'package:flutter/material.dart';

import '../models/credit_note.dart';

class CreateCreditNoteController extends ChangeNotifier {
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

  DateTime? get issueDate => _issueDate;

  void setIssueDate(DateTime? d) {
    _issueDate = d;
    notifyListeners();
  }

  final TextEditingController creditNoteNumberController =
      TextEditingController(text: 'HNV-2024-001');
  final TextEditingController originalInvoiceController = TextEditingController();
  final TextEditingController customerController = TextEditingController();
  final TextEditingController reasonDescriptionController = TextEditingController();
  final TextEditingController termsController = TextEditingController();

  String _reasonType = 'Select Reason';
  String get reasonType => _reasonType;

  set reasonType(String v) {
    if (v == _reasonType) return;
    _reasonType = v;
    notifyListeners();
  }

  final List<CreditNoteItem> _items = <CreditNoteItem>[];
  List<CreditNoteItem> get items => List<CreditNoteItem>.unmodifiable(_items);

  void addItem(CreditNoteItem item) {
    _items.add(item);
    notifyListeners();
  }

  void removeItemAt(int index) {
    if (index < 0 || index >= _items.length) return;
    _items.removeAt(index);
    notifyListeners();
  }

  double get subtotal => _items.fold<double>(
        0,
        (double p, CreditNoteItem e) => p + e.taxableAmount,
      );

  double get vatAmount => _items.fold<double>(
        0,
        (double p, CreditNoteItem e) => p + e.taxAmount,
      );

  double get total => _items.fold<double>(
        0,
        (double p, CreditNoteItem e) => p + e.total,
      );

  bool isStepValid(int step) {
    switch (step) {
      case 0:
        return creditNoteNumberController.text.trim().isNotEmpty &&
            _issueDate != null &&
            originalInvoiceController.text.trim().isNotEmpty &&
            customerController.text.trim().isNotEmpty;
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
    if (creditNoteNumberController.text.trim().isEmpty ||
        customerController.text.trim().isEmpty ||
        originalInvoiceController.text.trim().isEmpty ||
        _issueDate == null) {
      return 'Please complete required fields before saving';
    }
    return null;
  }

  CreditNote buildCreditNote({CreditNoteStatus status = CreditNoteStatus.draft}) {
    return CreditNote(
      id: creditNoteNumberController.text.trim(),
      customer: customerController.text.trim(),
      issueDate: _issueDate ?? DateTime.now(),
      currency: _currency,
      amount: total,
      status: status,
      items: List<CreditNoteItem>.unmodifiable(_items),
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
