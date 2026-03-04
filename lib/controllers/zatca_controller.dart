import 'package:flutter/material.dart';

import 'dart:convert';
import 'dart:typed_data';

import '../controllers/auth_controller.dart';
import '../core/services/api_client.dart';
import '../repositories/zatca_repository.dart';

class ZatcaController extends ChangeNotifier {
  final ZatcaRepository _repository;
  final AuthController _auth;

  bool _isLoading = false;
  String? _errorMessage;
  Map<String, dynamic>? _status;
  Map<String, dynamic>? _lastResult;

  ZatcaController({
    required ZatcaRepository repository,
    required AuthController auth,
  }) : _repository = repository,
       _auth = auth;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  Map<String, dynamic>? get status => _status;
  Map<String, dynamic>? get lastResult => _lastResult;

  Map<String, dynamic> _unwrap(Object? res) {
    if (res is Map<String, dynamic>) {
      final Object? data = res['data'];
      if (data is Map<String, dynamic>) {
        return data;
      }
      return res;
    }
    return <String, dynamic>{'value': res};
  }

  Future<void> loadStatus({required String companyId}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _status = await _repository.getStatus(companyId: companyId.trim());
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> reportInvoice({required String invoiceId}) async {
    if (invoiceId.trim().isEmpty) {
      _errorMessage = 'Invoice ID is required';
      notifyListeners();
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    _lastResult = null;
    notifyListeners();

    try {
      _lastResult = _unwrap(
        await _repository.reportInvoice(invoiceId: invoiceId.trim()),
      );
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> submitInvoice({required String invoiceId}) async {
    if (invoiceId.trim().isEmpty) {
      _errorMessage = 'Invoice ID is required';
      notifyListeners();
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    _lastResult = null;
    notifyListeners();

    try {
      _lastResult = _unwrap(
        await _repository.submitInvoice(invoiceId: invoiceId.trim()),
      );
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> clearInvoice({required String invoiceId}) async {
    if (invoiceId.trim().isEmpty) {
      _errorMessage = 'Invoice ID is required';
      notifyListeners();
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    _lastResult = null;
    notifyListeners();

    try {
      _lastResult = _unwrap(
        await _repository.clearInvoice(invoiceId: invoiceId.trim()),
      );
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> submitOrClearInvoice({required String invoiceId}) async {
    if (invoiceId.trim().isEmpty) {
      _errorMessage = 'Invoice ID is required';
      notifyListeners();
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    _lastResult = null;
    notifyListeners();

    try {
      try {
        _lastResult = _unwrap(
          await _repository.sendInvoice(invoiceId: invoiceId.trim()),
        );
      } on ApiClientException catch (eSend) {
        final String msg = eSend.message.toLowerCase();
        final bool isDuplicate = (eSend.statusCode == 400) &&
            (msg.contains('e11000') || msg.contains('duplicate key'));
        if (isDuplicate) {
          _lastResult = <String, dynamic>{
            'success': true,
            'message': 'Already processed',
          };
          return;
        }

        if (eSend.statusCode != 404 && eSend.statusCode != 405) {
          rethrow;
        }

        try {
        _lastResult = _unwrap(
          await _repository.reportInvoice(invoiceId: invoiceId.trim()),
        );
        } on ApiClientException catch (e0) {
          if (e0.statusCode != 404 && e0.statusCode != 405) {
            rethrow;
          }

          try {
            _lastResult = _unwrap(
              await _repository.submitInvoice(invoiceId: invoiceId.trim()),
            );
          } on ApiClientException catch (e1) {
            if (e1.statusCode != 404 && e1.statusCode != 405) {
              rethrow;
            }

            try {
              _lastResult = _unwrap(
                await _repository.clearInvoice(invoiceId: invoiceId.trim()),
              );
            } on ApiClientException catch (e2) {
              if (e2.statusCode != 404 && e2.statusCode != 405) {
                rethrow;
              }

              // Some backends only expose /zatca/validate (even if web UI calls it "submit").
              _lastResult = _unwrap(
                await _repository.validateInvoice(invoiceId: invoiceId.trim()),
              );
            }
          }
        }
      }
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> generateCsr({
    required String companyId,
    required String commonName,
    required String organizationIdentifier,
  }) async {
    if (commonName.trim().isEmpty || organizationIdentifier.trim().isEmpty) {
      _errorMessage = 'CommonName and OrganizationIdentifier are required';
      notifyListeners();
      return;
    }
    await _runCompanyAction(
      companyId: companyId,
      action: () => _repository.generateCsr(
        companyId: companyId.trim(),
        commonName: commonName.trim(),
        organizationIdentifier: organizationIdentifier.trim(),
      ),
    );
  }

  Future<void> getComplianceCert({required String companyId}) async {
    await _runCompanyAction(
      companyId: companyId,
      action: () => _repository.getComplianceCert(companyId: companyId.trim()),
    );
  }

  Future<void> getProductionCsid({required String companyId}) async {
    await _runCompanyAction(
      companyId: companyId,
      action: () => _repository.getProductionCsid(companyId: companyId.trim()),
    );
  }

  Future<void> _runCompanyAction({
    required String companyId,
    required Future<Map<String, dynamic>> Function() action,
  }) async {
    if (companyId.trim().isEmpty) {
      _errorMessage = 'Company ID is required';
      notifyListeners();
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    _lastResult = null;
    notifyListeners();

    try {
      _lastResult = _unwrap(await action());
      await loadStatus(companyId: companyId);
      await _auth.refreshMyCompany();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> validateInvoice({required String invoiceId}) async {
    if (invoiceId.trim().isEmpty) {
      _errorMessage = 'Invoice ID is required';
      notifyListeners();
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    _lastResult = null;
    notifyListeners();

    try {
      _lastResult = _unwrap(
        await _repository.validateInvoice(invoiceId: invoiceId.trim()),
      );
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  String? _extractBase64Pdf(Object? raw) {
    if (raw == null) return null;

    if (raw is Map<String, dynamic>) {
      final Object? v = raw['pdf'] ??
          raw['pdfUrl'] ??
          raw['pdfBase64'] ??
          raw['base64'] ??
          raw['content'] ??
          raw['data'];
      return _extractBase64Pdf(v);
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

  Future<Uint8List?> getInvoicePdfBytes({
    required String invoiceId,
    String? fallbackBase64,
  }) async {
    if (invoiceId.trim().isEmpty) {
      _errorMessage = 'Invoice ID is required';
      notifyListeners();
      return null;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final String? direct = _extractBase64Pdf(fallbackBase64);
      if (direct != null && direct.trim().isNotEmpty) {
        try {
          final String cleaned = _normalizeBase64(direct.trim());
          return base64Decode(cleaned);
        } catch (_) {
          // ignore and fall back to network
        }
      }

      String? b64;
      try {
        final Map<String, dynamic> res =
            await _repository.getInvoicePdf(invoiceId: invoiceId.trim());
        final Map<String, dynamic> data = _unwrap(res);
        b64 = _extractBase64Pdf(data) ?? _extractBase64Pdf(res);
      } catch (_) {
        final String raw =
            await _repository.getInvoicePdfText(invoiceId: invoiceId.trim());
        b64 = _extractBase64Pdf(raw);
      }

      if (b64 == null || b64.trim().isEmpty) {
        _errorMessage = 'PDF not available';
        return null;
      }

      final String cleaned = _normalizeBase64(b64.trim());
      return base64Decode(cleaned);
    } catch (e) {
      _errorMessage = e.toString();
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
