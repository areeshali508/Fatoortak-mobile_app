import '../core/services/api_client.dart';

class ZatcaRepository {
  ApiClient _api;

  ZatcaRepository({required ApiClient api}) : _api = api;

  void updateApi(ApiClient api) {
    _api = api;
  }

  Future<Map<String, dynamic>> getStatus({required String companyId}) async {
    return _api.getJson('/api/companies/$companyId/zatca/status');
  }

  Future<Map<String, dynamic>> generateCsr({
    required String companyId,
    required String commonName,
    required String organizationIdentifier,
  }) async {
    return _api.postJson(
      '/api/companies/$companyId/zatca/generate-csr',
      queryParameters: <String, String>{
        'CommonName': commonName,
        'OrganizationIdentifier': organizationIdentifier,
        'commonName': commonName,
        'organizationIdentifier': organizationIdentifier,
        'common_name': commonName,
        'organization_identifier': organizationIdentifier,
      },
      body: <String, dynamic>{
        // Intentionally empty: backend appears to not parse request body for this route.
      },
    );
  }

  Future<Map<String, dynamic>> getComplianceCert({required String companyId}) async {
    return _api.postJson(
      '/api/companies/$companyId/zatca/compliance-cert',
      body: const <String, dynamic>{},
    );
  }

  Future<Map<String, dynamic>> getProductionCsid({required String companyId}) async {
    return _api.postJson(
      '/api/companies/$companyId/zatca/production-csid',
      body: const <String, dynamic>{},
    );
  }

  Future<Map<String, dynamic>> validateInvoice({required String invoiceId}) async {
    return _api.postJson(
      '/api/invoices/$invoiceId/zatca/validate',
      body: const <String, dynamic>{},
    );
  }

  Future<Map<String, dynamic>> getInvoiceQrCode({required String invoiceId}) async {
    return _api.getJson('/api/invoices/$invoiceId/zatca/qrcode');
  }

  Future<Map<String, dynamic>> getInvoicePdf({required String invoiceId}) async {
    return _api.getJson('/api/invoices/$invoiceId/zatca/pdf');
  }

  Future<String> getInvoicePdfText({required String invoiceId}) async {
    return _api.getText('/api/invoices/$invoiceId/zatca/pdf');
  }
}
