import 'package:flutter/material.dart';

import '../../../core/constants/app_responsive.dart';

class UpgradePlanScreen extends StatefulWidget {
  const UpgradePlanScreen({super.key});

  @override
  State<UpgradePlanScreen> createState() => _UpgradePlanScreenState();
}

class _UpgradePlanScreenState extends State<UpgradePlanScreen> {
  bool _isYearly = true;

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
          16,
          22,
        );

        return Scaffold(
          backgroundColor: const Color(0xFFF7FAFF),
          appBar: AppBar(
            title: const Text('Upgrade Plan'),
            leading: const BackButton(),
          ),
          body: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(hPad, sectionGap, hPad, sectionGap),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                _BillingToggle(
                  isYearly: _isYearly,
                  onChanged: (bool v) => setState(() => _isYearly = v),
                ),
                SizedBox(height: sectionGap),
                _PlanCard(
                  radius: cardRadius,
                  isHighlighted: false,
                  titleSmall: 'STARTER PLAN',
                  price: _isYearly ? 'SAR 990' : 'SAR 99',
                  priceSuffix: _isYearly ? '/yr' : '/mo',
                  icon: Icons.rocket_launch_outlined,
                  features: const <_FeatureItem>[
                    _FeatureItem('Up to 50 Invoices', true),
                    _FeatureItem('1 User Access', true),
                    _FeatureItem('Basic Reports', true),
                    _FeatureItem('Custom Branding', false),
                  ],
                  primaryCtaText: 'Select Plan',
                  onPrimaryTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Select plan is not connected yet')),
                    );
                  },
                ),
                SizedBox(height: sectionGap),
                _PlanCard(
                  radius: cardRadius,
                  isHighlighted: true,
                  ribbonText: 'BEST VALUE',
                  titleSmall: 'BUSINESS PLAN',
                  price: _isYearly ? 'SAR 2,990' : 'SAR 299',
                  priceSuffix: _isYearly ? '/yr' : '/mo',
                  icon: Icons.work_outline,
                  features: const <_FeatureItem>[
                    _FeatureItem('Unlimited Invoices', true),
                    _FeatureItem('Up to 5 Users', true),
                    _FeatureItem('Advanced Reports & Analytics', true),
                    _FeatureItem('Custom Branding', true),
                    _FeatureItem('Priority Email Support', true),
                  ],
                  primaryCtaText: 'Upgrade to Business',
                  onPrimaryTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Upgrade is not connected yet')),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _BillingToggle extends StatelessWidget {
  final bool isYearly;
  final ValueChanged<bool> onChanged;

  const _BillingToggle({required this.isYearly, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    const Color navy = Color(0xFF0A1F6D);

    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFE9EEF5)),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: _TogglePill(
              text: 'Monthly',
              selected: !isYearly,
              onTap: () => onChanged(false),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Stack(
              alignment: Alignment.center,
              children: <Widget>[
                _TogglePill(
                  text: 'Yearly',
                  selected: isYearly,
                  onTap: () => onChanged(true),
                ),
                Positioned(
                  right: 10,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: const Color(0xFFE7F5EC),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      child: Text(
                        '-20%',
                        style: TextStyle(
                          color: navy,
                          fontWeight: FontWeight.w900,
                          fontSize: 11,
                        ),
                      ),
                    ),
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

class _TogglePill extends StatelessWidget {
  final String text;
  final bool selected;
  final VoidCallback onTap;

  const _TogglePill({required this.text, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    const Color navy = Color(0xFF0A1F6D);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? navy : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Center(
          child: Text(
            text,
            style: TextStyle(
              color: selected ? Colors.white : const Color(0xFF6B7895),
              fontWeight: FontWeight.w900,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }
}

class _FeatureItem {
  final String text;
  final bool enabled;

  const _FeatureItem(this.text, this.enabled);
}

class _PlanCard extends StatelessWidget {
  final double radius;
  final bool isHighlighted;
  final String? ribbonText;
  final String titleSmall;
  final String price;
  final String priceSuffix;
  final IconData icon;
  final List<_FeatureItem> features;
  final String primaryCtaText;
  final VoidCallback onPrimaryTap;

  const _PlanCard({
    required this.radius,
    required this.isHighlighted,
    required this.titleSmall,
    required this.price,
    required this.priceSuffix,
    required this.icon,
    required this.features,
    required this.primaryCtaText,
    required this.onPrimaryTap,
    this.ribbonText,
  });

  @override
  Widget build(BuildContext context) {
    const Color navy = Color(0xFF0A1F6D);

    final Color borderColor = isHighlighted ? navy : const Color(0xFFE9EEF5);
    final double borderWidth = isHighlighted ? 2 : 1;

    return Stack(
      clipBehavior: Clip.none,
      children: <Widget>[
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(color: borderColor, width: borderWidth),
            boxShadow: const <BoxShadow>[
              BoxShadow(
                color: Color(0x110B1B4B),
                blurRadius: 18,
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
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            titleSmall,
                            style: const TextStyle(
                              color: Color(0xFF6B7895),
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.2,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: <Widget>[
                              Text(
                                price,
                                style: const TextStyle(
                                  color: Color(0xFF0B1B4B),
                                  fontWeight: FontWeight.w900,
                                  fontSize: 38,
                                  height: 1.0,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Padding(
                                padding: const EdgeInsets.only(bottom: 6),
                                child: Text(
                                  priceSuffix,
                                  style: const TextStyle(
                                    color: Color(0xFF6B7895),
                                    fontWeight: FontWeight.w900,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 46,
                      height: 46,
                      decoration: const BoxDecoration(
                        color: Color(0xFFF3F6FB),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(icon, color: navy, size: 22),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                for (int i = 0; i < features.length; i++)
                  Padding(
                    padding: EdgeInsets.only(bottom: i == features.length - 1 ? 0 : 12),
                    child: _FeatureRow(item: features[i], highlight: isHighlighted),
                  ),
                const SizedBox(height: 22),
                SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    onPressed: onPrimaryTap,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isHighlighted ? navy : Colors.white,
                      foregroundColor: isHighlighted ? Colors.white : navy,
                      elevation: isHighlighted ? 8 : 0,
                      shadowColor: const Color(0x330A1F6D),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: isHighlighted
                            ? BorderSide.none
                            : const BorderSide(color: Color(0xFF0A1F6D), width: 2),
                      ),
                      textStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
                    ),
                    child: Text(primaryCtaText),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (ribbonText != null)
          Positioned(
            top: -14,
            left: 0,
            right: 0,
            child: Center(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: navy,
                  borderRadius: BorderRadius.circular(999),
                  boxShadow: const <BoxShadow>[
                    BoxShadow(
                      color: Color(0x220A1F6D),
                      blurRadius: 12,
                      offset: Offset(0, 6),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  child: Text(
                    ribbonText!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.2,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _FeatureRow extends StatelessWidget {
  final _FeatureItem item;
  final bool highlight;

  const _FeatureRow({required this.item, required this.highlight});

  @override
  Widget build(BuildContext context) {
    const Color navy = Color(0xFF0A1F6D);

    final Color iconColor = item.enabled
        ? navy
        : const Color(0xFFBCC5D6);

    final Color textColor = item.enabled
        ? const Color(0xFF0B1B4B)
        : const Color(0xFFBCC5D6);

    return Row(
      children: <Widget>[
        Container(
          width: 18,
          height: 18,
          decoration: BoxDecoration(
            color: item.enabled ? const Color(0xFFEAF0FF) : const Color(0xFFF3F6FB),
            shape: BoxShape.circle,
          ),
          child: Icon(
            item.enabled ? Icons.check : Icons.close,
            size: 12,
            color: iconColor,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            item.text,
            style: TextStyle(
              color: textColor,
              fontWeight: item.enabled ? FontWeight.w800 : FontWeight.w700,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }
}
