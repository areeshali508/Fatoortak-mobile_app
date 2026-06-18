import 'package:flutter/material.dart';

import '../models/customer.dart';
import '../models/invoice.dart';
import '../models/pos_order.dart';
import '../models/product.dart';
import '../repositories/customer_repository.dart';
import '../repositories/invoice_repository.dart';
import '../repositories/product_repository.dart';

class PosController extends ChangeNotifier {
  final ProductRepository _productRepository;
  final CustomerRepository _customerRepository;
  final InvoiceRepository _invoiceRepository;

  PosController({
    required ProductRepository productRepository,
    required CustomerRepository customerRepository,
    required InvoiceRepository invoiceRepository,
  })  : _productRepository = productRepository,
        _customerRepository = customerRepository,
        _invoiceRepository = invoiceRepository;

  // ─── Company ────────────────────────────────────────────────────────────
  String? _companyId;
  String? get companyId => _companyId;

  void setCompanyId(String? id) {
    final String? next = (id ?? '').trim().isEmpty ? null : id!.trim();
    if (next == _companyId) return;
    _companyId = next;
    _cart.clear();
    _selectedCustomer = null;
    _products = const <Product>[];
    _filteredProducts = const <Product>[];
    _sessionOrders.clear();
    notifyListeners();
  }

  // ─── Products ────────────────────────────────────────────────────────────
  List<Product> _products = const <Product>[];
  List<Product> _filteredProducts = const <Product>[];
  bool _isLoadingProducts = false;
  String _productSearch = '';

  List<Product> get filteredProducts => _filteredProducts;
  bool get isLoadingProducts => _isLoadingProducts;
  String get productSearch => _productSearch;

  Future<void> loadProducts() async {
    final String cid = (_companyId ?? '').trim();
    _isLoadingProducts = true;
    notifyListeners();
    try {
      _products = await _productRepository.listProducts(
        companyId: cid.isEmpty ? null : cid,
        limit: 100,
      );
      _applySearch(_productSearch);
    } catch (_) {
      _products = const <Product>[];
      _filteredProducts = const <Product>[];
    } finally {
      _isLoadingProducts = false;
      notifyListeners();
    }
  }

  void setProductSearch(String q) {
    _productSearch = q.trim();
    _applySearch(_productSearch);
    notifyListeners();
  }

  void _applySearch(String q) {
    if (q.isEmpty) {
      _filteredProducts = _products;
      return;
    }
    final String lower = q.toLowerCase();
    _filteredProducts = _products.where((Product p) {
      return p.name.toLowerCase().contains(lower) ||
          p.sku.toLowerCase().contains(lower) ||
          p.barcode.toLowerCase().contains(lower);
    }).toList();
  }

  // ─── Customers ───────────────────────────────────────────────────────────
  List<Customer> _customers = const <Customer>[];
  bool _isLoadingCustomers = false;
  Customer? _selectedCustomer;

  List<Customer> get customers => _customers;
  bool get isLoadingCustomers => _isLoadingCustomers;
  Customer? get selectedCustomer => _selectedCustomer;

  Future<void> loadCustomers() async {
    final String cid = (_companyId ?? '').trim();
    if (cid.isEmpty) return;
    _isLoadingCustomers = true;
    notifyListeners();
    try {
      _customers = await _customerRepository.listCustomers(companyId: cid);
    } catch (_) {
      _customers = const <Customer>[];
    } finally {
      _isLoadingCustomers = false;
      notifyListeners();
    }
  }

  void selectCustomer(Customer? c) {
    _selectedCustomer = c;
    notifyListeners();
  }

  // ─── Cart ────────────────────────────────────────────────────────────────
  final List<PosCartItem> _cart = <PosCartItem>[];
  List<PosCartItem> get cart => List<PosCartItem>.unmodifiable(_cart);

  bool get cartIsEmpty => _cart.isEmpty;
  int get cartItemCount =>
      _cart.fold(0, (int s, PosCartItem i) => s + i.qty);
  double get cartSubtotal =>
      _cart.fold(0.0, (double s, PosCartItem i) => s + i.subtotal);
  double get cartTax =>
      _cart.fold(0.0, (double s, PosCartItem i) => s + i.taxAmount);
  double get cartTotal => cartSubtotal + cartTax;

  void addToCart(Product product) {
    final int idx =
        _cart.indexWhere((PosCartItem i) => i.productId == product.id);
    if (idx >= 0) {
      _cart[idx] = _cart[idx].copyWith(qty: _cart[idx].qty + 1);
    } else {
      _cart.add(PosCartItem(
        productId: product.id,
        name: product.name,
        sku: product.sku,
        price: product.price,
        taxRate: product.taxRate,
      ));
    }
    notifyListeners();
  }

