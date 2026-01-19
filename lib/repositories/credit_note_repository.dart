import '../models/credit_note.dart';

class CreditNoteRepository {
  final List<CreditNote> _notes = <CreditNote>[];

  Future<List<CreditNote>> listCreditNotes() async {
    return List<CreditNote>.unmodifiable(_notes);
  }

  Future<void> addCreditNote(CreditNote note) async {
    _notes.insert(0, note);
  }
}
