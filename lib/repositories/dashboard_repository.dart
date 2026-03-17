import '../core/services/api_client.dart';

class DashboardRepository {
  ApiClient _api;

  DashboardRepository({required ApiClient api}) : _api = api;

  String _trimCompanyId(String? companyId) {
    return (companyId ?? '').trim();
  }

  Future<double> getCompanyRevenueFromInvoices({
    required String companyId,
    int pageLimit = 200,
    int maxInvoices = 2000,
  }) async {
    final String trimmedCompanyId = _trimCompanyId(companyId);
    if (trimmedCompanyId.isEmpty) return 0.0;

    int page = 1;
    int? totalPages;
    int seen = 0;
    double sum = 0.0;

    while (true) {
      final Map<String, dynamic> res = await _api.getJson(
        '/api/invoices',
        queryParameters: <String, String>{
          'limit': pageLimit.toString(),
          'page': page.toString(),
          'companyId': trimmedCompanyId,
        },
      );

      final Object? data = res['data'];
      if (data is! Map<String, dynamic>) break;

      final Object? invoicesObj = data['invoices'];
      final List<dynamic> invoices = invoicesObj is List ? invoicesObj : <dynamic>[];
      if (invoices.isEmpty) break;

      for (final Object? inv in invoices) {
        if (inv is! Map<String, dynamic>) continue;
        final Object? t = inv['total'] ?? inv['grandTotal'] ?? inv['amount'];
        if (t is num) {
          sum += t.toDouble();
        } else if (t is String) {
          sum += double.tryParse(t) ?? 0.0;
        }
      }

      seen += invoices.length;
      if (seen >= maxInvoices) break;

      totalPages ??= () {
        final Object? pagination = data['pagination'];
        if (pagination is Map<String, dynamic>) {
          final Object? pages = pagination['pages'];
          if (pages is int) return pages;
          if (pages is num) return pages.toInt();
          if (pages is String) return int.tryParse(pages);
        }
        return null;
      }();

      if (totalPages != null && page >= totalPages) break;
      page += 1;
    }

    return sum;
  }

  void updateApi(ApiClient api) {
    _api = api;
  }

  List<String> getFilterLabels() {
    return const <String>['Last 30 Days'];
  }

  /// Get authoritative invoices total count using pagination.total
  /// GET /api/invoices?limit=1&page=1&companyId={companyId}
  Future<int> getInvoicesTotalCount({
    String? companyId,
  }) async {
    final String trimmedCompanyId = _trimCompanyId(companyId);
    final Map<String, String> qp = <String, String>{
      'limit': '1',
      'page': '1',
      if (trimmedCompanyId.isNotEmpty) 'companyId': trimmedCompanyId,
    };

    final Map<String, dynamic> res = await _api.getJson(
      '/api/invoices',
      queryParameters: qp,
    );

    final Object? data = res['data'];
    if (data is Map<String, dynamic>) {
      final Object? pagination = data['pagination'];
      if (pagination is Map<String, dynamic>) {
        final Object? total = pagination['total'];
        if (total is int) return total;
        if (total is num) return total.toInt();
        if (total is String) return int.tryParse(total) ?? 0;
      }
    }
    return 0;
  }

  /// Get recent invoices for dashboard activity feed
  /// GET /api/invoices?limit={limit}&page=1&companyId={companyId}
  Future<List<Map<String, dynamic>>> getRecentInvoices({
    String? companyId,
    int limit = 5,
  }) async {
    final String trimmedCompanyId = _trimCompanyId(companyId);
    final Map<String, String> qp = <String, String>{
      'limit': limit.toString(),
      'page': '1',
      if (trimmedCompanyId.isNotEmpty) 'companyId': trimmedCompanyId,
    };

    final Map<String, dynamic> res = await _api.getJson(
      '/api/invoices',
      queryParameters: qp,
    );

    final Object? data = res['data'];
    if (data is Map<String, dynamic>) {
      final Object? invoices = data['invoices'];
      if (invoices is List) {
        return invoices.whereType<Map<String, dynamic>>().toList();
      }
    }
    return <Map<String, dynamic>>[];
  }

  /// Get recent customers for dashboard
  /// GET /api/customers?limit={limit}&companyId={companyId}
  Future<List<Map<String, dynamic>>> getRecentCustomers({
    String? companyId,
    int limit = 5,
  }) async {
    final String trimmedCompanyId = _trimCompanyId(companyId);
    final Map<String, String> qp = <String, String>{
      'limit': limit.toString(),
      if (trimmedCompanyId.isNotEmpty) 'companyId': trimmedCompanyId,
    };

    final Map<String, dynamic> res = await _api.getJson(
      '/api/customers',
      queryParameters: qp,
    );

    final Object? data = res['data'];
    if (data is Map<String, dynamic>) {
      final Object? customers = data['customers'];
      if (customers is List) {
        return customers
            .whereType<Map<String, dynamic>>()
            .toList();
      }
    }
    return <Map<String, dynamic>>[];
  }

