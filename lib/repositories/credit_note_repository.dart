import 'dart:convert';
import 'dart:typed_data';

import '../core/services/api_client.dart';
import '../models/credit_note.dart';

class CreditNoteRepository {
  ApiClient _api;

  CreditNoteRepository({required ApiClient api}) : _api = api;

  void updateApi(ApiClient api) {
    _api = api;
  }

  Future<String?> getNextCreditNoteNumber({required String companyId}) async {
    final String cid = companyId.trim();
    if (cid.isEmpty) {
      throw const ApiClientException('Company id is required');
    }

    final Map<String, dynamic> res =
        await _api.getJson('/api/credit-notes/next-number/$cid');

    Object? obj = res['data'] ?? res;
    if (obj is Map<String, dynamic>) {
      final String? number =
          (obj['creditNoteNumber'] ?? obj['invoiceNumber'])?.toString();
      if (number != null && number.trim().isNotEmpty) {
        return number.trim();
      }
    }
    return null;
  }

  Future<CreditNote> createCreditNote({required Map<String, dynamic> payload}) async {
    final Map<String, dynamic> res =
        await _api.postJson('/api/credit-notes', body: payload);

    Object? obj = res['creditNote'];
    final Object? dataObj = res['data'];
    if (obj == null && dataObj is Map<String, dynamic>) {
      obj = dataObj['creditNote'] ?? dataObj['invoice'];
    }
    obj ??= res;

    if (obj is Map<String, dynamic>) {
      final CreditNote created = _mapCreditNote(obj);
      if (created.id.trim().isNotEmpty) {
        _localNotes.removeWhere((CreditNote n) => n.id == created.id);
        _localNotes.insert(0, created);
      }
      return created;
    }

    throw const ApiClientException('Invalid credit note create response');
  }

  Future<Map<String, dynamic>> validateZatca({required String id}) async {
    final String noteId = id.trim();
    if (noteId.isEmpty) {
      throw const ApiClientException('Credit note id is required');
    }

    final Map<String, dynamic> res = await _api.postJson(
      '/api/credit-notes/$noteId/zatca/validate',
      body: const <String, dynamic>{},
    );
    return res;
  }

  Future<CreditNote> updateCreditNote({
    required String id,
    required Map<String, dynamic> payload,
  }) async {
    final String noteId = id.trim();
    if (noteId.isEmpty) {
      throw const ApiClientException('Credit note id is required');
    }

    final List<Future<Map<String, dynamic>> Function()> calls =
        <Future<Map<String, dynamic>> Function()>[
      () => _api.patchJson('/api/credit-notes/$noteId', body: payload),
      () => _api.patchJson('/api/credit-notes/$noteId/update', body: payload),
      () => _api.patchJson('/api/credit-notes/$noteId/edit', body: payload),
      () => _api.postJson('/api/credit-notes/$noteId/update', body: payload),
      () => _api.postJson('/api/credit-notes/$noteId/edit', body: payload),
    ];

    Map<String, dynamic>? lastRes;
    for (final Future<Map<String, dynamic>> Function() fn in calls) {
      try {
        lastRes = await fn();
        final Object? obj = lastRes['creditNote'] ??
            lastRes['invoice'] ??
            lastRes['data'] ??
            lastRes;

        Object? raw = obj;
        if (raw is Map<String, dynamic>) {
          raw = raw['creditNote'] ?? raw['invoice'] ?? raw;
        }
        if (raw is Map<String, dynamic>) {
          final CreditNote updated = _mapCreditNote(raw);
          if (updated.id.trim().isNotEmpty) {
            _localNotes.removeWhere((CreditNote n) => n.id == updated.id);
            _localNotes.insert(0, updated);
          }
          return updated;
        }
      } on ApiClientException catch (e) {
        if (e.statusCode == 404 || e.statusCode == 405) {
          continue;
        }
        rethrow;
      }
    }

    throw const ApiClientException('Invalid credit note update response');
  }

  Future<String> getCreditNotePdfText({required String id}) async {
    final String noteId = id.trim();
    if (noteId.isEmpty) {
      throw const ApiClientException('Credit note id is required');
    }

    final List<Future<String> Function()> calls = <Future<String> Function()>[
      () => _api.getText('/api/credit-notes/$noteId/zatca/pdf'),
      () => _api.getText('/api/credit-notes/$noteId/pdf'),
      () => _api.getText('/api/credit-notes/$noteId/print'),
    ];

    ApiClientException? last;
    for (final Future<String> Function() fn in calls) {
      try {
        return await fn();
      } on ApiClientException catch (e) {
        last = e;
        if (e.statusCode == 404 || e.statusCode == 405) {
          continue;
        }
        rethrow;
      }
    }

    throw last ?? const ApiClientException('Unable to load credit note PDF');
  }

