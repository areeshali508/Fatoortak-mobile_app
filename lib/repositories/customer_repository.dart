import '../models/customer.dart';
import '../core/services/api_client.dart';

class CustomerRepository {
  ApiClient _api;

  CustomerRepository({required ApiClient api}) : _api = api;

  void updateApi(ApiClient api) {
    _api = api;
  }

  Future<List<Customer>> listCustomers({
    required String companyId,
    int page = 1,
    int limit = 50,
    String? search,
  }) async {
    final String companyFilter = companyId.trim();
    final Map<String, String> qp = <String, String>{
      'companyId': companyFilter,
      'page': page.toString(),
      'limit': limit.toString(),
    };
    if (search != null && search.trim().isNotEmpty) {
      qp['search'] = search.trim();
    }

    final Map<String, dynamic> res = await _api.getJson(
      '/api/customers',
      queryParameters: qp,
    );

    final Object? data = res['data'];
    if (data is Map<String, dynamic>) {
      final Object? customers = data['customers'];
      if (customers is List) {
        final List<Customer> mapped = customers
            .whereType<Map<String, dynamic>>()
            .map(_mapCustomer)
            .where((Customer c) => c.id.trim().isNotEmpty)
            .toList();
        if (companyFilter.isEmpty) {
          return mapped;
        }
        return mapped.where((Customer c) {
          final String cid = c.companyId.trim();
          if (cid.isEmpty) return true;
          return cid == companyFilter;
        }).toList();
      }
    }
    return <Customer>[];
  }

  Future<Customer> createCustomer({
    required String companyId,
    required String customerName,
    required String customerType,
    String email = '',
    String phone = '',
    String taxId = '',
  }) async {
    final String cid = companyId.trim();
    if (cid.isEmpty) {
      throw const ApiClientException('Company id is required');
    }
    final String name = customerName.trim();
    if (name.isEmpty) {
      throw const ApiClientException('Customer name is required');
    }
    final String type = customerType.trim();
    if (type.isEmpty) {
      throw const ApiClientException('Customer type is required');
    }

    final Map<String, dynamic> body = <String, dynamic>{
      'customerName': name,
      'customerType': type,
      'companyId': cid,
      if (email.trim().isNotEmpty) 'email': email.trim(),
      if (phone.trim().isNotEmpty) 'phone': phone.trim(),
      if (taxId.trim().isNotEmpty) 'taxId': taxId.trim(),
    };

    final Map<String, dynamic> res = await _api.postJson(
      '/api/customers',
      body: body,
    );

    Object? raw = res['data'] ?? res['customer'];
    if (raw is Map<String, dynamic>) {
      raw = raw['customer'] ?? raw['data'] ?? raw;
    }
    if (raw is Map) {
      return _mapCustomer(raw.cast<String, dynamic>());
    }
    throw const ApiClientException('Invalid customer create response');
  }

  Customer _mapCustomer(Map<String, dynamic> json) {
    String companyId = '';
    final Object? companyRaw = json['companyId'] ?? json['company'];
    if (companyRaw is Map<String, dynamic>) {
      companyId = (companyRaw['_id'] ?? companyRaw['id'])?.toString() ?? '';
    } else {
      companyId = companyRaw?.toString() ?? '';
    }

    final Object? contactInfo = json['contactInfo'];
    final Map<String, dynamic>? contact =
        contactInfo is Map<String, dynamic> ? contactInfo : null;
    return Customer(
      id: (json['_id'] ?? json['id'])?.toString() ?? '',
      companyId: companyId,
      name: (json['customerName'] ?? json['name'])?.toString() ?? '',
      email: (contact?['email'] ?? json['email'])?.toString() ?? '',
      phone: (contact?['phone'] ?? json['phone'])?.toString() ?? '',
    );
  }
}
