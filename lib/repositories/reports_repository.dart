import '../core/services/api_client.dart';

class ReportsRepository {
  ApiClient _api;

  ReportsRepository({required ApiClient api}) : _api = api;

  void updateApi(ApiClient api) {
    _api = api;
  }

  /// Get dashboard statistics
  /// GET /api/reports/dashboard/stats?companyId={companyId}
  Future<DashboardStats> getDashboardStats({required String companyId}) async {
    final Map<String, String> qp = <String, String>{
      'companyId': companyId,
    };

    final Map<String, dynamic> res = await _api.getJson(
      '/api/reports/dashboard/stats',
      queryParameters: qp,
    );

    final Object? data = res['data'];
    if (data is Map<String, dynamic>) {
      return DashboardStats.fromJson(data);
    }
    return const DashboardStats.empty();
  }

  /// Get sales overview
  /// GET /api/reports/sales/overview?companyId={companyId}&dateFrom={dateFrom}&dateTo={dateTo}
  Future<SalesOverview> getSalesOverview({
    required String companyId,
    String? dateFrom,
    String? dateTo,
  }) async {
    final Map<String, String> qp = <String, String>{
      'companyId': companyId,
    };
    if (dateFrom != null && dateFrom.isNotEmpty) {
      qp['dateFrom'] = dateFrom;
    }
    if (dateTo != null && dateTo.isNotEmpty) {
      qp['dateTo'] = dateTo;
    }

    final Map<String, dynamic> res = await _api.getJson(
      '/api/reports/sales/overview',
      queryParameters: qp,
    );

    final Object? data = res['data'];
    if (data is Map<String, dynamic>) {
      return SalesOverview.fromJson(data);
    }
    return const SalesOverview.empty();
  }

  /// Get monthly revenue
  /// GET /api/reports/sales/monthly-revenue?companyId={companyId}&year={year}
  Future<List<MonthlyRevenue>> getMonthlyRevenue({
    required String companyId,
    int? year,
  }) async {
    final Map<String, String> qp = <String, String>{
      'companyId': companyId,
    };
    if (year != null) {
      qp['year'] = year.toString();
    }

    final Map<String, dynamic> res = await _api.getJson(
      '/api/reports/sales/monthly-revenue',
      queryParameters: qp,
    );

    final Object? data = res['data'];
    if (data is List) {
      return data
          .whereType<Map<String, dynamic>>()
          .map(MonthlyRevenue.fromJson)
          .toList();
    }
    return <MonthlyRevenue>[];
  }

  /// Get top customers
  /// GET /api/reports/sales/top-customers?companyId={companyId}&limit={limit}
  Future<List<TopCustomer>> getTopCustomers({
    required String companyId,
    int limit = 10,
  }) async {
    final Map<String, String> qp = <String, String>{
      'companyId': companyId,
      'limit': limit.toString(),
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

  /// Get top products
  /// GET /api/reports/sales/top-products?companyId={companyId}&limit={limit}
  Future<List<TopProduct>> getTopProducts({
    required String companyId,
    int limit = 10,
  }) async {
    final Map<String, String> qp = <String, String>{
      'companyId': companyId,
      'limit': limit.toString(),
    };

    final Map<String, dynamic> res = await _api.getJson(
      '/api/reports/sales/top-products',
      queryParameters: qp,
    );

    final Object? data = res['data'];
    if (data is List) {
      return data
          .whereType<Map<String, dynamic>>()
          .map(TopProduct.fromJson)
          .toList();
    }
    return <TopProduct>[];
  }

  /// Get revenue trend
  /// GET /api/reports/financial/revenue-trend?companyId={companyId}&period={period}
  Future<RevenueTrend> getRevenueTrend({
    required String companyId,
    String? period,
  }) async {
    final Map<String, String> qp = <String, String>{
      'companyId': companyId,
    };
    if (period != null && period.isNotEmpty) {
      qp['period'] = period;
    }

    final Map<String, dynamic> res = await _api.getJson(
      '/api/reports/financial/revenue-trend',
      queryParameters: qp,
    );

    final Object? data = res['data'];
    if (data is Map<String, dynamic>) {
      return RevenueTrend.fromJson(data);
    }
    return const RevenueTrend.empty();
  }
}

/// Dashboard Statistics Model
class DashboardStats {
  final int totalInvoices;
  final int activeCustomers;
  final int totalProducts;
  final double totalRevenue;

  const DashboardStats({
    required this.totalInvoices,
    required this.activeCustomers,
    required this.totalProducts,
    required this.totalRevenue,
  });

  const DashboardStats.empty()
      : totalInvoices = 0,
        activeCustomers = 0,
        totalProducts = 0,
        totalRevenue = 0;

  factory DashboardStats.fromJson(Map<String, dynamic> json) {
    return DashboardStats(
      totalInvoices: (json['totalInvoices'] as num?)?.toInt() ?? 0,
      activeCustomers: (json['activeCustomers'] as num?)?.toInt() ?? 0,
      totalProducts: (json['totalProducts'] as num?)?.toInt() ?? 0,
      totalRevenue: (json['totalRevenue'] as num?)?.toDouble() ?? 0,
    );
  }

  String get formattedRevenue {
    if (totalRevenue >= 1000000) {
      return 'SAR ${(totalRevenue / 1000000).toStringAsFixed(1)}M';
    } else if (totalRevenue >= 1000) {
      return 'SAR ${(totalRevenue / 1000).toStringAsFixed(1)}K';
    }
    return 'SAR ${totalRevenue.toStringAsFixed(0)}';
  }
}

/// Sales Overview Model
class SalesOverview {
  final MetricValue totalRevenue;
  final MetricValue totalInvoices;
  final MetricValue activeCustomers;
  final MetricValue averageInvoice;

  const SalesOverview({
    required this.totalRevenue,
    required this.totalInvoices,
    required this.activeCustomers,
    required this.averageInvoice,
  });

  const SalesOverview.empty()
      : totalRevenue = const MetricValue.empty(),
        totalInvoices = const MetricValue.empty(),
        activeCustomers = const MetricValue.empty(),
        averageInvoice = const MetricValue.empty();

  factory SalesOverview.fromJson(Map<String, dynamic> json) {
    return SalesOverview(
      totalRevenue: MetricValue.fromJson(json['totalRevenue']),
      totalInvoices: MetricValue.fromJson(json['totalInvoices']),
      activeCustomers: MetricValue.fromJson(json['activeCustomers']),
      averageInvoice: MetricValue.fromJson(json['averageInvoice']),
    );
  }
}

/// Metric Value with change info
class MetricValue {
  final double value;
  final String formatted;
  final double change;
  final String changeType;

  const MetricValue({
    required this.value,
    required this.formatted,
    required this.change,
    required this.changeType,
  });

  const MetricValue.empty()
      : value = 0,
        formatted = '0',
        change = 0,
        changeType = 'increase';

  factory MetricValue.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const MetricValue.empty();
    return MetricValue(
      value: (json['value'] as num?)?.toDouble() ?? 0,
      formatted: json['formatted']?.toString() ?? '0',
      change: (json['change'] as num?)?.toDouble() ?? 0,
      changeType: json['changeType']?.toString() ?? 'increase',
    );
  }

  bool get isIncrease => changeType == 'increase';
  String get changeFormatted => '${isIncrease ? '+' : '-'}${change.toStringAsFixed(1)}%';
}

/// Monthly Revenue Model
class MonthlyRevenue {
  final String month;
  final double revenue;
  final int invoices;

