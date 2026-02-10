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

    final List<Future<Map<String, dynamic>> Function()> calls =
        <Future<Map<String, dynamic>> Function()>[
      () => _api.getJson('/api/quotations/next-number/$id'),
      () => _api.getJson(
            '/api/quotations/next-number',
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
          final Object? candidate = data['data'] ?? data['quotation'] ?? data;
          if (candidate is Map<String, dynamic>) {
            final Object? nested = candidate['quotation'] ?? candidate;
            if (nested is Map<String, dynamic>) {
              final String? v = (nested['nextNumber'] ??
                      nested['quotationNumber'] ??
                      nested['quoteNumber'] ??
                      nested['formattedQuoteNumber'])
                  ?.toString()
                  .trim();
              if (v != null && v.isNotEmpty) {
                return v;
              }
            }
          }

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
      } catch (_) {
        // try next
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

  Future<Quotation> getQuotationById({required String quotationId}) async {
    final String id = quotationId.trim();
    if (id.isEmpty) {
      throw const ApiClientException('Quotation id is required');
    }

    final Map<String, dynamic> res = await _api.getJson(
      '/api/quotations/$id',
    );

    return _parseQuotation(res);
  }

  Future<Quotation> markQuotationAccepted({required String quotationId}) async {
    final String id = quotationId.trim();
    if (id.isEmpty) {
      throw const ApiClientException('Quotation id is required');
    }

    ApiClientException? last;

    Future<Quotation> attempt(Future<Map<String, dynamic>> Function() call) async {
      final Map<String, dynamic> res = await call();
      return _parseQuotation(res);
    }

    final List<Future<Quotation> Function()> attempts = <Future<Quotation> Function()>[
      () => attempt(
            () => _api.patchJson(
              '/api/quotations/$id',
              body: const <String, dynamic>{'outcomeStatus': 'accepted'},
            ),
          ),
      () => attempt(
            () => _api.patchJson(
              '/api/quotations/$id',
              body: const <String, dynamic>{'status': 'accepted'},
            ),
          ),
      () => attempt(
            () => _api.patchJson(
              '/api/quotations/$id/status',
              body: const <String, dynamic>{'outcomeStatus': 'accepted'},
            ),
          ),
      () => attempt(
            () => _api.patchJson(
              '/api/quotations/$id/status',
              body: const <String, dynamic>{'status': 'accepted'},
            ),
          ),
      () => attempt(
            () => _api.postJson(
              '/api/quotations/$id/accept',
              body: const <String, dynamic>{},
            ),
          ),
      () => attempt(
            () => _api.postJson(
              '/api/quotations/$id/approve',
              body: const <String, dynamic>{},
            ),
          ),
    ];

    for (final Future<Quotation> Function() fn in attempts) {
      try {
        return await fn();
      } on ApiClientException catch (e) {
        last = e;
      }
    }

    throw ApiClientException(
      last?.message ?? 'Failed to mark quotation as accepted',
      statusCode: last?.statusCode,
    );
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

    bool samePayload(Map<String, dynamic> a, Map<String, dynamic> b) {
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
      final String rawMsg = e.toString();
      final String msg = rawMsg.toLowerCase();

      String? extractDuplicateQuoteNumber(String raw) {
        final RegExp a = RegExp(r'quoteNumber:\s*"([^"]+)"');
        final RegExp b = RegExp(r'quoteNumber:\s*\\"([^\\"]+)\\"');
        final RegExpMatch? ma = a.firstMatch(raw);
        final RegExpMatch? mb = b.firstMatch(raw);
        final String? v = (ma?.groupCount ?? 0) >= 1
            ? ma!.group(1)
            : ((mb?.groupCount ?? 0) >= 1 ? mb!.group(1) : null);
        final String out = (v ?? '').trim();
        return out.isEmpty ? null : out;
      }

      String? incrementQuoteNumber(String v) {
        final RegExpMatch? m = RegExp(r'^(.*?)(\d+)$').firstMatch(v.trim());
        if (m == null) return null;
        final String prefix = (m.group(1) ?? '');
        final String digits = (m.group(2) ?? '');
        final int? n = int.tryParse(digits);
        if (n == null) return null;
        final String nextDigits = (n + 1).toString().padLeft(digits.length, '0');
        final String out = '$prefix$nextDigits'.trim();
        return out.isEmpty ? null : out;
      }

      final bool duplicateQuoteNumber =
          msg.contains('e11000') && msg.contains('quote') && msg.contains('number');

      if (duplicateQuoteNumber) {
        final String? dup = extractDuplicateQuoteNumber(rawMsg);
        if (qn.isNotEmpty) {
          final Map<String, dynamic> altKeyBody =
              baseBody(includeProduct: true)..putIfAbsent('quotationNumber', () => qn);
          if (!samePayload(baseBody(includeProduct: true), altKeyBody)) {
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

        try {
          final String? inc = incrementQuoteNumber(dup ?? qn);
          if (inc != null && inc.trim().isNotEmpty && inc.trim() != qn) {
            final String use = inc.trim();
            final Map<String, dynamic> incBody = baseBody(
              includeProduct: true,
              quoteNumberOverride: use,
            )
              ..putIfAbsent('quotationNumber', () => use);
            final Map<String, dynamic> res = await _api.postJson(
              '/api/quotations',
              body: incBody,
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
        final String dupPart = dup != null && dup.trim().isNotEmpty
            ? ' Duplicate: ${dup.trim()}.'
            : '';
        final String attemptedPart = qn.isNotEmpty ? ' Attempted: $qn.' : '';
        throw ApiClientException(
          'Quotation number conflict.$dupPart$attemptedPart$suffix Please contact support/admin to reset quotation numbering for your company.',
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
          if (!samePayload(firstBody, noProductBody)) {
            final Map<String, dynamic> res = await _api.postJson(
              '/api/quotations',
              body: noProductBody,
            );
            return _parseQuotation(res);
          }
        }

        // Retry B: backend compatibility key remaps.
        // Some backends accept `customer`/`company` instead of `customerId`/`companyId`
        // and may reject payloads that send both.
        final List<Map<String, dynamic>> variants = <Map<String, dynamic>>[
          // Variant 1: customer + companyId
          <String, dynamic>{
            ...baseBody(includeProduct: anyItemHasProduct),
            'customer': cust,
          }..remove('customerId'),
          // Variant 2: customer + company
          <String, dynamic>{
            ...baseBody(includeProduct: anyItemHasProduct),
            'customer': cust,
            'company': cid,
          }
            ..remove('customerId')
            ..remove('companyId'),
          // Variant 3: customerId + company
          <String, dynamic>{
            ...baseBody(includeProduct: anyItemHasProduct),
            'company': cid,
          }..remove('companyId'),
        ];

        for (final Map<String, dynamic> body in variants) {
          if (samePayload(firstBody, body)) continue;
          try {
            final Map<String, dynamic> res = await _api.postJson(
              '/api/quotations',
              body: body,
            );
            return _parseQuotation(res);
          } catch (_) {
            // try next variant
          }
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
