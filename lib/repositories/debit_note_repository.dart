import '../core/services/api_client.dart';
import '../models/debit_note.dart';

class DebitNoteRepository {
  ApiClient _api;

  final List<DebitNote> _notes = <DebitNote>[
    DebitNote(
      id: 'DN-2024-001',
      customer: 'Sarah Jenkins',
      customerType: 'B2C',
      issueDate: DateTime(2024, 10, 12),
      currency: 'SAR',
      amount: 450.00,
      status: DebitNoteStatus.submitted,
      paymentStatus: DebitNotePaymentStatus.pending,
      originalInvoiceNo: 'INV-2024-1102',
      originalInvoiceCustomerType: 'B2C',
      zatcaUuid: 'dn-uuid-001',
      zatcaHash: 'dn-hash-001',
      items: <DebitNoteItem>[
        DebitNoteItem(
          description: 'Service Adjustment',
          qty: 1,
          price: 450.00,
          discount: 0,
          vatCategory: 'Standard',
          taxPercent: 15,
        ),
      ],
    ),
    DebitNote(
      id: 'DN-2024-002',
      customer: 'Abdul Rahman',
      customerType: 'B2B',
      issueDate: DateTime(2024, 11, 2),
      currency: 'SAR',
      amount: 2100.00,
      status: DebitNoteStatus.cleared,
      paymentStatus: DebitNotePaymentStatus.paid,
      originalInvoiceNo: 'INV-2024-1148',
      originalInvoiceCustomerType: 'B2B',
      zatcaUuid: 'dn-uuid-002',
      zatcaHash: 'dn-hash-002',
      items: <DebitNoteItem>[
        DebitNoteItem(
          description: 'Additional Items',
          qty: 2,
          price: 1050.00,
          discount: 0,
          vatCategory: 'Standard',
          taxPercent: 15,
        ),
      ],
    ),
    DebitNote(
      id: 'DN-2024-003',
      customer: 'Omar Farooq',
      customerType: 'B2C',
      issueDate: DateTime(2024, 11, 9),
      currency: 'SAR',
      amount: 320.00,
      status: DebitNoteStatus.rejected,
      paymentStatus: DebitNotePaymentStatus.cancelled,
      originalInvoiceNo: 'INV-2024-1164',
      originalInvoiceCustomerType: 'B2C',
      zatcaErrorMessage: 'Rejected by ZATCA (dummy)',
      items: <DebitNoteItem>[
        DebitNoteItem(
          description: 'Late Fee',
          qty: 1,
          price: 320.00,
          discount: 0,
          vatCategory: 'Standard',
          taxPercent: 15,
        ),
      ],
    ),
  ];

  DebitNoteRepository({required ApiClient api}) : _api = api;

  void updateApi(ApiClient api) {
    _api = api;
  }

  Future<String?> getNextDebitNoteNumber({required String companyId}) async {
    final String cid = companyId.trim();
    if (cid.isEmpty) {
      throw const ApiClientException('Company id is required');
    }

    final Map<String, dynamic> res =
        await _api.getJson('/api/debit-notes/next-number/$cid');

    final Object? data = res['data'] ?? res;
    if (data is Map<String, dynamic>) {
      final String? v = (data['debitNoteNumber'] ?? data['invoiceNumber'])
          ?.toString()
          .trim();
      if (v != null && v.isNotEmpty) {
        return v;
      }
    }

    return null;
  }

  Future<List<DebitNote>> listDebitNotes() async {
    final List<DebitNote> fresh = await listAllDebitNotes(limit: 100);
    _notes
      ..clear()
      ..addAll(fresh);
    return List<DebitNote>.unmodifiable(_notes);
  }

