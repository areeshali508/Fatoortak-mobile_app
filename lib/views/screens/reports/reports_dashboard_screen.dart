import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../controllers/auth_controller.dart';
import '../../../controllers/reports_controller.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_responsive.dart';
import '../../../app/app_routes.dart';
import '../../layout/app_drawer.dart';

class ReportsDashboardScreen extends StatefulWidget {
  const ReportsDashboardScreen({super.key});

  @override
  State<ReportsDashboardScreen> createState() => _ReportsDashboardScreenState();
}

class _ReportsDashboardScreenState extends State<ReportsDashboardScreen> {
  int _rangeIndex = 1;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDashboardData();
    });
  }

  void _loadDashboardData() {
    final AuthController auth = context.read<AuthController>();
    final String? companyId = auth.activeCompanyId;
    if (companyId != null && companyId.isNotEmpty) {
      context.read<ReportsController>().loadDashboardStats(companyId: companyId);
    }
  }

  void _comingSoon() {
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Coming soon')));
  }

  void _onBottomTap(int index) {
    if (index == 0) {
      Navigator.of(context).pushReplacementNamed(AppRoutes.dashboard);
      return;
    }
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
    _comingSoon();
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
            title: const Text('Reports Dashboard'),
            leading: Builder(
              builder: (BuildContext scaffoldContext) {
                return IconButton(
                  icon: const Icon(Icons.menu),
                  onPressed: () => Scaffold.of(scaffoldContext).openDrawer(),
                );
              },
            ),
            actions: <Widget>[
              IconButton(
                onPressed: _comingSoon,
                icon: const Icon(Icons.notifications_outlined),
              ),
            ],
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(hPad, gap, hPad, gap),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  _RangeChips(
                    constraints: constraints,
                    index: _rangeIndex,
                    onChanged: (int i) => setState(() => _rangeIndex = i),
                  ),
                  SizedBox(height: gap),
                  const _SectionTitle('BUSINESS OVERVIEW'),
                  SizedBox(height: gap),
                  _BusinessOverviewGrid(
                    constraints: constraints,
                    onRefresh: _loadDashboardData,
                  ),
                  SizedBox(height: gap),
                  _TopProductCustomerRow(constraints: constraints),
                  SizedBox(height: gap),
                  const _SectionTitle('DETAILED REPORTS'),
                  SizedBox(height: gap),
                  _DetailedReportsList(
                    constraints: constraints,
                    onSalesTap: () => Navigator.of(context).pushNamed(AppRoutes.salesReports),
                    onCustomerTap: () => Navigator.of(context).pushNamed(AppRoutes.customerReports),
                    onProductTap: () => Navigator.of(context).pushNamed(AppRoutes.productReports),
                  ),
                  SizedBox(height: gap),
                  _RecentActivityHeader(
                    constraints: constraints,
                    onViewAll: _comingSoon,
                  ),
                  SizedBox(height: gap),
                  _RecentActivityList(constraints: constraints),
                  SizedBox(height: gap),
                  _CustomReportBanner(constraints: constraints),
                ],
              ),
            ),
          ),
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: 0,
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

class _RangeChips extends StatelessWidget {
  final BoxConstraints constraints;
  final int index;
  final ValueChanged<int> onChanged;

