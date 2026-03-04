enum CreditNoteStatus { draft, submitted, cleared, reported, rejected }

enum CreditNotePaymentStatus { pending, refunded, applied }

class CreditNoteItem {
  final String description;
  final int qty;
  final double price;
  final double discount;
  final String vatCategory;
  final double taxPercent;

  const CreditNoteItem({
    required this.description,
    required this.qty,
    required this.price,
    required this.discount,
    required this.vatCategory,
    required this.taxPercent,
  });

  double get gross => qty * price;

  double get discountAmount {
    if (discount <= 0) return 0;
    if (discount >= gross) return gross;
    return discount;
  }

  double get taxableAmount => gross - discountAmount;

  double get taxAmount => taxableAmount * (taxPercent / 100);

  double get total => taxableAmount + taxAmount;
}

class CreditNote {
  final String id;
  final String? number;
  final String? companyId;
  final String customer;
  final String customerType;
  final DateTime issueDate;
  final String currency;
  final double amount;
  final CreditNoteStatus status;
  final CreditNotePaymentStatus paymentStatus;
  final String? originalInvoiceId;
  final String? originalInvoiceNo;
  final String? originalInvoiceCustomerType;
  final String? zatcaStatus;
  final String? zatcaValidationStatus;
  final DateTime? zatcaLastValidatedAt;
  final DateTime? zatcaClearedAt;
  final String? zatcaUuid;
  final String? zatcaHash;
  final String? zatcaErrorMessage;
  final List<CreditNoteItem> items;

  const CreditNote({
    required this.id,
    this.number,
    this.companyId,
    required this.customer,
    required this.customerType,
    required this.issueDate,
    required this.currency,
    required this.amount,
    required this.status,
    this.paymentStatus = CreditNotePaymentStatus.pending,
    this.originalInvoiceId,
    this.originalInvoiceNo,
    this.originalInvoiceCustomerType,
    this.zatcaStatus,
    this.zatcaValidationStatus,
    this.zatcaLastValidatedAt,
    this.zatcaClearedAt,
    this.zatcaUuid,
    this.zatcaHash,
    this.zatcaErrorMessage,
    this.items = const <CreditNoteItem>[],
  });
}