  Future<({
    List<DebitNote> notes,
    int total,
    int pages,
    int current,
    int limit,
  })> listDebitNotesWithPagination({
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
      '/api/debit-notes',
      queryParameters: qp,
    );

    Object? itemsObj =
        res['debitNotes'] ??
        res['invoices'] ??
        res['items'] ??
        res['results'] ??
        res['data'];
    Map<String, dynamic>? pagination;

    if (itemsObj is Map<String, dynamic>) {
      pagination = itemsObj['pagination'] is Map<String, dynamic>
          ? itemsObj['pagination'] as Map<String, dynamic>
          : null;

      itemsObj = itemsObj['debitNotes'] ??
          itemsObj['invoices'] ??
          itemsObj['items'] ??
          itemsObj['results'] ??
          itemsObj['data'];
    }

    pagination ??= res['pagination'] is Map<String, dynamic>
        ? res['pagination'] as Map<String, dynamic>
        : null;

    final List<DebitNote> notes = <DebitNote>[];
    if (itemsObj is List) {
      for (final Object? it in itemsObj) {
        if (it is Map<String, dynamic>) {
          notes.add(_mapDebitNote(it));
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

  Future<List<DebitNote>> listAllDebitNotes({
    int limit = 100,
    String? companyId,
  }) async {
    final ({
      List<DebitNote> notes,
      int total,
      int pages,
      int current,
      int limit,
    }) first = await listDebitNotesWithPagination(
      page: 1,
      limit: limit,
      companyId: companyId,
    );

    final List<DebitNote> all = <DebitNote>[...first.notes];
    final int pages = first.pages > 0 ? first.pages : 1;
    final List<int> remainingPages = <int>[
      for (int p = 2; p <= pages; p++) p,
    ];
    const int batchSize = 4;

    for (int i = 0; i < remainingPages.length; i += batchSize) {
      final int end = (i + batchSize < remainingPages.length)
          ? i + batchSize
          : remainingPages.length;
      final List<int> batch = remainingPages.sublist(i, end);
      final List<({
        List<DebitNote> notes,
        int total,
        int pages,
        int current,
        int limit,
      })> batchResults = await Future.wait(
        batch.map(
          (int currentPage) => listDebitNotesWithPagination(
            page: currentPage,
            limit: limit,
            companyId: companyId,
          ),
        ),
      );

      for (final ({
        List<DebitNote> notes,
        int total,
        int pages,
        int current,
        int limit,
      }) result in batchResults) {
        all.addAll(result.notes);
      }
    }
    return all;
  }

  Future<DebitNote> getDebitNoteById(String debitNoteId) async {
    final Map<String, dynamic> res = await _api.getJson(
      '/api/debit-notes/$debitNoteId',
    );

    Object? dataObj = res['data'] ?? res['debitNote'] ?? res['result'];
    if (dataObj is Map<String, dynamic>) {
      dataObj = dataObj['debitNote'] ??
          dataObj['invoice'] ??
          dataObj['item'] ??
          dataObj['data'] ??
          dataObj;
    }
    if (dataObj is! Map<String, dynamic>) {
      throw const ApiClientException('Invalid response');
    }
    return _mapDebitNote(dataObj);
  }

  Future<Map<String, dynamic>> validateZatca({required String id}) async {
    final String noteId = id.trim();
    if (noteId.isEmpty) {
      throw const ApiClientException('Debit note id is required');
    }

    return _api.postJson(
      '/api/debit-notes/$noteId/zatca/validate',
      body: const <String, dynamic>{},
    );
  }

  Future<void> addDebitNote(DebitNote note) async {
    _notes.insert(0, note);
  }

  Future<DebitNote> createDebitNote({required Map<String, dynamic> payload}) async {
    final Map<String, dynamic> res = await _api.postJson(
      '/api/debit-notes',
      body: payload,
    );

    Object? dataObj = res['data'] ?? res['debitNote'] ?? res['result'];
    if (dataObj is Map<String, dynamic>) {
      dataObj = dataObj['debitNote'] ??
          dataObj['invoice'] ??
          dataObj['item'] ??
          dataObj['data'] ??
          dataObj;
    }

    if (dataObj is! Map<String, dynamic>) {
      throw const ApiClientException('Invalid response');
    }

    return _mapDebitNote(dataObj);
  }

  DebitNote _mapDebitNote(Map<String, dynamic> raw) {
    double parseDouble(Object? v, {double fallback = 0}) {
      if (v is num) return v.toDouble();
      return double.tryParse(v?.toString() ?? '') ?? fallback;
    }

    int parseInt(Object? v, {int fallback = 0}) {
      if (v is num) return v.toInt();
      return int.tryParse(v?.toString() ?? '') ?? fallback;
    }

    DateTime parseDate(Object? v) {
      final String s = v?.toString() ?? '';
      final DateTime? d = DateTime.tryParse(s);
      return d ?? DateTime.now();
    }

    DebitNoteStatus parseStatus(Object? v) {
      final String s = (v?.toString() ?? '').toLowerCase().trim();
      switch (s) {
        case 'draft':
          return DebitNoteStatus.draft;
        case 'submitted':
        case 'sent':
          return DebitNoteStatus.submitted;
        case 'cleared':
          return DebitNoteStatus.cleared;
        case 'reported':
          return DebitNoteStatus.reported;
        case 'rejected':
          return DebitNoteStatus.rejected;
        default:
          return DebitNoteStatus.draft;
      }
    }

    DebitNotePaymentStatus parsePaymentStatus(Object? v) {
      final String s = (v?.toString() ?? '').toLowerCase().trim();
      switch (s) {
        case 'paid':
          return DebitNotePaymentStatus.paid;
        case 'cancelled':
        case 'canceled':
          return DebitNotePaymentStatus.cancelled;
        case 'unpaid':
        case 'pending':
        default:
          return DebitNotePaymentStatus.pending;
      }
    }

    final String backendId = (raw['_id'] ?? raw['id'] ?? '').toString();
    final String debitNoteNo = (raw['debitNoteNumber'] ??
            raw['formattedDebitNoteNumber'] ??
            raw['debitNoteNo'] ??
            '')
        .toString();

    String customerName() {
      final Object? c = raw['customerId'] ?? raw['customer'] ?? raw['customerInfo'];
      if (c is Map<String, dynamic>) {
        final Object? n = c['customerName'] ?? c['name'] ?? c['fullName'];
        if (n != null && n.toString().trim().isNotEmpty) {
          return n.toString();
        }
      }
      return (raw['customerName'] ?? raw['customer'] ?? '').toString();
    }

    final List<DebitNoteItem> items = <DebitNoteItem>[];
    final Object? itemsObj = raw['items'];
    if (itemsObj is List) {
      for (final Object? it in itemsObj) {
        if (it is Map<String, dynamic>) {
          items.add(
            DebitNoteItem(
              description: (it['description'] ?? it['name'] ?? '').toString(),
              qty: parseInt(it['quantity'], fallback: 1),
              price: parseDouble(it['unitPrice'] ?? it['price']),
              discount: parseDouble(it['discount']),
              vatCategory: (it['vatCategory'] ?? 'Standard').toString(),
              taxPercent: parseDouble(it['taxRate'] ?? it['taxPercent']),
            ),
          );
        }
      }
    }

    final String originalInvoiceNo =
        (raw['originalInvoiceNumber'] ?? raw['originalInvoiceNo'] ?? '').toString();

    String? originalInvoiceNumberFromRef() {
      final Object? o = raw['originalInvoiceId'] ?? raw['originalInvoice'];
      if (o is Map<String, dynamic>) {
        final Object? n = o['invoiceNumber'] ?? o['invoiceNo'] ?? o['formattedInvoiceNumber'];
        final String s = n?.toString() ?? '';
        return s.trim().isEmpty ? null : s.trim();
      }
      return null;
    }

    return DebitNote(
      backendId: backendId,
      id: debitNoteNo,
      customer: customerName(),
      customerType: (raw['customerType'] ?? '').toString(),
      issueDate: parseDate(raw['issueDate'] ?? raw['createdAt']),
      currency: (raw['currency'] ?? 'SAR').toString(),
      amount: parseDouble(raw['total'] ?? raw['amount']),
      status: parseStatus(raw['status']),
      paymentStatus: parsePaymentStatus(raw['paymentStatus']),
      originalInvoiceNo: (originalInvoiceNo.trim().isNotEmpty
              ? originalInvoiceNo.trim()
              : originalInvoiceNumberFromRef())
          ?.trim(),
      originalInvoiceCustomerType:
          (raw['originalInvoiceCustomerType'] ?? raw['invoiceCategory'] ?? '').toString(),
      zatcaUuid: raw['zatca'] is Map<String, dynamic>
          ? (raw['zatca'] as Map<String, dynamic>)['uuid']?.toString()
          : raw['zatcaUuid']?.toString(),
      zatcaHash: raw['zatca'] is Map<String, dynamic>
          ? (raw['zatca'] as Map<String, dynamic>)['hash']?.toString()
          : raw['zatcaHash']?.toString(),
      zatcaErrorMessage: raw['zatca'] is Map<String, dynamic>
          ? ((raw['zatca'] as Map<String, dynamic>)['errors']?.toString())
          : raw['zatcaErrorMessage']?.toString(),
      items: List<DebitNoteItem>.unmodifiable(items),
    );
  }
}