  const MonthlyRevenue({
    required this.month,
    required this.revenue,
    required this.invoices,
  });

  factory MonthlyRevenue.fromJson(Map<String, dynamic> json) {
    return MonthlyRevenue(
      month: json['month']?.toString() ?? '',
      revenue: (json['revenue'] as num?)?.toDouble() ?? 0,
      invoices: (json['invoices'] as num?)?.toInt() ?? 0,
    );
  }
}

/// Top Customer Model
class TopCustomer {
  final String id;
  final String name;
  final double totalRevenue;
  final int invoiceCount;
  final String? email;

  const TopCustomer({
    required this.id,
    required this.name,
    required this.totalRevenue,
    required this.invoiceCount,
    this.email,
  });

  factory TopCustomer.fromJson(Map<String, dynamic> json) {
    return TopCustomer(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      name: json['customerName']?.toString() ??
          json['name']?.toString() ??
          'Unknown',
      totalRevenue: (json['totalRevenue'] as num?)?.toDouble() ??
          (json['revenue'] as num?)?.toDouble() ??
          0,
      invoiceCount: (json['invoiceCount'] as num?)?.toInt() ??
          (json['invoices'] as num?)?.toInt() ??
          0,
      email: json['email']?.toString(),
    );
  }
}

/// Top Product Model
class TopProduct {
  final String id;
  final String name;
  final double totalRevenue;
  final int quantitySold;
  final String? description;

  const TopProduct({
    required this.id,
    required this.name,
    required this.totalRevenue,
    required this.quantitySold,
    this.description,
  });

  factory TopProduct.fromJson(Map<String, dynamic> json) {
    return TopProduct(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      name: json['name']?.toString() ??
          json['productName']?.toString() ??
          'Unknown',
      totalRevenue: (json['totalRevenue'] as num?)?.toDouble() ??
          (json['revenue'] as num?)?.toDouble() ??
          0,
      quantitySold: (json['quantitySold'] as num?)?.toInt() ??
          (json['quantity'] as num?)?.toInt() ??
          0,
      description: json['description']?.toString(),
    );
  }
}

/// Revenue Trend Model
class RevenueTrend {
  final List<TrendPoint> points;

  const RevenueTrend({required this.points});

  const RevenueTrend.empty() : points = const <TrendPoint>[];

  factory RevenueTrend.fromJson(Map<String, dynamic> json) {
    final Object? data = json['data'] ?? json['points'] ?? json['trend'];
    if (data is List) {
      return RevenueTrend(
        points: data
            .whereType<Map<String, dynamic>>()
            .map(TrendPoint.fromJson)
            .toList(),
      );
    }
    return const RevenueTrend.empty();
  }
}

/// Trend Point Model
class TrendPoint {
  final String label;
  final double value;
  final DateTime? date;

  const TrendPoint({
    required this.label,
    required this.value,
    this.date,
  });

  factory TrendPoint.fromJson(Map<String, dynamic> json) {
    return TrendPoint(
      label: json['label']?.toString() ?? json['month']?.toString() ?? '',
      value: (json['value'] as num?)?.toDouble() ??
          (json['revenue'] as num?)?.toDouble() ??
          0,
      date: json['date'] != null
          ? DateTime.tryParse(json['date'].toString())
          : null,
    );
  }
}
