import 'package:flutter/material.dart';

import '../controllers/auth_controller.dart';
import '../models/dashboard.dart';
import '../repositories/dashboard_repository.dart';

class DashboardController extends ChangeNotifier {
  DashboardRepository _repository;

  int _bottomIndex = 0;
  int _filterIndex = 1;

  int _trendMetricIndex = 0;

  String? _companyId;
  bool _isCompanyInitialized = false;

  // Loading states
  bool _isLoading = false;
  String? _errorMessage;

  // Data
  DashboardStats _stats = const DashboardStats.empty();
  RevenueMetrics _revenue = const RevenueMetrics.empty();
  List<Map<String, dynamic>> _recentInvoicesRaw = <Map<String, dynamic>>[];
  List<Map<String, dynamic>> _recentCustomersRaw = <Map<String, dynamic>>[];

  List<DashboardCustomerModel> _recentInvoicesUi = const <DashboardCustomerModel>[];
  bool _recentInvoicesUiDirty = true;

  List<DashboardCustomerModel> _recentCustomersUi = const <DashboardCustomerModel>[];
  bool _recentCustomersUiDirty = true;

  List<DashboardCustomerModel> _topCustomersUi = const <DashboardCustomerModel>[];
  bool _topCustomersUiDirty = true;

  bool _hasMoreRecentInvoices = false;
  bool _hasMoreRecentCustomers = false;
  List<InvoiceStatusDistribution> _invoiceDistribution = <InvoiceStatusDistribution>[];
  List<TopCustomer> _topCustomers = <TopCustomer>[];
  InvoiceStats _invoiceStats = const InvoiceStats.empty();

  Map<String, double> _invoiceTrendSeries = <String, double>{};

  List<DashboardMetricModel> _topMetricsCache = const <DashboardMetricModel>[];
  bool _topMetricsDirty = true;

  DashboardProgressModel? _paidInvoicesProgressCache;
  bool _paidInvoicesProgressDirty = true;

  List<DashboardStatModel> _statsListCache = const <DashboardStatModel>[];
  bool _statsListDirty = true;

  DashboardTrendModel? _salesTrendCache;
  bool _salesTrendDirty = true;

  DashboardController({required DashboardRepository repository})
    : _repository = repository;

  int get bottomIndex => _bottomIndex;
  int get filterIndex => _filterIndex;
  int get trendMetricIndex => _trendMetricIndex;
  String? get companyId => _companyId;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  void syncWithAuth(AuthController auth) {
    if (!auth.isAuthenticated) {
      _companyId = null;
      _isCompanyInitialized = false;
      _stats = const DashboardStats.empty();
      _revenue = const RevenueMetrics.empty();
      _recentInvoicesRaw = <Map<String, dynamic>>[];
      _recentCustomersRaw = <Map<String, dynamic>>[];
      _invoiceDistribution = <InvoiceStatusDistribution>[];
      _topCustomers = <TopCustomer>[];
      _invoiceStats = const InvoiceStats.empty();
      _invoiceTrendSeries = <String, double>{};
      
      _recentInvoicesUiDirty = true;
      _recentCustomersUiDirty = true;
      _topCustomersUiDirty = true;
      _topMetricsDirty = true;
      _paidInvoicesProgressDirty = true;
      _statsListDirty = true;
      _salesTrendDirty = true;
    } else if (!_isCompanyInitialized) {
      _companyId = auth.activeCompanyId;
      _isCompanyInitialized = true;
    }
  }

  bool get hasMoreRecentInvoices => _hasMoreRecentInvoices;
  bool get hasMoreRecentCustomers => _hasMoreRecentCustomers;

  // Data getters
  DashboardStats get stats => _stats;
  RevenueMetrics get revenue => _revenue;
  InvoiceStats get invoiceStats => _invoiceStats;
  Map<String, double> get invoiceTrendSeries => _invoiceTrendSeries;

  List<String> get filterLabels => _repository.getFilterLabels();
  String get selectedFilterLabel => filterLabels[_filterIndex];

  List<String> get trendMetricLabels => const <String>['Revenue', 'Invoices'];

