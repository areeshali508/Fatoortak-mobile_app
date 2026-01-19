enum CreditNoteStatus {
  draft,
  applied,
}

class CreditNoteItem {
  final String description;
  final int qty;
  final double price;
  final double discountPercent;
  final String vatCategory;
  final double taxPercent;

  const CreditNoteItem({
    required this.description,
    required this.qty,
    required this.price,
    required this.discountPercent,
    required this.vatCategory,
    required this.taxPercent,
  });

  double get gross => qty * price;

  double get discountAmount => gross * (discountPercent / 100);

  double get taxableAmount => gross - discountAmount;

  double get taxAmount => taxableAmount * (taxPercent / 100);

  double get total => taxableAmount + taxAmount;
}

class CreditNote {
  final String id;
  final String customer;
  final DateTime issueDate;
  final String currency;
  final double amount;
  final CreditNoteStatus status;
  final List<CreditNoteItem> items;

  const CreditNote({
    required this.id,
    required this.customer,
    required this.issueDate,
    required this.currency,
    required this.amount,
    required this.status,
    this.items = const <CreditNoteItem>[],
  });
}
