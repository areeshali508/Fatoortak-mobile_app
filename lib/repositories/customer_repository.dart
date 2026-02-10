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

    final String normalizedType;
    switch (type.toLowerCase()) {
      case 'company':
      case 'business':
      case 'b2b':
        normalizedType = 'B2B';
        break;
      case 'individual':
      case 'person':
      case 'b2c':
        normalizedType = 'B2C';
        break;
      default:
        normalizedType = type;
    }

    final Map<String, dynamic> body = <String, dynamic>{
      'customerName': name,
      'customerType': normalizedType,
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

    final String rawType =
        (json['customerType'] ?? json['type'])?.toString().trim() ?? '';
    final String customerType;
    switch (rawType.toLowerCase()) {
      case 'company':
      case 'business':
      case 'b2b':
        customerType = 'B2B';
        break;
      case 'individual':
      case 'person':
      case 'b2c':
        customerType = 'B2C';
        break;
      default:
        customerType = rawType;
    }

    final Object? contactInfo = json['contactInfo'];
    final Map<String, dynamic>? contact =
        contactInfo is Map<String, dynamic> ? contactInfo : null;

    final Object? addressRaw = json['address'];
    final Map<String, dynamic>? address =
        addressRaw is Map<String, dynamic> ? addressRaw : null;

    final Object? complianceRaw = json['complianceInfo'];
    final Map<String, dynamic>? compliance =
        complianceRaw is Map<String, dynamic> ? complianceRaw : null;

    final Object? bankRaw = json['bankInfo'];
    final Map<String, dynamic>? bank = bankRaw is Map<String, dynamic> ? bankRaw : null;

    final Object? paymentLimitsRaw = json['paymentLimits'];
    final Map<String, dynamic>? paymentLimits =
        paymentLimitsRaw is Map<String, dynamic> ? paymentLimitsRaw : null;

    final List<String> tags = (json['tags'] is List)
        ? (json['tags'] as List)
            .map((Object? e) => e?.toString() ?? '')
            .where((String s) => s.trim().isNotEmpty)
            .toList()
        : const <String>[];

    DateTime? parseDate(Object? raw) {
      if (raw == null) return null;
      final String s = raw.toString().trim();
      if (s.isEmpty) return null;
      return DateTime.tryParse(s);
    }

    final String taxId = (compliance?['taxId'] ??
            compliance?['vatNumber'] ??
            compliance?['vat'] ??
            json['taxId'] ??
            json['vatNumber'] ??
            json['vat'])
        ?.toString() ??
        '';
    return Customer(
      id: (json['_id'] ?? json['id'])?.toString() ?? '',
      companyId: companyId,
      name: (json['customerName'] ?? json['name'])?.toString() ?? '',
      nameAr: (json['customerNameAr'] ?? json['nameAr'])?.toString() ?? '',
      email: (contact?['email'] ?? json['email'])?.toString() ?? '',
      phone: (contact?['phone'] ?? json['phone'])?.toString() ?? '',
      contactPerson: (contact?['contactPerson'] ?? json['contactPerson'])
              ?.toString() ??
          '',

      customerType: customerType,
      customerGroup: (json['customerGroup'] ?? json['group'])?.toString() ?? '',
      taxId: taxId,
      commercialRegistrationNumber:
          (json['commercialRegistrationNumber'] ?? json['crNumber'])?.toString() ?? '',
      industry: json['industry']?.toString() ?? '',
      website: json['website']?.toString() ?? '',
      notes: json['notes']?.toString() ?? '',

      street: address?['street']?.toString() ?? '',
      city: address?['city']?.toString() ?? '',
      state: address?['state']?.toString() ?? '',
      postalCode: address?['postalCode']?.toString() ?? '',
      country: address?['country']?.toString() ?? '',
      buildingNumber: address?['buildingNumber']?.toString() ?? '',
      district: address?['district']?.toString() ?? '',
      addressAdditionalNumber:
          address?['addressAdditionalNumber']?.toString() ?? '',

      bankName: bank?['bankName']?.toString() ?? '',
      accountNumber: bank?['accountNumber']?.toString() ?? '',
      iban: bank?['iban']?.toString() ?? '',
      swiftCode: (bank?['swiftCode'] ?? bank?['swiftBic'])?.toString() ?? '',
      currency: bank?['currency']?.toString() ?? '',

      creditLimit: (json['creditLimit'] is num)
          ? (json['creditLimit'] as num)
          : num.tryParse('${json['creditLimit'] ?? ''}') ?? 0,
      discount: (json['discount'] is num)
          ? (json['discount'] as num)
          : num.tryParse('${json['discount'] ?? ''}') ?? 0,

      dailyLimit: (paymentLimits?['dailyLimit'] is num)
          ? (paymentLimits?['dailyLimit'] as num)
          : num.tryParse('${paymentLimits?['dailyLimit'] ?? ''}') ?? 0,
      monthlyLimit: (paymentLimits?['monthlyLimit'] is num)
          ? (paymentLimits?['monthlyLimit'] as num)
          : num.tryParse('${paymentLimits?['monthlyLimit'] ?? ''}') ?? 0,
      perTransactionLimit: (paymentLimits?['perTransactionLimit'] is num)
          ? (paymentLimits?['perTransactionLimit'] as num)
          : num.tryParse('${paymentLimits?['perTransactionLimit'] ?? ''}') ?? 0,

      status: json['status']?.toString() ?? '',
      verificationStatus: json['verificationStatus']?.toString() ?? '',
      isActive: (json['isActive'] is bool)
          ? (json['isActive'] as bool)
          : ((json['active'] is bool) ? (json['active'] as bool) : true),
      referenceNumber: json['referenceNumber']?.toString() ?? '',

      tags: tags,
      source: json['source']?.toString() ?? '',
      priority: json['priority']?.toString() ?? '',
      assignedTo: json['assignedTo']?.toString() ?? '',
      totalPaymentsReceived: (json['totalPaymentsReceived'] is num)
          ? (json['totalPaymentsReceived'] as num)
          : num.tryParse('${json['totalPaymentsReceived'] ?? ''}') ?? 0,
      paymentCount: (json['paymentCount'] is num)
          ? (json['paymentCount'] as num)
          : num.tryParse('${json['paymentCount'] ?? ''}') ?? 0,
      lastPaymentDate: parseDate(json['lastPaymentDate']),
      createdAt: parseDate(json['createdAt']),
      updatedAt: parseDate(json['updatedAt']),
    );
  }
}
