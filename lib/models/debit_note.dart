enum DebitNoteStatus {
  draft,
  submitted,
  cleared,
  reported,
  rejected,
}

enum DebitNotePaymentStatus {
  pending,
  paid,
  cancelled,
}

class DebitNoteItem {
  final String description;
  final int qty;
  final double price;
  final double discountPercent;
  final String vatCategory;
  final double taxPercent;

  const DebitNoteItem({
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

class DebitNote {
  final String id;
  final String customer;
  final String customerType;
  final DateTime issueDate;
  final String currency;
  final double amount;
  final DebitNoteStatus status;
  final DebitNotePaymentStatus paymentStatus;
  final String? originalInvoiceNo;
  final String? originalInvoiceCustomerType;
  final String? zatcaUuid;
  final String? zatcaHash;
  final String? zatcaErrorMessage;
  final List<DebitNoteItem> items;

  const DebitNote({
    required this.id,
    required this.customer,
    required this.customerType,
    required this.issueDate,
    required this.currency,
    required this.amount,
    required this.status,
    this.paymentStatus = DebitNotePaymentStatus.pending,
    this.originalInvoiceNo,
    this.originalInvoiceCustomerType,
    this.zatcaUuid,
    this.zatcaHash,
    this.zatcaErrorMessage,
    this.items = const <DebitNoteItem>[],
  });
}
