import '../models/quotation.dart';
import '../core/services/api_client.dart';

class QuotationRepository {
  ApiClient _api;

  QuotationRepository({required ApiClient api}) : _api = api;

  void updateApi(ApiClient api) {
    _api = api;
  }

  Future<String?> getNextQuotationNumber({required String companyId}) async {
    final String id = companyId.trim();
    if (id.isEmpty) {
      throw const ApiClientException('Company id is required');
    }

    final Map<String, dynamic> res = await _api.getJson(
      '/api/quotations/next-number/$id',
    );

    final Object? data = res['data'] ?? res;
    if (data is String) {
      final String v = data.trim();
      return v.isEmpty ? null : v;
    }
    if (data is Map<String, dynamic>) {
      final String? v = (data['nextNumber'] ??
              data['quotationNumber'] ??
              data['quoteNumber'] ??
              data['formattedQuoteNumber'])
          ?.toString()
          .trim();
      if (v != null && v.isNotEmpty) {
        return v;
      }
    }
    return null;
  }

  Future<List<Quotation>> listQuotations({
    required String companyId,
    int page = 1,
    int limit = 10,
    String? status,
  }) async {
    final Map<String, String> qp = <String, String>{
      'companyId': companyId.trim(),
      'page': page.toString(),
      'limit': limit.toString(),
    };
    final String s = (status ?? '').trim();
    if (s.isNotEmpty) {
      qp['status'] = s;
    }

    final Map<String, dynamic> res = await _api.getJson(
      '/api/quotations',
      queryParameters: qp,
    );

    final Object? data = res['data'];
    Object? raw;
    if (data is Map<String, dynamic> && data['quotations'] is List) {
      raw = data['quotations'];
    } else {
      raw = data;
    }
    final List<dynamic> list = raw is List ? raw : <dynamic>[];
    return list
        .whereType<Map<String, dynamic>>()
        .map<Quotation>(Quotation.fromApi)
        .where((Quotation q) => q.id.trim().isNotEmpty)
        .toList();
  }

  String _toDateOnly(DateTime d) {
    final String mm = d.month.toString().padLeft(2, '0');
    final String dd = d.day.toString().padLeft(2, '0');
    return '${d.year}-$mm-$dd';
  }

  List<Map<String, dynamic>> _mapItems(
    List<QuotationItem> items, {
    required bool includeProduct,
  }) {
    return items.map((QuotationItem it) {
      final double taxRate = it.taxPercent;
      final String pid = it.productId.trim();
      final Map<String, dynamic> mapped = <String, dynamic>{
        if (includeProduct && pid.isNotEmpty) 'product': pid,
        'description': it.description,
        'quantity': it.qty,
        'unitPrice': it.price,
        'taxRate': taxRate,
        'discount': it.discountPercent,
      };
      return mapped;
    }).toList();
  }

  Quotation _parseQuotation(Map<String, dynamic> res) {
    final Object? data = res['data'] ?? res['quotation'] ?? res['quote'];
    Object? raw;
    if (data is Map<String, dynamic>) {
      raw = data['quotation'] ?? data['quote'] ?? data;
    } else {
      raw = data;
    }
    if (raw is Map<String, dynamic>) {
      return Quotation.fromApi(raw);
    }
    throw const ApiClientException('Invalid quotation response');
  }

