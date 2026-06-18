import 'package:flutter/material.dart';

import '../controllers/auth_controller.dart';
import '../models/customer.dart';
import '../repositories/customer_repository.dart';

class CustomerController extends ChangeNotifier {
  CustomerRepository _repository;
  bool _isLoading = false;
  String? _loadedCompanyId;
  bool _hasLoadedCompany = false;
  int _refreshRequestId = 0;

  List<Customer> _customers = const <Customer>[];

  CustomerController({required CustomerRepository repository})
    : _repository = repository;

  bool get isLoading => _isLoading;

  List<Customer> get customers => _customers;

  void updateRepository(CustomerRepository repository) {
    _repository = repository;
  }

  void syncWithAuth(AuthController auth) {
    final String? cid = auth.activeCompanyId;
    if (!auth.isAuthenticated || cid == null) {
      _customers = const <Customer>[];
      _loadedCompanyId = null;
      _hasLoadedCompany = false;
      notifyListeners();
    } else if (cid != _loadedCompanyId) {
      _customers = const <Customer>[];
      _loadedCompanyId = cid;
      _hasLoadedCompany = false;
      notifyListeners();
    }
  }

  Future<void> refresh({required String companyId, bool force = false}) async {
    final String cid = companyId.trim();
    if (cid.isEmpty) {
      return;
    }
    if (!force && _hasLoadedCompany && _loadedCompanyId == cid) {
      return;
    }

    final int requestId = ++_refreshRequestId;
    _isLoading = true;
    notifyListeners();
    try {
      final List<Customer> customers = await _repository.listCustomers(
        companyId: cid,
      );
      if (requestId != _refreshRequestId) {
        return;
      }
      _customers = customers;
      _loadedCompanyId = cid;
      _hasLoadedCompany = true;
    } finally {
      if (requestId == _refreshRequestId) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }
}