  String? _extractBase64Pdf(Object? raw) {
    if (raw == null) return null;

    if (raw is Map<String, dynamic>) {
      for (final String k in <String>[
        'pdf',
        'pdfUrl',
        'base64',
        'data',
        'result',
        'content',
      ]) {
        if (raw.containsKey(k)) {
          final String? v = _extractBase64Pdf(raw[k]);
          if (v != null && v.trim().isNotEmpty) return v;
        }
      }
      return null;
    }

    if (raw is List) {
      for (final Object? it in raw) {
        final String? v = _extractBase64Pdf(it);
        if (v != null && v.trim().isNotEmpty) return v;
      }
      return null;
    }

    final String s = raw.toString().trim();
    if (s.isEmpty) return null;

    final int comma = s.indexOf(',');
    if (s.startsWith('data:') && comma >= 0 && comma < s.length - 1) {
      return s.substring(comma + 1).trim();
    }

    if (s.toLowerCase().startsWith('pdf ')) {
      final String rest = s.substring(4).trim();
      return rest.isEmpty ? null : rest;
    }

    if (s.toLowerCase().startsWith('%pdf-')) {
      return null;
    }

    return s;
  }

  String _normalizeBase64(String b64) {
    return b64.replaceAll(RegExp(r'\s+'), '');
  }

