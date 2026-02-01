import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/app_routes.dart';
import '../../../controllers/quotations_controller.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_responsive.dart';
import '../../../models/quotation.dart';
import '../../layout/app_drawer.dart';
import '../../widgets/buttons/primary_add_fab.dart';
import 'quotation_details_screen.dart';

class QuotationsScreen extends StatefulWidget {
  const QuotationsScreen({super.key});

  @override
  State<QuotationsScreen> createState() => _QuotationsScreenState();
}

class _SheetActionTile extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _SheetActionTile({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: const Color(0xFFF7FAFF),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    label,
                    style: const TextStyle(
                      color: Color(0xFF0B1B4B),
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                  ),
                ),
                const Icon(Icons.chevron_right, color: Color(0xFF9AA5B6)),
              ],
            ),
          ),
        ),
      ),
    );
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
        hintText: 'Search quotations',
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

class _FilterRow extends StatelessWidget {
  final BoxConstraints constraints;
  final String statusLabel;
  final bool statusSelected;
  final VoidCallback onStatus;
  final String dateLabel;
  final bool dateSelected;
  final VoidCallback onDate;
  final String moreLabel;
  final bool moreSelected;
  final VoidCallback onMoreFilters;

  const _FilterRow({
    required this.constraints,
    required this.statusLabel,
    required this.statusSelected,
    required this.onStatus,
    required this.dateLabel,
    required this.dateSelected,
    required this.onDate,
    required this.moreLabel,
    required this.moreSelected,
    required this.onMoreFilters,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: _Pill(
            constraints: constraints,
            label: statusLabel,
            selected: statusSelected,
            trailing: Icons.keyboard_arrow_down,
            onTap: onStatus,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _Pill(
            constraints: constraints,
            label: dateLabel,
            selected: dateSelected,
            trailing: Icons.keyboard_arrow_down,
            onTap: onDate,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _Pill(
            constraints: constraints,
            label: moreLabel,
            selected: moreSelected,
            trailing: Icons.tune,
            onTap: onMoreFilters,
          ),
        ),
      ],
    );
  }
}

