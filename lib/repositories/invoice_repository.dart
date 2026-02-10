import '../core/services/api_client.dart';
import '../models/invoice.dart';

class InvoiceRepository {
  ApiClient _api;

  InvoiceRepository({required ApiClient api}) : _api = api;

  void updateApi(ApiClient api) {
    _api = api;
  }

  Future<String?> getNextInvoiceNumber({required String companyId}) async {
    final String id = companyId.trim();
    if (id.isEmpty) {
      throw const ApiClientException('Company id is required');
    }

    final List<Future<Map<String, dynamic>> Function()> calls =
        <Future<Map<String, dynamic>> Function()>[
      () => _api.getJson('/api/invoices/next-number/$id'),
      () => _api.getJson(
            '/api/invoices/next-number',
            queryParameters: <String, String>{'companyId': id},
          ),
    ];

    for (final Future<Map<String, dynamic>> Function() fn in calls) {
      try {
        final Map<String, dynamic> res = await fn();
        final Object? data = res['data'] ?? res;
        if (data is String) {
          final String v = data.trim();
          return v.isEmpty ? null : v;
        }
        if (data is Map<String, dynamic>) {
          final String? v = (data['nextNumber'] ??
                  data['invoiceNumber'] ??
                  data['invoiceNo'] ??
                  data['formattedInvoiceNumber'])
              ?.toString()
              .trim();
          if (v != null && v.isNotEmpty) {
            return v;
          }
        }
      } catch (_) {
        // try next
      }
    }

    return null;
  }

