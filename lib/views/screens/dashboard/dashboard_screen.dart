import 'package:flutter/material.dart';

import '../../../app/app_routes.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_responsive.dart';
import '../../layout/app_drawer.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _bottomIndex = 0;
  int _filterIndex = 0;

  void _showComingSoon() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Coming soon')),
    );
  }

  void _onBottomTap(int index) {
    if (index == 3) {
      Navigator.of(context).pushNamed(AppRoutes.settings);
      return;
    }
    setState(() => _bottomIndex = index);
    if (index != 0) {
      _showComingSoon();
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
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
                    index: _filterIndex,
                    onChanged: (int v) => setState(() => _filterIndex = v),
                  ),
                  SizedBox(height: gap),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: _MetricCard(
                          constraints: constraints,
                          icon: Icons.account_balance_wallet_outlined,
                          title: 'Revenue',
                          value: 'SAR 11,842',
                          trend: '+12%',
                          trendUp: true,
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
                          icon: Icons.receipt_long_outlined,
                          title: 'Invoices',
                          value: '45',
                          trend: '+5%',
                          trendUp: true,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: gap),
                  _ProgressCard(
                    constraints: constraints,
                    title: 'Paid Invoices',
                    value: 'SAR 8,242',
                    subtitle: '68% of goal',
                    progress: 0.68,
                  ),
                  SizedBox(height: gap),
                  _TrendCard(constraints: constraints, onViewReport: _showComingSoon),
                  SizedBox(height: gap),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: _StatCard(
                          constraints: constraints,
                          title: 'TOTAL CUSTOMERS',
                          value: '1,284',
                          subtitle: 'All time',
                          icon: Icons.groups_outlined,
                          accent: AppColors.primary,
                          showDot: false,
                          deltaText: null,
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
                          title: 'ACTIVE NOW',
                          value: '142',
                          subtitle: '+8% vs yesterday',
                          icon: Icons.circle,
                          accent: const Color(0xFF1DB954),
                          showDot: true,
                          deltaText: '+8% vs yesterday',
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
                  _CustomerTile(
                    constraints: constraints,
                    name: 'Sarah Williams',
                    time: '2 hours ago',
                    amount: 'SAR 1,200',
                    initials: 'S',
                    color: const Color(0xFFFFD6D6),
                  ),
                  _CustomerTile(
                    constraints: constraints,
                    name: 'Michael Chen',
                    time: '5 hours ago',
                    amount: 'SAR 850',
                    initials: 'M',
                    color: const Color(0xFFD9EEFF),
                  ),
                  _CustomerTile(
                    constraints: constraints,
                    name: 'John Doe Corp',
                    time: '1 day ago',
                    amount: 'SAR 3,420',
                    initials: 'JD',
                    color: const Color(0xFFE8E1FF),
                  ),
                ],
              ),
            ),
          ),
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _bottomIndex,
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
                label: 'Clients',
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
  final ValueChanged<int> onChanged;

  const _FilterChips({
    required this.constraints,
    required this.index,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        _Pill(
          constraints: constraints,
          label: 'Last 30 Days',
          selected: index == 0,
          onTap: () => onChanged(0),
        ),
        const SizedBox(width: 10),
        _Pill(
          constraints: constraints,
          label: 'Regions',
          selected: index == 1,
          onTap: () => onChanged(1),
        ),
        const SizedBox(width: 10),
        _Pill(
          constraints: constraints,
          label: 'Services',
          selected: index == 2,
          onTap: () => onChanged(2),
        ),
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

  const _TrendCard({required this.constraints, required this.onViewReport});

  @override
  Widget build(BuildContext context) {
    final List<double> values = <double>[0.35, 0.75, 0.6, 0.45, 0.65, 0.4, 0.48];
    const List<String> labels = <String>['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

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
                final bool highlight = i == 3;
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
