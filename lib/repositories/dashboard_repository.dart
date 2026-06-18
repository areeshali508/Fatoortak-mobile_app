import '../core/services/api_client.dart';

class DashboardRepository {
  ApiClient _api;

  DashboardRepository({required ApiClient api}) : _api = api;

  String _trimCompanyId(String? companyId) {
    return (companyId ?? '').trim();
  }

  String _normalizeDateRange(String? dateRange) {
    final String normalized = (dateRange ?? '').trim();
    return normalized.isEmpty ? '30days' : normalized;
  }

  DateTime? _parseBoundaryDate(String? raw, {required bool endOfDay}) {
    final String value = (raw ?? '').trim();
    if (value.isEmpty) return null;
    final DateTime? parsed = DateTime.tryParse(value)?.toLocal();
    if (parsed == null) return null;
    if (endOfDay) {
      return DateTime(
        parsed.year,
        parsed.month,
        parsed.day,
        23,
        59,
        59,
        999,
      );
    }
    return DateTime(parsed.year, parsed.month, parsed.day);
  }

  DateTime? _extractInvoiceDate(Map<String, dynamic> invoice) {
    final List<Object?> candidates = <Object?>[
      invoice['invoiceDate'],
      invoice['createdAt'],
      invoice['issueDate'],
      invoice['date'],
    ];
    for (final Object? candidate in candidates) {
      final String raw = candidate?.toString().trim() ?? '';
      if (raw.isEmpty) continue;
      final DateTime? parsed = DateTime.tryParse(raw)?.toLocal();
      if (parsed != null) {
        return parsed;
      }
    }
    return null;
  }

  bool _isWithinDateBounds(
    DateTime value, {
    DateTime? start,
    DateTime? end,
  }) {
    if (start != null && value.isBefore(start)) {
      return false;
    }
    if (end != null && value.isAfter(end)) {
      return false;
    }
    return true;
  }

