import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../controllers/auth_controller.dart';
import '../../../controllers/reports_controller.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_responsive.dart';
import '../../../app/app_routes.dart';

class SalesReportsScreen extends StatefulWidget {
  const SalesReportsScreen({super.key});

  @override
  State<SalesReportsScreen> createState() => _SalesReportsScreenState();
}

class _SalesReportsScreenState extends State<SalesReportsScreen> {
  int _rangeIndex = 1;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadSalesData();
    });
  }

  void _loadSalesData() {
    final AuthController auth = context.read<AuthController>();
    final String? companyId = auth.activeCompanyId;
    if (companyId != null && companyId.isNotEmpty) {
      context.read<ReportsController>().loadSalesOverview(companyId: companyId);
      context.read<ReportsController>().loadTopCustomers(companyId: companyId, limit: 3);
      context.read<ReportsController>().loadTopProducts(companyId: companyId, limit: 2);
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
          appBar: AppBar(
            title: const Text('Sales Reports'),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.of(context).maybePop(),
            ),
            actions: <Widget>[
              IconButton(
                onPressed: _comingSoon,
                icon: const Icon(Icons.file_download_outlined),
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
                  _MetricsGrid(constraints: constraints),
                  SizedBox(height: gap),
                  _RevenueTrendCard(
                    constraints: constraints,
                    onMore: _comingSoon,
                  ),
                  SizedBox(height: gap),
                  _InvoiceStatusCard(constraints: constraints),
                  SizedBox(height: gap),
                  _PaymentMethodsCard(constraints: constraints),
                  SizedBox(height: gap),
                  _TopCustomersCard(
                    constraints: constraints,
                    onViewAll: _comingSoon,
                  ),
                  SizedBox(height: gap),
                  _TopProductsCard(constraints: constraints),
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
      'Last 3 months',
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
              color: selected ? AppColors.primary : Colors.white,
              borderRadius: BorderRadius.circular(999),
              child: InkWell(
                onTap: () => onChanged(i),
                borderRadius: BorderRadius.circular(999),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 10,
                  ),
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
      }).toList(),
    );
  }
}

class _MetricsGrid extends StatelessWidget {
  final BoxConstraints constraints;

  const _MetricsGrid({required this.constraints});

