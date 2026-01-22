import 'package:flutter/material.dart';

import '../models/debit_note.dart';
import '../repositories/debit_note_repository.dart';

class DebitNotesController extends ChangeNotifier {
  final DebitNoteRepository _repository;

  bool _isLoading = false;
  String _searchQuery = '';
  DateTimeRange? _dateRange;
  DebitNoteStatus? _statusFilter;
  DebitNotePaymentStatus? _paymentStatusFilter;
  List<DebitNote> _notes = const <DebitNote>[];

  DebitNotesController({required DebitNoteRepository repository})
      : _repository = repository;

  bool get isLoading => _isLoading;

  String get searchQuery => _searchQuery;

  DateTimeRange? get dateRange => _dateRange;

  DebitNoteStatus? get statusFilter => _statusFilter;

  DebitNotePaymentStatus? get paymentStatusFilter => _paymentStatusFilter;

  List<DebitNote> get notes => _notes;

  Future<void> addDebitNote(DebitNote note) async {
    _notes = <DebitNote>[note, ..._notes];
    notifyListeners();
    await _repository.addDebitNote(note);
  }

  Future<void> refresh() async {
    _isLoading = true;
    notifyListeners();
    try {
      _notes = await _repository.listDebitNotes();
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

  void setStatusFilter(DebitNoteStatus? status) {
    if (_statusFilter == status) {
      return;
    }
    _statusFilter = status;
    notifyListeners();
  }

  void setPaymentStatusFilter(DebitNotePaymentStatus? status) {
    if (_paymentStatusFilter == status) {
      return;
    }
    _paymentStatusFilter = status;
    notifyListeners();
  }

  List<DebitNote> get visibleNotes {
    final String q = _searchQuery.toLowerCase();
    Iterable<DebitNote> result = _notes;

    if (_statusFilter != null) {
      result = result.where((DebitNote n) => n.status == _statusFilter);
    }

    if (_paymentStatusFilter != null) {
      result = result.where(
        (DebitNote n) => n.paymentStatus == _paymentStatusFilter,
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
      result = result.where((DebitNote n) {
        final DateTime d = n.issueDate;
        return !d.isBefore(start) && !d.isAfter(end);
      });
    }

    if (q.isNotEmpty) {
      result = result.where(
        (DebitNote n) =>
            n.id.toLowerCase().contains(q) ||
            n.customer.toLowerCase().contains(q),
      );
    }

    return result.toList();
  }

  int get totalNotesCount => _notes.length;

  int get draftCount =>
      _notes.where((DebitNote n) => n.status == DebitNoteStatus.draft).length;

  int get clearedCount =>
      _notes.where((DebitNote n) => n.status == DebitNoteStatus.cleared).length;

  int get reportedCount => _notes
      .where((DebitNote n) => n.status == DebitNoteStatus.reported)
      .length;

  int get clearedOrReportedCount => clearedCount + reportedCount;

  double get debitsTotal => _notes.fold<double>(
        0,
        (double p, DebitNote e) => p + e.amount,
      );

  String get debitsLabel {
    const String currency = 'SAR';
    final double total = debitsTotal;
    final bool asInt = (total - total.truncateToDouble()).abs() < 0.000001;
    final String formatted =
        asInt ? total.toStringAsFixed(0) : total.toStringAsFixed(2);
    return '$currency $formatted';
  }

  String dateLabel(DateTime d) {
    final String day = d.day.toString().padLeft(2, '0');
    final String month = d.month.toString().padLeft(2, '0');
    return '$day/$month/${d.year}';
  }

  String amountLabel(DebitNote note) {
    final double total = note.amount;
    final bool asInt = (total - total.truncateToDouble()).abs() < 0.000001;
    final String formatted =
        asInt ? total.toStringAsFixed(0) : total.toStringAsFixed(2);
    return '${note.currency} $formatted';
  }

  String get statusFilterLabel {
    final DebitNoteStatus? s = _statusFilter;
    if (s == null) {
      return 'All Status';
    }
    switch (s) {
      case DebitNoteStatus.draft:
        return 'Draft';
      case DebitNoteStatus.submitted:
        return 'Submitted';
      case DebitNoteStatus.cleared:
        return 'Cleared';
      case DebitNoteStatus.reported:
        return 'Reported';
      case DebitNoteStatus.rejected:
        return 'Rejected';
    }
  }

  String get paymentStatusFilterLabel {
    final DebitNotePaymentStatus? s = _paymentStatusFilter;
    if (s == null) {
      return 'All Payment Status';
    }
    switch (s) {
      case DebitNotePaymentStatus.pending:
        return 'Pending';
      case DebitNotePaymentStatus.paid:
        return 'Paid';
      case DebitNotePaymentStatus.cancelled:
        return 'Cancelled';
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