  const _RangeChips({
    required this.constraints,
    required this.index,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final List<String> labels = <String>[
      'Last 7 days',
      'Last 30 days',
      'This Year',
    ];

    final double fontSize = AppResponsive.clamp(
      AppResponsive.sp(constraints, 11.5),
      11,
      13,
    );

    return Row(
      children: List<Widget>.generate(labels.length, (int i) {
        final bool selected = i == index;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: i == labels.length - 1 ? 0 : 10),
            child: Material(
              color: selected ? const Color(0xFF0C1E59) : Colors.white,
              borderRadius: BorderRadius.circular(999),
              child: InkWell(
                onTap: () => onChanged(i),
                borderRadius: BorderRadius.circular(999),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                  child: Center(
                    child: Text(
                      labels[i],
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: selected ? Colors.white : const Color(0xFF0B1B4B),
                        fontWeight: FontWeight.w800,
                        fontSize: fontSize,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;

  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: Color(0xFF9AA5B6),
        fontSize: 12,
        letterSpacing: 1.2,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}

class _BusinessOverviewGrid extends StatelessWidget {
  final BoxConstraints constraints;
  final VoidCallback onRefresh;

  const _BusinessOverviewGrid({
    required this.constraints,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final ({DashboardStats stats, bool isLoading}) vm =
        context.select<ReportsController, ({DashboardStats stats, bool isLoading})>(
          (ReportsController ctrl) => (
            stats: ctrl.dashboardStats,
            isLoading: ctrl.isLoadingDashboard,
          ),
        );
    final DashboardStats stats = vm.stats;
    final bool isLoading = vm.isLoading;

    final double gap = AppResponsive.clamp(
      AppResponsive.vw(constraints, 3.2),
      12,
      16,
    );

    if (isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Column(
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: _OverviewCard(
                constraints: constraints,
                title: 'Total Revenue',
                value: stats.formattedRevenue,
                delta: '+15.3%',
                deltaColor: const Color(0xFF1E9E5C),
              ),
            ),
            SizedBox(width: gap),
            Expanded(
              child: _OverviewCard(
                constraints: constraints,
                title: 'Total Invoices',
                value: stats.totalInvoices.toString(),
                delta: '+8.7%',
                deltaColor: const Color(0xFF1E9E5C),
              ),
            ),
          ],
        ),
        SizedBox(height: gap),
        Row(
          children: <Widget>[
            Expanded(
              child: _OverviewCard(
                constraints: constraints,
                title: 'Active Customers',
                value: stats.activeCustomers.toString(),
                delta: '+12.1%',
                deltaColor: const Color(0xFF1E9E5C),
              ),
            ),
            SizedBox(width: gap),
            Expanded(
              child: _OverviewCard(
                constraints: constraints,
                title: 'Products Sold',
                value: stats.totalProducts.toString(),
                delta: '+6.3%',
                deltaColor: const Color(0xFF1E9E5C),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _OverviewCard extends StatelessWidget {
  final BoxConstraints constraints;
  final String title;
  final String value;
  final String delta;
  final Color deltaColor;

  const _OverviewCard({
    required this.constraints,
    required this.title,
    required this.value,
    required this.delta,
    required this.deltaColor,
  });

  @override
  Widget build(BuildContext context) {
    final double titleSize = AppResponsive.clamp(
      AppResponsive.sp(constraints, 11.5),
      11,
      13,
    );

    final double valueSize = AppResponsive.clamp(
      AppResponsive.sp(constraints, 18),
      16,
      20,
    );

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE9EEF5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            title,
            style: TextStyle(
              color: const Color(0xFF63708A),
              fontWeight: FontWeight.w800,
              fontSize: titleSize,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: const Color(0xFF0B1B4B),
              fontWeight: FontWeight.w900,
              fontSize: valueSize,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: <Widget>[
              Icon(
                Icons.trending_up,
                size: 16,
                color: deltaColor,
              ),
              const SizedBox(width: 6),
              Text(
                delta,
                style: TextStyle(
                  color: deltaColor,
                  fontWeight: FontWeight.w900,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TopProductCustomerRow extends StatelessWidget {
  final BoxConstraints constraints;

  const _TopProductCustomerRow({required this.constraints});

  @override
  Widget build(BuildContext context) {
    final double gap = AppResponsive.clamp(
      AppResponsive.vw(constraints, 3.2),
      12,
      16,
    );

    return Row(
      children: <Widget>[
        Expanded(
          child: _HighlightCard(
            constraints: constraints,
            icon: Icons.shopping_bag_outlined,
            iconBg: const Color(0xFFFFF5E6),
            iconColor: const Color(0xFFFF9800),
            badge: 'TOP PRODUCT',
            title: 'Enterprise Software',
            subtitle: 'SAR 450k revenue',
          ),
        ),
        SizedBox(width: gap),
        Expanded(
          child: _HighlightCard(
            constraints: constraints,
            icon: Icons.star,
            iconBg: const Color(0xFFEAFBF2),
            iconColor: const Color(0xFF1E9E5C),
            badge: 'TOP CUSTOMER',
            title: 'TechCorp Inc.',
            subtitle: '32 active subscriptions',
          ),
        ),
      ],
    );
  }
}

class _HighlightCard extends StatelessWidget {
  final BoxConstraints constraints;
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String badge;
  final String title;
  final String subtitle;

  const _HighlightCard({
    required this.constraints,
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.badge,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE9EEF5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 16),
              ),
              const SizedBox(width: 8),
              Text(
                badge,
                style: const TextStyle(
                  color: Color(0xFF9AA5B6),
                  fontWeight: FontWeight.w800,
                  fontSize: 10,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF0B1B4B),
              fontWeight: FontWeight.w900,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(
              color: Color(0xFF63708A),
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailedReportsList extends StatelessWidget {
  final BoxConstraints constraints;
  final VoidCallback onSalesTap;
  final VoidCallback onCustomerTap;
  final VoidCallback onProductTap;

  const _DetailedReportsList({
    required this.constraints,
    required this.onSalesTap,
    required this.onCustomerTap,
    required this.onProductTap,
  });

  @override
  Widget build(BuildContext context) {
    final List<_DetailedReportItemData> items = <_DetailedReportItemData>[
      _DetailedReportItemData(
        icon: Icons.insert_chart_outlined,
        iconBg: const Color(0xFFEFF4FF),
        iconColor: AppColors.primary,
        title: 'Sales Reports',
        meta: 'Rev: SAR 1.2M • Inv: 1,254',
        onTap: onSalesTap,
      ),
      _DetailedReportItemData(
        icon: Icons.groups_outlined,
        iconBg: const Color(0xFFF0E6FF),
        iconColor: const Color(0xFF7C4DFF),
        title: 'Customer Reports',
        meta: 'Active: 342 • Retention: 87%',
        onTap: onCustomerTap,
      ),
      _DetailedReportItemData(
        icon: Icons.inventory_2_outlined,
        iconBg: const Color(0xFFFFF5E6),
        iconColor: const Color(0xFFFF9800),
        title: 'Product Reports',
        meta: 'Total: 156 • Top: Software Dev',
        onTap: onProductTap,
      ),
    ];

    return Column(
      children: items.map((_DetailedReportItemData item) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: _DetailedReportTile(item: item),
        );
      }).toList(),
    );
  }
}

class _DetailedReportItemData {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String title;
  final String meta;
  final VoidCallback onTap;

  const _DetailedReportItemData({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    required this.meta,
    required this.onTap,
  });
}

class _DetailedReportTile extends StatelessWidget {
  final _DetailedReportItemData item;

  const _DetailedReportTile({required this.item});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: item.onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE9EEF5)),
          ),
          child: Row(
            children: <Widget>[
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: item.iconBg,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(item.icon, color: item.iconColor, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      item.title,
                      style: const TextStyle(
                        color: Color(0xFF0B1B4B),
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.meta,
                      style: const TextStyle(
                        color: Color(0xFF63708A),
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Color(0xFF9AA5B6)),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecentActivityHeader extends StatelessWidget {
  final BoxConstraints constraints;
  final VoidCallback onViewAll;

  const _RecentActivityHeader({
    required this.constraints,
    required this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        const Text(
          'RECENT ACTIVITY',
          style: TextStyle(
            color: Color(0xFF9AA5B6),
            fontSize: 12,
            letterSpacing: 1.2,
            fontWeight: FontWeight.w800,
          ),
        ),
        TextButton(
          onPressed: onViewAll,
          child: const Text('View All'),
        ),
      ],
    );
  }
}

class _RecentActivityList extends StatelessWidget {
  final BoxConstraints constraints;

  const _RecentActivityList({required this.constraints});

  @override
  Widget build(BuildContext context) {
    final List<_ActivityItemData> items = const <_ActivityItemData>[
      _ActivityItemData(
        icon: Icons.receipt_outlined,
        iconBg: Color(0xFFEFF4FF),
        iconColor: Color(0xFF3E63F4),
        title: 'New invoice #INV-245 created',
        subtitle: 'SAR 4,500 • 10 mins ago',
      ),
      _ActivityItemData(
        icon: Icons.person_add_outlined,
        iconBg: Color(0xFFEAFBF2),
        iconColor: Color(0xFF1E9E5C),
        title: 'New customer added',
        subtitle: 'Global Logistics Ltd • 2 hrs ago',
      ),
      _ActivityItemData(
        icon: Icons.check_circle_outline,
        iconBg: Color(0xFFFFF5E6),
        iconColor: Color(0xFFFF9800),
        title: 'Payment received',
        subtitle: 'Invoice #INV-242 • 5 hrs ago',
      ),
    ];

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE9EEF5)),
      ),
      child: Column(
        children: items.map((_ActivityItemData item) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _ActivityRow(item: item),
          );
        }).toList(),
      ),
    );
  }
}

class _ActivityItemData {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String title;
  final String subtitle;

  const _ActivityItemData({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    required this.subtitle,
  });
}

class _ActivityRow extends StatelessWidget {
  final _ActivityItemData item;

  const _ActivityRow({required this.item});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: item.iconBg,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(item.icon, color: item.iconColor, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                item.title,
                style: const TextStyle(
                  color: Color(0xFF0B1B4B),
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                item.subtitle,
                style: const TextStyle(
                  color: Color(0xFF63708A),
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CustomReportBanner extends StatelessWidget {
  final BoxConstraints constraints;

  const _CustomReportBanner({required this.constraints});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            Color(0xFF0C1E59),
            Color(0xFF2B55FF),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.bar_chart,
              color: Colors.white,
              size: 22,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Need Custom Reports?',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Generate specific insights tailored to your unique business needs.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.85),
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(999),
              child: InkWell(
                onTap: () {},
                borderRadius: BorderRadius.circular(999),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: Center(
                    child: Text(
                      'Create Custom Report',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w900,
                        fontSize: AppResponsive.clamp(
                          AppResponsive.sp(constraints, 13),
                          13,
                          15,
                        ),
                      ),
                    ),
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