  Future<Uint8List?> getCreditNotePdfBytes({required String id}) async {
    final String noteId = id.trim();
    if (noteId.isEmpty) {
      throw const ApiClientException('Credit note id is required');
    }

    final List<Future<Map<String, dynamic>> Function()> jsonCalls =
        <Future<Map<String, dynamic>> Function()>[
      () => _api.getJson('/api/credit-notes/$noteId/zatca/pdf'),
      () => _api.getJson('/api/credit-notes/$noteId/pdf'),
      () => _api.getJson('/api/credit-notes/$noteId/print'),
    ];

    String? b64;
    for (final Future<Map<String, dynamic>> Function() fn in jsonCalls) {
      try {
        final Map<String, dynamic> res = await fn();
        b64 = _extractBase64Pdf(res['data']) ?? _extractBase64Pdf(res);
        if (b64 != null && b64.trim().isNotEmpty) {
          break;
        }
      } on ApiClientException catch (e) {
        if (e.statusCode == 404 || e.statusCode == 405) {
          continue;
        }
        rethrow;
      } catch (_) {
        // ignore and fall back
      }
    }

    b64 ??= _extractBase64Pdf(await getCreditNotePdfText(id: noteId));

    if (b64 == null || b64.trim().isEmpty) {
      return null;
    }

    try {
      final String cleaned = _normalizeBase64(b64.trim());
      return base64Decode(cleaned);
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, dynamic>> sendToZatca({required String id}) async {
    final String noteId = id.trim();
    if (noteId.isEmpty) {
      throw const ApiClientException('Credit note id is required');
    }

    final Map<String, dynamic> res = await _api.postJson(
      '/api/credit-notes/$noteId/send',
      body: const <String, dynamic>{},
    );
    return res;
  }

  Future<CreditNote?> applyCreditNote({
    required String id,
    Map<String, dynamic>? payload,
  }) async {
    final String noteId = id.trim();
    if (noteId.isEmpty) {
      throw const ApiClientException('Credit note id is required');
    }

    final String invoiceId =
        (payload?['invoiceId'] ?? payload?['invoice'] ?? '').toString().trim();
    if (invoiceId.isEmpty) {
      throw const ApiClientException('Invoice ID is required');
    }

    final Map<String, dynamic> res = await _api.postJson(
      '/api/credit-notes/$noteId/apply',
      body: <String, dynamic>{'invoiceId': invoiceId},
    );

    final Object? obj = res['creditNote'] ?? res['data'] ?? res;
    if (obj is Map<String, dynamic>) {
      final CreditNote updated = _mapCreditNote(obj);
      if (updated.id.trim().isNotEmpty) {
        _localNotes.removeWhere((CreditNote n) => n.id == updated.id);
        _localNotes.insert(0, updated);
      }
      return updated;
    }

    if (res['data'] is Map<String, dynamic> &&
        (res['data'] as Map<String, dynamic>)['creditNote']
            is Map<String, dynamic>) {
      final CreditNote updated = _mapCreditNote(
        (res['data'] as Map<String, dynamic>)['creditNote']
            as Map<String, dynamic>,
      );
      if (updated.id.trim().isNotEmpty) {
        _localNotes.removeWhere((CreditNote n) => n.id == updated.id);
        _localNotes.insert(0, updated);
      }
      return updated;
    }

    return null;
  }

  final List<CreditNote> _localNotes = <CreditNote>[];

  Future<({
    List<CreditNote> notes,
    int total,
    int pages,
    int current,
    int limit,
  })> listCreditNotesWithPagination({
    int page = 1,
    int limit = 10,
    String? companyId,
  }) async {
    final Map<String, String> qp = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
    };
    final String cid = (companyId ?? '').trim();
    if (cid.isNotEmpty) {
      qp['companyId'] = cid;
    }

    final Map<String, dynamic> res = await _api.getJson(
      '/api/credit-notes',
      queryParameters: qp,
    );

    Object? itemsObj =
        res['creditNotes'] ?? res['items'] ?? res['results'] ?? res['data'];
    Map<String, dynamic>? pagination;

    if (itemsObj is Map<String, dynamic>) {
      pagination = itemsObj['pagination'] is Map<String, dynamic>
          ? itemsObj['pagination'] as Map<String, dynamic>
          : null;

      itemsObj = itemsObj['creditNotes'] ??
          itemsObj['invoices'] ??
          itemsObj['items'] ??
          itemsObj['results'];
    }

    pagination ??= res['pagination'] is Map<String, dynamic>
        ? res['pagination'] as Map<String, dynamic>
        : null;

    final List<CreditNote> notes = <CreditNote>[];
    if (itemsObj is List) {
      for (final Object? it in itemsObj) {
        if (it is Map<String, dynamic>) {
          notes.add(_mapCreditNote(it));
        }
      }
    }

    int parseInt(Object? v, {int fallback = 0}) {
      if (v is num) return v.toInt();
      return int.tryParse(v?.toString() ?? '') ?? fallback;
    }

    final int total = parseInt(pagination?['total']);
    final int pages = parseInt(pagination?['pages']);
    final int current = parseInt(pagination?['current'], fallback: page);
    final int appliedLimit = parseInt(pagination?['limit'], fallback: limit);

    return (
      notes: notes,
      total: total,
      pages: pages,
      current: current,
      limit: appliedLimit,
    );
  }

  Future<List<CreditNote>> listCreditNotes({
    int page = 1,
    int limit = 10,
    String? companyId,
  }) async {
    final Map<String, String> qp = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
    };
    final String cid = (companyId ?? '').trim();
    if (cid.isNotEmpty) {
      qp['companyId'] = cid;
    }

    final Map<String, dynamic> res = await _api.getJson(
      '/api/credit-notes',
      queryParameters: qp,
    );

    Object? itemsObj =
        res['creditNotes'] ?? res['items'] ?? res['results'] ?? res['data'];

    if (itemsObj is Map<String, dynamic>) {
      itemsObj = itemsObj['creditNotes'] ??
          itemsObj['invoices'] ??
          itemsObj['items'] ??
          itemsObj['results'];
    }

    final List<CreditNote> notes = <CreditNote>[];
    if (itemsObj is List) {
      for (final Object? it in itemsObj) {
        if (it is Map<String, dynamic>) {
          notes.add(_mapCreditNote(it));
        }
      }
    }

    if (_localNotes.isEmpty) {
      return notes;
    }

    final Set<String> apiIds = notes.map((CreditNote e) => e.id).toSet();
    final List<CreditNote> merged = <CreditNote>[
      ..._localNotes.where((CreditNote n) => !apiIds.contains(n.id)),
      ...notes,
    ];
    return merged;
  }

  Future<CreditNote> getCreditNoteById({required String id}) async {
    final String noteId = id.trim();
    if (noteId.isEmpty) {
      throw const ApiClientException('Credit note id is required');
    }

    final Map<String, dynamic> res =
        await _api.getJson('/api/credit-notes/$noteId');
    Object? obj = res['creditNote'] ?? res['invoice'] ?? res['data'] ?? res;

    if (obj is Map<String, dynamic>) {
      obj = obj['creditNote'] ?? obj['invoice'] ?? obj;
    }

    if (obj is Map<String, dynamic>) {
      return _mapCreditNote(obj);
    }
    throw const ApiClientException('Invalid credit note response');
  }

  Future<void> addCreditNote(CreditNote note) async {
    _localNotes.insert(0, note);
  }