  @override
  Widget build(BuildContext context) {
    final ({SalesOverview overview, bool isLoading}) vm =
        context.select<ReportsController, ({SalesOverview overview, bool isLoading})>(
          (ReportsController ctrl) => (
            overview: ctrl.salesOverview,
            isLoading: ctrl.isLoadingSales,
          ),
        );
    final SalesOverview overview = vm.overview;
    final bool isLoading = vm.isLoading;

    final double gap = AppResponsive.clamp(
      AppResponsive.vw(constraints, 3.5),
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
              child: _MetricCard(
                constraints: constraints,
                icon: Icons.payments_outlined,
                iconBg: const Color(0xFFEFF4FF),
                iconColor: AppColors.primary,
                title: 'Total Revenue',
                value: overview.totalRevenue.formatted,
                deltaText: overview.totalRevenue.changeFormatted,
                deltaUp: overview.totalRevenue.isIncrease,
              ),
            ),
            SizedBox(width: gap),
            Expanded(
              child: _MetricCard(
                constraints: constraints,
                icon: Icons.receipt_long_outlined,
                iconBg: const Color(0xFFEFF4FF),
                iconColor: AppColors.primary,
                title: 'Total Invoices',
                value: overview.totalInvoices.formatted,
                deltaText: overview.totalInvoices.changeFormatted,
                deltaUp: overview.totalInvoices.isIncrease,
              ),
            ),
          ],
        ),
        SizedBox(height: gap),
        Row(
          children: <Widget>[
            Expanded(
              child: _MetricCard(
                constraints: constraints,
                icon: Icons.group_outlined,
                iconBg: const Color(0xFFF3F0FF),
                iconColor: const Color(0xFF6D4CFF),
                title: 'Active Customers',
                value: overview.activeCustomers.formatted,
                deltaText: overview.activeCustomers.changeFormatted,
                deltaUp: overview.activeCustomers.isIncrease,
              ),
            ),
            SizedBox(width: gap),
            Expanded(
              child: _MetricCard(
                constraints: constraints,
                icon: Icons.insights_outlined,
                iconBg: const Color(0xFFFFF3E8),
                iconColor: const Color(0xFFFB8C00),
                title: 'Avg. Invoice',
                value: overview.averageInvoice.formatted,
                deltaText: overview.averageInvoice.changeFormatted,
                deltaUp: overview.averageInvoice.isIncrease,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _RevenueTrendCard extends StatelessWidget {
  final BoxConstraints constraints;
  final VoidCallback onMore;

  const _RevenueTrendCard({
    required this.constraints,
    required this.onMore,
  });

  @override
  Widget build(BuildContext context) {
    final double titleSize = AppResponsive.clamp(
      AppResponsive.sp(constraints, 15.5),
      14,
      17,
    );

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
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
              Expanded(
                child: Text(
                  'Revenue Trend',
                  style: TextStyle(
                    color: const Color(0xFF0B1B4B),
                    fontWeight: FontWeight.w900,
                    fontSize: titleSize,
                  ),
                ),
              ),
              IconButton(
                onPressed: onMore,
                icon: const Icon(Icons.more_horiz),
                color: const Color(0xFF6B7895),
              ),
            ],
          ),
          const SizedBox(height: 6),
          SizedBox(
            height: AppResponsive.clamp(
              AppResponsive.scaledByHeight(constraints, 180),
              160,
              220,
            ),
            child: Column(
              children: <Widget>[
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF7FAFF),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: <Widget>[
                        _Bar(heightFactor: 0.22),
                        const SizedBox(width: 10),
                        _Bar(heightFactor: 0.35),
                        const SizedBox(width: 10),
                        _Bar(heightFactor: 0.28),
                        const SizedBox(width: 10),
                        _Bar(heightFactor: 0.40),
                        const SizedBox(width: 10),
                        _Bar(heightFactor: 0.55),
                        const SizedBox(width: 10),
                        _Bar(heightFactor: 0.70, highlight: true),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const <Widget>[
                    _AxisLabel('May'),
                    _AxisLabel('Jun'),
                    _AxisLabel('Jul'),
                    _AxisLabel('Aug'),
                    _AxisLabel('Sep'),
                    _AxisLabel('Oct'),
                    _AxisLabel('Nov'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  final double heightFactor;
  final bool highlight;

  const _Bar({required this.heightFactor, this.highlight = false});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: FractionallySizedBox(
        heightFactor: heightFactor,
        alignment: Alignment.bottomCenter,
        child: Container(
          decoration: BoxDecoration(
            color: highlight ? AppColors.primary : const Color(0xFFBFD1FF),
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }
}

class _AxisLabel extends StatelessWidget {
  final String text;

  const _AxisLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: Color(0xFF9AA5B6),
        fontWeight: FontWeight.w800,
        fontSize: 11,
      ),
    );
  }
}

class _InvoiceStatusCard extends StatelessWidget {
  final BoxConstraints constraints;

  const _InvoiceStatusCard({required this.constraints});

  @override
  Widget build(BuildContext context) {
    final double titleSize = AppResponsive.clamp(
      AppResponsive.sp(constraints, 15.5),
      14,
      17,
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
            'Invoice Status',
            style: TextStyle(
              color: const Color(0xFF0B1B4B),
              fontWeight: FontWeight.w900,
              fontSize: titleSize,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: <Widget>[
              SizedBox(
                width: AppResponsive.clamp(
                  AppResponsive.vw(constraints, 28),
                  110,
                  140,
                ),
                height: AppResponsive.clamp(
                  AppResponsive.vw(constraints, 28),
                  110,
                  140,
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: <Widget>[
                    SizedBox(
                      width: double.infinity,
                      height: double.infinity,
                      child: CircularProgressIndicator(
                        value: 0.68,
                        strokeWidth: 10,
                        backgroundColor: const Color(0xFFE9EEF5),
                        color: AppColors.primary,
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: const <Widget>[
                        Text(
                          'Paid',
                          style: TextStyle(
                            color: Color(0xFF6B7895),
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          '68%',
                          style: TextStyle(
                            color: Color(0xFF0B1B4B),
                            fontWeight: FontWeight.w900,
                            fontSize: 20,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  children: <Widget>[
                    _LegendRow(
                      color: AppColors.primary,
                      label: 'Paid',
                      value: '68%',
                    ),
                    SizedBox(height: 10),
                    _LegendRow(
                      color: Color(0xFFFFB300),
                      label: 'Pending',
                      value: '19%',
                    ),
                    SizedBox(height: 10),
                    _LegendRow(
                      color: Color(0xFFD93025),
                      label: 'Overdue',
                      value: '8%',
                    ),
                    SizedBox(height: 10),
                    _LegendRow(
                      color: Color(0xFF9AA5B6),
                      label: 'Draft',
                      value: '5%',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LegendRow extends StatelessWidget {
  final Color color;
  final String label;
  final String value;

  const _LegendRow({
    required this.color,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: Color(0xFF0B1B4B),
              fontWeight: FontWeight.w800,
              fontSize: 13,
            ),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Color(0xFF6B7895),
            fontWeight: FontWeight.w900,
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}

class _PaymentMethodsCard extends StatelessWidget {
  final BoxConstraints constraints;

  const _PaymentMethodsCard({required this.constraints});

  @override
  Widget build(BuildContext context) {
    final double titleSize = AppResponsive.clamp(
      AppResponsive.sp(constraints, 15.5),
      14,
      17,
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
            'Payment Methods',
            style: TextStyle(
              color: const Color(0xFF0B1B4B),
              fontWeight: FontWeight.w900,
              fontSize: titleSize,
            ),
          ),
          const SizedBox(height: 12),
          const _PayRow(
            label: 'Bank Transfer',
            value: 'SAR 542k',
            factor: 0.84,
            color: AppColors.primary,
          ),
          const SizedBox(height: 12),
          const _PayRow(
            label: 'Credit Card',
            value: 'SAR 210k',
            factor: 0.50,
            color: Color(0xFF6D4CFF),
          ),
          const SizedBox(height: 12),
          const _PayRow(
            label: 'Cash',
            value: 'SAR 89k',
            factor: 0.22,
            color: Color(0xFF1DB954),
          ),
        ],
      ),
    );
  }
}

class _PayRow extends StatelessWidget {
  final String label;
  final String value;
  final double factor;
  final Color color;

  const _PayRow({
    required this.label,
    required this.value,
    required this.factor,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  color: Color(0xFF0B1B4B),
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                color: Color(0xFF0B1B4B),
                fontWeight: FontWeight.w900,
                fontSize: 13,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: SizedBox(
            height: 6,
            child: LinearProgressIndicator(
              value: factor,
              backgroundColor: const Color(0xFFE9EEF5),
              color: color,
            ),
          ),
        ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  final BoxConstraints constraints;
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String title;
  final String value;
  final String deltaText;
  final bool deltaUp;

  const _MetricCard({
    required this.constraints,
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    required this.value,
    required this.deltaText,
    required this.deltaUp,
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
    final Color deltaColor =
        deltaUp ? const Color(0xFF1DB954) : const Color(0xFFD93025);

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
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: const Color(0xFF6B7895),
                    fontWeight: FontWeight.w800,
                    fontSize: titleSize,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
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
                deltaUp
                    ? Icons.arrow_upward_rounded
                    : Icons.arrow_downward_rounded,
                size: 14,
                color: deltaColor,
              ),
              const SizedBox(width: 4),
              Text(
                deltaText,
                style: TextStyle(
                  color: deltaColor,
                  fontWeight: FontWeight.w900,
                  fontSize: titleSize,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RankTile extends StatelessWidget {
  final String rank;
  final String name;
  final String meta;
  final String amount;
  final String deltaText;
  final bool deltaUp;

  const _RankTile({
    required this.rank,
    required this.name,
    required this.meta,
    required this.amount,
    required this.deltaText,
    required this.deltaUp,
  });

  @override
  Widget build(BuildContext context) {
    final Color deltaColor =
        deltaUp ? const Color(0xFF1DB954) : const Color(0xFFD93025);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF7FAFF),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 30,
            height: 30,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFFEFF4FF),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              rank,
              style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w900,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: 10),
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
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  meta,
                  style: const TextStyle(
                    color: Color(0xFF6B7895),
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              Text(
                amount,
                style: const TextStyle(
                  color: Color(0xFF0B1B4B),
                  fontWeight: FontWeight.w900,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                deltaText,
                style: TextStyle(
                  color: deltaColor,
                  fontWeight: FontWeight.w800,
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

class _TopCustomersCard extends StatelessWidget {
  final BoxConstraints constraints;
  final VoidCallback onViewAll;

  const _TopCustomersCard({
    required this.constraints,
    required this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    final ({List<TopCustomer> customers, bool isLoading}) vm =
        context.select<ReportsController,
            ({List<TopCustomer> customers, bool isLoading})>(
          (ReportsController ctrl) => (
            customers: ctrl.topCustomers,
            isLoading: ctrl.isLoadingCustomers,
          ),
        );
    final List<TopCustomer> customers = vm.customers;
    final bool isLoading = vm.isLoading;

    final double titleSize = AppResponsive.clamp(
      AppResponsive.sp(constraints, 15.5),
      14,
      17,
    );

    if (isLoading) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE9EEF5)),
        ),
        child: const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }

    if (customers.isEmpty) {
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
              'Top Customers',
              style: TextStyle(
                color: const Color(0xFF0B1B4B),
                fontWeight: FontWeight.w900,
                fontSize: titleSize,
              ),
            ),
            const SizedBox(height: 24),
            const Center(
              child: Text(
                'No customer data available',
                style: TextStyle(
                  color: Color(0xFF6B7895),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      );
    }

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
            'Top Customers',
            style: TextStyle(
              color: const Color(0xFF0B1B4B),
              fontWeight: FontWeight.w900,
              fontSize: titleSize,
            ),
          ),
          const SizedBox(height: 12),
          ...customers.asMap().entries.map((MapEntry<int, TopCustomer> entry) {
            final int index = entry.key;
            final TopCustomer customer = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _RankTile(
                rank: '${index + 1}',
                name: customer.name,
                meta: '${customer.invoiceCount} invoices',
                amount: 'SAR ${(customer.totalRevenue / 1000).toStringAsFixed(0)}k',
                deltaText: '+${(customer.totalRevenue / 10000).toStringAsFixed(1)}%',
                deltaUp: true,
              ),
            );
          }),
          const SizedBox(height: 8),
          Center(
            child: TextButton(
              onPressed: onViewAll,
              child: const Text('View All Customers'),
            ),
          ),
        ],
      ),
    );
  }
}

class _TopProductsCard extends StatelessWidget {
  final BoxConstraints constraints;

  const _TopProductsCard({required this.constraints});

  @override
  Widget build(BuildContext context) {
    final ({List<TopProduct> products, bool isLoading}) vm =
        context.select<ReportsController,
            ({List<TopProduct> products, bool isLoading})>(
          (ReportsController ctrl) => (
            products: ctrl.topProducts,
            isLoading: ctrl.isLoadingProducts,
          ),
        );
    final List<TopProduct> products = vm.products;
    final bool isLoading = vm.isLoading;

    final double titleSize = AppResponsive.clamp(
      AppResponsive.sp(constraints, 15.5),
      14,
      17,
    );

    if (isLoading) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE9EEF5)),
        ),
        child: const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }

    if (products.isEmpty) {
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
              'Top Products',
              style: TextStyle(
                color: const Color(0xFF0B1B4B),
                fontWeight: FontWeight.w900,
                fontSize: titleSize,
              ),
            ),
            const SizedBox(height: 24),
            const Center(
              child: Text(
                'No product data available',
                style: TextStyle(
                  color: Color(0xFF6B7895),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      );
    }

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
            'Top Products',
            style: TextStyle(
              color: const Color(0xFF0B1B4B),
              fontWeight: FontWeight.w900,
              fontSize: titleSize,
            ),
          ),
          const SizedBox(height: 12),
          ...products.map((TopProduct product) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _ProductTile(
                iconBg: const Color(0xFFEFF4FF),
                iconColor: AppColors.primary,
                icon: Icons.inventory_2_outlined,
                name: product.name,
                meta: '${product.quantitySold} sales',
                amount: 'SAR ${(product.totalRevenue / 1000).toStringAsFixed(0)}k',
              ),
            );
          }),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _ProductTile extends StatelessWidget {
  final Color iconBg;
  final Color iconColor;
  final IconData icon;
  final String name;
  final String meta;
  final String amount;

  const _ProductTile({
    required this.iconBg,
    required this.iconColor,
    required this.icon,
    required this.name,
    required this.meta,
    required this.amount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF7FAFF),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(width: 10),
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
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  meta,
                  style: const TextStyle(
                    color: Color(0xFF6B7895),
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
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
