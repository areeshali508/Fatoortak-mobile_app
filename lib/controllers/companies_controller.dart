import 'package:flutter/material.dart';

import '../repositories/company_repository.dart';

class CompaniesController extends ChangeNotifier {
  final CompanyRepository _repository;

  bool _isLoading = false;
  String? _errorMessage;
  List<Map<String, dynamic>> _companies = const <Map<String, dynamic>>[];

  CompaniesController({required CompanyRepository repository})
      : _repository = repository;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<Map<String, dynamic>> get companies => _companies;

  Future<void> load({int page = 1, int limit = 50}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _companies = await _repository.listCompanyMaps(page: page, limit: limit);
    } catch (e) {
      _companies = const <Map<String, dynamic>>[];
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refresh({int page = 1, int limit = 50}) async {
    await load(page: page, limit: limit);
  }
}
