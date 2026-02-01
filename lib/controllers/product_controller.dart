import 'package:flutter/material.dart';

import '../models/product.dart';
import '../repositories/product_repository.dart';

class ProductController extends ChangeNotifier {
  ProductRepository _repository;
  bool _isLoading = false;
  String? _errorMessage;

  List<Product> _products = const <Product>[];

  ProductController({required ProductRepository repository})
    : _repository = repository;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  List<Product> get products => _products;

  void updateRepository(ProductRepository repository) {
    _repository = repository;
  }

  Future<void> refresh({
    String? companyId,
    int page = 1,
    int limit = 50,
    String? search,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _products = await _repository.listProducts(
        companyId: companyId,
        page: page,
        limit: limit,
        search: search,
      );
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addProduct(Product product) async {
    await _repository.addProduct(product);
    _products = await _repository.listProducts();
    notifyListeners();
  }

  Future<void> addProductToBackend({
    required Product draft,
    required String companyId,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _repository.createProduct(draft: draft, companyId: companyId);
      _products = await _repository.listProducts(companyId: companyId);
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