  /// Get dashboard statistics from sales overview
  /// GET /api/reports/sales/overview?dateRange={dateRange}&companyId={companyId}
  Future<DashboardStats> getDashboardStats({
    String? companyId,
    String? dateFrom,
    String? dateTo,
  }) async {
    final String trimmedCompanyId = _trimCompanyId(companyId);
    final Map<String, String> qp = <String, String>{
      'dateRange': '30days',
      if (trimmedCompanyId.isNotEmpty) 'companyId': trimmedCompanyId,
    };

    final Map<String, dynamic> res = await _api.getJson(
      '/api/reports/sales/overview',
      queryParameters: qp,
    );

    final Object? data = res['data'];
    if (data is Map<String, dynamic>) {
      return DashboardStats.fromOverviewJson(data);
    }
    return const DashboardStats.empty();
  }

  /// Get revenue metrics from monthly revenue data
  /// GET /api/reports/sales/monthly-revenue?dateRange={dateRange}&companyId={companyId}
  Future<RevenueMetrics> getRevenueMetrics({
    String? companyId,
    String? period,
  }) async {
    final String trimmedCompanyId = _trimCompanyId(companyId);
    final Map<String, String> qp = <String, String>{
      'dateRange': '30days',
      if (trimmedCompanyId.isNotEmpty) 'companyId': trimmedCompanyId,
    };

    final Map<String, dynamic> res = await _api.getJson(
      '/api/reports/sales/monthly-revenue',
      queryParameters: qp,
    );

    final Object? data = res['data'];
    if (data is List) {
      final List<Map<String, dynamic>> monthlyData = data
          .whereType<Map<String, dynamic>>()
          .toList();
      return RevenueMetrics.fromMonthlyData(monthlyData);
    }
    return const RevenueMetrics.empty();
  }

  /// Get invoice status distribution
  /// GET /api/reports/sales/invoice-distribution?dateRange={dateRange}&companyId={companyId}
  Future<List<InvoiceStatusDistribution>> getInvoiceDistribution({
    String? companyId,
  }) async {
    final String trimmedCompanyId = _trimCompanyId(companyId);
    final Map<String, String> qp = <String, String>{
      'dateRange': '30days',
      if (trimmedCompanyId.isNotEmpty) 'companyId': trimmedCompanyId,
    };

    final Map<String, dynamic> res = await _api.getJson(
      '/api/reports/sales/invoice-distribution',
      queryParameters: qp,
    );

    final Object? data = res['data'];
    if (data is List) {
      return data
          .whereType<Map<String, dynamic>>()
          .map(InvoiceStatusDistribution.fromJson)
          .toList();
    }
    return <InvoiceStatusDistribution>[];
  }
  /// Get top customers by revenue
  /// GET /api/reports/sales/top-customers?dateRange={dateRange}&limit={limit}&companyId={companyId}
  Future<List<TopCustomer>> getTopCustomers({
    String? companyId,
    int limit = 5,
  }) async {
    final String trimmedCompanyId = _trimCompanyId(companyId);
    final Map<String, String> qp = <String, String>{
      'dateRange': '30days',
      'limit': limit.toString(),
      if (trimmedCompanyId.isNotEmpty) 'companyId': trimmedCompanyId,
    };

    final Map<String, dynamic> res = await _api.getJson(
      '/api/reports/sales/top-customers',
      queryParameters: qp,
    );

    final Object? data = res['data'];
    if (data is List) {
      return data
          .whereType<Map<String, dynamic>>()
          .map(TopCustomer.fromJson)
          .toList();
    }
    return <TopCustomer>[];
  }
  /// Get invoice statistics
  /// GET /api/invoices/stats?companyId={companyId}
  Future<InvoiceStats> getInvoiceStats({
    String? companyId,
  }) async {
    final String trimmedCompanyId = _trimCompanyId(companyId);
    final Map<String, String> qp = <String, String>{
      if (trimmedCompanyId.isNotEmpty) 'companyId': trimmedCompanyId,
    };

    final Map<String, dynamic> res = await _api.getJson(
      '/api/invoices/stats',
      queryParameters: qp,
    );

    final Object? data = res['data'];
    if (data is Map<String, dynamic>) {
      final Object? stats = data['stats'];
      if (stats is Map<String, dynamic>) {
        return InvoiceStats.fromJson(stats);
      }
    }
    return const InvoiceStats.empty();
  }
}