  Future<double> getCompanyRevenueFromInvoices({
    required String companyId,
    String? dateFrom,
    String? dateTo,
    int pageLimit = 200,
    int maxInvoices = 2000,
  }) async {
    final String trimmedCompanyId = _trimCompanyId(companyId);
    if (trimmedCompanyId.isEmpty) return 0.0;
    final DateTime? start = _parseBoundaryDate(dateFrom, endOfDay: false);
    final DateTime? end = _parseBoundaryDate(dateTo, endOfDay: true);

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
        final DateTime? invoiceDate = _extractInvoiceDate(inv);
        if ((start != null || end != null) &&
            (invoiceDate == null ||
                !_isWithinDateBounds(invoiceDate, start: start, end: end))) {
          continue;
        }
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
    return const <String>[
      'Last 7 Days',
      'Last 30 Days',
      'Last 3 Months',
      'Last 6 Months',
      'Last 12 Months',
    ];
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
    String? dateRange,
  }) async {
    final String trimmedCompanyId = _trimCompanyId(companyId);
    final String trimmedDateFrom = (dateFrom ?? '').trim();
    final String trimmedDateTo = (dateTo ?? '').trim();
    final bool hasExplicitDates =
        trimmedDateFrom.isNotEmpty && trimmedDateTo.isNotEmpty;
    final Map<String, String> qp = <String, String>{
      if (trimmedCompanyId.isNotEmpty) 'companyId': trimmedCompanyId,
      if (hasExplicitDates) 'dateFrom': trimmedDateFrom,
      if (hasExplicitDates) 'dateTo': trimmedDateTo,
      if (!hasExplicitDates) 'dateRange': _normalizeDateRange(dateRange),
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
      'dateRange': _normalizeDateRange(period),
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
    String? dateRange,
  }) async {
    final String trimmedCompanyId = _trimCompanyId(companyId);
    final Map<String, String> qp = <String, String>{
      'dateRange': _normalizeDateRange(dateRange),
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
    String? dateRange,
  }) async {
    final String trimmedCompanyId = _trimCompanyId(companyId);
    final Map<String, String> qp = <String, String>{
      'dateRange': _normalizeDateRange(dateRange),
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

  /// Get customer statistics
  /// GET /api/customers/stats?companyId={companyId}
  Future<Map<String, dynamic>> getCustomerStats({
    String? companyId,
  }) async {
    final String trimmedCompanyId = _trimCompanyId(companyId);
    final Map<String, String> qp = <String, String>{
      if (trimmedCompanyId.isNotEmpty) 'companyId': trimmedCompanyId,
    };

    final Map<String, dynamic> res = await _api.getJson(
      '/api/customers/stats',
      queryParameters: qp,
    );

    final Object? data = res['data'];
    if (data is Map<String, dynamic>) {
      final Object? stats = data['stats'];
      if (stats is Map<String, dynamic>) {
        return stats;
      }
    }
    return const <String, dynamic>{};
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
  final Map<String, double> invoiceCounts;

  const RevenueMetrics({
    required this.currentRevenue,
    required this.previousRevenue,
    required this.trend,
    required this.trendUp,
    required this.dailyRevenue,
    required this.invoiceCounts,
  });

  const RevenueMetrics.empty()
      : currentRevenue = 0.0,
        previousRevenue = 0.0,
        trend = 0.0,
        trendUp = true,
        dailyRevenue = const <String, double>{},
        invoiceCounts = const <String, double>{};

  factory RevenueMetrics.fromMonthlyData(List<Map<String, dynamic>> monthlyData) {
    if (monthlyData.isEmpty) {
      return const RevenueMetrics.empty();
    }

    final List<Map<String, dynamic>> sorted = List<Map<String, dynamic>>.from(monthlyData)
      ..sort((Map<String, dynamic> a, Map<String, dynamic> b) {
        final int ai = _monthSortValue(a);
        final int bi = _monthSortValue(b);
        return ai.compareTo(bi);
      });

    final Map<String, double> daily = <String, double>{};
    final Map<String, double> invoiceCounts = <String, double>{};

    for (final Map<String, dynamic> item in sorted) {
      final double revenue = _parseDouble(item['revenue']);
      final String key = _seriesKeyFromMonthItem(item);
      if (key.isNotEmpty) {
        daily[key] = revenue;
        invoiceCounts[key] = _parseDouble(item['invoices']);
      }
    }

    double trend = 0.0;
    bool trendUp = true;
    final double currentRevenue = _parseDouble(sorted.last['revenue']);
    final double previousRevenue = sorted.length > 1
        ? _parseDouble(sorted[sorted.length - 2]['revenue'])
        : 0.0;
    if (sorted.length >= 2) {
      final double lastMonth = currentRevenue;
      final double previousMonth = previousRevenue;
      if (previousMonth > 0) {
        trend = ((lastMonth - previousMonth) / previousMonth).abs() * 100;
        trendUp = lastMonth >= previousMonth;
      }
    }

    return RevenueMetrics(
      currentRevenue: currentRevenue,
      previousRevenue: previousRevenue,
      trend: trend,
      trendUp: trendUp,
      dailyRevenue: daily,
      invoiceCounts: invoiceCounts,
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
      invoiceCounts: const <String, double>{},
    );
  }
}

int _monthSortValue(Map<String, dynamic> item) {
  final String rawYear = item['year']?.toString().trim() ?? '';
  final int year = int.tryParse(rawYear) ?? 0;
  final int month = _monthNumberFromValue(item['month']);
  if (year > 0 && month > 0) {
    return (year * 12) + month;
  }
  if (month > 0) {
    return month;
  }
  return 0;
}

String _seriesKeyFromMonthItem(Map<String, dynamic> item) {
  final String rawYear = item['year']?.toString().trim() ?? '';
  final int? year = int.tryParse(rawYear);
  final int month = _monthNumberFromValue(item['month']);
  if (year != null && month > 0) {
    final String mm = month.toString().padLeft(2, '0');
    return '${year.toString().padLeft(4, '0')}-$mm';
  }
  return item['month']?.toString().trim() ?? '';
}

int _monthNumberFromValue(dynamic value) {
  final String raw = value?.toString().trim() ?? '';
  if (raw.isEmpty) return 0;
  final int? numeric = int.tryParse(raw);
  if (numeric != null && numeric >= 1 && numeric <= 12) {
    return numeric;
  }
  const List<String> monthShortNames = <String>[
    'jan',
    'feb',
    'mar',
    'apr',
    'may',
    'jun',
    'jul',
    'aug',
    'sep',
    'oct',
    'nov',
    'dec',
  ];
  final String prefix = raw.length >= 3 ? raw.substring(0, 3).toLowerCase() : raw.toLowerCase();
  final int index = monthShortNames.indexOf(prefix);
  if (index == -1) {
    return 0;
  }
  return index + 1;
}

double _parseDouble(dynamic value) {
  if (value == null) return 0.0;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? 0.0;
  return 0.0;
}
