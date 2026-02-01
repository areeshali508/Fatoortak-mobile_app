import '../core/services/api_client.dart';
import '../models/company.dart';

class CompanyRepository {
  ApiClient _api;

  CompanyRepository({required ApiClient api}) : _api = api;

  void updateApi(ApiClient api) {
    _api = api;
  }

  Future<List<Company>> listCompanies({int page = 1, int limit = 50}) async {
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
}
