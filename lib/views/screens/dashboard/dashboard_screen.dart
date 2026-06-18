import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../../../app/app_routes.dart';
import '../../../controllers/companies_controller.dart';
import '../../../controllers/dashboard_controller.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_responsive.dart';
import '../../../models/dashboard.dart';
import '../../layout/app_drawer.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _CompanyFilter extends StatelessWidget {
  final BoxConstraints constraints;
  final String? selectedCompanyId;
  final List<Map<String, dynamic>> companies;
  final bool isLoading;
  final ValueChanged<String?> onChanged;

  const _CompanyFilter({
    required this.constraints,
    required this.selectedCompanyId,
    required this.companies,
    required this.isLoading,
    required this.onChanged,
  });

  String _companyLabelById(String? id) {
    final String key = (id ?? '').trim();
    if (key.isEmpty) return 'All Companies';
    try {
      final Map<String, dynamic> c = companies.firstWhere(
        (Map<String, dynamic> c) =>
            (c['_id'] ?? c['id'])?.toString().trim() == key,
      );
      final String label = (c['companyName'] ?? c['name'] ?? key)
              ?.toString()
              .trim() ??
          key;
      return label.isEmpty ? key : label;
    } catch (_) {
      return key;
    }
  }

  Future<void> _openCompanyPicker(BuildContext context) async {
    if (isLoading) return;

    const String allKey = '__ALL__';
    final String? picked = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (BuildContext ctx) {
        final List<Map<String, dynamic>> list = companies
            .where((Map<String, dynamic> c) {
              final String id =
                  (c['_id'] ?? c['id'])?.toString().trim() ?? '';
              return id.isNotEmpty;
            })
            .toList();

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 6, 18, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                const Text(
                  'Select Company',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFF0B1B4B),
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 10),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: list.length + 1,
                    separatorBuilder: (BuildContext context, int index) =>
                        const SizedBox(height: 8),
                    itemBuilder: (BuildContext context, int i) {
                      if (i == 0) {
                        final bool isSelected =
                            (selectedCompanyId ?? '').trim().isEmpty;
                        return Material(
                          color: const Color(0xFFF7FAFF),
                          borderRadius: BorderRadius.circular(14),
                          child: InkWell(
                            onTap: () => Navigator.of(ctx).pop(allKey),
                            borderRadius: BorderRadius.circular(14),
                            child: Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 12,
                              ),
                              child: Row(
                                children: <Widget>[
                                  Expanded(
                                    child: Text(
                                      'All Companies',
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: Color(0xFF0B1B4B),
                                        fontWeight: FontWeight.w800,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                  Icon(
                                    isSelected
                                        ? Icons.radio_button_checked
                                        : Icons.radio_button_off,
                                    color: isSelected
                                        ? AppColors.primary
                                        : Color(0xFF9AA5B6),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }

                      final Map<String, dynamic> c = list[i - 1];
                      final String id =
                          (c['_id'] ?? c['id'])?.toString().trim() ?? '';
                      final String label = (c['companyName'] ?? c['name'] ?? id)
                              ?.toString()
                              .trim() ??
                          id;
                      final bool isSelected =
                          (id.isNotEmpty && id == (selectedCompanyId ?? '').trim());

                      return Material(
                        color: const Color(0xFFF7FAFF),
                        borderRadius: BorderRadius.circular(14),
                        child: InkWell(
                          onTap: id.isEmpty
                              ? null
                              : () => Navigator.of(ctx).pop(id),
                          borderRadius: BorderRadius.circular(14),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            child: Row(
                              children: <Widget>[
                                Expanded(
                                  child: Text(
                                    label.isEmpty ? id : label,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Color(0xFF0B1B4B),
                                      fontWeight: FontWeight.w800,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                                Icon(
                                  isSelected
                                      ? Icons.radio_button_checked
                                      : Icons.radio_button_off,
                                  color: isSelected
                                      ? AppColors.primary
                                      : const Color(0xFF9AA5B6),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    final String next = (picked ?? '').trim();
    if (next.isEmpty) return;
    if (next == allKey) {
      onChanged(null);
      return;
    }
    if (next == (selectedCompanyId ?? '').trim()) return;
    onChanged(next);
  }

  @override
  Widget build(BuildContext context) {
    final String label = _companyLabelById(selectedCompanyId);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: <Widget>[
          const Text(
            'Company',
            style: TextStyle(
              color: Color(0xFF9AA5B6),
              fontWeight: FontWeight.w800,
              fontSize: 11,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Material(
              color: const Color(0xFFF7FAFF),
              borderRadius: BorderRadius.circular(14),
              child: InkWell(
                onTap: isLoading ? null : () => _openCompanyPicker(context),
                borderRadius: BorderRadius.circular(14),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF0B1B4B),
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      if (isLoading)
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      else
                        const Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: Color(0xFF9AA5B6),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PeriodFilter extends StatelessWidget {
  final int selectedIndex;
  final List<String> labels;
  final bool isLoading;
  final Future<void> Function(int index) onChanged;

  const _PeriodFilter({
    required this.selectedIndex,
    required this.labels,
    required this.isLoading,
    required this.onChanged,
  });

  Future<void> _openPeriodPicker(BuildContext context) async {
    if (isLoading || labels.isEmpty) return;

    final int? picked = await showModalBottomSheet<int>(
      context: context,
      showDragHandle: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (BuildContext ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 6, 18, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                const Text(
                  'Select Period',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFF0B1B4B),
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 10),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: labels.length,
                    separatorBuilder: (BuildContext context, int index) =>
                        const SizedBox(height: 8),
                    itemBuilder: (BuildContext context, int index) {
                      final bool isSelected = index == selectedIndex;
                      final String label = labels[index];
                      return Material(
                        color: const Color(0xFFF7FAFF),
                        borderRadius: BorderRadius.circular(14),
                        child: InkWell(
                          onTap: () => Navigator.of(ctx).pop(index),
                          borderRadius: BorderRadius.circular(14),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            child: Row(
                              children: <Widget>[
                                Expanded(
                                  child: Text(
                                    label,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Color(0xFF0B1B4B),
                                      fontWeight: FontWeight.w800,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                                Icon(
                                  isSelected
                                      ? Icons.radio_button_checked
                                      : Icons.radio_button_off,
                                  color: isSelected
                                      ? AppColors.primary
                                      : const Color(0xFF9AA5B6),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (picked == null || picked == selectedIndex) {
      return;
    }
    await onChanged(picked);
  }

  @override
  Widget build(BuildContext context) {
    final int safeIndex = labels.isEmpty
        ? 0
        : (selectedIndex < 0
            ? 0
            : (selectedIndex >= labels.length ? labels.length - 1 : selectedIndex));
    final String label = labels.isEmpty ? 'Last 30 Days' : labels[safeIndex];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: <Widget>[
          const Text(
            'Period',
            style: TextStyle(
              color: Color(0xFF9AA5B6),
              fontWeight: FontWeight.w800,
              fontSize: 11,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Material(
              color: const Color(0xFFF7FAFF),
              borderRadius: BorderRadius.circular(14),
              child: InkWell(
                onTap: isLoading ? null : () => _openPeriodPicker(context),
                borderRadius: BorderRadius.circular(14),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF0B1B4B),
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      if (isLoading)
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      else
                        const Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: Color(0xFF9AA5B6),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDashboardData();
    });
  }

  void _loadDashboardData() {
    final DashboardController ctrl = context.read<DashboardController>();
    final String? companyId = ctrl.companyId;
    ctrl.loadDashboardData(
      companyId: (companyId != null && companyId.trim().isNotEmpty)
          ? companyId.trim()
          : null,
    );
  }

  void _showComingSoon() {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Coming soon')));
  }

  void _onBottomTap(int index) {
    final DashboardController ctrl = context.read<DashboardController>();
    if (index == 1) {
      Navigator.of(context).pushReplacementNamed(AppRoutes.invoices);
      return;
    }
    if (index == 2) {
      Navigator.of(context).pushReplacementNamed(AppRoutes.customers);
      return;
    }
    if (index == 3) {
      Navigator.of(context).pushNamed(AppRoutes.settings);
      return;
    }
    ctrl.setBottomIndex(index);
    if (index != 0) {
      _showComingSoon();
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final DashboardController ctrl = context.read<DashboardController>();
        final double hPad = AppResponsive.clamp(
          AppResponsive.vw(constraints, 5.5),
          16,
          22,
        );
        final double gap = AppResponsive.clamp(
          AppResponsive.scaledByHeight(constraints, 16),
          12,
          18,
        );

        return Selector<DashboardController, String?>(
          selector: (_, DashboardController c) => c.errorMessage,
          builder: (BuildContext context, String? error, Widget? _) {
            if (error != null) {
              return Scaffold(
                backgroundColor: const Color(0xFFF7FAFF),
                drawer: const AppDrawer(),
                appBar: _buildAppBar(),
                body: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      const Icon(
                        Icons.error_outline,
                        color: Colors.red,
                        size: 48,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Failed to load dashboard',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: _loadDashboardData,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
                bottomNavigationBar: Selector<DashboardController, int>(
                  selector: (_, DashboardController c) => c.bottomIndex,
                  builder: (BuildContext context, int bottomIndex, Widget? child) {
                    return _buildBottomNav(ctrl);
                  },
                ),
              );
            }

            return Scaffold(
              backgroundColor: const Color(0xFFF7FAFF),
              drawer: const AppDrawer(),
              appBar: AppBar(
                backgroundColor: AppColors.splashBottom,
                foregroundColor: Colors.white,
                surfaceTintColor: AppColors.splashBottom,
                elevation: 0,
                centerTitle: true,
                title: const Text('Sales Dashboard'),
                leading: Builder(
                  builder: (BuildContext context) {
                    return IconButton(
                      icon: const Icon(Icons.menu),
                      onPressed: () => Scaffold.of(context).openDrawer(),
                    );
                  },
                ),
                actions: <Widget>[
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: IconButton(
                      onPressed: _showComingSoon,
                      icon: Stack(
                        clipBehavior: Clip.none,
                        children: <Widget>[
                          const Icon(Icons.notifications_none_rounded),
                          Positioned(
                            right: -1,
                            top: -1,
                            child: Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Color(0xFFE53935),
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              body: SafeArea(
                child: Selector<DashboardController, bool>(
                  selector: (_, DashboardController c) => c.isLoading,
                  builder: (BuildContext context, bool isLoading, Widget? _) {
                    return Skeletonizer(
                      enabled: isLoading && !kIsWeb,
                      child: SingleChildScrollView(
                        padding: EdgeInsets.fromLTRB(hPad, gap, hPad, gap),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: <Widget>[
                            Selector<DashboardController, String?>(
                              selector: (_, DashboardController c) => c.companyId,
                              builder:
                                  (BuildContext context, String? companyId, Widget? _) {
                                return Selector<CompaniesController,
                                    ({List<Map<String, dynamic>> companies, bool isLoading})>(
                                  selector: (_, CompaniesController c) => (
                                    companies: c.companies,
                                    isLoading: c.isLoading,
                                  ),
                                  builder: (
                                    BuildContext context,
                                    ({List<Map<String, dynamic>> companies, bool isLoading})
                                        companiesVm,
                                    Widget? _,
                                  ) {
                                    return _CompanyFilter(
                                      constraints: constraints,
                                      selectedCompanyId: companyId,
                                      companies: companiesVm.companies,
                                      isLoading: companiesVm.isLoading,
                                      onChanged: ctrl.setCompanyId,
                                    );
                                  },
                                );
                              },
                            ),
                            SizedBox(height: gap * 0.75),
                            Selector<DashboardController, int>(
                              selector: (_, DashboardController c) => c.filterIndex,
                              builder: (
                                BuildContext context,
                                int filterIndex,
                                Widget? _,
                              ) {
                                return _PeriodFilter(
                                  selectedIndex: filterIndex,
                                  labels: ctrl.filterLabels,
                                  isLoading: isLoading,
                                  onChanged: ctrl.setFilterIndex,
                                );
                              },
                            ),
                            SizedBox(height: gap),
                            Selector<DashboardController, List<DashboardMetricModel>>(
                              selector: (_, DashboardController c) => c.topMetrics,
                              builder: (BuildContext context,
                                  List<DashboardMetricModel> metrics, Widget? _) {
                                return Row(
                                  children: <Widget>[
                                    Expanded(
                                      child: _MetricCard(
                                        constraints: constraints,
                                        icon: metrics.first.icon,
                                        title: metrics.first.title,
                                        value: metrics.first.value,
                                        trend: metrics.first.trend,
                                        trendUp: metrics.first.trendUp,
                                      ),
                                    ),
                                    SizedBox(
                                      width: AppResponsive.clamp(
                                        AppResponsive.vw(constraints, 3.5),
                                        12,
                                        16,
                                      ),
                                    ),
                                    Expanded(
                                      child: _MetricCard(
                                        constraints: constraints,
                                        icon: metrics.length > 1
                                            ? metrics[1].icon
                                            : Icons.receipt_long_outlined,
                                        title: metrics.length > 1
                                            ? metrics[1].title
                                            : 'Invoices',
                                        value: metrics.length > 1
                                            ? metrics[1].value
                                            : '0',
                                        trend: metrics.length > 1
                                            ? metrics[1].trend
                                            : '+0%',
                                        trendUp: metrics.length > 1
                                            ? metrics[1].trendUp
                                            : true,
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                            SizedBox(height: gap),
                            Selector<DashboardController, DashboardProgressModel>(
                              selector:
                                  (_, DashboardController c) => c.paidInvoicesProgress,
                              builder: (BuildContext context,
                                  DashboardProgressModel progress, Widget? _) {
                                return _ProgressCard(
                                  constraints: constraints,
                                  title: progress.title,
                                  value: progress.value,
                                  subtitle: progress.subtitle,
                                  progress: progress.progress,
                                );
                              },
                            ),
                            SizedBox(height: gap),
                            Selector<DashboardController,
                                ({DashboardTrendModel trend, int metricIndex})>(
                              selector: (_, DashboardController c) => (
                                trend: c.salesTrend,
                                metricIndex: c.trendMetricIndex,
                              ),
                              builder: (
                                BuildContext context,
                                ({DashboardTrendModel trend, int metricIndex}) vm,
                                Widget? _,
                              ) {
                                return _TrendCard(
                                  constraints: constraints,
                                  onViewReport: _showComingSoon,
                                  trend: vm.trend,
                                  metricIndex: vm.metricIndex,
                                  metricLabels: ctrl.trendMetricLabels,
                                  onMetricChanged: ctrl.setTrendMetricIndex,
                                );
                              },
                            ),
                            SizedBox(height: gap),
                            Selector<DashboardController, List<DashboardStatModel>>(
                              selector: (_, DashboardController c) => c.statsList,
                              builder: (BuildContext context,
                                  List<DashboardStatModel> stats, Widget? _) {
                                return Row(
                                  children: <Widget>[
                                    Expanded(
                                      child: _StatCard(
                                        constraints: constraints,
                                        title: stats.first.title,
                                        value: stats.first.value,
                                        subtitle: stats.first.subtitle,
                                        icon: stats.first.icon,
                                        accent: stats.first.accent,
                                        showDot: stats.first.showDot,
                                        deltaText: stats.first.deltaText,
                                      ),
                                    ),
                                    SizedBox(
                                      width: AppResponsive.clamp(
                                        AppResponsive.vw(constraints, 3.5),
                                        12,
                                        16,
                                      ),
                                    ),
                                    Expanded(
                                      child: _StatCard(
                                        constraints: constraints,
                                        title: stats.length > 1
                                            ? stats[1].title
                                            : 'ACTIVE NOW',
                                        value:
                                            stats.length > 1 ? stats[1].value : '0',
                                        subtitle: stats.length > 1
                                            ? stats[1].subtitle
                                            : '+0% vs yesterday',
                                        icon: stats.length > 1
                                            ? stats[1].icon
                                            : Icons.circle,
                                        accent: stats.length > 1
                                            ? stats[1].accent
                                            : const Color(0xFF1DB954),
                                        showDot: stats.length > 1
                                            ? stats[1].showDot
                                            : true,
                                        deltaText: stats.length > 1
                                            ? stats[1].deltaText
                                            : '+0% vs yesterday',
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                            SizedBox(height: gap),
                            Selector<DashboardController,
                                ({List<DashboardCustomerModel> items, bool hasMore})>(
                              selector: (_, DashboardController c) => (
                                items: c.recentInvoices,
                                hasMore: c.hasMoreRecentInvoices,
                              ),
                              builder: (
                                BuildContext context,
                                ({List<DashboardCustomerModel> items, bool hasMore}) vm,
                                Widget? _,
                              ) {
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: <Widget>[
                                    Row(
                                      children: <Widget>[
                                        Expanded(
                                          child: Text(
                                            'Recent Invoices',
                                            style: TextStyle(
                                              fontSize: AppResponsive.clamp(
                                                AppResponsive.sp(constraints, 16),
                                                15,
                                                18,
                                              ),
                                              fontWeight: FontWeight.w800,
                                              color: const Color(0xFF0B1B4B),
                                            ),
                                          ),
                                        ),
                                        if (vm.hasMore)
                                          TextButton(
                                            style: TextButton.styleFrom(
                                              foregroundColor: AppColors.primary,
                                            ),
                                            onPressed: () => Navigator.of(context)
                                                .pushReplacementNamed(
                                              AppRoutes.invoices,
                                            ),
                                            child: const Text('View All'),
                                          ),
                                      ],
                                    ),
                                    ...vm.items.map((DashboardCustomerModel inv) {
                                      return _CustomerTile(
                                        constraints: constraints,
                                        name: inv.name,
                                        time: inv.time,
                                        amount: inv.amount,
                                        initials: inv.initials,
                                        color: inv.color,
                                      );
                                    }),
                                  ],
                                );
                              },
                            ),
                            SizedBox(height: gap),
                            Selector<DashboardController,
                                ({List<DashboardCustomerModel> items, bool hasMore})>(
                              selector: (_, DashboardController c) => (
                                items: c.recentCustomers,
                                hasMore: c.hasMoreRecentCustomers,
                              ),
                              builder: (
                                BuildContext context,
                                ({List<DashboardCustomerModel> items, bool hasMore}) vm,
                                Widget? _,
                              ) {
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: <Widget>[
                                    Row(
                                      children: <Widget>[
                                        Expanded(
                                          child: Text(
                                            'Recent Customers',
                                            style: TextStyle(
                                              fontSize: AppResponsive.clamp(
                                                AppResponsive.sp(constraints, 16),
                                                15,
                                                18,
                                              ),
                                              fontWeight: FontWeight.w800,
                                              color: const Color(0xFF0B1B4B),
                                            ),
                                          ),
                                        ),
                                        if (vm.hasMore)
                                          TextButton(
                                            style: TextButton.styleFrom(
                                              foregroundColor: AppColors.primary,
                                            ),
                                            onPressed: () => Navigator.of(context)
                                                .pushReplacementNamed(
                                              AppRoutes.customers,
                                            ),
                                            child: const Text('View All'),
                                          ),
                                      ],
                                    ),
                                    ...vm.items.map((DashboardCustomerModel c) {
                                      return _CustomerTile(
                                        constraints: constraints,
                                        name: c.name,
                                        time: c.time,
                                        amount: c.amount,
                                        initials: c.initials,
                                        color: c.color,
                                      );
                                    }),
                                  ],
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              bottomNavigationBar: Selector<DashboardController, int>(
                selector: (_, DashboardController c) => c.bottomIndex,
                builder: (BuildContext context, int bottomIndex, Widget? child) {
                  return _buildBottomNav(ctrl);
                },
              ),
            );
          },
        );
      },
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.splashBottom,
      foregroundColor: Colors.white,
      surfaceTintColor: AppColors.splashBottom,
      elevation: 0,
      centerTitle: true,
      title: const Text('Sales Dashboard'),
      leading: Builder(
        builder: (BuildContext context) {
          return IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          );
        },
      ),
      actions: <Widget>[
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: IconButton(
            onPressed: _showComingSoon,
            icon: Stack(
              clipBehavior: Clip.none,
              children: <Widget>[
                const Icon(Icons.notifications_none_rounded),
                Positioned(
                  right: -1,
                  top: -1,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Color(0xFFE53935),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  BottomNavigationBar _buildBottomNav(DashboardController ctrl) {
    return BottomNavigationBar(
      currentIndex: ctrl.bottomIndex,
      onTap: _onBottomTap,
      type: BottomNavigationBarType.fixed,
      selectedItemColor: AppColors.primary,
      unselectedItemColor: const Color(0xFF9AA5B6),
      items: const <BottomNavigationBarItem>[
        BottomNavigationBarItem(
          icon: Icon(Icons.home_rounded),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.receipt_long_outlined),
          label: 'Invoices',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.groups_outlined),
          label: 'Customers',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.settings_outlined),
          label: 'Settings',
        ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  final BoxConstraints constraints;
  final IconData icon;
  final String title;
  final String value;
  final String trend;
  final bool trendUp;

  const _MetricCard({
    required this.constraints,
    required this.icon,
    required this.title,
    required this.value,
    required this.trend,
    required this.trendUp,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F6FB),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AppColors.primary, size: 20),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFFAF3),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  children: <Widget>[
                    Icon(
                      Icons.trending_up,
                      size: 14,
                      color: const Color(0xFF1DB954),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      trend,
                      style: const TextStyle(
                        color: Color(0xFF1DB954),
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF6B7895),
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              color: const Color(0xFF0B1B4B),
              fontWeight: FontWeight.w900,
              fontSize: AppResponsive.clamp(
                AppResponsive.sp(constraints, 18),
                16,
                20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressCard extends StatelessWidget {
  final BoxConstraints constraints;
  final String title;
  final String value;
  final String subtitle;
  final double progress;

  const _ProgressCard({
    required this.constraints,
    required this.title,
    required this.value,
    required this.subtitle,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 28,
                height: 28,
                decoration: const BoxDecoration(
                  color: Color(0xFFEFFAF3),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check,
                  color: Color(0xFF1DB954),
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF0B1B4B),
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF0B1B4B),
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: const Color(0xFFE9EEF5),
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              subtitle,
              style: const TextStyle(
                color: Color(0xFF6B7895),
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TrendCard extends StatefulWidget {
  final BoxConstraints constraints;
  final VoidCallback onViewReport;
  final DashboardTrendModel trend;
  final int metricIndex;
  final List<String> metricLabels;
  final ValueChanged<int> onMetricChanged;

  const _TrendCard({
    required this.constraints,
    required this.onViewReport,
    required this.trend,
    required this.metricIndex,
    required this.metricLabels,
    required this.onMetricChanged,
  });

  @override
  State<_TrendCard> createState() => _TrendCardState();
}

class _TrendCardState extends State<_TrendCard> {
  int? _activeIndex;

  String _formatValue(double v, bool isCurrency) {
    if (isCurrency) {
      return 'SAR ${v.toStringAsFixed(2)}';
    }
    return v.toStringAsFixed(0);
  }

  int _indexFromDx(double dx, double width, int n) {
    if (n <= 1 || width <= 0) return 0;
    final double t = (dx / width).clamp(0.0, 1.0);
    return (t * (n - 1)).round().clamp(0, n - 1);
  }

  @override
  Widget build(BuildContext context) {
    final List<double> values = widget.trend.values;
    final List<double> rawValues = widget.trend.rawValues;
    final List<String> labels = widget.trend.labels;
    final int n = values.length;

    final int index = (_activeIndex ?? widget.trend.highlightIndex)
        .clamp(0, (n - 1).clamp(0, 0x7fffffff));

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: <Widget>[
          Row(
            children: <Widget>[
              const Text(
                'Sales Trend',
                style: TextStyle(
                  color: Color(0xFF0B1B4B),
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: widget.onViewReport,
                child: const Text('View Report'),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerLeft,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5FB),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: List<Widget>.generate(widget.metricLabels.length,
                    (int i) {
                  final bool selected = i == widget.metricIndex;
                  return InkWell(
                    onTap: () => widget.onMetricChanged(i),
                    borderRadius: BorderRadius.circular(999),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: selected ? Colors.white : Colors.transparent,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        widget.metricLabels[i],
                        style: TextStyle(
                          color: selected
                              ? const Color(0xFF0B1B4B)
                              : const Color(0xFF6B7895),
                          fontWeight:
                              selected ? FontWeight.w800 : FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: AppResponsive.clamp(
              AppResponsive.scaledByHeight(widget.constraints, 120),
              96,
              160,
            ),
            child: LayoutBuilder(
              builder: (BuildContext context, BoxConstraints c) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Column(
                    children: <Widget>[
                      Expanded(
                        child: Stack(
                          children: <Widget>[
                            Positioned.fill(
                              child: MouseRegion(
                                onHover: (e) {
                                  final RenderBox box =
                                      context.findRenderObject()! as RenderBox;
                                  final Offset local =
                                      box.globalToLocal(e.position);
                                  setState(() {
                                    _activeIndex = _indexFromDx(
                                      local.dx,
                                      c.maxWidth,
                                      n,
                                    );
                                  });
                                },
                                onExit: (_) {
                                  setState(() {
                                    _activeIndex = null;
                                  });
                                },
                                child: GestureDetector(
                                  behavior: HitTestBehavior.translucent,
                                  onTapDown: (TapDownDetails d) {
                                    setState(() {
                                      _activeIndex = _indexFromDx(
                                        d.localPosition.dx,
                                        c.maxWidth,
                                        n,
                                      );
                                    });
                                  },
                                  child: RepaintBoundary(
                                    child: CustomPaint(
                                      painter: _TrendLinePainter(
                                        values: values,
                                        highlightIndex: index,
                                        lineColor: AppColors.primary,
                                        fillColor: AppColors.primary
                                            .withValues(alpha: 0.12),
                                        gridColor: const Color(0xFFE9EEF5),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            if (rawValues.isNotEmpty && labels.isNotEmpty)
                              Positioned(
                                left: (n <= 1)
                                    ? (c.maxWidth / 2 - 60)
                                    : (() {
                                        final double raw =
                                            (index / (n - 1)) * c.maxWidth -
                                                60;
                                        final double maxLeft =
                                            (c.maxWidth - 126) < 6
                                                ? 6.0
                                                : (c.maxWidth - 126);
                                        return raw.clamp(6.0, maxLeft);
                                      })(),
                                top: 6,
                                child: Container(
                                  width: 120,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF0B1B4B),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: <Widget>[
                                      Text(
                                        labels[index],
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 11,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        _formatValue(
                                          rawValues[index],
                                          widget.trend.isCurrency,
                                        ),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w900,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: List<Widget>.generate(labels.length,
                            (int i) {
                          final bool highlight = i == index;
                          return Expanded(
                            child: Text(
                              labels[i],
                              textAlign: TextAlign.center,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: highlight
                                    ? AppColors.primary
                                    : const Color(0xFF9AA5B6),
                                fontWeight: highlight
                                    ? FontWeight.w800
                                    : FontWeight.w700,
                                fontSize: 11,
                              ),
                            ),
                          );
                        }),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _TrendLinePainter extends CustomPainter {
  final List<double> values;
  final int highlightIndex;
  final Color lineColor;
  final Color fillColor;
  final Color gridColor;

  const _TrendLinePainter({
    required this.values,
    required this.highlightIndex,
    required this.lineColor,
    required this.fillColor,
    required this.gridColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty || size.width <= 0 || size.height <= 0) return;

    final Paint gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    final Paint linePaint = Paint()
      ..color = lineColor
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    final Paint fillPaint = Paint()
      ..color = fillColor
      ..style = PaintingStyle.fill;

    final double leftPad = 4;
    final double rightPad = 4;
    final double topPad = 8;
    final double bottomPad = 8;

    final Rect chart = Rect.fromLTWH(
      leftPad,
      topPad,
      (size.width - leftPad - rightPad).clamp(0, size.width),
      (size.height - topPad - bottomPad).clamp(0, size.height),
    );

    if (chart.width <= 0 || chart.height <= 0) return;

    for (int i = 1; i <= 2; i++) {
      final double y = chart.top + (chart.height * (i / 3));
      canvas.drawLine(Offset(chart.left, y), Offset(chart.right, y), gridPaint);
    }

    final int n = values.length;
    final double dx = n == 1 ? 0 : chart.width / (n - 1);

    Offset pointAt(int i) {
      final double v = values[i].clamp(0.0, 1.0);
      final double x = chart.left + (dx * i);
      final double y = chart.bottom - (v * chart.height);
      return Offset(x, y);
    }

    final Path line = Path();
    final Offset p0 = pointAt(0);
    line.moveTo(p0.dx, p0.dy);
    if (n == 2) {
      final Offset p1 = pointAt(1);
      line.lineTo(p1.dx, p1.dy);
    } else {
      for (int i = 1; i < n - 1; i++) {
        final Offset p1 = pointAt(i);
        final Offset p2 = pointAt(i + 1);
        final Offset mid = Offset(
          (p1.dx + p2.dx) / 2,
          (p1.dy + p2.dy) / 2,
        );
        line.quadraticBezierTo(p1.dx, p1.dy, mid.dx, mid.dy);
      }
      final Offset last = pointAt(n - 1);
      line.lineTo(last.dx, last.dy);
    }

    final Path fill = Path.from(line)
      ..lineTo(pointAt(n - 1).dx, chart.bottom)
      ..lineTo(pointAt(0).dx, chart.bottom)
      ..close();

    canvas.drawPath(fill, fillPaint);
    canvas.drawPath(line, linePaint);

    final int idx = highlightIndex.clamp(0, n - 1);
    final Offset hp = pointAt(idx);

    final Paint haloPaint = Paint()
      ..color = lineColor.withValues(alpha: 0.18)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(hp, 10, haloPaint);

    final Paint dotPaint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.fill;
    canvas.drawCircle(hp, 4.5, dotPaint);

    final Paint dotBorder = Paint()
      ..color = Colors.white
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(hp, 4.5, dotBorder);
  }

  @override
  bool shouldRepaint(covariant _TrendLinePainter oldDelegate) {
    return oldDelegate.values != values ||
        oldDelegate.highlightIndex != highlightIndex ||
        oldDelegate.lineColor != lineColor ||
        oldDelegate.fillColor != fillColor ||
        oldDelegate.gridColor != gridColor;
  }
}

class _StatCard extends StatelessWidget {
  final BoxConstraints constraints;
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color accent;
  final bool showDot;
  final String? deltaText;

  const _StatCard({
    required this.constraints,
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.accent,
    required this.showDot,
    required this.deltaText,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF9AA5B6),
                    fontWeight: FontWeight.w800,
                    fontSize: 11,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              const Spacer(),
              if (showDot)
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: accent,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: const Color(0xFF0B1B4B),
              fontWeight: FontWeight.w900,
              fontSize: AppResponsive.clamp(
                AppResponsive.sp(constraints, 18),
                16,
                22,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: <Widget>[
              Icon(
                icon,
                size: 14,
                color: showDot ? accent : const Color(0xFF9AA5B6),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  showDot ? subtitle : subtitle,
                  style: TextStyle(
                    color: showDot ? accent : const Color(0xFF6B7895),
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CustomerTile extends StatelessWidget {
  final BoxConstraints constraints;
  final String name;
  final String time;
  final String amount;
  final String initials;
  final Color color;

  const _CustomerTile({
    required this.constraints,
    required this.name,
    required this.time,
    required this.amount,
    required this.initials,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: <Widget>[
          CircleAvatar(
            radius: 22,
            backgroundColor: color,
            child: Text(
              initials,
              style: const TextStyle(
                color: Color(0xFF0B1B4B),
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF0B1B4B),
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  time,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF9AA5B6),
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            amount,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF0B1B4B),
              fontWeight: FontWeight.w900,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
