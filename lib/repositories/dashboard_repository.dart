import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';
import '../models/dashboard.dart';

class DashboardRepository {
  const DashboardRepository();

  List<String> getFilterLabels() {
    return const <String>['Last 30 Days', 'Regions', 'Services'];
  }

  List<DashboardMetricModel> getTopMetrics({required int filterIndex}) {
    return const <DashboardMetricModel>[
      DashboardMetricModel(
        icon: Icons.account_balance_wallet_outlined,
        title: 'Revenue',
        value: 'SAR 11,842',
        trend: '+12%',
        trendUp: true,
      ),
      DashboardMetricModel(
        icon: Icons.receipt_long_outlined,
        title: 'Invoices',
        value: '45',
        trend: '+5%',
        trendUp: true,
      ),
    ];
  }

  DashboardProgressModel getPaidInvoicesProgress({required int filterIndex}) {
    return const DashboardProgressModel(
      title: 'Paid Invoices',
      value: 'SAR 8,242',
      subtitle: '68% of goal',
      progress: 0.68,
    );
  }

  DashboardTrendModel getSalesTrend({required int filterIndex}) {
    return const DashboardTrendModel(
      values: <double>[0.35, 0.75, 0.6, 0.45, 0.65, 0.4, 0.48],
      labels: <String>['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'],
      highlightIndex: 3,
    );
  }

  List<DashboardStatModel> getStats({required int filterIndex}) {
    return const <DashboardStatModel>[
      DashboardStatModel(
        title: 'TOTAL CUSTOMERS',
        value: '1,284',
        subtitle: 'All time',
        icon: Icons.groups_outlined,
        accent: AppColors.primary,
        showDot: false,
        deltaText: null,
      ),
      DashboardStatModel(
        title: 'ACTIVE NOW',
        value: '142',
        subtitle: '+8% vs yesterday',
        icon: Icons.circle,
        accent: Color(0xFF1DB954),
        showDot: true,
        deltaText: '+8% vs yesterday',
      ),
    ];
  }

  List<DashboardCustomerModel> getRecentCustomers({required int filterIndex}) {
    return const <DashboardCustomerModel>[
      DashboardCustomerModel(
        name: 'Sarah Williams',
        time: '2 hours ago',
        amount: 'SAR 1,200',
        initials: 'S',
        color: Color(0xFFFFD6D6),
      ),
      DashboardCustomerModel(
        name: 'Michael Chen',
        time: '5 hours ago',
        amount: 'SAR 850',
        initials: 'M',
        color: Color(0xFFD9EEFF),
      ),
      DashboardCustomerModel(
        name: 'John Doe Corp',
        time: '1 day ago',
        amount: 'SAR 3,420',
        initials: 'JD',
        color: Color(0xFFE8E1FF),
      ),
    ];
  }
}