  Future<Quotation> createQuotation({
    required String companyId,
    required String customerId,
    required List<QuotationItem> items,
    String quoteNumber = '',
    DateTime? issueDate,
    String currency = '',
    String paymentTerms = '',
    String terms = '',
    DateTime? validUntil,
    String notes = '',
  }) async {
    final String cid = companyId.trim();
    final String cust = customerId.trim();
    final String qn = quoteNumber.trim();
    final String cur = currency.trim();
    final String pay = paymentTerms.trim();
    final String t = terms.trim();

    final bool anyItemHasProduct = items.any(
      (QuotationItem it) => it.productId.trim().isNotEmpty,
    );

    String? nextNumberFromServer;

    Map<String, dynamic> baseBody({
      required bool includeProduct,
      String quoteNumberOverride = '',
    }) {
      final String useNumber = quoteNumberOverride.trim().isNotEmpty
          ? quoteNumberOverride.trim()
          : qn;

      return <String, dynamic>{
        'customerId': cust,
        'companyId': cid,
        'items': _mapItems(items, includeProduct: includeProduct),
        if (useNumber.isNotEmpty) 'quoteNumber': useNumber,
        if (issueDate != null) 'issueDate': _toDateOnly(issueDate),
        if (cur.isNotEmpty) 'currency': cur,
        if (pay.isNotEmpty) 'paymentTerms': pay,
        if (t.isNotEmpty) 'terms': t,
        if (validUntil != null) 'validUntil': _toDateOnly(validUntil),
        if (notes.trim().isNotEmpty) 'notes': notes.trim(),
      };
    }

    bool _samePayload(Map<String, dynamic> a, Map<String, dynamic> b) {
      if (a.length != b.length) return false;
      for (final MapEntry<String, dynamic> e in a.entries) {
        if (!b.containsKey(e.key)) return false;
        final dynamic av = e.value;
        final dynamic bv = b[e.key];
        if (av is List && bv is List) {
          if (av.length != bv.length) return false;
          for (int i = 0; i < av.length; i++) {
            final dynamic avi = av[i];
            final dynamic bvi = bv[i];
            if (avi is Map && bvi is Map) {
              if (avi.length != bvi.length) return false;
              for (final MapEntry<dynamic, dynamic> me in avi.entries) {
                if (!bvi.containsKey(me.key) || bvi[me.key] != me.value) {
                  return false;
                }
              }
            } else if (avi != bvi) {
              return false;
            }
          }
        } else if (av is Map && bv is Map) {
          if (av.length != bv.length) return false;
          for (final MapEntry<dynamic, dynamic> me in av.entries) {
            if (!bv.containsKey(me.key) || bv[me.key] != me.value) {
              return false;
            }
          }
        } else if (av != bv) {
          return false;
        }
      }
      return true;
    }

    try {
      final Map<String, dynamic> firstBody = baseBody(includeProduct: true);
      final Map<String, dynamic> res = await _api.postJson(
        '/api/quotations',
        body: firstBody,
      );
      return _parseQuotation(res);
    } on ApiClientException catch (e) {
      final String msg = e.toString().toLowerCase();

      final bool duplicateQuoteNumber =
          msg.contains('e11000') && msg.contains('quote') && msg.contains('number');

      if (duplicateQuoteNumber) {
        if (qn.isNotEmpty) {
          final Map<String, dynamic> altKeyBody =
              baseBody(includeProduct: true)..putIfAbsent('quotationNumber', () => qn);
          if (!_samePayload(baseBody(includeProduct: true), altKeyBody)) {
            try {
              final Map<String, dynamic> res = await _api.postJson(
                '/api/quotations',
                body: altKeyBody,
              );
              return _parseQuotation(res);
            } catch (_) {
              // fall through
            }
          }
        }

        try {
          final String? next = await getNextQuotationNumber(companyId: cid);
          if (next != null && next.trim().isNotEmpty) {
            final String nextTrim = next.trim();
            nextNumberFromServer = nextTrim;
          }
          final String? serverNext = nextNumberFromServer;
          if (serverNext != null &&
              serverNext.trim().isNotEmpty &&
              serverNext.trim() != qn) {
            final String nextTrim = serverNext.trim();
            final Map<String, dynamic> nextBody = baseBody(
              includeProduct: true,
              quoteNumberOverride: nextTrim,
            )
              ..putIfAbsent('quotationNumber', () => nextTrim);

            final Map<String, dynamic> res = await _api.postJson(
              '/api/quotations',
              body: nextBody,
            );
            return _parseQuotation(res);
          }
        } catch (_) {
          // ignore and rethrow original
        }

        final String? serverNextForMsg = nextNumberFromServer;
        final String suffix = serverNextForMsg != null && serverNextForMsg.trim().isNotEmpty
            ? ' (server next number: ${serverNextForMsg.trim()})'
            : '';
        throw ApiClientException(
          'Quotation number conflict$suffix. Please contact support/admin to reset quotation numbering for your company.',
          statusCode: e.statusCode,
        );
      }

      final bool customerRejected =
          msg.contains('customer not found') || msg.contains('not accessible');

      final bool productRejected = msg.contains('product') &&
          (msg.contains('not found') || msg.contains('not accessible'));

      if (customerRejected || productRejected) {
        final Map<String, dynamic> firstBody = baseBody(includeProduct: true);

        // Retry A: remove product ids if we actually had any.
        if (anyItemHasProduct) {
          final Map<String, dynamic> noProductBody = baseBody(includeProduct: false);
          if (!_samePayload(firstBody, noProductBody)) {
            final Map<String, dynamic> res = await _api.postJson(
              '/api/quotations',
              body: noProductBody,
            );
            return _parseQuotation(res);
          }
        }

        // Retry B: backend compatibility keys while keeping required fields.
        final Map<String, dynamic> compatBody = Map<String, dynamic>.from(
          baseBody(includeProduct: anyItemHasProduct),
        )
          ..putIfAbsent('customer', () => cust)
          ..putIfAbsent('company', () => cid);

        if (!_samePayload(firstBody, compatBody)) {
          final Map<String, dynamic> res = await _api.postJson(
            '/api/quotations',
            body: compatBody,
          );
          return _parseQuotation(res);
        }
      }

      rethrow;
    }
  }

  Future<String?> convertToInvoice({required String quotationId}) async {
    final String id = quotationId.trim();
    if (id.isEmpty) {
      throw const ApiClientException('Quotation id is required');
    }

    final Map<String, dynamic> res = await _api.postJson(
      '/api/quotations/$id/convert',
      body: const <String, dynamic>{},
    );

    final Object? data = res['data'] ?? res['invoice'] ?? res;
    Object? invoice;
    if (data is Map<String, dynamic>) {
      invoice = data['invoice'] ?? data['data'] ?? data;
    } else {
      invoice = data;
    }

    if (invoice is Map<String, dynamic>) {
      final String? invId = (invoice['invoiceNo'] ?? invoice['_id'] ?? invoice['id'])
          ?.toString()
          .trim();
      if (invId != null && invId.isNotEmpty) {
        return invId;
      }
    }
    return null;
  }
}
