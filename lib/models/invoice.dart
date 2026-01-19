enum InvoiceStatus {
  draft,
  sent,
  overdue,
  paid,
  none,
}

class InvoiceItem {
  final String product;
  final int qty;
  final double price;
  final double discountPercent;
  final String vatCategory;
  final double taxPercent;

  const InvoiceItem({
    required this.product,
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

class Invoice {
  final String invoiceNo;
  final String customer;
  final DateTime issueDate;
  final DateTime? dueDate;
  final String currency;
  final InvoiceStatus status;
  final String company;
  final String customerType;
  final String invoiceType;
  final String paymentTerms;
  final List<InvoiceItem> items;
  final String notes;
  final String terms;

  const Invoice({
    required this.invoiceNo,
    required this.customer,
    required this.issueDate,
    required this.currency,
    required this.status,
    required this.company,
    required this.customerType,
    required this.invoiceType,
    required this.paymentTerms,
    required this.items,
    required this.notes,
    required this.terms,
    this.dueDate,
  });

  double get subtotal => items.fold<double>(
        0,
        (double p, InvoiceItem e) => p + e.taxableAmount,
      );

  double get vatAmount => items.fold<double>(
        0,
        (double p, InvoiceItem e) => p + e.taxAmount,
      );

  double get total => items.fold<double>(
        0,
        (double p, InvoiceItem e) => p + e.total,
      );
}
