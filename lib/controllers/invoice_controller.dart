import 'package:flutter/foundation.dart';

class InvoiceController extends ChangeNotifier {
  int _draftCount = 0;

  int get draftCount => _draftCount;

  void createDraft() {
    _draftCount++;
    notifyListeners();
  }
}