class _StatusOption extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _StatusOption({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: selected ? const Color(0xFFF3F6FB) : const Color(0xFFF7FAFF),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    label,
                    style: const TextStyle(
                      color: Color(0xFF0B1B4B),
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                  ),
                ),
                if (selected)
                  const Icon(
                    Icons.check_circle,
                    color: AppColors.primary,
                    size: 20,
                  )
                else
                  const Icon(
                    Icons.radio_button_unchecked,
                    color: Color(0xFF9AA5B6),
                    size: 20,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final BoxConstraints constraints;
  final String label;
  final bool selected;
  final IconData trailing;
  final VoidCallback onTap;

  const _Pill({
    required this.constraints,
    required this.label,
    required this.selected,
    required this.trailing,
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
          color: selected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? Colors.transparent : const Color(0xFFE9EEF5),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: selected ? Colors.white : const Color(0xFF0B1B4B),
                  fontWeight: FontWeight.w800,
                  fontSize: AppResponsive.clamp(
                    AppResponsive.sp(constraints, 12),
                    11,
                    13,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 6),
            Icon(
              trailing,
              size: 18,
              color: selected ? Colors.white : const Color(0xFF6B7895),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuotationsScreenState extends State<QuotationsScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<QuotationsController>().refresh();
    });
  }

  void _showComingSoon() {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Coming soon')));
  }

  Future<void> _openDateFilter() async {
    final QuotationsController ctrl = context.read<QuotationsController>();
    final _DateAction? action = await showModalBottomSheet<_DateAction>(
      context: context,
      showDragHandle: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (BuildContext ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 6, 18, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                const Text(
                  'Date Range',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFF0B1B4B),
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 10),
                _SheetActionTile(
                  label: 'Select Start to End',
                  onTap: () => Navigator.of(ctx).pop(_DateAction.pick),
                ),
                if (ctrl.dateRange != null)
                  _SheetActionTile(
                    label: 'Clear Date Range',
                    onTap: () => Navigator.of(ctx).pop(_DateAction.clear),
                  ),
              ],
            ),
          ),
        );
      },
    );

    if (!mounted || action == null) {
      return;
    }

    if (action == _DateAction.clear) {
      ctrl.setDateRange(null);
      return;
    }

    final DateTime now = DateTime.now();
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020, 1, 1),
      lastDate: DateTime(now.year + 2, 12, 31),
      initialDateRange: ctrl.dateRange,
      helpText: 'Select date range',
    );

    if (!mounted || picked == null) {
      return;
    }

    ctrl.setDateRange(picked);
  }

  Future<void> _openStatusFilter() async {
    final QuotationsController ctrl = context.read<QuotationsController>();
    final QuotationStatus? result =
        await showModalBottomSheet<QuotationStatus?>(
          context: context,
          showDragHandle: true,
          backgroundColor: Colors.white,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
          ),
          builder: (BuildContext ctx) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 6, 18, 18),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    const Text(
                      'Quotation Status',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFF0B1B4B),
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _StatusOption(
                      label: 'All Status',
                      selected: ctrl.statusFilter == null,
                      onTap: () => Navigator.of(ctx).pop(null),
                    ),
                    _StatusOption(
                      label: 'Draft',
                      selected: ctrl.statusFilter == QuotationStatus.draft,
                      onTap: () {
                        Navigator.of(ctx).pop(
                          ctrl.statusFilter == QuotationStatus.draft
                              ? null
                              : QuotationStatus.draft,
                        );
                      },
                    ),
                    _StatusOption(
                      label: 'Sent',
                      selected: ctrl.statusFilter == QuotationStatus.sent,
                      onTap: () {
                        Navigator.of(ctx).pop(
                          ctrl.statusFilter == QuotationStatus.sent
                              ? null
                              : QuotationStatus.sent,
                        );
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );

    if (!mounted) {
      return;
    }

    ctrl.setStatusFilter(result);
  }

  Future<void> _openOutcomeFilter() async {
    final QuotationsController ctrl = context.read<QuotationsController>();
    final QuotationOutcomeStatus?
    result = await showModalBottomSheet<QuotationOutcomeStatus?>(
      context: context,
      showDragHandle: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (BuildContext ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 6, 18, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                const Text(
                  'Outcome Status',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFF0B1B4B),
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 10),
                _StatusOption(
                  label: 'All Outcomes',
                  selected: ctrl.outcomeStatusFilter == null,
                  onTap: () => Navigator.of(ctx).pop(null),
                ),
                _StatusOption(
                  label: 'Pending',
                  selected:
                      ctrl.outcomeStatusFilter ==
                      QuotationOutcomeStatus.pending,
                  onTap: () {
                    Navigator.of(ctx).pop(
                      ctrl.outcomeStatusFilter == QuotationOutcomeStatus.pending
                          ? null
                          : QuotationOutcomeStatus.pending,
                    );
                  },
                ),
                _StatusOption(
                  label: 'Accepted',
                  selected:
                      ctrl.outcomeStatusFilter ==
                      QuotationOutcomeStatus.accepted,
                  onTap: () {
                    Navigator.of(ctx).pop(
                      ctrl.outcomeStatusFilter ==
                              QuotationOutcomeStatus.accepted
                          ? null
                          : QuotationOutcomeStatus.accepted,
                    );
                  },
                ),
                _StatusOption(
                  label: 'Declined',
                  selected:
                      ctrl.outcomeStatusFilter ==
                      QuotationOutcomeStatus.declined,
                  onTap: () {
                    Navigator.of(ctx).pop(
                      ctrl.outcomeStatusFilter ==
                              QuotationOutcomeStatus.declined
                          ? null
                          : QuotationOutcomeStatus.declined,
                    );
                  },
                ),
                _StatusOption(
                  label: 'Expired',
                  selected:
                      ctrl.outcomeStatusFilter ==
                      QuotationOutcomeStatus.expired,
                  onTap: () {
                    Navigator.of(ctx).pop(
                      ctrl.outcomeStatusFilter == QuotationOutcomeStatus.expired
                          ? null
                          : QuotationOutcomeStatus.expired,
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );

    if (!mounted) {
      return;
    }

    ctrl.setOutcomeStatusFilter(result);
  }

  Future<void> _openCreateQuotation() async {
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    final QuotationsController ctrl = context.read<QuotationsController>();
    final Object? result = await Navigator.of(
      context,
    ).pushNamed(AppRoutes.createQuotation);

    if (!mounted || result == null || result is! Quotation) {
      return;
    }

    await ctrl.addQuotation(result);

    messenger.showSnackBar(
      SnackBar(
        content: Text(
          result.status == QuotationStatus.draft
              ? 'Quotation saved as draft'
              : 'Quotation saved',
        ),
      ),
    );
  }

  void _clearFilters() {
    final QuotationsController ctrl = context.read<QuotationsController>();
    _searchController.clear();
    ctrl.setSearchQuery('');
    ctrl.setDateRange(null);
    ctrl.setStatusFilter(null);
    ctrl.setOutcomeStatusFilter(null);
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
    _showComingSoon();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final QuotationsController ctrl = context.watch<QuotationsController>();
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
            title: const Text('Quotations'),
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
                            color: Color(0xFFE53935),
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
          floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
          floatingActionButton: PrimaryAddFab(onPressed: _openCreateQuotation),
          body: SafeArea(
            child: RefreshIndicator(
              onRefresh: ctrl.refresh,
              child: ListView(
                padding: EdgeInsets.fromLTRB(
                  hPad,
                  gap,
                  hPad,
                  AppResponsive.clamp(
                    AppResponsive.scaledByHeight(constraints, 110),
                    100,
                    140,
                  ),
                ),
                children: <Widget>[
                  _StatsGrid(
                    constraints: constraints,
                    total: ctrl.totalQuotationsCount.toString(),
                    draft: ctrl.draftCount.toString(),
                    sent: ctrl.sentCount.toString(),
                    amount: ctrl.quotationsLabel,
                  ),
                  SizedBox(height: gap),
                  _SearchField(
                    constraints: constraints,
                    controller: _searchController,
                    onChanged: ctrl.setSearchQuery,
                  ),
                  SizedBox(height: gap),
                  _FilterRow(
                    constraints: constraints,
                    statusLabel: ctrl.statusFilterLabel,
                    statusSelected: ctrl.statusFilter != null,
                    onStatus: _openStatusFilter,
                    dateLabel: ctrl.dateRangeLabel,
                    dateSelected: ctrl.dateRange != null,
                    onDate: _openDateFilter,
                    moreLabel: ctrl.outcomeStatusFilterLabel,
                    moreSelected: ctrl.outcomeStatusFilter != null,
                    onMoreFilters: _openOutcomeFilter,
                  ),
                  SizedBox(height: gap),
                  if (ctrl.isLoading && ctrl.quotations.isEmpty)
                    const Padding(
                      padding: EdgeInsets.only(top: 28),
                      child: Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primary,
                        ),
                      ),
                    )
                  else if (ctrl.visibleQuotations.isEmpty &&
                      (ctrl.searchQuery.isNotEmpty ||
                          ctrl.dateRange != null ||
                          ctrl.statusFilter != null ||
                          ctrl.outcomeStatusFilter != null))
                    _NoResultsState(onClear: _clearFilters)
                  else if (ctrl.visibleQuotations.isEmpty)
                    _EmptyState(
                      constraints: constraints,
                      onGetStarted: _openCreateQuotation,
                    )
                  else
                    ...ctrl.visibleQuotations.map((Quotation q) {
                      return _QuotationCard(
                        id: q.id,
                        customer: q.customer,
                        date: ctrl.dateLabel(q.issueDate),
                        amount: ctrl.amountLabel(q),
                        status: q.status,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) =>
                                  QuotationDetailsScreen(quotation: q),
                            ),
                          );
                        },
                      );
                    }),
                ],
              ),
            ),
          ),
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: 1,
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

