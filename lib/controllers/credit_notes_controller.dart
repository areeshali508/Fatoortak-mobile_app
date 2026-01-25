import 'package:flutter/material.dart';

import '../models/credit_note.dart';
import '../repositories/credit_note_repository.dart';

class CreditNotesController extends ChangeNotifier {
  final CreditNoteRepository _repository;

  bool _isLoading = false;
  String _searchQuery = '';
  DateTimeRange? _dateRange;
  CreditNoteStatus? _statusFilter;
  CreditNotePaymentStatus? _paymentStatusFilter;
  List<CreditNote> _notes = const <CreditNote>[];

  CreditNotesController({required CreditNoteRepository repository})
    : _repository = repository;

  bool get isLoading => _isLoading;

  String get searchQuery => _searchQuery;

  DateTimeRange? get dateRange => _dateRange;

  CreditNoteStatus? get statusFilter => _statusFilter;

  CreditNotePaymentStatus? get paymentStatusFilter => _paymentStatusFilter;

  List<CreditNote> get notes => _notes;

  Future<void> addCreditNote(CreditNote note) async {
    _notes = <CreditNote>[note, ..._notes];
    notifyListeners();
    await _repository.addCreditNote(note);
  }

  Future<void> refresh() async {
    _isLoading = true;
    notifyListeners();
    try {
      _notes = await _repository.listCreditNotes();
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

  void setStatusFilter(CreditNoteStatus? status) {
    if (_statusFilter == status) {
      return;
    }
    _statusFilter = status;
    notifyListeners();
  }

  void setPaymentStatusFilter(CreditNotePaymentStatus? status) {
    if (_paymentStatusFilter == status) {
      return;
    }
    _paymentStatusFilter = status;
    notifyListeners();
  }

  List<CreditNote> get visibleNotes {
    final String q = _searchQuery.toLowerCase();
    Iterable<CreditNote> result = _notes;

    if (_statusFilter != null) {
      result = result.where((CreditNote n) => n.status == _statusFilter);
    }

    if (_paymentStatusFilter != null) {
      result = result.where(
        (CreditNote n) => n.paymentStatus == _paymentStatusFilter,
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
      result = result.where((CreditNote n) {
        final DateTime d = n.issueDate;
        return !d.isBefore(start) && !d.isAfter(end);
      });
    }

    if (q.isNotEmpty) {
      result = result.where(
        (CreditNote n) =>
            n.id.toLowerCase().contains(q) ||
            n.customer.toLowerCase().contains(q),
      );
    }

    return result.toList();
  }

  int get totalNotesCount => _notes.length;

  int get draftCount =>
      _notes.where((CreditNote n) => n.status == CreditNoteStatus.draft).length;

  int get clearedCount => _notes
      .where((CreditNote n) => n.status == CreditNoteStatus.cleared)
      .length;

  int get reportedCount => _notes
      .where((CreditNote n) => n.status == CreditNoteStatus.reported)
      .length;

  int get clearedOrReportedCount => clearedCount + reportedCount;

  double get creditsTotal =>
      _notes.fold<double>(0, (double p, CreditNote e) => p + e.amount);

  String get creditsLabel {
    const String currency = 'SAR';
    final double total = creditsTotal;
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

  String amountLabel(CreditNote note) {
    final double total = note.amount;
    final bool asInt = (total - total.truncateToDouble()).abs() < 0.000001;
    final String formatted = asInt
        ? total.toStringAsFixed(0)
        : total.toStringAsFixed(2);
    return '${note.currency} $formatted';
  }

  String get statusFilterLabel {
    final CreditNoteStatus? s = _statusFilter;
    if (s == null) {
      return 'All Status';
    }
    switch (s) {
      case CreditNoteStatus.draft:
        return 'Draft';
      case CreditNoteStatus.submitted:
        return 'Submitted';
      case CreditNoteStatus.cleared:
        return 'Cleared';
      case CreditNoteStatus.reported:
        return 'Reported';
      case CreditNoteStatus.rejected:
        return 'Rejected';
    }
  }

  String get paymentStatusFilterLabel {
    final CreditNotePaymentStatus? s = _paymentStatusFilter;
    if (s == null) {
      return 'All Payment Status';
    }
    switch (s) {
      case CreditNotePaymentStatus.pending:
        return 'Pending';
      case CreditNotePaymentStatus.refunded:
        return 'Refunded';
      case CreditNotePaymentStatus.applied:
        return 'Applied';
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
