import 'package:flutter/material.dart';

import '../../../app/app_routes.dart';
import '../../../core/constants/app_responsive.dart';

class SubscriptionScreen extends StatelessWidget {
  const SubscriptionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double hPad = AppResponsive.clamp(
          AppResponsive.vw(constraints, 6),
          16,
          22,
        );

        final double sectionGap = AppResponsive.clamp(
          AppResponsive.scaledByHeight(constraints, 16),
          12,
          20,
        );

        final double cardRadius = AppResponsive.clamp(
          AppResponsive.scaledByHeight(constraints, 18),
          14,
          20,
        );

        return Scaffold(
          backgroundColor: const Color(0xFFF7FAFF),
          appBar: AppBar(
            title: const Text('Subscription Plans'),
            leading: const BackButton(),
          ),
          body: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(hPad, sectionGap, hPad, sectionGap),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                _PlanCard(
                  radius: cardRadius + 6,
                  onCancel: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Cancel plan is not connected yet')),
                    );
                  },
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: () => Navigator.of(context).pushNamed(AppRoutes.upgradePlan),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF0A1F6D),
                    side: const BorderSide(color: Color(0xFF0A1F6D), width: 2),
                    backgroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    textStyle: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  child: const Text('Upgrade Plan'),
                ),
                SizedBox(height: sectionGap),
                _UsageCycleCard(radius: cardRadius + 6),
                SizedBox(height: sectionGap),
                const Text(
                  'Payment History',
                  style: TextStyle(
                    color: Color(0xFF0B1B4B),
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 12),
                _PaymentHistoryCard(radius: cardRadius + 6),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Full history is not connected yet')),
                    );
                  },
                  child: const Text(
                    'View full history',
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
class _StatusPill extends StatelessWidget {
  final String text;
  final Color background;
  final Color foreground;

  const _StatusPill({
    required this.text,
    required this.background,
    required this.foreground,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        child: Text(
          text,
          style: TextStyle(
            color: foreground,
            fontWeight: FontWeight.w900,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}


class _PlanCard extends StatelessWidget {
  final double radius;
  final VoidCallback onCancel;

  const _PlanCard({required this.radius, required this.onCancel});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            Color(0xFF0B2B8F),
            Color(0xFF0A1F6D),
          ],
        ),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x220B1B4B),
            blurRadius: 16,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Row(
              children: <Widget>[
                _StatusPill(
                  text: 'Active',
                  background: const Color(0x2200D084),
                  foreground: const Color(0xFF00D084),
                ),
                const Spacer(),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Enterprise Plan',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 24,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Unlimited invoices & users',
              style: TextStyle(
                color: Color(0xCCFFFFFF),
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 18),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: const <Widget>[
                Text(
                  'SAR 999.00',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 32,
                    height: 1.0,
                  ),
                ),
                SizedBox(width: 8),
                Padding(
                  padding: EdgeInsets.only(bottom: 4),
                  child: Text(
                    '/ monthly',
                    style: TextStyle(
                      color: Color(0xCCFFFFFF),
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            OutlinedButton(
              onPressed: onCancel,
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: Color(0x44FFFFFF)),
                backgroundColor: Colors.transparent,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                textStyle: const TextStyle(fontWeight: FontWeight.w900),
              ),
              child: const Text('Cancel Plan'),
            ),
          ],
        ),
      ),
    );
  }
}

class _UsageCycleCard extends StatelessWidget {
  final double radius;

  const _UsageCycleCard({required this.radius});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: DecoratedBox(
        decoration: const BoxDecoration(color: Colors.white),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Row(
                children: <Widget>[
                  const Text(
                    'USAGE CYCLE',
                    style: TextStyle(
                      color: Color(0xFF6B7895),
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.2,
                      fontSize: 12,
                    ),
                  ),
                  const Spacer(),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F6FB),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      child: Text(
                        '27 Days Remaining',
                        style: TextStyle(
                          color: Color(0xFF0B1B4B),
                          fontWeight: FontWeight.w900,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Row(
                children: const <Widget>[
                  Expanded(
                    child: Text(
                      'Feb 9',
                      style: TextStyle(
                        color: Color(0xFF0B1B4B),
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  Text(
                    'Mar 9',
                    style: TextStyle(
                      color: Color(0xFF0B1B4B),
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              _ProgressBar(value: 0.12),
              const SizedBox(height: 12),
              Row(
                children: const <Widget>[
                  Expanded(
                    child: Text(
                      'Start Date',
                      style: TextStyle(
                        color: Color(0xFF9AA5B6),
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  Text(
                    'Renewal Date',
                    style: TextStyle(
                      color: Color(0xFF9AA5B6),
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  final double value;

  const _ProgressBar({required this.value});

  @override
  Widget build(BuildContext context) {
    final double v = value.clamp(0.0, 1.0);

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints c) {
        final double w = c.maxWidth;
        return Stack(
          children: <Widget>[
            Container(
              height: 8,
              decoration: BoxDecoration(
                color: const Color(0xFFE9EEF5),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            Container(
              height: 8,
              width: w * v,
              decoration: BoxDecoration(
                color: const Color(0xFF0B2B8F),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _PaymentHistoryCard extends StatelessWidget {
  final double radius;

  const _PaymentHistoryCard({required this.radius});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: DecoratedBox(
        decoration: const BoxDecoration(color: Colors.white),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const <Widget>[
            _PaymentItem(
              title: 'Subscription to Business plan',
              date: 'Dec 4, 2025',
              amount: 'SAR 97.75',
              status: 'Succeeded',
              showDivider: true,
              icon: Icons.receipt_long_outlined,
            ),
            _PaymentItem(
              title: 'Payment for plan',
              date: 'Sep 14, 2025',
              amount: 'SAR 85.00',
              status: 'Succeeded',
              showDivider: false,
              icon: Icons.autorenew,
            ),
          ],
        ),
      ),
    );
  }
}

class _PaymentItem extends StatelessWidget {
  final String title;
  final String date;
  final String amount;
  final String status;
  final bool showDivider;
  final IconData icon;

  const _PaymentItem({
    required this.title,
    required this.date,
    required this.amount,
    required this.status,
    required this.showDivider,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final bool ok = status.toLowerCase() == 'succeeded';

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          leading: Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              color: Color(0xFFF3F6FB),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: const Color(0xFF0B1B4B), size: 20),
          ),
          title: Text(
            title,
            style: const TextStyle(
              color: Color(0xFF0B1B4B),
              fontWeight: FontWeight.w900,
              fontSize: 13,
            ),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              date,
              style: const TextStyle(
                color: Color(0xFF9AA5B6),
                fontWeight: FontWeight.w800,
                fontSize: 12,
              ),
            ),
          ),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
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
              const SizedBox(height: 6),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Icon(
                    ok ? Icons.check_circle : Icons.error,
                    size: 14,
                    color: ok ? const Color(0xFF00B46E) : const Color(0xFFD93025),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    status,
                    style: TextStyle(
                      color: ok ? const Color(0xFF00B46E) : const Color(0xFFD93025),
                      fontWeight: FontWeight.w900,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        if (showDivider)
          const Divider(height: 1, thickness: 1, color: Color(0xFFE9EEF5)),
      ],
    );
  }
}
