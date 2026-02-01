import 'package:flutter/material.dart';

import '../controllers/auth_controller.dart';
import '../models/quotation.dart';
import '../repositories/quotation_repository.dart';

class QuotationsController extends ChangeNotifier {
  final QuotationRepository _repository;
  final AuthController _auth;

  bool _isLoading = false;
  String _searchQuery = '';
  DateTimeRange? _dateRange;
  QuotationStatus? _statusFilter;
  QuotationOutcomeStatus? _outcomeStatusFilter;
  List<Quotation> _quotations = const <Quotation>[];

  QuotationsController({required QuotationRepository repository, required AuthController auth})
    : _repository = repository,
      _auth = auth;

  bool get isLoading => _isLoading;

  String get searchQuery => _searchQuery;

  DateTimeRange? get dateRange => _dateRange;

  QuotationStatus? get statusFilter => _statusFilter;

  QuotationOutcomeStatus? get outcomeStatusFilter => _outcomeStatusFilter;

  List<Quotation> get quotations => _quotations;

  Future<void> addQuotation(Quotation quotation) async {
    _quotations = <Quotation>[quotation, ..._quotations];
    notifyListeners();
  }

  Future<void> refresh() async {
    _isLoading = true;
    notifyListeners();
    try {
      Map<String, dynamic>? company = _auth.myCompany;
      String? companyId = (company?['_id'] ?? company?['id'])?.toString().trim();
      if (companyId == null || companyId.isEmpty) {
        await _auth.refreshMyCompany();
        company = _auth.myCompany;
        companyId = (company?['_id'] ?? company?['id'])?.toString().trim();
      }

      if (companyId == null || companyId.isEmpty) {
        _quotations = const <Quotation>[];
        return;
      }

      _quotations = await _repository.listQuotations(
        companyId: companyId,
        page: 1,
        limit: 50,
        status: _statusFilter == null
            ? null
            : (_statusFilter == QuotationStatus.sent ? 'sent' : 'draft'),
      );
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setSearchQuery(String v) {
    final String next = v.trim();
    if (next == _searchQuery) {
      return;
    }
    _searchQuery = next;
    notifyListeners();
  }

  void setDateRange(DateTimeRange? range) {
    if (_dateRange == range) {
      return;
    }
    _dateRange = range;
    notifyListeners();
  }

  void setStatusFilter(QuotationStatus? status) {
    if (_statusFilter == status) {
      return;
    }
    _statusFilter = status;
    notifyListeners();
  }

  void setOutcomeStatusFilter(QuotationOutcomeStatus? status) {
    if (_outcomeStatusFilter == status) {
      return;
    }
    _outcomeStatusFilter = status;
    notifyListeners();
  }

  List<Quotation> get visibleQuotations {
    final String q = _searchQuery.toLowerCase();
    Iterable<Quotation> result = _quotations;

    if (_statusFilter != null) {
      result = result.where((Quotation n) => n.status == _statusFilter);
    }

    if (_outcomeStatusFilter != null) {
      result = result.where(
        (Quotation n) => n.outcomeStatus == _outcomeStatusFilter,
      );
    }

    if (_dateRange != null) {
      final DateTime start = DateTime(
        _dateRange!.start.year,
        _dateRange!.start.month,
        _dateRange!.start.day,
      );
      final DateTime end = DateTime(
        _dateRange!.end.year,
        _dateRange!.end.month,
        _dateRange!.end.day,
        23,
        59,
        59,
      );
      result = result.where((Quotation n) {
        final DateTime d = n.issueDate;
        return !d.isBefore(start) && !d.isAfter(end);
      });
    }

    if (q.isNotEmpty) {
      result = result.where(
        (Quotation n) =>
            n.id.toLowerCase().contains(q) ||
            n.customer.toLowerCase().contains(q),
      );
    }

    return result.toList();
  }

  int get totalQuotationsCount => _quotations.length;

  int get draftCount => _quotations
      .where((Quotation n) => n.status == QuotationStatus.draft)
      .length;

  int get sentCount => _quotations
      .where((Quotation n) => n.status == QuotationStatus.sent)
      .length;

  double get quotationsTotal =>
      _quotations.fold<double>(0, (double p, Quotation e) => p + e.amount);

  String get quotationsLabel {
    const String currency = 'SAR';
    final double total = quotationsTotal;
    final bool asInt = (total - total.truncateToDouble()).abs() < 0.000001;
    final String formatted = asInt
        ? total.toStringAsFixed(0)
        : total.toStringAsFixed(2);
    return '$currency $formatted';
  }

  String dateLabel(DateTime d) {
    final String day = d.day.toString().padLeft(2, '0');
    final String month = d.month.toString().padLeft(2, '0');
    return '$day/$month/${d.year}';
  }

  String amountLabel(Quotation quotation) {
    final double total = quotation.amount;
    final bool asInt = (total - total.truncateToDouble()).abs() < 0.000001;
    final String formatted = asInt
        ? total.toStringAsFixed(0)
        : total.toStringAsFixed(2);
    return '${quotation.currency} $formatted';
  }

  String get statusFilterLabel {
    final QuotationStatus? s = _statusFilter;
    if (s == null) {
      return 'All Status';
    }
    switch (s) {
      case QuotationStatus.draft:
        return 'Draft';
      case QuotationStatus.sent:
        return 'Sent';
    }
  }

  String get outcomeStatusFilterLabel {
    final QuotationOutcomeStatus? s = _outcomeStatusFilter;
    if (s == null) {
      return 'All Outcomes';
    }
    switch (s) {
      case QuotationOutcomeStatus.pending:
        return 'Pending';
      case QuotationOutcomeStatus.accepted:
        return 'Accepted';
      case QuotationOutcomeStatus.declined:
        return 'Declined';
      case QuotationOutcomeStatus.expired:
        return 'Expired';
    }
  }

  String get dateRangeLabel {
    final DateTimeRange? r = _dateRange;
    if (r == null) {
      return 'Date';
    }

    String d(DateTime v) {
      final String day = v.day.toString().padLeft(2, '0');
      final String month = v.month.toString().padLeft(2, '0');
      return '$day/$month';
    }

    return '${d(r.start)} - ${d(r.end)}';
  }
}
