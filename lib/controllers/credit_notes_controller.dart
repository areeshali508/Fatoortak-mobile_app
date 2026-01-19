import 'package:flutter/material.dart';

import '../models/credit_note.dart';
import '../repositories/credit_note_repository.dart';

class CreditNotesController extends ChangeNotifier {
  final CreditNoteRepository _repository;

  bool _isLoading = false;
  String _searchQuery = '';
  List<CreditNote> _notes = const <CreditNote>[];

  CreditNotesController({required CreditNoteRepository repository})
      : _repository = repository;

  bool get isLoading => _isLoading;

  String get searchQuery => _searchQuery;

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

  List<CreditNote> get visibleNotes {
    final String q = _searchQuery.toLowerCase();
    if (q.isEmpty) {
      return _notes;
    }
    return _notes
        .where(
          (CreditNote n) =>
              n.id.toLowerCase().contains(q) ||
              n.customer.toLowerCase().contains(q),
        )
        .toList();
  }

  int get totalNotesCount => _notes.length;

  int get draftCount =>
      _notes.where((CreditNote n) => n.status == CreditNoteStatus.draft).length;

  int get appliedCount => _notes
      .where((CreditNote n) => n.status == CreditNoteStatus.applied)
      .length;

  double get creditsTotal => _notes.fold<double>(
        0,
        (double p, CreditNote e) => p + e.amount,
      );

  String get creditsLabel {
    const String currency = 'SAR';
    final double total = creditsTotal;
    final bool asInt = (total - total.truncateToDouble()).abs() < 0.000001;
    final String formatted =
        asInt ? total.toStringAsFixed(0) : total.toStringAsFixed(2);
    return '$currency $formatted';
  }
}