  CreditNote _mapCreditNote(Map<String, dynamic> json) {
    final String id = (json['_id'] ?? json['id'])?.toString() ?? '';
    final String? number = (json['formattedCreditNoteNumber'] ??
            json['creditNoteNumber'] ??
            json['creditNoteNo'] ??
            json['number'])
        ?.toString();

    final Object? companyObj = json['companyId'] ?? json['company'];
    final String? companyId = companyObj is Map<String, dynamic>
        ? (companyObj['_id'] ?? companyObj['id'])?.toString()
        : companyObj?.toString();

    String customer = '';
    final Object? customerObj = json['customerId'] ?? json['customer'];
    if (customerObj is Map<String, dynamic>) {
      customer = (customerObj['customerName'] ??
              customerObj['customerNameAr'] ??
              customerObj['name'] ??
              customerObj['email'] ??
              customerObj['_id'])
          ?.toString() ??
          '';
    } else {
      customer = customerObj?.toString() ?? '';
    }

    String customerType = '';
    if (customerObj is Map<String, dynamic>) {
      customerType =
          (customerObj['customerType'] ?? customerObj['type'])?.toString() ??
              '';
    }

    final Object? invoiceObj =
        json['originalInvoiceId'] ?? json['originalInvoice'] ?? json['invoiceId'];

    if (customerType.trim().isEmpty) {
      customerType = (json['customerType'] ??
              json['originalInvoiceCustomerType'] ??
              json['creditNoteType'] ??
              (invoiceObj is Map<String, dynamic>
                  ? (invoiceObj['invoiceType'] ?? invoiceObj['customerType'])
                  : null) ??
              json['invoiceType'])
          ?.toString() ??
          '';
    }
    customerType = customerType.trim();

    final String customerTypeLower = customerType.toLowerCase();
    if (customerTypeLower == 'standard') {
      customerType = 'B2B';
    } else if (customerTypeLower == 'simplified') {
      customerType = 'B2C';
    }

    DateTime issueDate = DateTime.now();
    final String? issueDateStr =
        (json['issueDate'] ?? json['creditNoteDate'] ?? json['createdAt'])
            ?.toString();
    if (issueDateStr != null && issueDateStr.trim().isNotEmpty) {
      final DateTime? parsed = DateTime.tryParse(issueDateStr.trim());
      if (parsed != null) issueDate = parsed;
    }

    final String currency = (json['currency']?.toString() ?? 'SAR');
    final double amount = _parseAmount(
      json['amount'] ??
          json['total'] ??
          json['totalAmount'] ??
          json['grandTotal'],
    );

    final CreditNoteStatus status = _mapStatus(json['status']?.toString());
    final CreditNotePaymentStatus paymentStatus = _mapPaymentStatus(
      (json['paymentStatus'] ?? json['applicationStatus'])?.toString(),
    );

    final String? originalInvoiceId = invoiceObj is Map<String, dynamic>
        ? (invoiceObj['_id'] ?? invoiceObj['id'])?.toString()
        : (invoiceObj?.toString().trim().isEmpty ?? true)
            ? null
            : invoiceObj?.toString();
    final String? originalInvoiceNo = invoiceObj is Map<String, dynamic>
        ? (invoiceObj['invoiceNumber'] ??
                invoiceObj['invoiceNo'] ??
                invoiceObj['formattedInvoiceNumber'] ??
                invoiceObj['_id'])
            ?.toString()
        : (json['originalInvoiceNumber'] ?? json['originalInvoiceNo'])?.toString();

    final String? originalInvoiceCustomerType = invoiceObj is Map<String, dynamic>
        ? (invoiceObj['customerType'] ?? invoiceObj['invoiceType'])?.toString()
        : json['originalInvoiceCustomerType']?.toString();

    final Object? zatcaObj = json['zatca'];
    final Map<String, dynamic>? zatcaMap =
        zatcaObj is Map<String, dynamic> ? zatcaObj : null;

    DateTime? parseDate(Object? raw) {
      if (raw == null) return null;
      final String s = raw.toString().trim();
      if (s.isEmpty) return null;
      return DateTime.tryParse(s);
    }

    final String? zatcaStatus =
        (zatcaMap?['status'] ?? json['zatcaStatus'])?.toString();
    final String? zatcaValidationStatus =
        (zatcaMap?['validationStatus'] ?? json['validationStatus'])?.toString();
    final DateTime? zatcaLastValidatedAt =
        parseDate(zatcaMap?['lastValidatedAt'] ?? json['lastValidatedAt']);
    final DateTime? zatcaClearedAt =
        parseDate(zatcaMap?['clearedAt'] ?? json['clearedAt']);

    final String? zatcaUuid =
        (zatcaMap?['uuid'] ?? json['zatcaUuid'] ?? json['uuid'])?.toString();
    final String? zatcaHash =
        (zatcaMap?['hash'] ?? json['zatcaHash'] ?? json['hash'])?.toString();
    final String? zatcaErrorMessage = (zatcaMap?['errorMessage'] ??
            zatcaMap?['error'] ??
            json['zatcaErrorMessage'] ??
            json['errorMessage'])
        ?.toString();

    final List<CreditNoteItem> items = <CreditNoteItem>[];
    final Object? itemsObj = json['items'] ?? json['lineItems'];
    if (itemsObj is List) {
      for (final Object? it in itemsObj) {
        if (it is Map<String, dynamic>) {
          items.add(_mapItem(it));
        }
      }
    }

    return CreditNote(
      id: id,
      number: (number != null && number.trim().isEmpty) ? null : number,
      companyId: (companyId != null && companyId.trim().isEmpty)
          ? null
          : companyId,
      customer: customer,
      customerType: customerType,
      issueDate: issueDate,
      currency: currency,
      amount: amount,
      status: status,
      paymentStatus: paymentStatus,
      originalInvoiceId:
          (originalInvoiceId != null && originalInvoiceId.trim().isEmpty)
              ? null
              : originalInvoiceId,
      originalInvoiceNo: originalInvoiceNo,
      originalInvoiceCustomerType: originalInvoiceCustomerType,
      zatcaStatus:
          (zatcaStatus != null && zatcaStatus.trim().isEmpty) ? null : zatcaStatus,
      zatcaValidationStatus: (zatcaValidationStatus != null &&
              zatcaValidationStatus.trim().isEmpty)
          ? null
          : zatcaValidationStatus,
      zatcaLastValidatedAt: zatcaLastValidatedAt,
      zatcaClearedAt: zatcaClearedAt,
      zatcaUuid: (zatcaUuid != null && zatcaUuid.trim().isEmpty)
          ? null
          : zatcaUuid,
      zatcaHash: (zatcaHash != null && zatcaHash.trim().isEmpty)
          ? null
          : zatcaHash,
      zatcaErrorMessage:
          (zatcaErrorMessage != null && zatcaErrorMessage.trim().isEmpty)
              ? null
              : zatcaErrorMessage,
      items: items,
    );
  }