class _StatsGrid extends StatelessWidget {
  final BoxConstraints constraints;
  final String total;
  final String draft;
  final String sent;
  final String amount;

  const _StatsGrid({
    required this.constraints,
    required this.total,
    required this.draft,
    required this.sent,
    required this.amount,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: _StatCard(
                title: 'Total',
                value: total,
                icon: Icons.description_outlined,
                iconColor: const Color(0xFF9AA5B6),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                title: 'Draft',
                value: draft,
                icon: Icons.access_time,
                iconColor: const Color(0xFF9AA5B6),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: <Widget>[
            Expanded(
              child: _StatCard(
                title: 'Sent',
                value: sent,
                icon: Icons.send,
                iconColor: AppColors.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                title: 'Amount',
                value: amount,
                icon: Icons.trending_up,
                iconColor: AppColors.primary,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _QuotationCard extends StatelessWidget {
  final String id;
  final String customer;
  final String date;
  final String amount;
  final QuotationStatus status;
  final VoidCallback onTap;

  const _QuotationCard({
    required this.id,
    required this.customer,
    required this.date,
    required this.amount,
    required this.status,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final (_StatusStyle style, String text) = _statusStyle(status);

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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        'Quotation #$id',
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    Flexible(
                      child: Text(
                        amount,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                          color: Color(0xFF0B1B4B),
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  customer,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF0B1B4B),
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        date,
                        style: const TextStyle(
                          color: Color(0xFF9AA5B6),
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: style.bg,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        text,
                        style: TextStyle(
                          color: style.fg,
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  (_StatusStyle, String) _statusStyle(QuotationStatus s) {
    switch (s) {
      case QuotationStatus.draft:
        return (
          const _StatusStyle(bg: Color(0xFFF3F6FB), fg: Color(0xFF6B7895)),
          'Draft',
        );
      case QuotationStatus.sent:
        return (
          const _StatusStyle(bg: Color(0xFFE7F1FF), fg: AppColors.primary),
          'Sent',
        );
    }
  }
}

class _StatusStyle {
  final Color bg;
  final Color fg;

  const _StatusStyle({required this.bg, required this.fg});
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color iconColor;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.iconColor,
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
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF6B7895),
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
              ),
              Icon(icon, color: iconColor, size: 18),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              color: const Color(0xFF0B1B4B),
              fontWeight: FontWeight.w900,
              fontSize: value.startsWith('SAR') ? 18 : 22,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final BoxConstraints constraints;
  final VoidCallback onGetStarted;

  const _EmptyState({required this.constraints, required this.onGetStarted});

  @override
  Widget build(BuildContext context) {
    final double circle = AppResponsive.clamp(
      AppResponsive.scaledByHeight(constraints, 120),
      92,
      140,
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 22),
      decoration: BoxDecoration(
        color: const Color(0xFFF7FAFF),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        children: <Widget>[
          Container(
            width: circle,
            height: circle,
            decoration: const BoxDecoration(
              color: Color(0xFFEDEBFF),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Icon(
                Icons.description_outlined,
                color: Color(0xFF8A7CFF),
                size: 44,
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'No Quotations Yet',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF0B1B4B),
              fontWeight: FontWeight.w900,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Create your first quotation to share pricing\nwith customers and track outcomes.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF6B7895),
              fontWeight: FontWeight.w700,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: onGetStarted,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEDEBFF),
              foregroundColor: AppColors.primary,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(999),
              ),
              textStyle: const TextStyle(fontWeight: FontWeight.w900),
            ),
            child: const Text('Get Started'),
          ),
        ],
      ),
    );
  }
}

class _NoResultsState extends StatelessWidget {
  final VoidCallback onClear;

  const _NoResultsState({required this.onClear});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 18),
      decoration: BoxDecoration(
        color: const Color(0xFFF7FAFF),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE9EEF5)),
      ),
      child: Column(
        children: <Widget>[
          const Text(
            'No results found',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF0B1B4B),
              fontWeight: FontWeight.w900,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Try changing your search or filters.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF6B7895),
              fontWeight: FontWeight.w700,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 14),
          OutlinedButton(
            onPressed: onClear,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: Color(0xFFE9EEF5)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(999),
              ),
              textStyle: const TextStyle(fontWeight: FontWeight.w900),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            ),
            child: const Text('Clear Filters'),
          ),
        ],
      ),
    );
  }
}

enum _DateAction { pick, clear }