  static const List<String> _monthShortNames = <String>[
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  ({
    String apiDateRange,
    String dateFrom,
    String dateTo,
    DateTime start,
    DateTime end,
  }) _resolveActiveDateFilter({
    String? overrideDateFrom,
    String? overrideDateTo,
  }) {
    final DateTime now = DateTime.now();
    final DateTime defaultEnd = _endOfDay(now);
    late final DateTime defaultStart;

    switch (_filterIndex) {
      case 0:
        defaultStart = _startOfDay(
          defaultEnd.subtract(const Duration(days: 6)),
        );
        break;
      case 1:
        defaultStart = _startOfDay(
          defaultEnd.subtract(const Duration(days: 29)),
        );
        break;
      case 2:
        defaultStart = _startOfDay(_subtractMonths(defaultEnd, 3));
        break;
      case 3:
        defaultStart = _startOfDay(_subtractMonths(defaultEnd, 6));
        break;
      case 4:
        defaultStart = _startOfDay(_subtractMonths(defaultEnd, 12));
        break;
      default:
        defaultStart = _startOfDay(
          defaultEnd.subtract(const Duration(days: 29)),
        );
        break;
    }

    final String trimmedDateFrom = (overrideDateFrom ?? '').trim();
    final String trimmedDateTo = (overrideDateTo ?? '').trim();
    final DateTime start = trimmedDateFrom.isNotEmpty
        ? _startOfDay(DateTime.tryParse(trimmedDateFrom) ?? defaultStart)
        : defaultStart;
    final DateTime end = trimmedDateTo.isNotEmpty
        ? _endOfDay(DateTime.tryParse(trimmedDateTo) ?? defaultEnd)
        : defaultEnd;

    return (
      apiDateRange: _getPeriodFromFilter(),
      dateFrom: _formatDateOnly(start),
      dateTo: _formatDateOnly(end),
      start: start,
      end: end,
    );
  }

  DateTime _startOfDay(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }

  DateTime _endOfDay(DateTime value) {
    return DateTime(value.year, value.month, value.day, 23, 59, 59, 999);
  }

  DateTime _subtractMonths(DateTime value, int months) {
    int year = value.year;
    int month = value.month - months;
    while (month <= 0) {
      month += 12;
      year -= 1;
    }
    final int lastDay = DateTime(year, month + 1, 0).day;
    final int day = value.day > lastDay ? lastDay : value.day;
    return DateTime(year, month, day);
  }

  String _formatDateOnly(DateTime value) {
    final String year = value.year.toString().padLeft(4, '0');
    final String month = value.month.toString().padLeft(2, '0');
    final String day = value.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  bool _isWithinDateRange(DateTime value, DateTime start, DateTime end) {
    return !value.isBefore(start) && !value.isAfter(end);
  }

  List<Map<String, dynamic>> _filterItemsByDate(
    List<Map<String, dynamic>> items, {
    required DateTime start,
    required DateTime end,
  }) {
    return items.where((Map<String, dynamic> item) {
      final String raw = (item['createdAt'] ??
                  item['invoiceDate'] ??
                  item['issueDate'] ??
                  item['date'])
              ?.toString()
              .trim() ??
          '';
      if (raw.isEmpty) {
        return true;
      }
      try {
        final DateTime parsed = DateTime.parse(raw).toLocal();
        return _isWithinDateRange(parsed, start, end);
      } catch (_) {
        return true;
      }
    }).toList();
  }

  int _countInvoiceDistribution(Iterable<String> statuses) {
    final Set<String> normalized = statuses
        .map((String status) => status.trim().toLowerCase())
        .where((String status) => status.isNotEmpty)
        .toSet();
    if (normalized.isEmpty) {
      return 0;
    }
    return _invoiceDistribution.fold<int>(0, (
      int sum,
      InvoiceStatusDistribution item,
    ) {
      final String status = item.status.trim().toLowerCase();
      if (!normalized.contains(status)) {
        return sum;
      }
      return sum + item.count;
    });
  }

  int _monthIndexFromKey(String key) {
    final String k = key.trim();
    if (k.isEmpty) return -1;

    final RegExp isoMonth = RegExp(r'^\d{4}-\d{2}');
    if (isoMonth.hasMatch(k)) {
      final List<String> parts = k.split('-');
      if (parts.length >= 2) {
        final int? year = int.tryParse(parts[0]);
        final int? month = int.tryParse(parts[1]);
        if (year != null && month != null && month >= 1 && month <= 12) {
          return (year * 12) + (month - 1);
        }
      }
    }

    final String prefix = k.length >= 3 ? k.substring(0, 3) : k;
    final int idx = _monthShortNames.indexWhere(
      (String m) => m.toLowerCase() == prefix.toLowerCase(),
    );
    return idx;
  }

  String _labelFromSeriesKey(String key) {
    final String k = key.trim();
    if (k.isEmpty) return '';
    final RegExp isoMonth = RegExp(r'^\d{4}-\d{2}');
    if (isoMonth.hasMatch(k)) {
      final List<String> parts = k.split('-');
      if (parts.length >= 2) {
        final int? month = int.tryParse(parts[1]);
        if (month != null && month >= 1 && month <= 12) {
          return _monthShortNames[month - 1];
        }
      }
    }
    return k.length >= 3 ? k.substring(0, 3) : k;
  }

  /// Get top metrics from stats data
  List<DashboardMetricModel> get topMetrics {
    if (_topMetricsDirty) {
      final String revenueValue =
          'SAR ${_stats.totalRevenue.toStringAsFixed(0)}';
      final String invoicesValue = _stats.totalInvoices.toString();
      final String trendStr = '${_stats.trendPercentage >= 0 ? '+' : ''}'
          '${_stats.trendPercentage.toStringAsFixed(1)}%';

      _topMetricsCache = <DashboardMetricModel>[
        DashboardMetricModel(
          icon: Icons.account_balance_wallet_outlined,
          title: 'Revenue',
          value: revenueValue,
          trend: trendStr,
          trendUp: _stats.trendPercentage >= 0,
        ),
        DashboardMetricModel(
          icon: Icons.receipt_long_outlined,
          title: 'Invoices',
          value: invoicesValue,
          trend: '+${_stats.paidInvoices}',
          trendUp: true,
        ),
      ];
      _topMetricsDirty = false;
    }
    return _topMetricsCache;
  }

  /// Get paid invoices progress using invoice stats data
  DashboardProgressModel get paidInvoicesProgress {
    if (_paidInvoicesProgressDirty || _paidInvoicesProgressCache == null) {
      // Use invoice stats for accurate counts
      final int distributionTotal = _invoiceDistribution.fold(
        0,
        (int sum, InvoiceStatusDistribution d) => sum + d.count,
      );
      final bool hasDistribution = distributionTotal > 0;
      final int totalCount = hasDistribution
          ? distributionTotal
          : (_stats.totalInvoices > 0
              ? _stats.totalInvoices
              : _invoiceStats.totalInvoices);
      final int paidCount = hasDistribution
          ? _countInvoiceDistribution(const <String>['paid'])
          : _invoiceStats.paidInvoices;
      final int sentCount = hasDistribution
          ? _countInvoiceDistribution(const <String>['sent'])
          : _invoiceStats.sentInvoices;
      final int overdueCount = hasDistribution
          ? _countInvoiceDistribution(const <String>['overdue'])
          : _invoiceStats.overdueInvoices;

      // Calculate progress based on paid invoices
      final double progress = totalCount > 0 ? paidCount / totalCount : 0.0;

      // Build subtitle with breakdown
      final List<String> parts = <String>[];
      if (sentCount > 0) parts.add('$sentCount sent');
      if (overdueCount > 0) parts.add('$overdueCount overdue');

      _paidInvoicesProgressCache = DashboardProgressModel(
        title: 'Invoice Status',
        value: '$paidCount paid',
        subtitle: parts.isNotEmpty
            ? '${parts.join(', ')}, $totalCount total'
            : '$totalCount total',
        progress: progress,
      );
      _paidInvoicesProgressDirty = false;
    }
    return _paidInvoicesProgressCache!;
  }

  /// Get sales trend from revenue data
  DashboardTrendModel get salesTrend {
    if (_salesTrendDirty || _salesTrendCache == null) {
      final bool isRevenue = _trendMetricIndex == 0;
      final Map<String, double> series =
          isRevenue ? _revenue.dailyRevenue : _invoiceTrendSeries;

      if (series.isEmpty) {
        _salesTrendCache = DashboardTrendModel(
          values: <double>[0.35, 0.75, 0.6, 0.45, 0.65, 0.4, 0.48],
          rawValues: <double>[35, 75, 60, 45, 65, 40, 48],
          labels: <String>['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'],
          highlightIndex: 3,
          isCurrency: isRevenue,
        );
      } else {
        final List<MapEntry<String, double>> entries = series.entries.toList();
        entries.sort((MapEntry<String, double> a, MapEntry<String, double> b) {
          final int ai = _monthIndexFromKey(a.key);
          final int bi = _monthIndexFromKey(b.key);
          if (ai == -1 && bi == -1) return 0;
          if (ai == -1) return 1;
          if (bi == -1) return -1;
          return ai.compareTo(bi);
        });

        final List<double> rawValues =
            entries.map((MapEntry<String, double> e) => e.value).toList();
        final List<String> labels =
            entries.map((MapEntry<String, double> e) => _labelFromSeriesKey(e.key)).toList();

        // Normalize values to 0-1 range for display
        final double maxVal = rawValues.isNotEmpty
            ? rawValues.reduce((double a, double b) => a > b ? a : b)
            : 1.0;
        final List<double> normalized = rawValues
            .map((double v) => maxVal > 0 ? v / maxVal : 0.0)
            .toList();

        _salesTrendCache = DashboardTrendModel(
          values: normalized.isNotEmpty
              ? normalized
              : const <double>[0.35, 0.75, 0.6, 0.45, 0.65, 0.4, 0.48],
          rawValues: rawValues,
          labels: labels.isNotEmpty
              ? labels
              : const <String>['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'],
          highlightIndex: (normalized.length / 2).floor(),
          isCurrency: isRevenue,
        );
      }

      _salesTrendDirty = false;
    }
    return _salesTrendCache!;
  }

  /// Get stats for display
  List<DashboardStatModel> get statsList {
    if (_statsListDirty) {
      _statsListCache = <DashboardStatModel>[
        DashboardStatModel(
          title: 'TOTAL CUSTOMERS',
          value: _stats.totalCustomers.toString(),
          subtitle: 'All time',
          icon: Icons.groups_outlined,
          accent: const Color(0xFF0C1E59),
          showDot: false,
          deltaText: null,
        ),
        DashboardStatModel(
          title: 'ACTIVE NOW',
          value: _stats.activeCustomers.toString(),
          subtitle: '${_stats.activeCustomers} active',
          icon: Icons.circle,
          accent: const Color(0xFF1DB954),
          showDot: true,
          deltaText: null,
        ),
      ];
      _statsListDirty = false;
    }
    return _statsListCache;
  }

  /// Get recent invoices mapped from API data for activity feed
  List<DashboardCustomerModel> get recentInvoices {
    if (_recentInvoicesUiDirty) {
      _recentInvoicesUi = List<DashboardCustomerModel>.unmodifiable(
        _recentInvoicesRaw.map((Map<String, dynamic> inv) {
          // Extract customer info - could be nested or direct
          final Object? customerIdObj = inv['customerId'];
          String customerName = 'Unknown';
          if (customerIdObj is Map<String, dynamic>) {
            customerName =
                customerIdObj['customerName']?.toString() ?? 'Unknown';
          }

          final String invoiceNumber =
              inv['invoiceNumber']?.toString() ?? 'N/A';
          final String status = inv['status']?.toString() ?? 'unknown';
          final double total = (inv['total'] as num?)?.toDouble() ?? 0.0;
          final String createdAt = inv['createdAt']?.toString() ?? '';
          final String timeAgo = _formatTimeAgo(createdAt);

          // Generate initials from customer name
          final List<String> nameParts = customerName.split(' ');
          final String initials = nameParts.length > 1
              ? '${nameParts[0][0]}${nameParts[1][0]}'
              : customerName.isNotEmpty
                  ? customerName[0]
                  : '?';

          // Generate consistent color based on status
          final Color color = _getStatusColor(status);

          return DashboardCustomerModel(
            name: customerName,
            time: '$invoiceNumber • $timeAgo',
            amount: 'SAR ${total.toStringAsFixed(2)} • $status',
            initials: initials,
            color: color,
          );
        }),
      );
      _recentInvoicesUiDirty = false;
    }
    return _recentInvoicesUi;
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'sent':
        return const Color(0xFFD6F5E3); // Green
      case 'overdue':
        return const Color(0xFFFFD6D6); // Red
      case 'draft':
        return const Color(0xFFFFF3CD); // Yellow
      case 'paid':
        return const Color(0xFFD9EEFF); // Blue
      default:
        return const Color(0xFFE8E1FF); // Purple
    }
  }

  /// Get top customers for dashboard display
  List<DashboardCustomerModel> get topCustomers {
    if (_topCustomersUiDirty) {
      _topCustomersUi = List<DashboardCustomerModel>.unmodifiable(
        _topCustomers.map((TopCustomer c) {
          // Generate initials from name
          final List<String> nameParts = c.name.split(' ');
          final String initials = nameParts.length > 1
              ? '${nameParts[0][0]}${nameParts[1][0]}'
              : c.name.isNotEmpty
                  ? c.name[0]
                  : '?';

          // Generate consistent color based on name hash
          final int hash = c.name.hashCode.abs();
          final List<Color> colors = <Color>[
            const Color(0xFFFFD6D6),
            const Color(0xFFD9EEFF),
            const Color(0xFFE8E1FF),
            const Color(0xFFD6F5E3),
            const Color(0xFFFFF3CD),
          ];
          final Color color = colors[hash % colors.length];

          return DashboardCustomerModel(
            name: c.name,
            time: '${c.invoices} invoices',
            amount: 'SAR ${c.revenue.toStringAsFixed(2)}',
            initials: initials,
            color: color,
          );
        }),
      );
      _topCustomersUiDirty = false;
    }
    return _topCustomersUi;
  }

  /// Get recent customers mapped from API data (fallback)
  List<DashboardCustomerModel> get recentCustomers {
    if (_recentCustomersUiDirty) {
      _recentCustomersUi = List<DashboardCustomerModel>.unmodifiable(
        _recentCustomersRaw.map((Map<String, dynamic> c) {
          final String name = c['customerName'] as String? ?? 'Unknown';
          final String createdAt = c['createdAt'] as String? ?? '';
          final String timeAgo = _formatTimeAgo(createdAt);

          // Generate initials from name
          final List<String> nameParts = name.split(' ');
          final String initials = nameParts.length > 1
              ? '${nameParts[0][0]}${nameParts[1][0]}'
              : name.isNotEmpty
                  ? name[0]
                  : '?';

          // Generate consistent color based on name
          final int hash = name.hashCode.abs();
          final List<Color> colors = <Color>[
            const Color(0xFFFFD6D6),
            const Color(0xFFD9EEFF),
            const Color(0xFFE8E1FF),
            const Color(0xFFD6F5E3),
            const Color(0xFFFFF3CD),
          ];
          final Color color = colors[hash % colors.length];

          return DashboardCustomerModel(
            name: name,
            time: timeAgo,
            amount: 'SAR 0',
            initials: initials,
            color: color,
          );
        }),
      );
      _recentCustomersUiDirty = false;
    }
    return _recentCustomersUi;
  }

  /// Load all dashboard data
  Future<void> loadDashboardData({
    String? companyId,
    String? dateFrom,
    String? dateTo,
  }) async {
    _companyId = companyId;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      const int recentInvoicesLimit = 10;
      const int recentCustomersLimit = 6;
      const int recentPreviewCount = 5;
      final ({
        String apiDateRange,
        String dateFrom,
        String dateTo,
        DateTime start,
        DateTime end,
      }) activeFilter = _resolveActiveDateFilter(
        overrideDateFrom: dateFrom,
        overrideDateTo: dateTo,
      );

      // PERFORMANCE OPTIMIZATION: Parallelize all API calls instead of sequential
      final List<dynamic> results = await Future.wait<dynamic>([
        _repository
            .getDashboardStats(
              companyId: companyId,
              dateRange: activeFilter.apiDateRange,
            )
            .catchError((Object e) {
          debugPrint('Dashboard: Error loading stats: $e');
          return const DashboardStats.empty();
        }),
        _repository
            .getRevenueMetrics(
              companyId: companyId,
              period: activeFilter.apiDateRange,
            )
            .catchError((Object e) {
          debugPrint('Dashboard: Error loading revenue: $e');
          return const RevenueMetrics.empty();
        }),
        _repository
            .getInvoiceDistribution(
              companyId: companyId,
              dateRange: activeFilter.apiDateRange,
            )
            .catchError((Object e) {
          debugPrint('Dashboard: Error loading invoice distribution: $e');
          return <InvoiceStatusDistribution>[];
        }),
        _repository
            .getRecentInvoices(
              companyId: companyId,
              limit: recentInvoicesLimit,
            )
            .catchError((Object e) {
          debugPrint('Dashboard: Error loading recent invoices: $e');
          return <Map<String, dynamic>>[];
        }),
        _repository
            .getRecentCustomers(
              companyId: companyId,
              limit: recentCustomersLimit,
            )
            .catchError((Object e) {
          debugPrint('Dashboard: Error loading recent customers: $e');
          return <Map<String, dynamic>>[];
        }),
        _repository
            .getInvoiceStats(
              companyId: companyId,
            )
            .catchError((Object e) {
          debugPrint('Dashboard: Error loading invoice stats: $e');
          return const InvoiceStats.empty();
        }),
        _repository
            .getCustomerStats(
              companyId: companyId,
            )
            .catchError((Object e) {
          debugPrint('Dashboard: Error loading customer stats: $e');
          return const <String, dynamic>{};
        }),
      ]);

      // Extract results from parallel execution
      final DashboardStats stats = results[0] as DashboardStats;
      final RevenueMetrics revenue = results[1] as RevenueMetrics;
      final List<InvoiceStatusDistribution> invoiceDistribution =
          results[2] as List<InvoiceStatusDistribution>;
      final List<Map<String, dynamic>> recentInvoices =
          results[3] as List<Map<String, dynamic>>;
      final List<Map<String, dynamic>> recentCustomers =
          results[4] as List<Map<String, dynamic>>;
      final InvoiceStats invoiceStats = results[5] as InvoiceStats;
      final Map<String, dynamic> customerStats =
          results[6] as Map<String, dynamic>;

      final List<Map<String, dynamic>> filteredRecentInvoices =
          _filterItemsByDate(
        recentInvoices,
        start: activeFilter.start,
        end: activeFilter.end,
      );
      final List<Map<String, dynamic>> filteredRecentCustomers =
          _filterItemsByDate(
        recentCustomers,
        start: activeFilter.start,
        end: activeFilter.end,
      );

      final int totalCust = customerStats['total'] is int
          ? (customerStats['total'] as int)
          : (int.tryParse(customerStats['total']?.toString() ?? '') ??
              stats.totalCustomers);
      final int activeCust = customerStats['active'] is int
          ? (customerStats['active'] as int)
          : (int.tryParse(customerStats['active']?.toString() ?? '') ??
              stats.activeCustomers);

      _stats = DashboardStats(
        totalCustomers: totalCust,
        activeCustomers: activeCust,
        totalInvoices: stats.totalInvoices,
        paidInvoices: stats.paidInvoices,
        totalRevenue: stats.totalRevenue,
        pendingAmount: stats.pendingAmount,
        trendPercentage: stats.trendPercentage,
      );
      _revenue = revenue;
      _topMetricsDirty = true;
      _statsListDirty = true;
      _salesTrendDirty = true;

      _hasMoreRecentInvoices = filteredRecentInvoices.length > recentPreviewCount;
      _hasMoreRecentCustomers =
          filteredRecentCustomers.length > recentPreviewCount;

      _recentCustomersRaw = filteredRecentCustomers.length > recentPreviewCount
          ? filteredRecentCustomers.take(recentPreviewCount).toList()
          : filteredRecentCustomers;
      _recentCustomersUiDirty = true;

      final List<Map<String, dynamic>> invoiceSample =
          filteredRecentInvoices.length > recentInvoicesLimit
          ? filteredRecentInvoices.take(recentInvoicesLimit).toList()
          : filteredRecentInvoices;
      final List<Map<String, dynamic>> invoiceUi =
          invoiceSample.length > recentPreviewCount
          ? invoiceSample.take(recentPreviewCount).toList()
          : invoiceSample;

      _invoiceTrendSeries = revenue.invoiceCounts.isNotEmpty
          ? revenue.invoiceCounts
          : _buildInvoiceTrendSeries(invoiceSample);
      _salesTrendDirty = true;

      // Strip heavy ZATCA fields to reduce memory bloat (UI list only)
      _recentInvoicesRaw = invoiceUi.map((inv) {
        return <String, dynamic>{
          'customerId': inv['customerId'],
          'invoiceNumber': inv['invoiceNumber'],
          'status': inv['status'],
          'total': inv['total'],
          'createdAt': inv['createdAt'],
          // Exclude: signedXML, qrCode, pdfUrl, zatca (large data)
        };
      }).toList();
      _recentInvoicesUiDirty = true;

      _invoiceDistribution = invoiceDistribution;
      _paidInvoicesProgressDirty = true;
      _topCustomers = const <TopCustomer>[];
      _topCustomersUiDirty = true;
      _invoiceStats = invoiceStats;
      _paidInvoicesProgressDirty = true;

      final int distributionTotalCount = _invoiceDistribution.fold(
        0,
        (int sum, InvoiceStatusDistribution d) => sum + d.count,
      );
      final int distributionPaidCount = _invoiceDistribution.isNotEmpty
          ? _countInvoiceDistribution(const <String>['paid'])
          : _stats.paidInvoices;
      final int nextStatsTotalInvoices = _stats.totalInvoices > 0
          ? _stats.totalInvoices
          : distributionTotalCount;
      if (nextStatsTotalInvoices != _stats.totalInvoices ||
          distributionPaidCount != _stats.paidInvoices) {
        _stats = DashboardStats(
          totalCustomers: _stats.totalCustomers,
          activeCustomers: _stats.activeCustomers,
          totalInvoices: nextStatsTotalInvoices,
          paidInvoices: distributionPaidCount,
          totalRevenue: _stats.totalRevenue,
          pendingAmount: _stats.pendingAmount,
          trendPercentage: _stats.trendPercentage,
        );
        _topMetricsDirty = true;
      }

      // Authoritative totals:
      // - totalInvoices should come from invoices pagination.total
      // - totalRevenue should come from overview if present, otherwise invoiceStats
      if ((_stats.totalRevenue == 0.0) && _revenue.currentRevenue > 0.0) {
        final double revenueFromMetrics = _revenue.currentRevenue;
        _stats = DashboardStats(
          totalCustomers: _stats.totalCustomers,
          activeCustomers: _stats.activeCustomers,
          totalInvoices: _stats.totalInvoices,
          paidInvoices: _stats.paidInvoices,
          totalRevenue: revenueFromMetrics,
          pendingAmount: _stats.pendingAmount,
          trendPercentage: _stats.trendPercentage,
        );
        _topMetricsDirty = true;
      }

      // Some backend report endpoints can return zeros when filtered by companyId
      // even though invoices exist. In that case, compute revenue from invoices.
      final String trimmedCompanyId = (_companyId ?? '').trim();
      final bool isCompanySelected = trimmedCompanyId.isNotEmpty;
      final bool hasFilteredInvoiceEvidence =
          _stats.totalInvoices > 0 ||
          distributionTotalCount > 0 ||
          filteredRecentInvoices.isNotEmpty;
      if (isCompanySelected &&
          _stats.totalRevenue == 0.0 &&
          hasFilteredInvoiceEvidence) {
        try {
          final double computedRevenue =
              await _repository.getCompanyRevenueFromInvoices(
            companyId: trimmedCompanyId,
            dateFrom: activeFilter.dateFrom,
            dateTo: activeFilter.dateTo,
          );

          if (computedRevenue > 0.0) {
            _stats = DashboardStats(
              totalCustomers: _stats.totalCustomers,
              activeCustomers: _stats.activeCustomers,
              totalInvoices: _stats.totalInvoices,
              paidInvoices: _stats.paidInvoices,
              totalRevenue: computedRevenue,
              pendingAmount: _stats.pendingAmount,
              trendPercentage: _stats.trendPercentage,
            );
            _topMetricsDirty = true;

            _invoiceStats = InvoiceStats(
              totalInvoices: _invoiceStats.totalInvoices,
              draftInvoices: _invoiceStats.draftInvoices,
              sentInvoices: _invoiceStats.sentInvoices,
              paidInvoices: _invoiceStats.paidInvoices,
              overdueInvoices: _invoiceStats.overdueInvoices,
              totalRevenue: computedRevenue,
              totalOutstanding: _invoiceStats.totalOutstanding,
              averageInvoiceValue: _invoiceStats.averageInvoiceValue,
            );
            _paidInvoicesProgressDirty = true;
          }
        } catch (_) {
          // ignore computed revenue fallback failure
        }
      }

      final bool reportsEmpty =
          (_stats.totalInvoices == 0 && _stats.totalRevenue == 0.0) &&
          _invoiceDistribution.isEmpty &&
          invoiceSample.isNotEmpty;

      if (reportsEmpty) {
        List<Map<String, dynamic>> fallbackInvoices = invoiceSample;
        const int minAllCompaniesFallbackSample = 30;
        const int allCompaniesFallbackFetchLimit = 60;

        if ((_companyId == null || _companyId!.trim().isEmpty) &&
            fallbackInvoices.length < minAllCompaniesFallbackSample) {
          try {
            final List<Map<String, dynamic>> bigger =
                await _repository.getRecentInvoices(
              companyId: null,
              limit: allCompaniesFallbackFetchLimit,
            );
            final List<Map<String, dynamic>> filteredBigger = _filterItemsByDate(
              bigger,
              start: activeFilter.start,
              end: activeFilter.end,
            );
            if (filteredBigger.isNotEmpty) {
              fallbackInvoices = filteredBigger;
            }
          } catch (_) {
            // ignore fallback enrichment
          }
        }

        final _FallbackDashboardComputed computed =
            _computeFallbackFromInvoices(fallbackInvoices);

        if ((_stats.totalInvoices == 0 && computed.totalInvoices > 0) ||
            (_stats.paidInvoices == 0 && computed.paidInvoices > 0)) {
          _stats = DashboardStats(
            totalCustomers: _stats.totalCustomers,
            activeCustomers: _stats.activeCustomers,
            totalInvoices: _stats.totalInvoices == 0
                ? computed.totalInvoices
                : _stats.totalInvoices,
            paidInvoices: _stats.paidInvoices == 0
                ? computed.paidInvoices
                : _stats.paidInvoices,
            totalRevenue: computed.totalRevenue,
            pendingAmount: _stats.pendingAmount,
            trendPercentage: _stats.trendPercentage,
          );
        }

        if (_invoiceStats.totalInvoices == 0 && computed.totalInvoices > 0) {
          _invoiceStats = InvoiceStats(
            totalInvoices: computed.totalInvoices,
            draftInvoices: computed.draftInvoices,
            sentInvoices: computed.sentInvoices,
            paidInvoices: computed.paidInvoices,
            overdueInvoices: computed.overdueInvoices,
            totalRevenue: computed.totalRevenue,
            totalOutstanding: 0.0,
            averageInvoiceValue: computed.totalInvoices > 0
                ? computed.totalRevenue / computed.totalInvoices
                : 0.0,
          );
        }

        if (_revenue.dailyRevenue.isEmpty && computed.monthlyRevenue.isNotEmpty) {
          _revenue = RevenueMetrics(
            currentRevenue: computed.totalRevenue,
            previousRevenue: 0.0,
            trend: 0.0,
            trendUp: true,
            dailyRevenue: computed.monthlyRevenue,
            invoiceCounts: computed.monthlyInvoiceCounts,
          );
        }

        if (_invoiceTrendSeries.isEmpty && computed.monthlyInvoiceCounts.isNotEmpty) {
          _invoiceTrendSeries = computed.monthlyInvoiceCounts;
          _salesTrendDirty = true;
        }

        if (_invoiceDistribution.isEmpty && computed.distribution.isNotEmpty) {
          _invoiceDistribution = computed.distribution;
          _paidInvoicesProgressDirty = true;
        }

        debugPrint(
          'Dashboard: Using fallback computed metrics from invoices sample (${fallbackInvoices.length})',
        );
      }
      
      debugPrint(
        'Dashboard: Loaded ${_recentInvoicesRaw.length} invoices and ${_recentCustomersRaw.length} recent customers',
      );
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('Dashboard: Error loading dashboard data: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
      debugPrint('Dashboard: notifyListeners called, isLoading=$_isLoading');
    }
  }

  /// Refresh dashboard data
  Future<void> refreshData() async {
    return loadDashboardData(companyId: _companyId);
  }

  Future<void> setCompanyId(String? companyId) async {
    final String? normalized = (companyId == null || companyId.trim().isEmpty)
        ? null
        : companyId.trim();
    if (normalized == _companyId) return;
    _isCompanyInitialized = true;
    await loadDashboardData(companyId: normalized);
  }

  String _getPeriodFromFilter() {
    switch (_filterIndex) {
      case 0:
        return '7days';
      case 1:
        return '30days';
      case 2:
        return '3months';
      case 3:
        return '6months';
      case 4:
        return '12months';
      default:
        return '30days';
    }
  }

  String _formatTimeAgo(String isoDate) {
    if (isoDate.isEmpty) return 'Unknown';
    try {
      final DateTime created = DateTime.parse(isoDate);
      final Duration diff = DateTime.now().difference(created);

      if (diff.inDays > 365) {
        return '${(diff.inDays / 365).floor()} years ago';
      } else if (diff.inDays > 30) {
        return '${(diff.inDays / 30).floor()} months ago';
      } else if (diff.inDays > 0) {
        return '${diff.inDays} days ago';
      } else if (diff.inHours > 0) {
        return '${diff.inHours} hours ago';
      } else if (diff.inMinutes > 0) {
        return '${diff.inMinutes} minutes ago';
      } else {
        return 'Just now';
      }
    } catch (_) {
      return 'Unknown';
    }
  }

  void setBottomIndex(int index) {
    if (index == _bottomIndex) {
      return;
    }
    _bottomIndex = index;
    notifyListeners();
  }

  Future<void> setFilterIndex(int index) async {
    if (index < 0 || index >= filterLabels.length) {
      return;
    }
    if (index == _filterIndex) {
      return;
    }
    _filterIndex = index;
    notifyListeners();
    await loadDashboardData(companyId: _companyId);
  }

  void setTrendMetricIndex(int index) {
    if (index == _trendMetricIndex) {
      return;
    }
    if (index < 0 || index > 1) {
      return;
    }
    _trendMetricIndex = index;
    _salesTrendDirty = true;
    notifyListeners();
  }

  void updateRepository(DashboardRepository repository) {
    _repository = repository;
  }

  Map<String, double> _buildInvoiceTrendSeries(
    List<Map<String, dynamic>> invoices,
  ) {
    if (invoices.isEmpty) return <String, double>{};
    final Map<String, double> counts = <String, double>{};
    for (final Map<String, dynamic> inv in invoices) {
      final String createdAt = inv['createdAt']?.toString() ?? '';
      if (createdAt.isEmpty) continue;
      try {
        final DateTime dt = DateTime.parse(createdAt);
        final String key = _monthShortNames[dt.month - 1];
        counts[key] = (counts[key] ?? 0.0) + 1.0;
      } catch (_) {}
    }

    final Map<String, double> ordered = <String, double>{};
    for (final String m in _monthShortNames) {
      final double? v = counts[m];
      if (v != null) {
        ordered[m] = v;
      }
    }
    return ordered;
  }
}

class _FallbackDashboardComputed {
  final int totalInvoices;
  final int draftInvoices;
  final int sentInvoices;
  final int paidInvoices;
  final int overdueInvoices;
  final double totalRevenue;
  final Map<String, double> monthlyRevenue;
  final Map<String, double> monthlyInvoiceCounts;
  final List<InvoiceStatusDistribution> distribution;
  final List<TopCustomer> topCustomers;

