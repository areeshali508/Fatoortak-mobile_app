import 'package:flutter/material.dart';

import 'dart:async';

import '../models/company.dart';
import '../models/credit_note.dart';
import '../repositories/company_repository.dart';
import '../repositories/credit_note_repository.dart';

class CreditNotesController extends ChangeNotifier {
  final CreditNoteRepository _repository;
  final CompanyRepository _companyRepository;

  bool _isLoading = false;
  String _searchQuery = '';
  DateTimeRange? _dateRange;
  CreditNoteStatus? _statusFilter;
  CreditNotePaymentStatus? _paymentStatusFilter;
  List<CreditNote> _notes = const <CreditNote>[];

  bool _isLoadingCompanies = false;
  List<Company> _companies = const <Company>[];
  String? _companyId;

  bool _isLoadingStats = false;
  int _statsTotalNotes = 0;
  int _statsDraftCount = 0;
  int _statsAppliedCount = 0;
  double _statsCreditsTotal = 0;

  CreditNotesController({
    required CreditNoteRepository repository,
    required CompanyRepository companyRepository,
  }) : _repository = repository,
       _companyRepository = companyRepository;

  bool get isLoading => _isLoading;

  bool get isLoadingCompanies => _isLoadingCompanies;
  List<Company> get companies => _companies;
  String? get companyId => _companyId;

  bool get isLoadingStats => _isLoadingStats;
  int get statsTotalNotes => _statsTotalNotes;
  int get statsDraftCount => _statsDraftCount;
  int get statsAppliedCount => _statsAppliedCount;
  double get statsCreditsTotal => _statsCreditsTotal;

  String get statsCreditsLabel {
    const String currency = 'SAR';
    final double total = _statsCreditsTotal;
    final bool asInt = (total - total.truncateToDouble()).abs() < 0.000001;
    final String formatted = asInt
        ? total.toStringAsFixed(0)
        : total.toStringAsFixed(2);
    return '$currency $formatted';
  }

  String get searchQuery => _searchQuery;

  DateTimeRange? get dateRange => _dateRange;

  CreditNoteStatus? get statusFilter => _statusFilter;

  CreditNotePaymentStatus? get paymentStatusFilter => _paymentStatusFilter;

  List<CreditNote> get notes => _notes;

  Future<void> loadCompanies({int page = 1, int limit = 50}) async {
    _isLoadingCompanies = true;
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

  void setCompanyId(String? id) {
    final String next = (id ?? '').trim();
    final String? normalized = next.isEmpty ? null : next;
    if (normalized == _companyId) return;
    _companyId = normalized;
    _statsTotalNotes = 0;
    _statsDraftCount = 0;
    _statsAppliedCount = 0;
    _statsCreditsTotal = 0;
    notifyListeners();
  }

  Future<void> addCreditNote(CreditNote note) async {
    _notes = <CreditNote>[note, ..._notes];
    notifyListeners();
    await _repository.addCreditNote(note);
  }

  Future<void> refresh({int page = 1, int limit = 10}) async {
    _isLoading = true;
    notifyListeners();
    try {
      _notes = await _repository.listCreditNotes(
        page: page,
        limit: limit,
        companyId: _companyId,
      );
    } finally {
      _isLoading = false;
      notifyListeners();
    }

    unawaited(_refreshStats());
  }

  Future<void> _refreshStats() async {
    if (_isLoadingStats) return;
    _isLoadingStats = true;
    notifyListeners();

    try {
      final String? cid = _companyId;
      const int pageLimit = 100;

      final ({
        List<CreditNote> notes,
        int total,
        int pages,
        int current,
        int limit,
      }) first = await _repository.listCreditNotesWithPagination(
        page: 1,
        limit: pageLimit,
        companyId: cid,
      );

      final List<CreditNote> all = <CreditNote>[...first.notes];
      final int pages = first.pages > 0 ? first.pages : 1;

      final List<int> remainingPages = <int>[
        for (int p = 2; p <= pages; p++) p,
      ];
      const int batchSize = 4;

      for (int i = 0; i < remainingPages.length; i += batchSize) {
        final int end = (i + batchSize < remainingPages.length)
            ? i + batchSize
            : remainingPages.length;
        final List<int> batch = remainingPages.sublist(i, end);
        final List<({
          List<CreditNote> notes,
          int total,
          int pages,
          int current,
          int limit,
        })> batchResults = await Future.wait(
          batch.map(
            (int currentPage) => _repository.listCreditNotesWithPagination(
              page: currentPage,
              limit: pageLimit,
              companyId: cid,
            ),
          ),
        );

        for (final ({
          List<CreditNote> notes,
          int total,
          int pages,
          int current,
          int limit,
        }) result in batchResults) {
          all.addAll(result.notes);
        }
      }

      final int totalNotes = first.total > 0 ? first.total : all.length;
      final int draftCount =
          all.where((CreditNote n) => n.status == CreditNoteStatus.draft).length;
      final int appliedCount = all
          .where((CreditNote n) => n.paymentStatus == CreditNotePaymentStatus.applied)
          .length;
      final double creditsTotal =
          all.fold<double>(0, (double p, CreditNote e) => p + e.amount);

      _statsTotalNotes = totalNotes;
      _statsDraftCount = draftCount;
      _statsAppliedCount = appliedCount;
      _statsCreditsTotal = creditsTotal;
    } catch (_) {
      _statsTotalNotes = 0;
      _statsDraftCount = 0;
      _statsAppliedCount = 0;
      _statsCreditsTotal = 0;
    } finally {
      _isLoadingStats = false;
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

    final String selectedCompanyId = (_companyId ?? '').trim();
    if (selectedCompanyId.isNotEmpty) {
      result = result.where((CreditNote n) {
        final String noteCompanyId = (n.companyId ?? '').trim();
        if (noteCompanyId.isEmpty) return false;
        return noteCompanyId == selectedCompanyId;
      });
    }

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