/// Invoice statistics model
class InvoiceStats {
  final int totalInvoices;
  final int draftInvoices;
  final int sentInvoices;
  final int paidInvoices;
  final int overdueInvoices;
  final double totalRevenue;
  final double totalOutstanding;
  final double averageInvoiceValue;

  const InvoiceStats({
    required this.totalInvoices,
    required this.draftInvoices,
    required this.sentInvoices,
    required this.paidInvoices,
    required this.overdueInvoices,
    required this.totalRevenue,
    required this.totalOutstanding,
    required this.averageInvoiceValue,
  });

  const InvoiceStats.empty()
      : totalInvoices = 0,
        draftInvoices = 0,
        sentInvoices = 0,
        paidInvoices = 0,
        overdueInvoices = 0,
        totalRevenue = 0.0,
        totalOutstanding = 0.0,
        averageInvoiceValue = 0.0;

  static double _readDouble(Map<String, dynamic> json, String key) {
    final Object? v = json[key];
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? 0.0;
    return 0.0;
  }

  factory InvoiceStats.fromJson(Map<String, dynamic> json) {
    final double totalRevenue = _readDouble(json, 'totalRevenue') != 0.0
        ? _readDouble(json, 'totalRevenue')
        : (_readDouble(json, 'revenue') != 0.0
            ? _readDouble(json, 'revenue')
            : (_readDouble(json, 'totalAmount') != 0.0
                ? _readDouble(json, 'totalAmount')
                : _readDouble(json, 'totalSales')));

    return InvoiceStats(
      totalInvoices: json['totalInvoices'] is int ? json['totalInvoices'] : int.tryParse(json['totalInvoices']?.toString() ?? '0') ?? 0,
      draftInvoices: json['draftInvoices'] is int ? json['draftInvoices'] : int.tryParse(json['draftInvoices']?.toString() ?? '0') ?? 0,
      sentInvoices: json['sentInvoices'] is int ? json['sentInvoices'] : int.tryParse(json['sentInvoices']?.toString() ?? '0') ?? 0,
      paidInvoices: json['paidInvoices'] is int ? json['paidInvoices'] : int.tryParse(json['paidInvoices']?.toString() ?? '0') ?? 0,
      overdueInvoices: json['overdueInvoices'] is int ? json['overdueInvoices'] : int.tryParse(json['overdueInvoices']?.toString() ?? '0') ?? 0,
      totalRevenue: totalRevenue,
      totalOutstanding: _readDouble(json, 'totalOutstanding'),
      averageInvoiceValue: _readDouble(json, 'averageInvoiceValue'),
    );
  }
}

/// Top customer model
class TopCustomer {
  final String customerId;
  final String name;
  final double revenue;
  final int invoices;

  const TopCustomer({
    required this.customerId,
    required this.name,
    required this.revenue,
    required this.invoices,
  });

  factory TopCustomer.fromJson(Map<String, dynamic> json) {
    return TopCustomer(
      customerId: json['customerId']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Unknown',
      revenue: (json['revenue'] as num?)?.toDouble() ?? 0.0,
      invoices: json['invoices'] is int ? json['invoices'] : int.tryParse(json['invoices']?.toString() ?? '0') ?? 0,
    );
  }
}

/// Invoice status distribution model
class InvoiceStatusDistribution {
  final String status;
  final int count;
  final int percentage;
  final String color;

  const InvoiceStatusDistribution({
    required this.status,
    required this.count,
    required this.percentage,
    required this.color,
  });

  factory InvoiceStatusDistribution.fromJson(Map<String, dynamic> json) {
    return InvoiceStatusDistribution(
      status: json['status']?.toString() ?? '',
      count: json['count'] is int ? json['count'] : int.tryParse(json['count']?.toString() ?? '0') ?? 0,
      percentage: json['percentage'] is int ? json['percentage'] : int.tryParse(json['percentage']?.toString() ?? '0') ?? 0,
      color: json['color']?.toString() ?? 'bg-gray-500',
    );
  }
}

/// Dashboard statistics model
class DashboardStats {
  final int totalCustomers;
  final int activeCustomers;
  final int totalInvoices;
  final int paidInvoices;
  final double totalRevenue;
  final double pendingAmount;
  final double trendPercentage;

  const DashboardStats({
    required this.totalCustomers,
    required this.activeCustomers,
    required this.totalInvoices,
    required this.paidInvoices,
    required this.totalRevenue,
    required this.pendingAmount,
    required this.trendPercentage,
  });

