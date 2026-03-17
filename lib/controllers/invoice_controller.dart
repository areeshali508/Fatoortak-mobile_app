import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../models/invoice.dart';
import '../repositories/invoice_repository.dart';

class InvoiceController extends ChangeNotifier {
  InvoiceRepository _repository;
  List<Invoice> _invoices = <Invoice>[];

  List<Invoice> _visibleInvoices = const <Invoice>[];
  bool _visibleDirty = true;

  bool _isLoading = false;
  String? _errorMessage;

  InvoiceController({required InvoiceRepository repository})
    : _repository = repository;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  void updateRepository(InvoiceRepository repository) {
    _repository = repository;
  }

  Future<Invoice?> updateInvoiceStatus({
    required String invoiceId,
    required InvoiceStatus status,
  }) async {
    final String id = invoiceId.trim();
    if (id.isEmpty) {
      _errorMessage = 'Invoice id is required';
      notifyListeners();
      return null;
    }

    final String apiStatus = status.name;

    _errorMessage = null;
    notifyListeners();

    try {
      final Invoice updated = await _repository.updateInvoiceStatus(
        invoiceId: id,
        status: apiStatus,
      );
      final int idx = _invoices.indexWhere((Invoice inv) => inv.id == updated.id);
      if (idx >= 0) {
        _invoices[idx] = updated;
      }
      notifyListeners();
      return updated;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return null;
    }
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
      // Avoid fetching all pages on Flutter Web for better responsiveness.
      final bool fetchAll = !kIsWeb;
      final List<Invoice> list = await _repository.getInvoices(
        companyId: companyId,
        page: 1,
        limit: 100,
        fetchAll: fetchAll,
      );

      _invoices = list;
      _visibleDirty = true;

      debugPrint(
        'INVOICES loaded count=${_invoices.length} companyId=${(companyId ?? '').trim()} fetchAll=$fetchAll',
      );
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Invoice?> refreshInvoiceById({required String invoiceId}) async {
    final String id = invoiceId.trim();
    if (id.isEmpty) {
      _errorMessage = 'Invoice id is required';
      notifyListeners();
      return null;
    }

    _errorMessage = null;
    notifyListeners();

    try {
      final Invoice updated = await _repository.getInvoiceById(invoiceId: id);
      final int idx = _invoices.indexWhere((Invoice inv) => inv.id == updated.id);
      if (idx >= 0) {
        _invoices[idx] = updated;
      } else {
        _invoices.insert(0, updated);
      }
      notifyListeners();
      return updated;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return null;
    }
  }

  void setSearchQuery(String q) {
    final String next = q.trim();
    if (next == _searchQuery) {
      return;
    }
    _searchQuery = next;
    _visibleDirty = true;
    notifyListeners();
  }

  void setStatusFilter(InvoiceStatus? status) {
    if (status == _statusFilter) {
      return;
    }
    _statusFilter = status;
    _visibleDirty = true;
    notifyListeners();
  }

  void setDateRange(DateTimeRange? range) {
    _dateRange = range;
    _visibleDirty = true;
    notifyListeners();
  }

  bool _inDateRange(DateTime d) {
    if (_dateRange == null) {
      return true;
    }
    return !d.isBefore(_dateRange!.start) && !d.isAfter(_dateRange!.end);
  }

  List<Invoice> get visibleInvoices {
    if (_visibleDirty) {
      final String q = _searchQuery.toLowerCase();
      final List<Invoice> next = _invoices.where((Invoice inv) {
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
      _visibleInvoices = List<Invoice>.unmodifiable(next);
      _visibleDirty = false;
    }
    return _visibleInvoices;
  }

  void addInvoice(Invoice invoice) {
    _invoices.insert(0, invoice);
    _visibleDirty = true;
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
