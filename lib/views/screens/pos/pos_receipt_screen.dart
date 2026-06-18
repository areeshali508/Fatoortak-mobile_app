import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../models/pos_order.dart';

class PosReceiptScreen extends StatelessWidget {
  final PosOrder order;
  const PosReceiptScreen({required this.order, super.key});

  static String _fmt(double v) => v % 1 == 0
      ? 'SAR ${v.toStringAsFixed(0)}'
      : 'SAR ${v.toStringAsFixed(2)}';

  static String _payLabel(PosPaymentMethod m) {
    switch (m) {
      case PosPaymentMethod.cash:
        return 'Cash';
      case PosPaymentMethod.card:
        return 'Card';
      case PosPaymentMethod.bankTransfer:
        return 'Bank Transfer';
    }
  }

  static String _ts(DateTime d) {
    String p(int n) => n.toString().padLeft(2, '0');
    return '${d.year}-${p(d.month)}-${p(d.day)}  ${p(d.hour)}:${p(d.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7FAFF),
      appBar: AppBar(
        title: const Text('Receipt'),
        leading: const BackButton(),
        actions: <Widget>[
          TextButton.icon(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.add_shopping_cart_outlined,
                color: Colors.white, size: 18),
            label: const Text('New Sale',
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w800)),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            // Success banner
            _successBanner(),
            const SizedBox(height: 16),

            // Items
            _card(child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                _label('ITEMS'),
                const SizedBox(height: 10),
                ...order.items.map(_itemRow),
              ],
            )),
            const SizedBox(height: 12),

            // Totals
            _card(child: Column(children: <Widget>[
              _totRow('Subtotal', _fmt(order.subtotal)),
              const SizedBox(height: 6),
              _totRow('VAT', _fmt(order.taxAmount)),
              const Padding(
                  padding: EdgeInsets.symmetric(vertical: 10),
                  child: Divider(height: 1, color: Color(0xFFE9EEF5))),
              _totRow('Total', _fmt(order.total), bold: true, large: true),
              if (order.paymentMethod == PosPaymentMethod.cash) ...<Widget>[
                const SizedBox(height: 6),
                _totRow('Cash Given', _fmt(order.cashGiven)),
                const SizedBox(height: 6),
                _totRow('Change', _fmt(order.change), accent: true),
              ],
            ])),
            const SizedBox(height: 12),

            // Payment
            _card(child: Row(children: <Widget>[
              _iconBox(order.paymentMethod == PosPaymentMethod.cash
                  ? Icons.payments_outlined
                  : order.paymentMethod == PosPaymentMethod.card
                      ? Icons.credit_card_outlined
                      : Icons.account_balance_outlined),
              const SizedBox(width: 12),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Text('Payment Method',
                      style: TextStyle(
                          color: Color(0xFF9AA5B6),
                          fontSize: 11,
                          fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text(_payLabel(order.paymentMethod),
                      style: const TextStyle(
                          color: Color(0xFF0B1B4B),
                          fontWeight: FontWeight.w900,
                          fontSize: 14)),
                ],
              )),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                    color: const Color(0xFFEFFAF3),
                    borderRadius: BorderRadius.circular(999)),
                child: const Text('PAID',
                    style: TextStyle(
                        color: Color(0xFF1DB954),
                        fontWeight: FontWeight.w900,
                        fontSize: 11,
                        letterSpacing: 0.6)),
              ),
            ])),

            // Customer (optional)
            if ((order.customerName ?? '').isNotEmpty) ...<Widget>[
              const SizedBox(height: 12),
              _card(child: Row(children: <Widget>[
                _iconBox(Icons.person_outline),
                const SizedBox(width: 12),
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Text('Customer',
                        style: TextStyle(
                            color: Color(0xFF9AA5B6),
                            fontSize: 11,
                            fontWeight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    Text(order.customerName!,
                        style: const TextStyle(
                            color: Color(0xFF0B1B4B),
                            fontWeight: FontWeight.w900,
                            fontSize: 14)),
                  ],
                )),
              ])),
            ],

            const SizedBox(height: 28),
            ElevatedButton.icon(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.point_of_sale_outlined),
              label: const Text('Back to POS'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                textStyle: const TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _successBanner() => Container(
        padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
        decoration: BoxDecoration(
            color: AppColors.splashBottom,
            borderRadius: BorderRadius.circular(20)),
        child: Column(children: <Widget>[
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                shape: BoxShape.circle),
            child: const Icon(Icons.check_rounded, color: Colors.white, size: 32),
          ),
          const SizedBox(height: 14),
          const Text('Sale Complete',
              style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 20)),
          const SizedBox(height: 6),
          Text(order.orderNumber,
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.75),
                  fontSize: 13,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(_ts(order.createdAt),
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5), fontSize: 12)),
        ]),
      );

  Widget _itemRow(PosCartItem item) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(children: <Widget>[
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
                color: const Color(0xFFEFF4FF),
                borderRadius: BorderRadius.circular(10)),
            alignment: Alignment.center,
            child: Text('${item.qty}×',
                style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w900,
                    fontSize: 11)),
          ),
          const SizedBox(width: 10),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(item.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      color: Color(0xFF0B1B4B),
                      fontWeight: FontWeight.w800,
                      fontSize: 13)),
              if (item.sku.isNotEmpty)
                Text(item.sku,
                    style: const TextStyle(
                        color: Color(0xFF9AA5B6),
                        fontSize: 11,
                        fontWeight: FontWeight.w600)),
            ],
          )),
          const SizedBox(width: 8),
          Text(_fmt(item.total),
              style: const TextStyle(
                  color: Color(0xFF0B1B4B),
                  fontWeight: FontWeight.w900,
                  fontSize: 13)),
        ]),
      );

  static Widget _card({required Widget child}) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE9EEF5))),
        child: child,
      );

  static Widget _label(String t) => Text(t,
      style: const TextStyle(
          color: Color(0xFF9AA5B6),
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.1));

  static Widget _iconBox(IconData icon) => Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
            color: const Color(0xFFEFF4FF),
            borderRadius: BorderRadius.circular(12)),
        child: Icon(icon, color: AppColors.primary, size: 20),
      );

  static Widget _totRow(String label, String value,
      {bool bold = false, bool large = false, bool accent = false}) {
    final Color vc = accent
        ? const Color(0xFF1DB954)
        : bold
            ? const Color(0xFF0B1B4B)
            : const Color(0xFF6B7895);
    return Row(children: <Widget>[
      Expanded(
        child: Text(label,
            style: TextStyle(
                color: bold
                    ? const Color(0xFF0B1B4B)
                    : const Color(0xFF6B7895),
                fontWeight: bold ? FontWeight.w900 : FontWeight.w700,
                fontSize: large ? 15 : 13)),
      ),
      Text(value,
          style: TextStyle(
              color: vc,
              fontWeight: FontWeight.w900,
              fontSize: large ? 18 : 13)),
    ]);
  }
}
