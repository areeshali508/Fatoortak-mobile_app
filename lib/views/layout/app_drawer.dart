import 'package:flutter/material.dart';

import '../../app/app_routes.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_responsive.dart';

class AppDrawer extends StatefulWidget {
  const AppDrawer({super.key});

  @override
  State<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer> {
  bool _salesExpanded = false;

  void _comingSoon(BuildContext context) {
    Navigator.of(context).pop();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Coming soon')));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final String? currentRoute = ModalRoute.of(context)?.settings.name;
    final bool salesSelected =
        currentRoute == AppRoutes.invoices ||
        currentRoute == AppRoutes.createInvoice ||
        currentRoute == AppRoutes.creditNotes ||
        currentRoute == AppRoutes.debitNotes ||
        currentRoute == AppRoutes.quotations;
    if (salesSelected && !_salesExpanded) {
      setState(() => _salesExpanded = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final String? currentRoute = ModalRoute.of(context)?.settings.name;
    final bool dashboardSelected = currentRoute == AppRoutes.dashboard;
    final bool invoicesSelected =
        currentRoute == AppRoutes.invoices ||
        currentRoute == AppRoutes.createInvoice;
    final bool creditNotesSelected = currentRoute == AppRoutes.creditNotes;
    final bool debitNotesSelected = currentRoute == AppRoutes.debitNotes;
    final bool quotationsSelected = currentRoute == AppRoutes.quotations;
    final bool salesSelected =
        invoicesSelected ||
        creditNotesSelected ||
        debitNotesSelected ||
        quotationsSelected;

    return Drawer(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: SafeArea(
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            topRight: Radius.circular(28),
            bottomRight: Radius.circular(28),
          ),
          child: ColoredBox(
            color: const Color(0xFFF5F6FA),
            child: LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                final double hPad = AppResponsive.clamp(
                  AppResponsive.vw(constraints, 5.5),
                  16,
                  22,
                );

                return ListView(
                  padding: EdgeInsets.zero,
                  children: <Widget>[
                    Container(
                      padding: EdgeInsets.fromLTRB(
                        hPad,
                        AppResponsive.clamp(
                          AppResponsive.scaledByHeight(constraints, 26),
                          18,
                          30,
                        ),
                        hPad,
                        AppResponsive.clamp(
                          AppResponsive.scaledByHeight(constraints, 22),
                          16,
                          28,
                        ),
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: <Color>[
                            AppColors.splashTop,
                            AppColors.splashBottom,
                          ],
                        ),
                      ),
                      child: Row(
                        children: <Widget>[
                          CircleAvatar(
                            radius: AppResponsive.clamp(
                              AppResponsive.scaledByHeight(constraints, 22),
                              18,
                              26,
                            ),
                            backgroundColor: Colors.white.withValues(
                              alpha: 0.18,
                            ),
                            child: const Text(
                              'A',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          SizedBox(
                            width: AppResponsive.clamp(
                              AppResponsive.vw(constraints, 3),
                              10,
                              14,
                            ),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  'areesh ali',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: AppResponsive.clamp(
                                      AppResponsive.sp(constraints, 18),
                                      16,
                                      20,
                                    ),
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                SizedBox(
                                  height: AppResponsive.clamp(
                                    AppResponsive.scaledByHeight(
                                      constraints,
                                      8,
                                    ),
                                    6,
                                    10,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.16),
                                    borderRadius: BorderRadius.circular(99),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: <Widget>[
                                      Icon(
                                        Icons.lock_outline,
                                        size: AppResponsive.clamp(
                                          AppResponsive.scaledByHeight(
                                            constraints,
                                            14,
                                          ),
                                          12,
                                          16,
                                        ),
                                        color: Colors.white.withValues(
                                          alpha: 0.90,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        'Admin',
                                        style: TextStyle(
                                          color: Colors.white.withValues(
                                            alpha: 0.92,
                                          ),
                                          fontWeight: FontWeight.w700,
                                          fontSize: AppResponsive.clamp(
                                            AppResponsive.sp(constraints, 12),
                                            11,
                                            13,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                        hPad,
                        AppResponsive.clamp(
                          AppResponsive.scaledByHeight(constraints, 18),
                          14,
                          22,
                        ),
                        hPad,
                        6,
                      ),
                      child: const _SectionTitle('MAIN'),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: hPad),
                      child: _DrawerItem(
                        icon: Icons.dashboard_outlined,
                        label: 'Dashboard',
                        selected: dashboardSelected,
                        onTap: () {
                          Navigator.of(context).pop();
                          Navigator.of(
                            context,
                          ).pushReplacementNamed(AppRoutes.dashboard);
                        },
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: hPad),
                      child: _DrawerItem(
                        icon: Icons.attach_money,
                        label: 'Sales',
                        selected: salesSelected,
                        trailing: _salesExpanded
                            ? Icons.keyboard_arrow_up
                            : Icons.keyboard_arrow_down,
                        onTap: () {
                          setState(() => _salesExpanded = !_salesExpanded);
                        },
                      ),
                    ),
                    if (_salesExpanded)
                      Padding(
                        padding: EdgeInsets.fromLTRB(hPad + 18, 0, hPad, 0),
                        child: _DrawerItem(
                          icon: Icons.receipt_long_outlined,
                          label: 'Invoices',
                          selected: invoicesSelected,
                          onTap: () {
                            Navigator.of(context).pop();
                            if (currentRoute == AppRoutes.invoices) {
                              return;
                            }
                            Navigator.of(
                              context,
                            ).pushReplacementNamed(AppRoutes.invoices);
                          },
                        ),
                      ),
                    if (_salesExpanded)
                      Padding(
                        padding: EdgeInsets.fromLTRB(hPad + 18, 0, hPad, 0),
                        child: _DrawerItem(
                          icon: Icons.note_alt_outlined,
                          label: 'Credit Notes',
                          selected: creditNotesSelected,
                          onTap: () {
                            Navigator.of(context).pop();
                            if (currentRoute == AppRoutes.creditNotes) {
                              return;
                            }
                            Navigator.of(
                              context,
                            ).pushReplacementNamed(AppRoutes.creditNotes);
                          },
                        ),
                      ),
                    if (_salesExpanded)
                      Padding(
                        padding: EdgeInsets.fromLTRB(hPad + 18, 0, hPad, 0),
                        child: _DrawerItem(
                          icon: Icons.note_add_outlined,
                          label: 'Debit Notes',
                          selected: debitNotesSelected,
                          onTap: () {
                            Navigator.of(context).pop();
                            if (currentRoute == AppRoutes.debitNotes) {
                              return;
                            }
                            Navigator.of(
                              context,
                            ).pushReplacementNamed(AppRoutes.debitNotes);
                          },
                        ),
                      ),
                    if (_salesExpanded)
                      Padding(
                        padding: EdgeInsets.fromLTRB(hPad + 18, 0, hPad, 0),
                        child: _DrawerItem(
                          icon: Icons.description_outlined,
                          label: 'Quotations',
                          selected: quotationsSelected,
                          onTap: () {
                            Navigator.of(context).pop();
                            if (currentRoute == AppRoutes.quotations) {
                              return;
                            }
                            Navigator.of(
                              context,
                            ).pushReplacementNamed(AppRoutes.quotations);
                          },
                        ),
                      ),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: hPad),
                      child: _DrawerItem(
                        icon: Icons.inventory_2_outlined,
                        label: 'Products & Services',
                        onTap: () {
                          Navigator.of(context).pop();
                          Navigator.of(
                            context,
                          ).pushReplacementNamed(AppRoutes.products);
                        },
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                        hPad,
                        AppResponsive.clamp(
                          AppResponsive.scaledByHeight(constraints, 22),
                          18,
                          28,
                        ),
                        hPad,
                        6,
                      ),
                      child: const _SectionTitle('MANAGEMENT'),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: hPad),
                      child: _DrawerItem(
                        icon: Icons.groups_outlined,
                        label: 'Customers & Vendors',
                        onTap: () {
                          Navigator.of(context).pop();
                          Navigator.of(
                            context,
                          ).pushReplacementNamed(AppRoutes.customers);
                        },
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: hPad),
                      child: _DrawerItem(
                        icon: Icons.badge_outlined,
                        label: 'Users & Roles',
                        onTap: () => _comingSoon(context),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: hPad),
                      child: _DrawerItem(
                        icon: Icons.settings_outlined,
                        label: 'Business Settings',
                        onTap: () {
                          Navigator.of(context).pop();
                          Navigator.of(context).pushNamed(AppRoutes.settings);
                        },
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                        hPad,
                        AppResponsive.clamp(
                          AppResponsive.scaledByHeight(constraints, 22),
                          18,
                          28,
                        ),
                        hPad,
                        6,
                      ),
                      child: const _SectionTitle('FINANCE'),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: hPad),
                      child: _DrawerItem(
                        icon: Icons.account_balance_outlined,
                        label: 'Accounting',
                        onTap: () => _comingSoon(context),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: hPad),
                      child: _DrawerItem(
                        icon: Icons.bar_chart_outlined,
                        label: 'Reports',
                        onTap: () => _comingSoon(context),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                        hPad,
                        AppResponsive.clamp(
                          AppResponsive.scaledByHeight(constraints, 22),
                          18,
                          28,
                        ),
                        hPad,
                        6,
                      ),
                      child: const _SectionTitle('SUPPORT'),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: hPad),
                      child: _DrawerItem(
                        icon: Icons.logout,
                        label: 'Logout',
                        color: const Color(0xFFD93025),
                        onTap: () {
                          Navigator.of(context).pop();
                          Navigator.of(
                            context,
                          ).pushReplacementNamed(AppRoutes.login);
                        },
                      ),
                    ),
                    SizedBox(
                      height: AppResponsive.clamp(
                        AppResponsive.scaledByHeight(constraints, 18),
                        16,
                        28,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
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
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final IconData? trailing;
  final Color? color;
  final VoidCallback onTap;

  const _DrawerItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.selected = false,
    this.trailing,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final Color baseColor = color ?? const Color(0xFF344055);
    final Color iconColor = selected ? AppColors.primary : baseColor;
    final Color textColor = selected ? AppColors.primary : baseColor;

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: selected ? const Color(0xFFE4E7EF) : Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Row(
              children: <Widget>[
                Icon(icon, color: iconColor, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: textColor,
                      fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                ),
                if (trailing != null)
                  Icon(trailing, color: const Color(0xFF9AA5B6), size: 22),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
