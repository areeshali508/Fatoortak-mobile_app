import 'package:flutter/material.dart';

import '../models/product.dart';
import '../repositories/product_repository.dart';

class ProductController extends ChangeNotifier {
  ProductRepository _repository;
  bool _isLoading = false;

  List<Product> _products = const <Product>[];

  ProductController({required ProductRepository repository})
    : _repository = repository;

  bool get isLoading => _isLoading;

  List<Product> get products => _products;

  void updateRepository(ProductRepository repository) {
    _repository = repository;
  }

  Future<void> refresh() async {
    _isLoading = true;
    notifyListeners();
    try {
      _products = await _repository.listProducts();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
