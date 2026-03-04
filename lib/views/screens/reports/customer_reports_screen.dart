import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../controllers/auth_controller.dart';
import '../../../controllers/reports_controller.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_responsive.dart';
import '../../../app/app_routes.dart';

class CustomerReportsScreen extends StatefulWidget {
  const CustomerReportsScreen({super.key});

  @override
  State<CustomerReportsScreen> createState() => _CustomerReportsScreenState();
}

class _CustomerReportsScreenState extends State<CustomerReportsScreen> {
  int _rangeIndex = 1;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCustomerData();
    });
  }

  void _loadCustomerData() {
    final AuthController auth = context.read<AuthController>();
    final String? companyId = auth.activeCompanyId;
    if (companyId != null && companyId.isNotEmpty) {
      context.read<ReportsController>().loadTopCustomers(companyId: companyId, limit: 5);
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
            title: const Text('Customer Reports'),
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
                  _SegmentationCard(
                    constraints: constraints,
                    onViewAll: _comingSoon,
                  ),
                  SizedBox(height: gap),
                  _CustomerGrowthCard(constraints: constraints),
                  SizedBox(height: gap),
                  _LifecycleCard(constraints: constraints),
                  SizedBox(height: gap),
                  _EngagementCard(constraints: constraints),
                  SizedBox(height: gap),
                  _TopCustomersCard(
                    constraints: constraints,
                    onSeeAll: _comingSoon,
                  ),
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
      }),
    );
  }
}

class _MetricsGrid extends StatelessWidget {
  final BoxConstraints constraints;

  const _MetricsGrid({required this.constraints});

  @override
  Widget build(BuildContext context) {
    final double gap = AppResponsive.clamp(
      AppResponsive.vw(constraints, 3.5),
      12,
      16,
    );

    return Column(
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: _MetricCard(
                constraints: constraints,
                icon: Icons.groups_outlined,
                iconBg: const Color(0xFFEFF4FF),
                iconColor: AppColors.primary,
                title: 'Total Customers',
                value: '342',
                deltaText: '+12.1 %',
                deltaUp: true,
              ),
            ),
            SizedBox(width: gap),
            Expanded(
              child: _MetricCard(
                constraints: constraints,
                icon: Icons.person_add_alt_1_outlined,
                iconBg: const Color(0xFFEFF4FF),
                iconColor: AppColors.primary,
                title: 'New This Month',
                value: '45',
                deltaText: '+8.4 %',
                deltaUp: true,
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
                icon: Icons.payments_outlined,
                iconBg: const Color(0xFFEFF4FF),
                iconColor: AppColors.primary,
                title: 'Avg. Customer Value',
                value: 'SAR 3,642',
                deltaText: '+5.3 %',
                deltaUp: true,
              ),
            ),
            SizedBox(width: gap),
            Expanded(
              child: _MetricCard(
                constraints: constraints,
                icon: Icons.refresh,
                iconBg: const Color(0xFFFFF3E8),
                iconColor: const Color(0xFFFB8C00),
                title: 'Retention Rate',
                value: '87%',
                deltaText: '-2.1 %',
                deltaUp: false,
              ),
            ),
          ],
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
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x0A0B1B4B),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
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

class _SegmentationCard extends StatelessWidget {
  final BoxConstraints constraints;
  final VoidCallback onViewAll;

