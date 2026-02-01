import 'package:flutter/material.dart';

import '../controllers/auth_controller.dart';
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
      _lastResult = await action();
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
      _lastResult = await _repository.validateInvoice(invoiceId: invoiceId.trim());
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
