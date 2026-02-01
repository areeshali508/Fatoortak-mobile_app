import '../core/services/api_client.dart';
import '../models/invoice.dart';

class InvoiceRepository {
  ApiClient _api;

  InvoiceRepository({required ApiClient api}) : _api = api;

  void updateApi(ApiClient api) {
    _api = api;
  }

  Future<List<Invoice>> getInvoices({String? companyId}) async {
    final String trimmed = (companyId ?? '').trim();
    final Map<String, dynamic> res = await _api.getJson(
      '/api/invoices',
      queryParameters: trimmed.isEmpty ? null : <String, String>{'companyId': trimmed},
    );

    final Object? rawTop = res['invoices'];
    final Object? data = res['data'];

    Object? raw;
    if (rawTop is List) {
      raw = rawTop;
    } else if (data is Map<String, dynamic> && data['invoices'] is List) {
      raw = data['invoices'];
    } else {
      raw = data;
    }

    final List<dynamic> list = raw is List ? raw : <dynamic>[];
    return list
        .map((dynamic e) => e is Map<String, dynamic> ? _mapInvoice(e) : null)
        .whereType<Invoice>()
        .toList();
  }

  Future<Invoice> createInvoice({
    required String companyId,
    required String customerId,
    required DateTime invoiceDate,
    required DateTime dueDate,
    required List<InvoiceItem> items,
    required String currency,
    required String invoiceType,
    required String paymentTerms,
    String notes = '',
    double discount = 0,
  }) async {
    final Map<String, dynamic> body = <String, dynamic>{
      'customerId': customerId,
      'companyId': companyId,
      'invoiceDate': _toDateOnly(invoiceDate),
      'dueDate': _toDateOnly(dueDate),
      'items': items.map(_mapItemToApi).toList(),
      'discount': discount,
      'currency': currency,
      'invoiceType': invoiceType,
      'notes': notes,
      'paymentTerms': paymentTerms,
    };

    final Map<String, dynamic> res = await _api.postJson(
      '/api/invoices',
      body: body,
    );

    final Object? invoice = res['invoice'] ?? res['data'];
    if (invoice is Map<String, dynamic>) {
      return _mapInvoice(invoice);
    }

    throw const ApiClientException('Invalid invoice response');
  }

  Future<Invoice> updateInvoiceStatus({
    required String invoiceId,
    required String status,
  }) async {
    final Map<String, dynamic> res = await _api.patchJson(
      '/api/invoices/$invoiceId/status',
      body: <String, dynamic>{'status': status},
    );

    final Object? invoice = res['invoice'] ?? res['data'];
    if (invoice is Map<String, dynamic>) {
      return _mapInvoice(invoice);
    }

    throw const ApiClientException('Invalid invoice response');
  }

