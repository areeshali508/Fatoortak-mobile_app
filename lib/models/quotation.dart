enum QuotationStatus {
  draft,
  sent,
}

enum QuotationOutcomeStatus {
  pending,
  accepted,
  declined,
  expired,
}

class QuotationItem {
  final String description;
  final int qty;
  final double price;
  final double discountPercent;
  final String vatCategory;
  final double taxPercent;

  const QuotationItem({
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

class Quotation {
  final String id;
  final String customer;
  final DateTime issueDate;
  final DateTime? validUntil;
  final String currency;
  final double amount;
  final QuotationStatus status;
  final QuotationOutcomeStatus outcomeStatus;
  final List<QuotationItem> items;
  final String notes;
  final String terms;

  const Quotation({
    required this.id,
    required this.customer,
    required this.issueDate,
    required this.currency,
    required this.amount,
    required this.status,
    this.outcomeStatus = QuotationOutcomeStatus.pending,
    this.validUntil,
    this.items = const <QuotationItem>[],
    this.notes = '',
    this.terms = '',
  });
}
