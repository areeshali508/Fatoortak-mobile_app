import 'package:flutter/material.dart';

import '../models/dashboard.dart';
import '../repositories/dashboard_repository.dart';

class DashboardController extends ChangeNotifier {
  final DashboardRepository _repository;

  int _bottomIndex = 0;
  int _filterIndex = 0;

  DashboardController({required DashboardRepository repository})
    : _repository = repository;

  int get bottomIndex => _bottomIndex;
  int get filterIndex => _filterIndex;

  List<String> get filterLabels => _repository.getFilterLabels();

  List<DashboardMetricModel> get topMetrics =>
      _repository.getTopMetrics(filterIndex: _filterIndex);

  DashboardProgressModel get paidInvoicesProgress =>
      _repository.getPaidInvoicesProgress(filterIndex: _filterIndex);

  DashboardTrendModel get salesTrend =>
      _repository.getSalesTrend(filterIndex: _filterIndex);

  List<DashboardStatModel> get stats =>
      _repository.getStats(filterIndex: _filterIndex);

  List<DashboardCustomerModel> get recentCustomers =>
      _repository.getRecentCustomers(filterIndex: _filterIndex);

  void setBottomIndex(int index) {
    if (index == _bottomIndex) {
      return;
    }
    _bottomIndex = index;
    notifyListeners();
  }

  void setFilterIndex(int index) {
    if (index == _filterIndex) {
      return;
    }
    _filterIndex = index;
    notifyListeners();
  }
}
