enum QuotationStatus { draft, sent }

enum QuotationOutcomeStatus { pending, accepted, declined, expired }

class QuotationItem {
  final String productId;
  final String description;
  final int qty;
  final double price;
  final double discountPercent;
  final String vatCategory;
  final double taxPercent;

  const QuotationItem({
    this.productId = '',
    required this.description,
    required this.qty,
    required this.price,
    required this.discountPercent,
    required this.vatCategory,
    required this.taxPercent,
  });

  factory QuotationItem.fromApi(Map<String, dynamic> json) {
    String productId = '';
    String desc = '';
    final Object? productRaw = json['product'];
    if (productRaw is Map<String, dynamic>) {
      productId = (productRaw['_id'] ?? productRaw['id'])?.toString() ?? '';
      desc = (productRaw['name'] ?? productRaw['productName'])?.toString() ?? '';
    } else {
      productId = productRaw?.toString() ?? '';
    }

    final String descriptionRaw = (json['description'] ?? '')?.toString() ?? '';
    if (descriptionRaw.trim().isNotEmpty) {
      desc = descriptionRaw;
    }
    if (desc.trim().isEmpty) {
      desc = productId;
    }
    desc = desc.trim();

    final int qty = (json['quantity'] is num)
        ? (json['quantity'] as num).toInt()
        : int.tryParse(json['quantity']?.toString() ?? '') ?? 0;
    final double unitPrice = (json['unitPrice'] is num)
        ? (json['unitPrice'] as num).toDouble()
        : double.tryParse(json['unitPrice']?.toString() ?? '') ?? 0;
    final double taxRate = (json['taxRate'] is num)
        ? (json['taxRate'] as num).toDouble()
        : double.tryParse(json['taxRate']?.toString() ?? '') ?? 0;
    final double discount = (json['discount'] is num)
        ? (json['discount'] as num).toDouble()
        : double.tryParse(json['discount']?.toString() ?? '') ?? 0;

    String vatCategory;
    if (taxRate.abs() < 0.000001) {
      vatCategory = 'Z - 0%';
    } else if ((taxRate - 15).abs() < 0.000001) {
      vatCategory = 'S - 15%';
    } else {
      vatCategory = 'S - ${taxRate.toStringAsFixed(0)}%';
    }

    return QuotationItem(
      productId: productId,
      description: desc,
      qty: qty,
      price: unitPrice,
      discountPercent: discount,
      vatCategory: vatCategory,
      taxPercent: taxRate,
    );
  }

  double get gross => qty * price;

  double get discountAmount => gross * (discountPercent / 100);

  double get taxableAmount => gross - discountAmount;

  double get taxAmount => taxableAmount * (taxPercent / 100);

  double get total => taxableAmount + taxAmount;
}

class Quotation {
  final String id;
  final String apiId;
  final String customer;
  final DateTime issueDate;
  final DateTime? validUntil;
  final String currency;
  final double amount;
  final String paymentTerms;
  final QuotationStatus status;
  final QuotationOutcomeStatus outcomeStatus;
  final List<QuotationItem> items;
  final String notes;
  final String terms;

  const Quotation({
    required this.id,
    this.apiId = '',
    required this.customer,
    required this.issueDate,
    required this.currency,
    required this.amount,
    this.paymentTerms = 'Due on Receipt',
    required this.status,
    this.outcomeStatus = QuotationOutcomeStatus.pending,
    this.validUntil,
    this.items = const <QuotationItem>[],
    this.notes = '',
    this.terms = '',
  });

  static QuotationStatus _statusFromApi(String raw) {
    final String s = raw.trim().toLowerCase();
    if (s == 'sent') return QuotationStatus.sent;
    return QuotationStatus.draft;
  }

  static DateTime _parseDate(Object? raw) {
    if (raw is String && raw.trim().isNotEmpty) {
      return DateTime.tryParse(raw.trim()) ?? DateTime.now();
    }
    return DateTime.now();
  }

  static DateTime? _parseDateNullable(Object? raw) {
    if (raw is String && raw.trim().isNotEmpty) {
      return DateTime.tryParse(raw.trim());
    }
    return null;
  }

  factory Quotation.fromApi(Map<String, dynamic> json) {
    final String apiId = (json['_id'] ?? json['id'])?.toString() ?? '';
    final String number = (json['quoteNumber'] ?? json['formattedQuoteNumber'])
            ?.toString() ??
        '';
    final String id = number.trim().isNotEmpty ? number : apiId;

    String customer = '';
    final Object? customerInfo = json['customerInfo'];
    if (customerInfo is Map<String, dynamic>) {
      customer = (customerInfo['name'] ?? customerInfo['customerName'])
              ?.toString() ??
          '';
    }
    if (customer.trim().isEmpty) {
      final Object? customerId = json['customerId'];
      if (customerId is Map<String, dynamic>) {
        customer = (customerId['customerName'] ?? customerId['name'])
                ?.toString() ??
            '';
      }
    }
    customer = customer.trim();

    final DateTime issueDate = _parseDate(json['quoteDate'] ?? json['issueDate']);
    final DateTime? validUntil = _parseDateNullable(json['validUntil']);
    final String currency = (json['currency'] ?? 'SAR')?.toString() ?? 'SAR';

    final double total = (json['total'] is num)
        ? (json['total'] as num).toDouble()
        : double.tryParse(json['total']?.toString() ?? '') ?? 0;

    final String paymentTerms = (json['paymentTerms'] ?? '')?.toString() ?? '';
    final String statusRaw = (json['status'] ?? '')?.toString() ?? '';

    final List<QuotationItem> items = <QuotationItem>[];
    final Object? itemsObj = json['items'];
    if (itemsObj is List) {
      for (final Object? it in itemsObj) {
        if (it is Map<String, dynamic>) {
          items.add(QuotationItem.fromApi(it));
        }
      }
    }

    return Quotation(
      id: id,
      apiId: apiId,
      customer: customer,
      issueDate: issueDate,
      validUntil: validUntil,
      currency: currency,
      amount: total,
      paymentTerms: paymentTerms.isEmpty ? 'Due on Receipt' : paymentTerms,
      status: _statusFromApi(statusRaw),
      items: List<QuotationItem>.unmodifiable(items),
      notes: (json['notes'] ?? '')?.toString() ?? '',
      terms: (json['termsAndConditions'] ?? json['terms'] ?? '')?.toString() ?? '',
    );
  }
}
