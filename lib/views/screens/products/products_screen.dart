import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/app_routes.dart';
import '../../../controllers/product_controller.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_responsive.dart';
import '../../../models/product.dart';
import '../../layout/app_drawer.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  int _segmentIndex = 0;

  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductController>().refresh();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showComingSoon() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Coming soon')),
    );
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
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final ProductController ctrl = context.watch<ProductController>();

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

        final List<_ProductVM> items = ctrl.products
            .asMap()
            .entries
            .map((MapEntry<int, Product> e) => _ProductVM.fromProduct(
                  product: e.value,
                  index: e.key,
                ))
            .where((_ProductVM p) {
              final String q = _searchController.text.trim().toLowerCase();
              if (q.isNotEmpty) {
                final bool matches = p.name.toLowerCase().contains(q) ||
                    p.sku.toLowerCase().contains(q) ||
                    p.category.toLowerCase().contains(q);
                if (!matches) {
                  return false;
                }
              }

              switch (_segmentIndex) {
                case 1:
                  return p.active;
                case 2:
                  return p.category.toLowerCase() == 'services';
                case 3:
                  return !p.active;
                default:
                  return true;
              }
            })
            .toList();

        final int inStockCount = ctrl.products
            .asMap()
            .entries
            .map((MapEntry<int, Product> e) =>
                _ProductVM.fromProduct(product: e.value, index: e.key))
            .where((_ProductVM p) => p.stockStatus == _StockStatus.inStock)
            .length;

        final int lowCount = ctrl.products
            .asMap()
            .entries
            .map((MapEntry<int, Product> e) =>
                _ProductVM.fromProduct(product: e.value, index: e.key))
            .where((_ProductVM p) => p.stockStatus == _StockStatus.low)
            .length;

        final int emptyCount = ctrl.products
            .asMap()
            .entries
            .map((MapEntry<int, Product> e) =>
                _ProductVM.fromProduct(product: e.value, index: e.key))
            .where((_ProductVM p) => p.stockStatus == _StockStatus.empty)
            .length;

        final double inventoryValue = ctrl.products
            .asMap()
            .entries
            .map((MapEntry<int, Product> e) {
              final _ProductVM p =
                  _ProductVM.fromProduct(product: e.value, index: e.key);
              return e.value.price * max(0, p.units);
            })
            .fold(0.0, (double a, double b) => a + b);

        return Scaffold(
          backgroundColor: const Color(0xFFF7FAFF),
          drawer: const AppDrawer(),
          appBar: AppBar(
            title: const Text('Products'),
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
                            color: Color(0xFFFF3B30),
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
            child: Padding(
              padding: EdgeInsets.fromLTRB(hPad, gap, hPad, 0),
              child: ctrl.isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: AppColors.primary),
                    )
                  : ListView(
                      padding: EdgeInsets.only(bottom: gap + 120),
                      children: <Widget>[
                        Row(
                          children: <Widget>[
                            Expanded(
                              child: _SearchField(
                                constraints: constraints,
                                controller: _searchController,
                                onChanged: (_) => setState(() {}),
                              ),
                            ),
                            const SizedBox(width: 12),
                            _IconPill(
                              icon: Icons.tune,
                              onTap: _showComingSoon,
                            ),
                          ],
                        ),
                        SizedBox(height: gap),
                        _InventoryValueCard(
                          constraints: constraints,
                          valueLabel: _moneyLabel(inventoryValue),
                          deltaText: '+4.2%',
                        ),
                        SizedBox(height: gap),
                        Row(
                          children: <Widget>[
                            Expanded(
                              child: _MiniStatCard(
                                label: 'IN STOCK',
                                value: inStockCount.toString(),
                                dotColor: const Color(0xFF1DB954),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _MiniStatCard(
                                label: 'LOW',
                                value: lowCount.toString(),
                                dotColor: const Color(0xFFFF9500),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _MiniStatCard(
                                label: 'EMPTY',
                                value: emptyCount.toString(),
                                dotColor: const Color(0xFFFF3B30),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: gap),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: <Widget>[
                              _SegmentChip(
                                constraints: constraints,
                                label: 'All Items',
                                selected: _segmentIndex == 0,
                                onTap: () => setState(() => _segmentIndex = 0),
                              ),
                              const SizedBox(width: 10),
                              _SegmentChip(
                                constraints: constraints,
                                label: 'Active',
                                selected: _segmentIndex == 1,
                                onTap: () => setState(() => _segmentIndex = 1),
                              ),
                              const SizedBox(width: 10),
                              _SegmentChip(
                                constraints: constraints,
                                label: 'Services',
                                selected: _segmentIndex == 2,
                                onTap: () => setState(() => _segmentIndex = 2),
                              ),
                              const SizedBox(width: 10),
                              _SegmentChip(
                                constraints: constraints,
                                label: 'Inactive',
                                selected: _segmentIndex == 3,
                                onTap: () => setState(() => _segmentIndex = 3),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: gap),
                        if (items.isEmpty)
                          const Padding(
                            padding: EdgeInsets.only(top: 24),
                            child: Center(
                              child: Text(
                                'No products',
                                style: TextStyle(
                                  color: Color(0xFF9AA5B6),
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          )
                        else
                          ...items.map((_ProductVM p) {
                            return _ProductCard(
                              product: p,
                              onTap: _showComingSoon,
                            );
                          }),
                      ],
                    ),
            ),
          ),
          floatingActionButton: SizedBox(
            width: 62,
            height: 62,
            child: FloatingActionButton(
              onPressed: _showComingSoon,
              backgroundColor: AppColors.primary,
              shape: const CircleBorder(),
              child: const Icon(Icons.add, color: Colors.white, size: 28),
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

  String _moneyLabel(double v) {
    if (v >= 1000) {
      final double k = v / 1000;
      return 'SAR ${k.toStringAsFixed(1)}K';
    }
    return 'SAR ${v.toStringAsFixed(0)}';
  }
}

class _SearchField extends StatelessWidget {
  final BoxConstraints constraints;
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const _SearchField({
    required this.constraints,
    required this.controller,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final double radius = AppResponsive.clamp(
      AppResponsive.scaledByHeight(constraints, 18),
      14,
      20,
    );

    return TextField(
      controller: controller,
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: 'Search products, SKU...',
        hintStyle: const TextStyle(color: Color(0xFF9AA5B6)),
        prefixIcon: const Icon(Icons.search, color: Color(0xFF9AA5B6)),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(vertical: 14),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius),
          borderSide: const BorderSide(color: Color(0xFFE9EEF5)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.4),
        ),
      ),
    );
  }
}

class _IconPill extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _IconPill({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: 48,
          height: 48,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE9EEF5)),
          ),
          child: Icon(icon, color: const Color(0xFF6B7895)),
        ),
      ),
    );
  }
}

class _InventoryValueCard extends StatelessWidget {
  final BoxConstraints constraints;
  final String valueLabel;
  final String deltaText;

  const _InventoryValueCard({
    required this.constraints,
    required this.valueLabel,
    required this.deltaText,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE9EEF5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              const Expanded(
                child: Text(
                  'Total Inventory Value',
                  style: TextStyle(
                    color: Color(0xFF6B7895),
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFFAF3),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    const Icon(
                      Icons.trending_up,
                      size: 14,
                      color: Color(0xFF1DB954),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      deltaText,
                      style: const TextStyle(
                        color: Color(0xFF1DB954),
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            valueLabel,
            style: TextStyle(
              color: const Color(0xFF0B1B4B),
              fontWeight: FontWeight.w900,
              fontSize: AppResponsive.clamp(
                AppResponsive.sp(constraints, 26),
                22,
                30,
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 84,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: DecoratedBox(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: <Color>[
                      Color(0xFFEFF4FF),
                      Color(0x00EFF4FF),
                    ],
                  ),
                ),
                child: CustomPaint(
                  painter: _MiniLineChartPainter(
                    color: AppColors.primary,
                    values: const <double>[
                      0.18,
                      0.24,
                      0.22,
                      0.26,
                      0.25,
                      0.30,
                      0.28,
                      0.34,
                      0.33,
                      0.38,
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

class _MiniLineChartPainter extends CustomPainter {
  final Color color;
  final List<double> values;

  const _MiniLineChartPainter({required this.color, required this.values});

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) {
      return;
    }

    final Paint line = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;

    final Paint fill = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: <Color>[
          color.withValues(alpha: 0.18),
          color.withValues(alpha: 0.00),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final Path p = Path();
    final Path fillPath = Path();

    final double step = values.length == 1
        ? 0
        : (size.width / (values.length - 1).toDouble());

    for (int i = 0; i < values.length; i++) {
      final double x = step * i;
      final double y = size.height - (values[i].clamp(0.0, 1.0) * size.height);
      if (i == 0) {
        p.moveTo(x, y);
        fillPath.moveTo(x, size.height);
        fillPath.lineTo(x, y);
      } else {
        p.lineTo(x, y);
        fillPath.lineTo(x, y);
      }
    }

    fillPath.lineTo(size.width, size.height);
    fillPath.close();

    canvas.drawPath(fillPath, fill);
    canvas.drawPath(p, line);
  }

  @override
  bool shouldRepaint(covariant _MiniLineChartPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.values != values;
  }
}

class _MiniStatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color dotColor;

  const _MiniStatCard({
    required this.label,
    required this.value,
    required this.dotColor,
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
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: dotColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: Color(0xFF6B7895),
                  fontWeight: FontWeight.w900,
                  fontSize: 11,
                  letterSpacing: 0.6,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
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

class _SegmentChip extends StatelessWidget {
  final BoxConstraints constraints;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _SegmentChip({
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
          color: selected ? const Color(0xFF0B1B4B) : Colors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? Colors.transparent : const Color(0xFFE9EEF5),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : const Color(0xFF6B7895),
            fontWeight: FontWeight.w800,
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

class _ProductCard extends StatelessWidget {
  final _ProductVM product;
  final VoidCallback onTap;

  const _ProductCard({required this.product, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final (_BadgeStyle badgeStyle, String badgeText) = product.badge;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Container(
            padding: const EdgeInsets.all(16),
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
                    color: product.iconBg,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    product.icon,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        product.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF0B1B4B),
                          fontWeight: FontWeight.w900,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${product.category} • SKU: ${product.sku}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF9AA5B6),
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: badgeStyle.bg,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          badgeText,
                          style: TextStyle(
                            color: badgeStyle.fg,
                            fontWeight: FontWeight.w800,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  product.priceLabel,
                  style: const TextStyle(
                    color: Color(0xFF0B1B4B),
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

enum _StockStatus {
  inStock,
  low,
  empty,
}

class _ProductVM {
  final String name;
  final String sku;
  final String category;
  final bool active;
  final int units;
  final double price;
  final String currency;

  const _ProductVM({
    required this.name,
    required this.sku,
    required this.category,
    required this.active,
    required this.units,
    required this.price,
    required this.currency,
  });

  factory _ProductVM.fromProduct({required Product product, required int index}) {
    final List<String> cats = <String>[
      'Electronics',
      'Furniture',
      'Supplies',
      'Accessories',
      'Services',
    ];

    final List<int> units = <int>[12, 3, 0, 45, 1, 8, 2];

    return _ProductVM(
      name: product.name,
      sku: (9000 + (index * 217) % 999).toString(),
      category: cats[index % cats.length],
      active: index % 5 != 3,
      units: units[index % units.length],
      price: product.price,
      currency: product.currency,
    );
  }

  _StockStatus get stockStatus {
    if (units <= 0) {
      return _StockStatus.empty;
    }
    if (units <= 3) {
      return _StockStatus.low;
    }
    return _StockStatus.inStock;
  }

  IconData get icon {
    switch (category.toLowerCase()) {
      case 'electronics':
        return Icons.laptop_mac;
      case 'furniture':
        return Icons.chair_alt_outlined;
      case 'supplies':
        return Icons.print_outlined;
      case 'accessories':
        return Icons.mouse_outlined;
      case 'services':
        return Icons.build_outlined;
      default:
        return Icons.inventory_2_outlined;
    }
  }

  Color get iconBg {
    const List<Color> palette = <Color>[
      Color(0xFFEFF4FF),
      Color(0xFFFFF3E6),
      Color(0xFFEFFAF3),
      Color(0xFFEDEBFF),
      Color(0xFFFFE7E7),
    ];
    return palette[name.length % palette.length];
  }

  (_BadgeStyle, String) get badge {
    switch (stockStatus) {
      case _StockStatus.inStock:
        return (
          const _BadgeStyle(bg: Color(0xFFEFFAF3), fg: Color(0xFF1DB954)),
          '$units UNITS'
        );
      case _StockStatus.low:
        return (
          const _BadgeStyle(bg: Color(0xFFFFF3E6), fg: Color(0xFFFF9500)),
          '$units UNITS'
        );
      case _StockStatus.empty:
        return (
          const _BadgeStyle(bg: Color(0xFFFFE7E7), fg: Color(0xFFFF3B30)),
          'OUT OF STOCK'
        );
    }
  }

  String get priceLabel {
    final String v = price == price.roundToDouble()
        ? price.toStringAsFixed(0)
        : price.toStringAsFixed(2);
    return '$currency $v';
  }
}

class _BadgeStyle {
  final Color bg;
  final Color fg;

  const _BadgeStyle({required this.bg, required this.fg});
}
