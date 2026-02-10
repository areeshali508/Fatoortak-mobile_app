import '../core/services/api_client.dart';
import '../models/company.dart';

class CompanyRepository {
  ApiClient _api;

  CompanyRepository({required ApiClient api}) : _api = api;

  void updateApi(ApiClient api) {
    _api = api;
  }

  Map<String, dynamic>? _extractCompanyMap(Map<String, dynamic> res) {
    final Object? data = res['data'] ?? res;
    if (data is Map<String, dynamic>) {
      final Object? inner = data['company'] ?? data['data'] ?? data;
      if (inner is Map<String, dynamic>) {
        return inner;
      }
      return data;
    }
    return null;
  }

  List<Map<String, dynamic>> _extractCompanyList(Map<String, dynamic> res) {
    Object? cur = res['data'] ?? res;

    for (int i = 0; i < 4; i++) {
      if (cur is List) {
        return cur.whereType<Map<String, dynamic>>().toList();
      }
      if (cur is! Map<String, dynamic>) {
        return const <Map<String, dynamic>>[];
      }

      final Object? next = cur['companies'] ??
          cur['results'] ??
          cur['items'] ??
          cur['data'] ??
          cur['company'] ??
          cur['payload'];
      if (next == null) {
        return const <Map<String, dynamic>>[];
      }
      cur = next;
    }

    if (cur is List) {
      return cur.whereType<Map<String, dynamic>>().toList();
    }
    return const <Map<String, dynamic>>[];
  }

  Future<List<Map<String, dynamic>>> _listMyCompanyMaps() async {
    final List<Future<Map<String, dynamic>> Function()> calls =
        <Future<Map<String, dynamic>> Function()>[
      () => _api.getJson('/api/companies/created-by-me'),
      () => _api.getJson('/api/companies/my'),
      () => _api.getJson('/api/companies/mine'),
      () => _api.getJson(
            '/api/companies',
            queryParameters: const <String, String>{'scope': 'mine'},
          ),
    ];

    for (final Future<Map<String, dynamic>> Function() fn in calls) {
      try {
        final Map<String, dynamic> res = await fn();
        final List<Map<String, dynamic>> list = _extractCompanyList(res)
            .where((Map<String, dynamic> c) {
              final String id = (c['_id'] ?? c['id'])?.toString().trim() ?? '';
              return id.isNotEmpty;
            })
            .toList();
        if (list.isNotEmpty) {
          final Set<String> seen = <String>{};
          final List<Map<String, dynamic>> out = <Map<String, dynamic>>[];
          for (final Map<String, dynamic> c in list) {
            final String id = (c['_id'] ?? c['id'])?.toString().trim() ?? '';
            if (id.isEmpty || seen.contains(id)) continue;
            seen.add(id);
            out.add(c);
          }
          return out;
        }
      } catch (_) {
        // try next
      }
    }

    final Map<String, dynamic> res = await _api.getJson('/api/companies/me');
    final Map<String, dynamic>? c = _extractCompanyMap(res);
    if (c == null) return const <Map<String, dynamic>>[];

    final String id = (c['_id'] ?? c['id'])?.toString().trim() ?? '';
    if (id.isEmpty) return const <Map<String, dynamic>>[];
    return <Map<String, dynamic>>[c];
  }

  Future<List<Company>> listCompanies({int page = 1, int limit = 50}) async {
    try {
      final List<Map<String, dynamic>> mine = await _listMyCompanyMaps();
      if (mine.isNotEmpty) {
        return mine
            .map(Company.fromJson)
            .where((Company c) => c.id.trim().isNotEmpty)
            .toList();
      }
    } catch (_) {
      // fall back
    }

    final Map<String, dynamic> res = await _api.getJson(
      '/api/companies',
      queryParameters: <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
      },
    );

    final Object? data = res['data'];

    Object? raw;
    if (data is Map<String, dynamic> && data['companies'] is List) {
      raw = data['companies'];
    } else {
      raw = data;
    }

    final List<dynamic> list = raw is List ? raw : <dynamic>[];
    return list
        .whereType<Map<String, dynamic>>()
        .map(Company.fromJson)
        .where((Company c) => c.id.trim().isNotEmpty)
        .toList();
  }

  Future<List<Map<String, dynamic>>> listCompanyMaps({int page = 1, int limit = 50}) async {
    try {
      final List<Map<String, dynamic>> mine = await _listMyCompanyMaps();
      if (mine.isNotEmpty) {
        return mine;
      }
    } catch (_) {
      // fall back
    }

    final Map<String, dynamic> res = await _api.getJson(
      '/api/companies',
      queryParameters: <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
      },
    );

    final Object? data = res['data'] ?? res;

    Object? raw;
    if (data is Map<String, dynamic> && data['companies'] is List) {
      raw = data['companies'];
    } else if (data is List) {
      raw = data;
    } else {
      raw = null;
    }

    final List<dynamic> list = raw is List ? raw : <dynamic>[];
    return list.whereType<Map<String, dynamic>>().toList();
  }
}