  const DashboardStats.empty()
      : totalCustomers = 0,
        activeCustomers = 0,
        totalInvoices = 0,
        paidInvoices = 0,
        totalRevenue = 0.0,
        pendingAmount = 0.0,
        trendPercentage = 0.0;

  factory DashboardStats.fromOverviewJson(Map<String, dynamic> json) {
    // Helper to extract value from nested metric objects
    double getMetricValue(String key) {
      final Object? metric = json[key];
      if (metric is Map<String, dynamic>) {
        final Object? val = metric['value'];
        if (val is num) return val.toDouble();
        if (val is String) return double.tryParse(val) ?? 0.0;
      }
      return 0.0;
    }

    int getMetricInt(String key) {
      final Object? metric = json[key];
      if (metric is Map<String, dynamic>) {
        final Object? val = metric['value'];
        if (val is num) return val.toInt();
        if (val is String) return int.tryParse(val) ?? 0;
      }
      return 0;
    }

    double getChangePercent(String key) {
      final Object? metric = json[key];
      if (metric is Map<String, dynamic>) {
        final Object? change = metric['change'];
        if (change is num) return change.toDouble();
        if (change is String) return double.tryParse(change) ?? 0.0;
      }
      return 0.0;
    }

    return DashboardStats(
      totalCustomers: 0, // Not provided by overview endpoint
      activeCustomers: getMetricInt('activeCustomers'),
      totalInvoices: getMetricInt('totalInvoices'),
      paidInvoices: 0, // Not directly provided
      totalRevenue: getMetricValue('totalRevenue'),
      pendingAmount: 0.0, // Not provided
      trendPercentage: getChangePercent('totalRevenue'),
    );
  }
}

/// Revenue metrics model
class RevenueMetrics {
  final double currentRevenue;
  final double previousRevenue;
  final double trend;
  final bool trendUp;
  final Map<String, double> dailyRevenue;

  const RevenueMetrics({
    required this.currentRevenue,
    required this.previousRevenue,
    required this.trend,
    required this.trendUp,
    required this.dailyRevenue,
  });

  const RevenueMetrics.empty()
      : currentRevenue = 0.0,
        previousRevenue = 0.0,
        trend = 0.0,
        trendUp = true,
        dailyRevenue = const <String, double>{};

  factory RevenueMetrics.fromMonthlyData(List<Map<String, dynamic>> monthlyData) {
    if (monthlyData.isEmpty) {
      return const RevenueMetrics.empty();
    }

    double totalRevenue = 0.0;
    final Map<String, double> daily = <String, double>{};

    for (final Map<String, dynamic> item in monthlyData) {
      final double revenue = _parseDouble(item['revenue']);
      totalRevenue += revenue;

      final String month = item['month']?.toString() ?? '';
      if (month.isNotEmpty) {
        daily[month] = revenue;
      }
    }

    // Calculate trend (compare last month to previous)
    double trend = 0.0;
    bool trendUp = true;
    if (monthlyData.length >= 2) {
      final double lastMonth = _parseDouble(monthlyData.last['revenue']);
      final double previousMonth = _parseDouble(monthlyData[monthlyData.length - 2]['revenue']);
      if (previousMonth > 0) {
        trend = ((lastMonth - previousMonth) / previousMonth).abs() * 100;
        trendUp = lastMonth >= previousMonth;
      }
    }

    return RevenueMetrics(
      currentRevenue: totalRevenue,
      previousRevenue: monthlyData.length > 1
          ? _parseDouble(monthlyData[monthlyData.length - 2]['revenue'])
          : 0.0,
      trend: trend,
      trendUp: trendUp,
      dailyRevenue: daily,
    );
  }

  factory RevenueMetrics.fromJson(Map<String, dynamic> json) {
    final Map<String, double> daily = <String, double>{};
    final Object? dailyData = json['dailyRevenue'];
    if (dailyData is Map) {
      dailyData.forEach((dynamic key, dynamic value) {
        if (key is String && value is num) {
          daily[key] = value.toDouble();
        }
      });
    }

    final double trend = _parseDouble(json['trend']);
    return RevenueMetrics(
      currentRevenue: _parseDouble(json['currentRevenue']),
      previousRevenue: _parseDouble(json['previousRevenue']),
      trend: trend.abs(),
      trendUp: trend >= 0,
      dailyRevenue: daily,
    );
  }
}

double _parseDouble(dynamic value) {
  if (value == null) return 0.0;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? 0.0;
  return 0.0;
}