  Invoice _mapInvoice(Map<String, dynamic> json) {
    final String id = (json['_id'] ?? json['id'])?.toString() ?? '';
    final String invoiceNo =
        (json['invoiceNumber'] ?? json['invoiceNo'])?.toString() ?? '';

    String customer = '';
    final Object? customerObj = json['customerId'] ?? json['customer'];
    if (customerObj is Map<String, dynamic>) {
      customer = (customerObj['customerName'] ??
              customerObj['customerNameAr'] ??
              customerObj['email'] ??
              customerObj['_id'])
          ?.toString() ??
          '';
    } else {
      customer = customerObj?.toString() ?? '';
    }

    DateTime issueDate = DateTime.now();
    final String? invoiceDateStr =
        (json['invoiceDate'] ?? json['createdAt'])?.toString();
    if (invoiceDateStr != null && invoiceDateStr.trim().isNotEmpty) {
      final DateTime? parsed = DateTime.tryParse(invoiceDateStr);
      if (parsed != null) issueDate = parsed;
    }

    DateTime? dueDate;
    final String? dueDateStr = json['dueDate']?.toString();
    if (dueDateStr != null && dueDateStr.trim().isNotEmpty) {
      dueDate = DateTime.tryParse(dueDateStr);
    }

    final String currency = (json['currency']?.toString() ?? 'SAR');
    final InvoiceStatus status = _mapStatus(json['status']?.toString());

    final List<InvoiceItem> items = <InvoiceItem>[];
    final Object? itemsObj = json['items'];
    if (itemsObj is List) {
      for (final Object? it in itemsObj) {
        if (it is Map<String, dynamic>) {
          items.add(_mapItem(it));
        }
      }
    }

    final String invoiceTypeRaw = json['invoiceType']?.toString() ?? '';
    final String invoiceType = invoiceTypeRaw.isEmpty
        ? ''
        : (invoiceTypeRaw == 'simplified'
            ? 'Tax Invoice (Simplified)'
            : 'Tax Invoice (Standard)');

    return Invoice(
      id: id,
      invoiceNo: invoiceNo,
      customer: customer,
      issueDate: issueDate,
      dueDate: dueDate,
      currency: currency,
      status: status,
      company: '',
      customerType: '',
      invoiceType: invoiceType,
      paymentTerms: json['paymentTerms']?.toString() ?? '',
      items: items,
      notes: json['notes']?.toString() ?? '',
      terms: '',
    );
  }

  InvoiceItem _mapItem(Map<String, dynamic> json) {
    final Object? productRaw = json['product'];
    final String productId = productRaw is Map<String, dynamic>
        ? (productRaw['_id'] ?? productRaw['id'])?.toString() ?? ''
        : productRaw?.toString() ?? '';
    final String productName = (json['description'] ??
            (productRaw is Map<String, dynamic> ? productRaw['name'] : null) ??
            json['_id'])
        ?.toString() ??
        '';
    final int qty = (json['quantity'] is num)
        ? (json['quantity'] as num).toInt()
        : int.tryParse(json['quantity']?.toString() ?? '0') ?? 0;
    final double price = (json['unitPrice'] is num)
        ? (json['unitPrice'] as num).toDouble()
        : double.tryParse(json['unitPrice']?.toString() ?? '0') ?? 0;
    final double discount = (json['discount'] is num)
        ? (json['discount'] as num).toDouble()
        : double.tryParse(json['discount']?.toString() ?? '0') ?? 0;
    final double taxPercent = (json['taxRate'] is num)
        ? (json['taxRate'] as num).toDouble()
        : double.tryParse(json['taxRate']?.toString() ?? '0') ?? 0;

    return InvoiceItem(
      productId: productId,
      product: productName,
      qty: qty,
      price: price,
      discount: discount,
      vatCategory: '-',
      taxPercent: taxPercent,
    );
  }

  InvoiceStatus _mapStatus(String? raw) {
    switch ((raw ?? '').toLowerCase()) {
      case 'draft':
        return InvoiceStatus.draft;
      case 'sent':
        return InvoiceStatus.sent;
      case 'paid':
        return InvoiceStatus.paid;
      case 'partially_paid':
        return InvoiceStatus.partiallyPaid;
      case 'overdue':
        return InvoiceStatus.overdue;
      case 'cancelled':
      case 'canceled':
        return InvoiceStatus.cancelled;
      case 'void':
      case 'voided':
        return InvoiceStatus.voided;
      default:
        return InvoiceStatus.none;
    }
  }

  Map<String, dynamic> _mapItemToApi(InvoiceItem item) {
    return <String, dynamic>{
      'product': item.productId,
      'description': item.product,
      'quantity': item.qty,
      'unitPrice': item.price,
      'taxRate': item.taxPercent,
      'discount': item.discount,
    };
  }

  String _toDateOnly(DateTime d) {
    final String yyyy = d.year.toString().padLeft(4, '0');
    final String mm = d.month.toString().padLeft(2, '0');
    final String dd = d.day.toString().padLeft(2, '0');
    return '$yyyy-$mm-$dd';
  }
}
