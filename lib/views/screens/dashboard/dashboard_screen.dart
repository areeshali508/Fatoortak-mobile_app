import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/app_routes.dart';
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

class _DashboardScreenState extends State<DashboardScreen> {
  void _showComingSoon() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Coming soon')),
    );
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
        final DashboardController ctrl = context.watch<DashboardController>();
        final List<DashboardMetricModel> metrics = ctrl.topMetrics;
        final DashboardProgressModel progress = ctrl.paidInvoicesProgress;
        final DashboardTrendModel trend = ctrl.salesTrend;
        final List<DashboardStatModel> stats = ctrl.stats;
        final List<DashboardCustomerModel> customers = ctrl.recentCustomers;
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
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(hPad, gap, hPad, gap),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  _FilterChips(
                    constraints: constraints,
                    index: ctrl.filterIndex,
                    labels: ctrl.filterLabels,
                    onChanged: ctrl.setFilterIndex,
                  ),
                  SizedBox(height: gap),
                  Row(
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
                      SizedBox(width: AppResponsive.clamp(
                        AppResponsive.vw(constraints, 3.5),
                        12,
                        16,
                      )),
                      Expanded(
                        child: _MetricCard(
                          constraints: constraints,
                          icon: metrics.length > 1
                              ? metrics[1].icon
                              : Icons.receipt_long_outlined,
                          title: metrics.length > 1 ? metrics[1].title : 'Invoices',
                          value: metrics.length > 1 ? metrics[1].value : '0',
                          trend: metrics.length > 1 ? metrics[1].trend : '+0%',
                          trendUp: metrics.length > 1 ? metrics[1].trendUp : true,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: gap),
                  _ProgressCard(
                    constraints: constraints,
                    title: progress.title,
                    value: progress.value,
                    subtitle: progress.subtitle,
                    progress: progress.progress,
                  ),
                  SizedBox(height: gap),
                  _TrendCard(
                    constraints: constraints,
                    onViewReport: _showComingSoon,
                    trend: trend,
                  ),
                  SizedBox(height: gap),
                  Row(
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
                      SizedBox(width: AppResponsive.clamp(
                        AppResponsive.vw(constraints, 3.5),
                        12,
                        16,
                      )),
                      Expanded(
                        child: _StatCard(
                          constraints: constraints,
                          title: stats.length > 1 ? stats[1].title : 'ACTIVE NOW',
                          value: stats.length > 1 ? stats[1].value : '0',
                          subtitle:
                              stats.length > 1 ? stats[1].subtitle : '+0% vs yesterday',
                          icon: stats.length > 1 ? stats[1].icon : Icons.circle,
                          accent: stats.length > 1
                              ? stats[1].accent
                              : const Color(0xFF1DB954),
                          showDot: stats.length > 1 ? stats[1].showDot : true,
                          deltaText:
                              stats.length > 1 ? stats[1].deltaText : '+0% vs yesterday',
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: gap),
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
                      TextButton(
                        onPressed: _showComingSoon,
                        child: const Text('View All'),
                      ),
                    ],
                  ),
                  ...customers.map((DashboardCustomerModel c) {
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
              ),
            ),
          ),
          bottomNavigationBar: BottomNavigationBar(
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
          ),
        );
      },
    );
  }
}

class _FilterChips extends StatelessWidget {
  final BoxConstraints constraints;
  final int index;
  final List<String> labels;
  final ValueChanged<int> onChanged;

  const _FilterChips({
    required this.constraints,
    required this.index,
    required this.labels,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final List<String> items = labels.length >= 3
        ? labels.take(3).toList()
        : const <String>['Last 30 Days', 'Regions', 'Services'];
    return Row(
      children: <Widget>[
        for (int i = 0; i < 3; i++) ...<Widget>[
          if (i != 0) const SizedBox(width: 10),
          _Pill(
            constraints: constraints,
            label: items[i],
            selected: index == i,
            onTap: () => onChanged(i),
          ),
        ],
      ],
    );
  }
}

class _Pill extends StatelessWidget {
  final BoxConstraints constraints;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _Pill({
    required this.constraints,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? Colors.transparent : const Color(0xFFE9EEF5),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : const Color(0xFF6B7895),
            fontWeight: FontWeight.w700,
            fontSize: AppResponsive.clamp(
              AppResponsive.sp(constraints, 12),
              11,
              13,
            ),
          ),
        ),
      ),
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
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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
                  style: const TextStyle(
                    color: Color(0xFF0B1B4B),
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
              ),
              Text(
                value,
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

class _TrendCard extends StatelessWidget {
  final BoxConstraints constraints;
  final VoidCallback onViewReport;
  final DashboardTrendModel trend;

  const _TrendCard({
    required this.constraints,
    required this.onViewReport,
    required this.trend,
  });

  @override
  Widget build(BuildContext context) {
    final List<double> values = trend.values;
    final List<String> labels = trend.labels;

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
                onPressed: onViewReport,
                child: const Text('View Report'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: AppResponsive.clamp(
              AppResponsive.scaledByHeight(constraints, 120),
              96,
              140,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List<Widget>.generate(values.length, (int i) {
                final bool highlight = i == trend.highlightIndex;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 5),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: <Widget>[
                        Expanded(
                          child: Align(
                            alignment: Alignment.bottomCenter,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 250),
                              height: double.infinity,
                              constraints: BoxConstraints(
                                maxHeight: (values[i] * 120).clamp(18, 120),
                              ),
                              decoration: BoxDecoration(
                                color: highlight
                                    ? AppColors.primary
                                    : const Color(0xFFE9EEF5),
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          labels[i],
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
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
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
              Text(
                title,
                style: const TextStyle(
                  color: Color(0xFF9AA5B6),
                  fontWeight: FontWeight.w800,
                  fontSize: 11,
                  letterSpacing: 1.2,
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
                  style: const TextStyle(
                    color: Color(0xFF0B1B4B),
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  time,
                  style: const TextStyle(
                    color: Color(0xFF9AA5B6),
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Text(
            amount,
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