  const _SegmentationCard({
    required this.constraints,
    required this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    final double titleSize = AppResponsive.clamp(
      AppResponsive.sp(constraints, 15.5),
      14,
      17,
    );

    final List<_Segment> segments = const <_Segment>[
      _Segment(label: 'VIP', percent: 0.18, amount: 'SAR 120k', color: Color(0xFF0B1B4B)),
      _Segment(label: 'Regular', percent: 0.42, amount: 'SAR 85k', color: AppColors.primary),
      _Segment(label: 'Occasional', percent: 0.30, amount: 'SAR 45k', color: Color(0xFF4DA3FF)),
      _Segment(label: 'New', percent: 0.10, amount: 'SAR 12k', color: Color(0xFF9AA5B6)),
    ];

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
              Expanded(
                child: Text(
                  'Customer Segmentation',
                  style: TextStyle(
                    color: const Color(0xFF0B1B4B),
                    fontWeight: FontWeight.w900,
                    fontSize: titleSize,
                  ),
                ),
              ),
              TextButton(
                onPressed: onViewAll,
                child: const Text('View All'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: <Widget>[
              _Donut(
                size: AppResponsive.clamp(
                  AppResponsive.vw(constraints, 32),
                  120,
                  150,
                ),
                totalLabel: 'Total',
                totalValue: '342',
                segments: segments,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  children: segments
                      .map((_Segment segment) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _SegmentRow(segment: segment),
                          ))
                      .toList(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Segment {
  final String label;
  final double percent;
  final String amount;
  final Color color;

  const _Segment({
    required this.label,
    required this.percent,
    required this.amount,
    required this.color,
  });
}

class _SegmentRow extends StatelessWidget {
  final _Segment segment;

  const _SegmentRow({required this.segment});

  @override
  Widget build(BuildContext context) {
    final String pct = '${(segment.percent * 100).round()}%';

    return Row(
      children: <Widget>[
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: segment.color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            '${segment.label} ($pct)',
            style: const TextStyle(
              color: Color(0xFF0B1B4B),
              fontWeight: FontWeight.w800,
              fontSize: 13,
            ),
          ),
        ),
        Text(
          segment.amount,
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

class _Donut extends StatelessWidget {
  final double size;
  final String totalLabel;
  final String totalValue;
  final List<_Segment> segments;

  const _Donut({
    required this.size,
    required this.totalLabel,
    required this.totalValue,
    required this.segments,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          CustomPaint(
            size: Size(size, size),
            painter: _DonutPainter(segments),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                totalLabel,
                style: const TextStyle(
                  color: Color(0xFF6B7895),
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                totalValue,
                style: const TextStyle(
                  color: Color(0xFF0B1B4B),
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  final List<_Segment> segments;

  _DonutPainter(this.segments);

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = Offset(size.width / 2, size.height / 2);
    final double radius = size.width / 2;
    final Rect rect = Rect.fromCircle(center: center, radius: radius);

    final Paint bg = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xFFE9EEF5);

    canvas.drawArc(rect.deflate(7), 0, math.pi * 2, false, bg);

    double start = -math.pi / 2;
    for (final _Segment s in segments) {
      final Paint p = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 14
        ..strokeCap = StrokeCap.round
        ..color = s.color;
      final double sweep = math.pi * 2 * s.percent;
      canvas.drawArc(rect.deflate(7), start, sweep, false, p);
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter oldDelegate) {
    return oldDelegate.segments != segments;
  }
}

class _CustomerGrowthCard extends StatelessWidget {
  final BoxConstraints constraints;

  const _CustomerGrowthCard({required this.constraints});

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
                  'Customer Growth',
                  style: TextStyle(
                    color: const Color(0xFF0B1B4B),
                    fontWeight: FontWeight.w900,
                    fontSize: titleSize,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                decoration: BoxDecoration(
                  color: const Color(0xFFF7FAFF),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Text(
                  'Jan - Jun',
                  style: TextStyle(
                    color: Color(0xFF6B7895),
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: AppResponsive.clamp(
              AppResponsive.scaledByHeight(constraints, 160),
              140,
              200,
            ),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF7FAFF),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const _GrowthPlaceholder(),
            ),
          ),
        ],
      ),
    );
  }
}

class _GrowthPlaceholder extends StatelessWidget {
  const _GrowthPlaceholder();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _GrowthPainter(),
      child: const SizedBox.expand(),
    );
  }
}

class _GrowthPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Paint grid = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = const Color(0xFFE9EEF5);

    for (int i = 1; i < 4; i++) {
      final double y = size.height * (i / 4);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }

    final List<Offset> pts = <Offset>[
      Offset(size.width * 0.08, size.height * 0.72),
      Offset(size.width * 0.25, size.height * 0.62),
      Offset(size.width * 0.42, size.height * 0.64),
      Offset(size.width * 0.60, size.height * 0.48),
      Offset(size.width * 0.78, size.height * 0.40),
      Offset(size.width * 0.92, size.height * 0.34),
    ];

    final Path line = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (int i = 1; i < pts.length; i++) {
      line.lineTo(pts[i].dx, pts[i].dy);
    }

    final Path area = Path.from(line)
      ..lineTo(pts.last.dx, size.height)
      ..lineTo(pts.first.dx, size.height)
      ..close();

    final Paint fill = Paint()
      ..style = PaintingStyle.fill
      ..color = AppColors.primary.withValues(alpha: 0.12);

    canvas.drawPath(area, fill);

    final Paint stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = AppColors.primary;

    canvas.drawPath(line, stroke);

    final Paint dot = Paint()..color = AppColors.primary;
    for (final Offset p in pts) {
      canvas.drawCircle(p, 3.5, dot);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}

class _LifecycleCard extends StatelessWidget {
  final BoxConstraints constraints;

  const _LifecycleCard({required this.constraints});

  @override
  Widget build(BuildContext context) {
    final double titleSize = AppResponsive.clamp(
      AppResponsive.sp(constraints, 15.5),
      14,
      17,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'Customer Lifecycle',
          style: TextStyle(
            color: const Color(0xFF0B1B4B),
            fontWeight: FontWeight.w900,
            fontSize: titleSize,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: const <Widget>[
            Expanded(
              child: _LifecycleTile(
                dotColor: Color(0xFF4DA3FF),
                label: 'New',
                value: '67',
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: _LifecycleTile(
                dotColor: Color(0xFF1DB954),
                label: 'Active',
                value: '247',
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: _LifecycleTile(
                dotColor: Color(0xFFFB8C00),
                label: 'At Risk',
                value: '18',
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _LifecycleTile extends StatelessWidget {
  final Color dotColor;
  final String label;
  final String value;

  const _LifecycleTile({
    required this.dotColor,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE9EEF5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF6B7895),
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFF0B1B4B),
              fontWeight: FontWeight.w900,
              fontSize: 18,
            ),
          ),
        ],
      ),
    );
  }
}

class _EngagementCard extends StatelessWidget {
  final BoxConstraints constraints;

  const _EngagementCard({required this.constraints});

  @override
  Widget build(BuildContext context) {
    final double titleSize = AppResponsive.clamp(
      AppResponsive.sp(constraints, 14.5),
      13,
      16,
    );

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.splashBottom,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Engagement Metrics',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: titleSize,
            ),
          ),
          const SizedBox(height: 12),
          const Row(
            children: <Widget>[
              Expanded(
                child: _EngagementStat(
                  label: 'AVG ORDER',
                  value: 'SAR 450',
                ),
              ),
              Expanded(
                child: _EngagementStat(
                  label: 'FREQ',
                  value: '2.4/mo',
                ),
              ),
              Expanded(
                child: _EngagementStat(
                  label: 'LIFETIME',
                  value: '14 mo',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EngagementStat extends StatelessWidget {
  final String label;
  final String value;

  const _EngagementStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        Text(
          label,
          style: const TextStyle(
            color: Color(0xB3FFFFFF),
            fontWeight: FontWeight.w800,
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}

class _TopCustomersCard extends StatelessWidget {
  final BoxConstraints constraints;
  final VoidCallback onSeeAll;

  const _TopCustomersCard({
    required this.constraints,
    required this.onSeeAll,
  });

  @override
  Widget build(BuildContext context) {
    final ReportsController ctrl = context.watch<ReportsController>();
    final List<TopCustomer> customers = ctrl.topCustomers;
    final bool isLoading = ctrl.isLoadingCustomers;

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
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  'Top Customers',
                  style: TextStyle(
                    color: const Color(0xFF0B1B4B),
                    fontWeight: FontWeight.w900,
                    fontSize: titleSize,
                  ),
                ),
              ),
              TextButton(
                onPressed: onSeeAll,
                child: const Text('See All'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...customers.map((TopCustomer customer) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _CustomerRow(
                data: _CustomerRowData(
                  name: customer.name,
                  meta: '${customer.invoiceCount} invoices',
                  amount: 'SAR ${(customer.totalRevenue / 1000).toStringAsFixed(0)}k',
                  tag: 'Active',
                  tagBg: const Color(0xFFE8F8EE),
                  tagColor: const Color(0xFF1DB954),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _CustomerRowData {
  final String name;
  final String meta;
  final String amount;
  final String tag;
  final Color tagBg;
  final Color tagColor;

  const _CustomerRowData({
    required this.name,
    required this.meta,
    required this.amount,
    required this.tag,
    required this.tagBg,
    required this.tagColor,
  });
}

class _CustomerRow extends StatelessWidget {
  final _CustomerRowData data;

  const _CustomerRow({required this.data});

  String _initials(String name) {
    final List<String> parts = name
        .split(RegExp(r'\s+'))
        .where((String s) => s.trim().isNotEmpty)
        .toList();
    if (parts.isEmpty) return 'C';
    final String a = parts.first.characters.first;
    final String b = parts.length > 1 ? parts[1].characters.first : '';
    return (a + b).toUpperCase();
  }

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
          CircleAvatar(
            radius: 18,
            backgroundColor: const Color(0xFFEFF4FF),
            child: Text(
              _initials(data.name),
              style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w900,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  data.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF0B1B4B),
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  children: <Widget>[
                    Text(
                      data.meta,
                      style: const TextStyle(
                        color: Color(0xFF6B7895),
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: data.tagBg,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        data.tag,
                        style: TextStyle(
                          color: data.tagColor,
                          fontWeight: FontWeight.w900,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              Text(
                data.amount,
                style: const TextStyle(
                  color: Color(0xFF0B1B4B),
                  fontWeight: FontWeight.w900,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 2),
              const Text(
                'Total Spent',
                style: TextStyle(
                  color: Color(0xFF6B7895),
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
