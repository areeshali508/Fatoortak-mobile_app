import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_responsive.dart';
import '../../../models/product.dart';

class ProductPreviewScreen extends StatelessWidget {
  final Product product;

  const ProductPreviewScreen({super.key, required this.product});

  Widget _section({required String title, required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE9EEF5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF0B1B4B),
              fontWeight: FontWeight.w900,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _infoRow({
    required String label,
    required String value,
    IconData? icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF7FAFF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE9EEF5)),
      ),
      child: Row(
        children: <Widget>[
          if (icon != null) ...<Widget>[
            Icon(icon, size: 18, color: const Color(0xFF6B7895)),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Text(
                  label,
                  style: const TextStyle(
                    color: Color(0xFF9AA5B6),
                    fontWeight: FontWeight.w800,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value.trim().isEmpty ? '-' : value.trim(),
                  style: const TextStyle(
                    color: Color(0xFF0B1B4B),
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _fmtNum(num v) {
    final String s = v.toString();
    if (s.endsWith('.0')) return s.substring(0, s.length - 2);
    return s;
  }

  String _moneyLabel({required String currency, required double v}) {
    final String n = (v == v.roundToDouble()) ? v.toStringAsFixed(0) : v.toStringAsFixed(2);
    return '$currency $n';
  }

  String get _stockLabel {
    final int u = product.units;
    if (u <= 0) return 'Out of stock';
    if (u <= 3) return 'Low stock';
    return 'In stock';
  }

  Color get _stockColor {
    final int u = product.units;
    if (u <= 0) return const Color(0xFFFF3B30);
    if (u <= 3) return const Color(0xFFFF9500);
    return const Color(0xFF1DB954);
  }

  IconData get _icon {
    final String c = product.category.trim().toLowerCase();
    switch (c) {
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

        final String name = product.name.trim().isEmpty ? 'Product' : product.name.trim();
        final String category = product.category.trim().isEmpty ? 'General' : product.category.trim();
        final String sku = product.sku.trim().isEmpty ? '-' : product.sku.trim();

        return Scaffold(
          backgroundColor: const Color(0xFFF7FAFF),
          appBar: AppBar(
            title: const Text('Product Preview'),
            actions: <Widget>[
              IconButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Coming soon')),
                  );
                },
                icon: const Icon(Icons.edit_outlined),
              ),
            ],
          ),
          body: SafeArea(
            child: ListView(
              padding: EdgeInsets.fromLTRB(hPad, gap, hPad, gap),
              children: <Widget>[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFFE9EEF5)),
                  ),
                  child: Row(
                    children: <Widget>[
                      Container(
                        width: 54,
                        height: 54,
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF4FF),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Icon(_icon, color: AppColors.primary, size: 26),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: <Widget>[
                            Text(
                              name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Color(0xFF0B1B4B),
                                fontWeight: FontWeight.w900,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '$category • SKU: $sku',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Color(0xFF6B7895),
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: <Widget>[
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: _stockColor,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  _stockLabel,
                                  style: TextStyle(
                                    color: _stockColor,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 12,
                                  ),
                                ),
                                const Spacer(),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: product.active
                                        ? const Color(0xFFEFFAF3)
                                        : const Color(0xFFFFE7E7),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    product.active ? 'ACTIVE' : 'INACTIVE',
                                    style: TextStyle(
                                      color: product.active
                                          ? const Color(0xFF1DB954)
                                          : const Color(0xFFFF3B30),
                                      fontWeight: FontWeight.w900,
                                      fontSize: 11,
                                      letterSpacing: 0.4,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: gap),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: _MetricCard(
                        title: 'Price',
                        value: _moneyLabel(currency: product.currency, v: product.price),
                        icon: Icons.sell_outlined,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _MetricCard(
                        title: 'Units',
                        value: product.units.toString(),
                        icon: Icons.inventory_2_outlined,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: gap),
                _section(
                  title: 'Pricing & Tax',
                  children: <Widget>[
                    _infoRow(
                      label: 'Currency',
                      value: product.currency,
                      icon: Icons.currency_exchange,
                    ),
                    const SizedBox(height: 10),
                    _infoRow(
                      label: 'Unit',
                      value: product.unit,
                      icon: Icons.straighten_outlined,
                    ),
                    const SizedBox(height: 10),
                    _infoRow(
                      label: 'Cost',
                      value: _moneyLabel(currency: product.currency, v: product.cost),
                      icon: Icons.account_balance_wallet_outlined,
                    ),
                    const SizedBox(height: 10),
                    _infoRow(
                      label: 'Tax Rate',
                      value: '${_fmtNum(product.taxRate)}%',
                      icon: Icons.percent,
                    ),
                  ],
                ),
                SizedBox(height: gap),
                _section(
                  title: 'Identifiers',
                  children: <Widget>[
                    _infoRow(
                      label: 'SKU',
                      value: product.sku,
                      icon: Icons.qr_code_2,
                    ),
                    const SizedBox(height: 10),
                    _infoRow(
                      label: 'Barcode',
                      value: product.barcode,
                      icon: Icons.qr_code,
                    ),
                    const SizedBox(height: 10),
                    _infoRow(
                      label: 'Product ID',
                      value: product.id,
                      icon: Icons.fingerprint,
                    ),
                  ],
                ),
                SizedBox(height: gap),
                _section(
                  title: 'Description',
                  children: <Widget>[
                    _infoRow(
                      label: 'Short Description',
                      value: product.shortDescription,
                      icon: Icons.short_text,
                    ),
                    const SizedBox(height: 10),
                    _infoRow(
                      label: 'Full Description',
                      value: product.description,
                      icon: Icons.notes_outlined,
                    ),
                  ],
                ),
                SizedBox(height: gap),
                _section(
                  title: 'Dimensions & Weight',
                  children: <Widget>[
                    _infoRow(
                      label: 'Weight (kg)',
                      value: _fmtNum(product.weightKg),
                      icon: Icons.scale_outlined,
                    ),
                    const SizedBox(height: 10),
                    _infoRow(
                      label: 'Length (cm)',
                      value: _fmtNum(product.lengthCm),
                      icon: Icons.straighten,
                    ),
                    const SizedBox(height: 10),
                    _infoRow(
                      label: 'Width (cm)',
                      value: _fmtNum(product.widthCm),
                      icon: Icons.straighten,
                    ),
                    const SizedBox(height: 10),
                    _infoRow(
                      label: 'Height (cm)',
                      value: _fmtNum(product.heightCm),
                      icon: Icons.straighten,
                    ),
                  ],
                ),
                SizedBox(height: gap),
                _section(
                  title: 'Tags',
                  children: <Widget>[
                    if (product.tags.isEmpty)
                      _infoRow(
                        label: 'Tags',
                        value: '-',
                        icon: Icons.sell_outlined,
                      )
                    else
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: product.tags
                            .map(
                              (String t) => Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEFF4FF),
                                  borderRadius: BorderRadius.circular(999),
                                  border: Border.all(
                                    color: const Color(0xFFE9EEF5),
                                  ),
                                ),
                                child: Text(
                                  t,
                                  style: const TextStyle(
                                    color: Color(0xFF0B1B4B),
                                    fontWeight: FontWeight.w800,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                  ],
                ),
                if (product.imagePaths.isNotEmpty) ...<Widget>[
                  SizedBox(height: gap),
                  _section(
                    title: 'Images',
                    children: <Widget>[
                      SizedBox(
                        height: 160,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: product.imagePaths.length,
                          separatorBuilder: (BuildContext context, int index) =>
                              const SizedBox(width: 12),
                          itemBuilder: (BuildContext context, int i) {
                            final String src = product.imagePaths[i].trim();
                            return ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Container(
                                width: 220,
                                color: const Color(0xFFF7FAFF),
                                child: src.isEmpty
                                    ? const Center(
                                        child: Icon(
                                          Icons.image_not_supported_outlined,
                                          color: Color(0xFF9AA5B6),
                                        ),
                                      )
                                    : Image.network(
                                        src,
                                        fit: BoxFit.cover,
                                        errorBuilder: (
                                          BuildContext context,
                                          Object error,
                                          StackTrace? stackTrace,
                                        ) {
                                          return const Center(
                                            child: Icon(
                                              Icons.broken_image_outlined,
                                              color: Color(0xFF9AA5B6),
                                            ),
                                          );
                                        },
                                      ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _MetricCard({
    required this.title,
    required this.value,
    required this.icon,
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
      child: Row(
        children: <Widget>[
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: const Color(0xFFEFF4FF),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF9AA5B6),
                    fontWeight: FontWeight.w800,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 4),
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
          ),
        ],
      ),
    );
  }
}
