import 'package:flutter/material.dart';

export '../repositories/reports_repository.dart';
import '../repositories/reports_repository.dart';

class ReportsController extends ChangeNotifier {
  ReportsRepository _repository;

  ReportsController({required ReportsRepository repository})
      : _repository = repository;

  void updateRepository(ReportsRepository repository) {
    _repository = repository;
  }

  // Loading states
  bool _isLoadingDashboard = false;
  bool _isLoadingSales = false;
  bool _isLoadingCustomers = false;
  bool _isLoadingProducts = false;

  // Error states
  String? _dashboardError;
  String? _salesError;
  String? _customersError;
  String? _productsError;

  // Data
  DashboardStats _dashboardStats = const DashboardStats.empty();
  SalesOverview _salesOverview = const SalesOverview.empty();
  List<MonthlyRevenue> _monthlyRevenue = <MonthlyRevenue>[];
  List<TopCustomer> _topCustomers = <TopCustomer>[];
  List<TopProduct> _topProducts = <TopProduct>[];

  // Getters
  bool get isLoadingDashboard => _isLoadingDashboard;
  bool get isLoadingSales => _isLoadingSales;
  bool get isLoadingCustomers => _isLoadingCustomers;
  bool get isLoadingProducts => _isLoadingProducts;

  String? get dashboardError => _dashboardError;
  String? get salesError => _salesError;
  String? get customersError => _customersError;
  String? get productsError => _productsError;

  DashboardStats get dashboardStats => _dashboardStats;
  SalesOverview get salesOverview => _salesOverview;
  List<MonthlyRevenue> get monthlyRevenue => _monthlyRevenue;
  List<TopCustomer> get topCustomers => _topCustomers;
  List<TopProduct> get topProducts => _topProducts;

  /// Load dashboard statistics
  Future<void> loadDashboardStats({required String companyId}) async {
    _isLoadingDashboard = true;
    _dashboardError = null;
    notifyListeners();

    try {
      _dashboardStats = await _repository.getDashboardStats(
        companyId: companyId,
      );
    } catch (e) {
      _dashboardError = e.toString();
    } finally {
      _isLoadingDashboard = false;
      notifyListeners();
    }
  }

  /// Load sales overview
  Future<void> loadSalesOverview({
    required String companyId,
    String? dateFrom,
    String? dateTo,
  }) async {
    _isLoadingSales = true;
    _salesError = null;
    notifyListeners();

    try {
      _salesOverview = await _repository.getSalesOverview(
        companyId: companyId,
        dateFrom: dateFrom,
        dateTo: dateTo,
      );
    } catch (e) {
      _salesError = e.toString();
    } finally {
      _isLoadingSales = false;
      notifyListeners();
    }
  }

  /// Load monthly revenue
  Future<void> loadMonthlyRevenue({
    required String companyId,
    int? year,
  }) async {
    _isLoadingSales = true;
    _salesError = null;
    notifyListeners();

    try {
      _monthlyRevenue = await _repository.getMonthlyRevenue(
        companyId: companyId,
        year: year,
      );
    } catch (e) {
      _salesError = e.toString();
    } finally {
      _isLoadingSales = false;
      notifyListeners();
    }
  }

  /// Load top customers
  Future<void> loadTopCustomers({
    required String companyId,
    int limit = 10,
  }) async {
    _isLoadingCustomers = true;
    _customersError = null;
    notifyListeners();

    try {
      _topCustomers = await _repository.getTopCustomers(
        companyId: companyId,
        limit: limit,
      );
    } catch (e) {
      _customersError = e.toString();
    } finally {
      _isLoadingCustomers = false;
      notifyListeners();
    }
  }

  /// Load top products
  Future<void> loadTopProducts({
    required String companyId,
    int limit = 10,
  }) async {
    _isLoadingProducts = true;
    _productsError = null;
    notifyListeners();

    try {
      _topProducts = await _repository.getTopProducts(
        companyId: companyId,
        limit: limit,
      );
    } catch (e) {
      _productsError = e.toString();
    } finally {
      _isLoadingProducts = false;
      notifyListeners();
    }
  }

  /// Load all reports data at once
  Future<void> loadAllReports({required String companyId}) async {
    await Future.wait(<Future<void>>[
      loadDashboardStats(companyId: companyId),
      loadSalesOverview(companyId: companyId),
      loadMonthlyRevenue(companyId: companyId),
      loadTopCustomers(companyId: companyId, limit: 5),
      loadTopProducts(companyId: companyId, limit: 5),
    ]);
  }
}
