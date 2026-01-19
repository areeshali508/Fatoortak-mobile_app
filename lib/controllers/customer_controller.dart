import 'package:flutter/material.dart';

import '../models/customer.dart';
import '../repositories/customer_repository.dart';

class CustomerController extends ChangeNotifier {
  CustomerRepository _repository;
  bool _isLoading = false;

  List<Customer> _customers = const <Customer>[];

  CustomerController({required CustomerRepository repository})
      : _repository = repository;

  bool get isLoading => _isLoading;

  List<Customer> get customers => _customers;

  void updateRepository(CustomerRepository repository) {
    _repository = repository;
  }

  Future<void> refresh() async {
    _isLoading = true;
    notifyListeners();
    try {
      _customers = await _repository.listCustomers();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
