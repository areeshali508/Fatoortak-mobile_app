import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../controllers/auth_controller.dart';
import '../../../controllers/reports_controller.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_responsive.dart';
import '../../../app/app_routes.dart';

class ProductReportsScreen extends StatefulWidget {
  const ProductReportsScreen({super.key});

  @override
  State<ProductReportsScreen> createState() => _ProductReportsScreenState();
}

class _ProductReportsScreenState extends State<ProductReportsScreen> {
  int _rangeIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadProductData();
    });
  }

  void _loadProductData() {
    final AuthController auth = context.read<AuthController>();
    final String? companyId = auth.activeCompanyId;
    if (companyId != null && companyId.isNotEmpty) {
      context.read<ReportsController>().loadTopProducts(companyId: companyId, limit: 5);
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
            title: const Text('Product Reports'),
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
                  _InventoryAlertsCard(constraints: constraints),
                  SizedBox(height: gap),
                  _SalesTrendCard(
                    constraints: constraints,
                    onMore: _comingSoon,
                  ),
                  SizedBox(height: gap),
                  _CategorySplitCard(constraints: constraints),
                  SizedBox(height: gap),
                  _HighlightsSection(constraints: constraints),
                  SizedBox(height: gap),
                  _TopProductsCard(
                    constraints: constraints,
                    onViewAll: _comingSoon,
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
      'Last 7d',
      '30d',
      '3m',
      '6m',
      '12m',
    ];

    final double fontSize = AppResponsive.clamp(
      AppResponsive.sp(constraints, 11.5),
      11,
      13,
    );

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List<Widget>.generate(labels.length, (int i) {
          final bool selected = i == index;
          return Padding(
            padding: EdgeInsets.only(right: i == labels.length - 1 ? 0 : 10),
            child: Material(
              color: selected ? const Color(0xFF0C1E59) : Colors.white,
              borderRadius: BorderRadius.circular(999),
              child: InkWell(
                onTap: () => onChanged(i),
                borderRadius: BorderRadius.circular(999),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  child: Text(
                    labels[i],
                    style: TextStyle(
                      color: selected ? Colors.white : const Color(0xFF0B1B4B),
                      fontWeight: FontWeight.w800,
                      fontSize: fontSize,
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _MetricsGrid extends StatelessWidget {
  final BoxConstraints constraints;

  const _MetricsGrid({required this.constraints});

  @override
  Widget build(BuildContext context) {
    final double gap = AppResponsive.clamp(
      AppResponsive.vw(constraints, 3.2),
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
                icon: Icons.inventory_2_outlined,
                title: 'Products',
                value: '156',
                delta: '+ 8 new',
                deltaColor: const Color(0xFF1E9E5C),
              ),
            ),
            SizedBox(width: gap),
            Expanded(
              child: _MetricCard(
                constraints: constraints,
                icon: Icons.payments_outlined,
                title: 'Revenue',
                value: '628k',
                delta: '+ 12.4%',
                deltaColor: const Color(0xFF1E9E5C),
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
                icon: Icons.shopping_bag_outlined,
                title: 'Sold',
                value: '2,456',
                delta: '+ 6.3%',
                deltaColor: const Color(0xFF1E9E5C),
              ),
            ),
            SizedBox(width: gap),
            Expanded(
              child: _MetricCard(
                constraints: constraints,
                icon: Icons.sell_outlined,
                title: 'Avg. Price',
                value: '256',
                delta: '- 3.2%',
                deltaColor: const Color(0xFFD93025),
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
  final String title;
  final String value;
  final String delta;
  final Color deltaColor;

  const _MetricCard({
    required this.constraints,
    required this.icon,
    required this.title,
    required this.value,
    required this.delta,
    required this.deltaColor,
  });

  @override
  Widget build(BuildContext context) {
    final double titleSize = AppResponsive.clamp(
      AppResponsive.sp(constraints, 12.5),
      12,
      14,
    );

    final double valueSize = AppResponsive.clamp(
      AppResponsive.sp(constraints, 20),
      18,
      22,
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
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: const Color(0xFFF3F6FF),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.primary, size: 18),
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: TextStyle(
              color: const Color(0xFF63708A),
              fontWeight: FontWeight.w800,
              fontSize: titleSize,
            ),
          ),
          const SizedBox(height: 6),
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
                delta.trimLeft().startsWith('-')
                    ? Icons.trending_down
                    : Icons.trending_up,
                size: 16,
                color: deltaColor,
              ),
              const SizedBox(width: 6),
              Text(
                delta,
                style: TextStyle(
                  color: deltaColor,
                  fontWeight: FontWeight.w900,
                  fontSize: AppResponsive.clamp(
                    AppResponsive.sp(constraints, 11.5),
                    11,
                    13,
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

class _InventoryAlertsCard extends StatelessWidget {
  final BoxConstraints constraints;

  const _InventoryAlertsCard({required this.constraints});

  @override
  Widget build(BuildContext context) {
    final double titleSize = AppResponsive.clamp(
      AppResponsive.sp(constraints, 14),
      13,
      16,
    );

    final List<_AlertRowData> alerts = const <_AlertRowData>[
      _AlertRowData(
        name: 'iPhone 14 Pro Max',
        sku: 'SKU: IP-14PM-256',
        status: 'CRITICAL',
        statusBg: Color(0xFFFFECEC),
        statusColor: Color(0xFFD93025),
        qtyLabel: '2 left',
      ),
      _AlertRowData(
        name: 'AirPods Max',
        sku: 'SKU: AP-MAX-SLV',
        status: 'LOW',
        statusBg: Color(0xFFFFF3E0),
        statusColor: Color(0xFFEF6C00),
        qtyLabel: '5 left',
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  'Inventory Alerts',
                  style: TextStyle(
                    color: const Color(0xFF0B1B4B),
                    fontWeight: FontWeight.w900,
                    fontSize: titleSize,
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFE8EA),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Text(
                  '4 Attention',
                  style: TextStyle(
                    color: Color(0xFFD93025),
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...alerts.map((_AlertRowData a) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _AlertRow(data: a),
            );
          }),
        ],
      ),
    );
  }
}

class _AlertRowData {
  final String name;
  final String sku;
  final String status;
  final Color statusBg;
  final Color statusColor;
  final String qtyLabel;

  const _AlertRowData({
    required this.name,
    required this.sku,
    required this.status,
    required this.statusBg,
    required this.statusColor,
    required this.qtyLabel,
  });
}

class _AlertRow extends StatelessWidget {
  final _AlertRowData data;

  const _AlertRow({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF7FAFF),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFFEFF2F7),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.inventory_2_outlined,
                color: Color(0xFF63708A), size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  data.name,
                  style: const TextStyle(
                    color: Color(0xFF0B1B4B),
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  data.sku,
                  style: const TextStyle(
                    color: Color(0xFF63708A),
                    fontWeight: FontWeight.w700,
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
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: data.statusBg,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  data.status,
                  style: TextStyle(
                    color: data.statusColor,
                    fontWeight: FontWeight.w900,
                    fontSize: 11,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                data.qtyLabel,
                style: const TextStyle(
                  color: Color(0xFF63708A),
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SalesTrendCard extends StatelessWidget {
  final BoxConstraints constraints;
  final VoidCallback onMore;

  const _SalesTrendCard({
    required this.constraints,
    required this.onMore,
  });

  @override
  Widget build(BuildContext context) {
    final double titleSize = AppResponsive.clamp(
      AppResponsive.sp(constraints, 14),
      13,
      16,
    );

    final double chartHeight = AppResponsive.clamp(
      AppResponsive.scaledByHeight(constraints, 170),
      140,
      190,
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
          Row(
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Sales Trend',
                      style: TextStyle(
                        color: const Color(0xFF0B1B4B),
                        fontWeight: FontWeight.w900,
                        fontSize: titleSize,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Jan - Jun 2024',
                      style: TextStyle(
                        color: Color(0xFF63708A),
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: onMore,
                icon: const Icon(Icons.more_horiz),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: chartHeight,
            child: const _SalesTrendChart(),
          ),
          const SizedBox(height: 4),
          const _XAxisLabels(),
        ],
      ),
    );
  }
}

class _XAxisLabels extends StatelessWidget {
  const _XAxisLabels();

  @override
  Widget build(BuildContext context) {
    const List<String> labels = <String>['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun'];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: labels
          .map(
            (String s) => Text(
              s,
              style: const TextStyle(
                color: Color(0xFF9AA6BC),
                fontWeight: FontWeight.w700,
                fontSize: 11,
              ),
            ),
          )
          .toList(),
    );
  }
}

class _SalesTrendChart extends StatelessWidget {
  const _SalesTrendChart();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _SalesTrendPainter(),
      child: const SizedBox.expand(),
    );
  }
}

class _SalesTrendPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Paint grid = Paint()
      ..color = const Color(0xFFEFF3FA)
      ..strokeWidth = 1;

    for (int i = 1; i <= 3; i++) {
      final double y = size.height * (i / 4);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }

    final List<Offset> points = <Offset>[
      Offset(0, size.height * 0.78),
      Offset(size.width * 0.18, size.height * 0.64),
      Offset(size.width * 0.36, size.height * 0.48),
      Offset(size.width * 0.56, size.height * 0.36),
      Offset(size.width * 0.76, size.height * 0.30),
      Offset(size.width, size.height * 0.28),
    ];

    final Path line = Path()..moveTo(points.first.dx, points.first.dy);
    for (int i = 1; i < points.length; i++) {
      final Offset p0 = points[i - 1];
      final Offset p1 = points[i];
      final double cx = (p0.dx + p1.dx) / 2;
      line.cubicTo(cx, p0.dy, cx, p1.dy, p1.dx, p1.dy);
    }

    final Path fill = Path.from(line)
      ..lineTo(points.last.dx, size.height)
      ..lineTo(0, size.height)
      ..close();

    final Rect rect = Offset.zero & size;
    final Paint fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: <Color>[
          const Color(0xFF0C1E59).withValues(alpha: 0.14),
          const Color(0xFF0C1E59).withValues(alpha: 0.02),
        ],
      ).createShader(rect);
    canvas.drawPath(fill, fillPaint);

    final Paint stroke = Paint()
      ..color = const Color(0xFF0C1E59)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(line, stroke);

    final Paint dot = Paint()..color = const Color(0xFF0C1E59);
    final Paint dotBorder = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    for (int i = 0; i < points.length; i++) {
      if (i == 2 || i == 4) {
        canvas.drawCircle(points[i], 6, dot);
        canvas.drawCircle(points[i], 6, dotBorder);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _CategorySplitCard extends StatelessWidget {
  final BoxConstraints constraints;

  const _CategorySplitCard({required this.constraints});

  @override
  Widget build(BuildContext context) {
    final double titleSize = AppResponsive.clamp(
      AppResponsive.sp(constraints, 14),
      13,
      16,
    );

    final List<_CategorySlice> slices = const <_CategorySlice>[
      _CategorySlice(label: 'Services', pct: 0.45, color: Color(0xFF0C1E59)),
      _CategorySlice(label: 'Products', pct: 0.35, color: Color(0xFF27C5D8)),
      _CategorySlice(label: 'Subs', pct: 0.15, color: Color(0xFF3E63F4)),
      _CategorySlice(label: 'Other', pct: 0.05, color: Color(0xFFB7C0D6)),
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
          Text(
            'Category Split',
            style: TextStyle(
              color: const Color(0xFF0B1B4B),
              fontWeight: FontWeight.w900,
              fontSize: titleSize,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: <Widget>[
              _Donut(
                size: AppResponsive.clamp(
                  AppResponsive.vw(constraints, 32),
                  120,
                  150,
                ),
                centerTop: 'Total',
                centerBottom: 'SAR',
                slices: slices,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  children: slices
                      .map((_CategorySlice s) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _LegendRow(
                              color: s.color,
                              label: s.label,
                              pct: '${(s.pct * 100).round()}%',
                            ),
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

class _CategorySlice {
  final String label;
  final double pct;
  final Color color;

  const _CategorySlice({
    required this.label,
    required this.pct,
    required this.color,
  });
}

class _Donut extends StatelessWidget {
  final double size;
  final String centerTop;
  final String centerBottom;
  final List<_CategorySlice> slices;

  const _Donut({
    required this.size,
    required this.centerTop,
    required this.centerBottom,
    required this.slices,
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
            painter: _DonutPainter(slices: slices),
            child: const SizedBox.expand(),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                centerTop,
                style: const TextStyle(
                  color: Color(0xFF63708A),
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                ),
              ),
              Text(
                centerBottom,
                style: const TextStyle(
                  color: Color(0xFF0B1B4B),
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
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
  final List<_CategorySlice> slices;

  const _DonutPainter({required this.slices});

  @override
  void paint(Canvas canvas, Size size) {
    final double stroke = size.width * 0.18;
    final Rect rect = Rect.fromLTWH(
      stroke / 2,
      stroke / 2,
      size.width - stroke,
      size.height - stroke,
    );

    final Paint bg = Paint()
      ..color = const Color(0xFFEFF3FA)
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, 0, math.pi * 2, false, bg);

    double start = -math.pi / 2;
    for (final _CategorySlice s in slices) {
      final Paint p = Paint()
        ..color = s.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round;
      final double sweep = (math.pi * 2) * s.pct;
      canvas.drawArc(rect, start, sweep, false, p);
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter oldDelegate) {
    return oldDelegate.slices != slices;
  }
}

class _LegendRow extends StatelessWidget {
  final Color color;
  final String label;
  final String pct;

  const _LegendRow({
    required this.color,
    required this.label,
    required this.pct,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(99),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: Color(0xFF0B1B4B),
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        Text(
          pct,
          style: const TextStyle(
            color: Color(0xFF0B1B4B),
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class _HighlightsSection extends StatelessWidget {
  final BoxConstraints constraints;

  const _HighlightsSection({required this.constraints});

  @override
  Widget build(BuildContext context) {
    final double gap = AppResponsive.clamp(
      AppResponsive.vw(constraints, 3.2),
      12,
      16,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const Text(
          'Highlights',
          style: TextStyle(
            color: Color(0xFF0B1B4B),
            fontWeight: FontWeight.w900,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: <Widget>[
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(14),
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.emoji_events_outlined,
                          color: Colors.white, size: 18),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Best Seller',
                      style: TextStyle(
                        color: Color(0xFFE7ECFF),
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Software Dev',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(width: gap),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFE9EEF5)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEAFBF2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.trending_up,
                          color: Color(0xFF1E9E5C), size: 18),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Fastest Growing',
                      style: TextStyle(
                        color: Color(0xFF63708A),
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Cloud Hosting',
                      style: TextStyle(
                        color: Color(0xFF0B1B4B),
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      '+15.3%',
                      style: TextStyle(
                        color: Color(0xFF1E9E5C),
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _TopProductsCard extends StatelessWidget {
  final BoxConstraints constraints;
  final VoidCallback onViewAll;

  const _TopProductsCard({
    required this.constraints,
    required this.onViewAll,
  });

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
      AppResponsive.sp(constraints, 14),
      13,
      16,
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
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  'Top Products',
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
          const SizedBox(height: 12),
          ...products.asMap().entries.map((MapEntry<int, TopProduct> entry) {
            final int index = entry.key;
            final TopProduct product = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _TopProductRow(
                data: _TopProductRowData(
                  rank: index + 1,
                  title: product.name,
                  meta: '${product.quantitySold} Sales',
                  amount: 'SAR ${(product.totalRevenue / 1000).toStringAsFixed(0)}k',
                  icon: Icons.inventory_2_outlined,
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _TopProductRowData {
  final int rank;
  final String title;
  final String meta;
  final String amount;
  final IconData icon;

  const _TopProductRowData({
    required this.rank,
    required this.title,
    required this.meta,
    required this.amount,
    required this.icon,
  });
}

class _TopProductRow extends StatelessWidget {
  final _TopProductRowData data;

  const _TopProductRow({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF7FAFF),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: <Widget>[
          SizedBox(
            width: 18,
            child: Text(
              '${data.rank}',
              style: const TextStyle(
                color: Color(0xFF9AA6BC),
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFFEFF2F7),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(data.icon, color: AppColors.primary, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  data.title,
                  style: const TextStyle(
                    color: Color(0xFF0B1B4B),
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  data.meta,
                  style: const TextStyle(
                    color: Color(0xFF63708A),
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            data.amount,
            style: const TextStyle(
              color: Color(0xFF0B1B4B),
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}