  const _FallbackDashboardComputed({
    required this.totalInvoices,
    required this.draftInvoices,
    required this.sentInvoices,
    required this.paidInvoices,
    required this.overdueInvoices,
    required this.totalRevenue,
    required this.monthlyRevenue,
    required this.monthlyInvoiceCounts,
    required this.distribution,
    required this.topCustomers,
  });
}

_FallbackDashboardComputed _computeFallbackFromInvoices(
  List<Map<String, dynamic>> invoices,
) {
  const List<String> months = <String>[
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  int draft = 0;
  int sent = 0;
  int paid = 0;
  int overdue = 0;
  double revenue = 0.0;

  final Map<String, int> statusCounts = <String, int>{};
  final Map<String, double> monthlyRevenue = <String, double>{};
  final Map<String, double> monthlyInvoiceCounts = <String, double>{};

  for (final Map<String, dynamic> inv in invoices) {
    final String status = inv['status']?.toString().toLowerCase() ?? '';
    statusCounts[status] = (statusCounts[status] ?? 0) + 1;
    switch (status) {
      case 'draft':
        draft++;
        break;
      case 'sent':
        sent++;
        break;
      case 'paid':
        paid++;
        break;
      case 'overdue':
        overdue++;
        break;
    }

    final double total = (inv['total'] as num?)?.toDouble() ?? 0.0;
    revenue += total;

    final String createdAt = inv['createdAt']?.toString() ?? '';
    try {
      if (createdAt.isNotEmpty) {
        final DateTime dt = DateTime.parse(createdAt);
        final String key = months[dt.month - 1];
        monthlyRevenue[key] = (monthlyRevenue[key] ?? 0.0) + total;
        monthlyInvoiceCounts[key] = (monthlyInvoiceCounts[key] ?? 0.0) + 1.0;
      }
    } catch (_) {}
  }

  final int totalInvoices = invoices.length;
  final List<InvoiceStatusDistribution> distribution = <InvoiceStatusDistribution>[];
  statusCounts.forEach((String status, int count) {
    if (status.isEmpty) return;
    final int pct = totalInvoices > 0 ? ((count / totalInvoices) * 100).round() : 0;
    distribution.add(
      InvoiceStatusDistribution(
        status: status,
        count: count,
        percentage: pct,
        color: 'bg-gray-500',
      ),
    );
  });
  distribution.sort((InvoiceStatusDistribution a, InvoiceStatusDistribution b) => b.count.compareTo(a.count));

  return _FallbackDashboardComputed(
    totalInvoices: totalInvoices,
    draftInvoices: draft,
    sentInvoices: sent,
    paidInvoices: paid,
    overdueInvoices: overdue,
    totalRevenue: revenue,
    monthlyRevenue: monthlyRevenue,
    monthlyInvoiceCounts: monthlyInvoiceCounts,
    distribution: distribution,
    topCustomers: const <TopCustomer>[],
  );
}