  void incrementItem(int index) {
    if (index < 0 || index >= _cart.length) return;
    _cart[index] = _cart[index].copyWith(qty: _cart[index].qty + 1);
    notifyListeners();
  }

  void decrementItem(int index) {
    if (index < 0 || index >= _cart.length) return;
    if (_cart[index].qty <= 1) {
      removeFromCart(index);
      return;
    }
    _cart[index] = _cart[index].copyWith(qty: _cart[index].qty - 1);
    notifyListeners();
  }

  void removeFromCart(int index) {
    if (index < 0 || index >= _cart.length) return;
    _cart.removeAt(index);
    notifyListeners();
  }

  void clearCart() {
    _cart.clear();
    _selectedCustomer = null;
    _cashGiven = 0;
    _paymentMethod = PosPaymentMethod.cash;
    notifyListeners();
  }

  // ─── Payment ─────────────────────────────────────────────────────────────
  PosPaymentMethod _paymentMethod = PosPaymentMethod.cash;
  double _cashGiven = 0;

  PosPaymentMethod get paymentMethod => _paymentMethod;
  double get cashGiven => _cashGiven;
  double get change => (_cashGiven - cartTotal).clamp(0.0, double.infinity);

  void setPaymentMethod(PosPaymentMethod method) {
    if (_paymentMethod == method) return;
    _paymentMethod = method;
    notifyListeners();
  }

  void setCashGiven(double amount) {
    _cashGiven = amount;
    notifyListeners();
  }

  // ─── Checkout ────────────────────────────────────────────────────────────
  bool _isCheckingOut = false;
  String? _checkoutError;

  bool get isCheckingOut => _isCheckingOut;
  String? get checkoutError => _checkoutError;

  // ─── Session orders ───────────────────────────────────────────────────────
  final List<PosOrder> _sessionOrders = <PosOrder>[];
  List<PosOrder> get sessionOrders =>
      List<PosOrder>.unmodifiable(_sessionOrders);

  Future<PosOrder?> checkout() async {
    if (_cart.isEmpty) {
      _checkoutError = 'Cart is empty';
      notifyListeners();
      return null;
    }
    final String cid = (_companyId ?? '').trim();
    if (cid.isEmpty) {
      _checkoutError = 'No company selected';
      notifyListeners();
      return null;
    }

    _isCheckingOut = true;
    _checkoutError = null;
    notifyListeners();

    try {
      final DateTime now = DateTime.now();
      final String orderNumber =
          'POS-${now.year}${now.month.toString().padLeft(2, '0')}'
          '${now.day.toString().padLeft(2, '0')}'
          '-${now.millisecondsSinceEpoch % 100000}';

      final String customerId = (_selectedCustomer?.id ?? '').trim();

      if (customerId.isNotEmpty) {
        final List<InvoiceItem> invoiceItems = _cart
            .map((PosCartItem i) => InvoiceItem(
                  productId: i.productId,
                  product: i.name,
                  qty: i.qty,
                  price: i.price,
                  discount: 0,
                  vatCategory: '-',
                  taxPercent: i.taxRate,
                ))
            .toList();

        await _invoiceRepository.createInvoice(
          companyId: cid,
          customerId: customerId,
          invoiceDate: now,
          dueDate: now,
          items: invoiceItems,
          currency: 'SAR',
          invoiceType: 'simplified',
          paymentTerms: '0',
          invoiceNumber: orderNumber,
          notes: 'POS – ${_paymentMethod.name}',
        );
      }

      final PosOrder order = PosOrder(
        id: now.millisecondsSinceEpoch.toString(),
        orderNumber: orderNumber,
        createdAt: now,
        items: List<PosCartItem>.from(_cart),
        paymentMethod: _paymentMethod,
        status: PosOrderStatus.paid,
        cashGiven: _cashGiven,
        customerId: _selectedCustomer?.id,
        customerName: _selectedCustomer?.name,
        companyId: cid,
        currency: 'SAR',
      );

      _sessionOrders.insert(0, order);
      clearCart();
      return order;
    } catch (e) {
      _checkoutError = e.toString();
      return null;
    } finally {
      _isCheckingOut = false;
      notifyListeners();
    }
  }

  // ─── Utility ──────────────────────────────────────────────────────────────
  static String fmtMoney(double v) {
    if ((v - v.truncateToDouble()).abs() < 0.005) {
      return 'SAR ${v.toStringAsFixed(0)}';
    }
    return 'SAR ${v.toStringAsFixed(2)}';
  }
}