  CreditNoteItem _mapItem(Map<String, dynamic> json) {
    final String description =
        (json['description'] ?? json['name'] ?? '').toString();
    final int qty = (json['quantity'] is num)
        ? (json['quantity'] as num).toInt()
        : int.tryParse(json['quantity']?.toString() ?? '0') ?? 0;
    final double price = (json['unitPrice'] is num)
        ? (json['unitPrice'] as num).toDouble()
        : double.tryParse(json['unitPrice']?.toString() ?? '0') ?? 0;
    final double discount = (json['discount'] is num)
        ? (json['discount'] as num).toDouble()
        : double.tryParse(json['discount']?.toString() ?? '0') ?? 0;
    final String vatCategory =
        (json['vatCategory'] ?? json['taxCategory'] ?? '-').toString();
    final double taxPercent = (json['taxRate'] is num)
        ? (json['taxRate'] as num).toDouble()
        : double.tryParse(json['taxRate']?.toString() ?? '0') ?? 0;

    return CreditNoteItem(
      description: description,
      qty: qty,
      price: price,
      discount: discount,
      vatCategory: vatCategory,
      taxPercent: taxPercent,
    );
  }

  CreditNoteStatus _mapStatus(String? raw) {
    switch ((raw ?? '').toLowerCase()) {
      case 'draft':
        return CreditNoteStatus.draft;
      case 'submitted':
      case 'sent':
        return CreditNoteStatus.submitted;
      case 'cleared':
        return CreditNoteStatus.cleared;
      case 'reported':
        return CreditNoteStatus.reported;
      case 'rejected':
      case 'failed':
        return CreditNoteStatus.rejected;
      default:
        return CreditNoteStatus.draft;
    }
  }

  CreditNotePaymentStatus _mapPaymentStatus(String? raw) {
    switch ((raw ?? '').toLowerCase()) {
      case 'refunded':
        return CreditNotePaymentStatus.refunded;
      case 'applied':
        return CreditNotePaymentStatus.applied;
      case 'pending':
      case 'not_applied':
      case 'unapplied':
      case 'open':
        return CreditNotePaymentStatus.pending;
      default:
        return CreditNotePaymentStatus.pending;
    }
  }

  double _parseAmount(Object? raw) {
    if (raw is num) return raw.toDouble();
    return double.tryParse(raw?.toString() ?? '') ?? 0;
  }
}