  Future<List<Invoice>> getInvoices({
    String? companyId,
    int page = 1,
    int limit = 100,
    bool fetchAll = true,
  }) async {
    final String trimmed = (companyId ?? '').trim();

    Future<Map<String, dynamic>> fetchPage(int p) {
      final Map<String, String> qp = <String, String>{
        'page': p.toString(),
        'limit': limit.toString(),
      };
      if (trimmed.isNotEmpty) {
        qp['companyId'] = trimmed;
      }
      return _api.getJson('/api/invoices', queryParameters: qp);
    }

    final Map<String, dynamic> first = await fetchPage(page);

    List<Map<String, dynamic>> extractInvoices(Map<String, dynamic> res) {
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
      return list.whereType<Map<String, dynamic>>().toList();
    }

    int? pages;
    final Object? d0 = first['data'];
    if (d0 is Map<String, dynamic>) {
      final Object? p0 = d0['pagination'];
      if (p0 is Map<String, dynamic>) {
        pages = int.tryParse(p0['pages']?.toString() ?? '');
      }
    }

    final List<Map<String, dynamic>> all = <Map<String, dynamic>>[
      ...extractInvoices(first),
    ];

    if (fetchAll && pages != null && pages > page) {
      for (int p = page + 1; p <= pages; p++) {
        try {
          final Map<String, dynamic> res = await fetchPage(p);
          all.addAll(extractInvoices(res));
        } catch (_) {
          // ignore page failure and keep what we have
        }
      }
    }

    return all
        .map((Map<String, dynamic> e) => _mapInvoice(e))
        .where((Invoice inv) => inv.id.trim().isNotEmpty)
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
    String? invoiceNumber,
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

    final String trimmedInvoiceNumber = (invoiceNumber ?? '').trim();
    if (trimmedInvoiceNumber.isNotEmpty) {
      body['invoiceNumber'] = trimmedInvoiceNumber;
    }

    Map<String, dynamic> extractInvoice(Map<String, dynamic> res) {
      final Object? invoice = res['invoice'] ?? res['data'];
      if (invoice is Map<String, dynamic>) {
        return invoice;
      }
      throw const ApiClientException('Invalid invoice response');
    }

    try {
      final Map<String, dynamic> res = await _api.postJson(
        '/api/invoices',
        body: body,
      );
      return _mapInvoice(extractInvoice(res));
    } on ApiClientException catch (e) {
      final String lower = e.toString().toLowerCase();

      final bool customerRejected =
          lower.contains('customer not found') || lower.contains('not accessible');
      final bool companyRejected =
          lower.contains('company not found') || lower.contains('not accessible');

      if (customerRejected || companyRejected) {
        final Map<String, dynamic> compatBody = Map<String, dynamic>.from(body)
          ..putIfAbsent('customer', () => customerId)
          ..putIfAbsent('company', () => companyId);

        final Map<String, dynamic> res = await _api.postJson(
          '/api/invoices',
          body: compatBody,
        );
        return _mapInvoice(extractInvoice(res));
      }

      rethrow;
    }
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

    String companyName = '';
    final Object? companyObj = json['companyId'] ?? json['company'];
    if (companyObj is Map<String, dynamic>) {
      companyName = (companyObj['companyName'] ?? companyObj['name'] ?? companyObj['_id'])
              ?.toString() ??
          '';
    } else {
      companyName = companyObj?.toString() ?? '';
    }

    String customerType = '';
    if (customerObj is Map<String, dynamic>) {
      customerType = (customerObj['customerType'] ?? customerObj['type'])?.toString() ?? '';
    }
    customerType = customerType.trim();

    DateTime? parseDate(Object? raw) {
      if (raw == null) return null;
      final String s = raw.toString().trim();
      if (s.isEmpty) return null;
      return DateTime.tryParse(s);
    }

    final Object? zatcaObj = json['zatca'];
    final Map<String, dynamic>? zatcaMap =
        zatcaObj is Map<String, dynamic> ? zatcaObj : null;

    final String zatcaStatus = (zatcaMap?['status'] ?? json['zatcaStatus'])?.toString() ?? '';
    final String validationStatus =
        (zatcaMap?['validationStatus'] ?? json['validationStatus'])?.toString() ?? '';
    final String uuid = (zatcaMap?['uuid'] ??
            json['zatcaUuid'] ??
            json['uuid'])
        ?.toString() ??
        '';
    final String hash = (zatcaMap?['hash'] ?? json['hash'])?.toString() ?? '';
    final String qrCode = (zatcaMap?['qrCode'] ?? json['qrCode'])?.toString() ?? '';
    final String pdfUrl = (zatcaMap?['pdfUrl'] ?? json['pdfUrl'])?.toString() ?? '';
    final String prevHash =
        (zatcaMap?['previousInvoiceHash'] ?? json['previousInvoiceHash'])?.toString() ?? '';
    final Object? hashChainRaw =
        (zatcaMap?['hashChainNumber'] ?? json['hashChainNumber']);
    final int? hashChainNumber = (hashChainRaw is num)
        ? hashChainRaw.toInt()
        : int.tryParse(hashChainRaw?.toString() ?? '');
    final String invoiceCategory =
        (zatcaMap?['invoiceCategory'] ?? json['invoiceCategory'])?.toString() ?? '';
    final DateTime? lastValidatedAt =
        parseDate(zatcaMap?['lastValidatedAt'] ?? json['lastValidatedAt']);
    final DateTime? clearedAt =
        parseDate(zatcaMap?['clearedAt'] ?? json['clearedAt']);

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
      company: companyName,
      customerType: customerType,
      invoiceType: invoiceType,
      paymentTerms: json['paymentTerms']?.toString() ?? '',
      items: items,
      notes: json['notes']?.toString() ?? '',
      terms: '',
      zatca: ZatcaInfo(
        status: zatcaStatus,
        validationStatus: validationStatus,
        uuid: uuid,
        lastValidatedAt: lastValidatedAt,
        clearedAt: clearedAt,
        hash: hash,
        qrCode: qrCode,
        pdfUrl: pdfUrl,
        previousInvoiceHash: prevHash,
        hashChainNumber: hashChainNumber,
        invoiceCategory: invoiceCategory,
      ),
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
