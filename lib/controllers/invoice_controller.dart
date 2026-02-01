import 'package:flutter/material.dart';

import '../models/invoice.dart';
import '../repositories/invoice_repository.dart';

class InvoiceController extends ChangeNotifier {
  InvoiceRepository _repository;
  List<Invoice> _invoices = <Invoice>[];

  bool _isLoading = false;
  String? _errorMessage;

  InvoiceController({required InvoiceRepository repository})
    : _repository = repository;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  void updateRepository(InvoiceRepository repository) {
    _repository = repository;
  }

  InvoiceStatus? _statusFilter;
  DateTimeRange? _dateRange;
  String _searchQuery = '';

  List<Invoice> get invoices => List<Invoice>.unmodifiable(_invoices);
  InvoiceStatus? get statusFilter => _statusFilter;
  DateTimeRange? get dateRange => _dateRange;
  String get searchQuery => _searchQuery;

  Future<void> loadInvoices({String? companyId}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _invoices = await _repository.getInvoices(companyId: companyId);
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setSearchQuery(String q) {
    final String next = q.trim();
    if (next == _searchQuery) {
      return;
    }
    _searchQuery = next;
    notifyListeners();
  }

  void setStatusFilter(InvoiceStatus? status) {
    if (status == _statusFilter) {
      return;
    }
    _statusFilter = status;
    notifyListeners();
  }

  void setDateRange(DateTimeRange? range) {
    _dateRange = range;
    notifyListeners();
  }

  bool _inDateRange(DateTime d) {
    if (_dateRange == null) {
      return true;
    }
    return !d.isBefore(_dateRange!.start) && !d.isAfter(_dateRange!.end);
  }

  List<Invoice> get visibleInvoices {
    final String q = _searchQuery.toLowerCase();
    return _invoices.where((Invoice inv) {
      final bool statusOk = _statusFilter == null
          ? true
          : inv.status == _statusFilter;
      final bool dateOk = _inDateRange(inv.issueDate);
      final bool searchOk = q.isEmpty
          ? true
          : inv.invoiceNo.toLowerCase().contains(q) ||
                inv.customer.toLowerCase().contains(q);
      return statusOk && dateOk && searchOk;
    }).toList();
  }

  void addInvoice(Invoice invoice) {
    _invoices.insert(0, invoice);
    notifyListeners();
  }

  String dateLabel(DateTime d) {
    const List<String> months = <String>[
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${d.day.toString().padLeft(2, '0')} ${months[d.month - 1]} ${d.year}';
  }

  String amountLabel(Invoice inv) {
    return '${inv.currency} ${_formatNumber(inv.total)}';
  }

  String _formatNumber(double v) {
    final bool asInt = (v - v.truncateToDouble()).abs() < 0.000001;
    final String s = asInt ? v.toStringAsFixed(0) : v.toStringAsFixed(2);
    final List<String> parts = s.split('.');
    final String intPart = parts[0];
    final String frac = parts.length > 1 ? '.${parts[1]}' : '';
    final String withCommas = intPart.replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (Match m) => ',',
    );
    return '$withCommas$frac';
  }
}
