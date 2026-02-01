import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../../../app/app_routes.dart';
import '../../../controllers/auth_controller.dart';
import '../../../controllers/invoice_controller.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_responsive.dart';
import '../../../models/invoice.dart';
import '../../layout/app_drawer.dart';
import '../../widgets/buttons/primary_add_fab.dart';
import 'invoice_details_screen.dart';

class InvoicesScreen extends StatefulWidget {
  const InvoicesScreen({super.key});

  @override
  State<InvoicesScreen> createState() => _InvoicesScreenState();
}

class _InvoicesScreenState extends State<InvoicesScreen> {
  int _filterIndex = 0;

  final TextEditingController _searchController = TextEditingController();

  bool _requestedInitialLoad = false;

  Future<void> _reloadInvoices() async {
    final AuthController auth = context.read<AuthController>();
    final Map<String, dynamic>? company = auth.myCompany;
    final String? companyId = (company?['_id'] ?? company?['id'])
        ?.toString()
        .trim();
    final InvoiceController invoiceCtrl = context.read<InvoiceController>();
    await invoiceCtrl.loadInvoices(companyId: companyId);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _reloadInvoices();
      if (!mounted) return;

      final InvoiceController invoiceCtrl = context.read<InvoiceController>();
      if (invoiceCtrl.errorMessage != null &&
          invoiceCtrl.errorMessage!.trim().isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(invoiceCtrl.errorMessage!)),
        );
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showComingSoon() {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Coming soon')));
  }

  Future<void> _openDateFilter() async {
    final InvoiceController invoiceCtrl = context.read<InvoiceController>();
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
            child: SingleChildScrollView(
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
                  if (invoiceCtrl.dateRange != null)
                    _SheetActionTile(
                      label: 'Clear Date Range',
                      onTap: () => Navigator.of(ctx).pop(_DateAction.clear),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );

    if (!mounted || action == null) {
      return;
    }

    if (action == _DateAction.clear) {
      invoiceCtrl.setDateRange(null);
      return;
    }

    final DateTime now = DateTime.now();
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020, 1, 1),
      lastDate: DateTime(now.year + 2, 12, 31),
      initialDateRange: invoiceCtrl.dateRange,
      helpText: 'Select date range',
    );

    if (!mounted || picked == null) {
      return;
    }

    invoiceCtrl.setDateRange(picked);
  }

  Future<void> _openMoreFilters() async {
    final InvoiceController invoiceCtrl = context.read<InvoiceController>();
    final InvoiceStatus? result = await showModalBottomSheet<InvoiceStatus?>(
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
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  const Text(
                    'Invoice Status',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFF0B1B4B),
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (invoiceCtrl.statusFilter != null) ...<Widget>[
                    _StatusOption(
                      label: 'Clear Filter',
                      selected: false,
                      onTap: () {
                        Navigator.of(ctx).pop(InvoiceStatus.none);
                      },
                    ),
                  ],
                  _StatusOption(
                    label: 'Draft',
                    selected: invoiceCtrl.statusFilter == InvoiceStatus.draft,
                    onTap: () {
                      Navigator.of(ctx).pop(
                        invoiceCtrl.statusFilter == InvoiceStatus.draft
                            ? InvoiceStatus.none
                            : InvoiceStatus.draft,
                      );
                    },
                  ),
                  _StatusOption(
                    label: 'Sent',
                    selected: invoiceCtrl.statusFilter == InvoiceStatus.sent,
                    onTap: () {
                      Navigator.of(ctx).pop(
                        invoiceCtrl.statusFilter == InvoiceStatus.sent
                            ? InvoiceStatus.none
                            : InvoiceStatus.sent,
                      );
                    },
                  ),
                  _StatusOption(
                    label: 'Paid',
                    selected: invoiceCtrl.statusFilter == InvoiceStatus.paid,
                    onTap: () {
                      Navigator.of(ctx).pop(
                        invoiceCtrl.statusFilter == InvoiceStatus.paid
                            ? InvoiceStatus.none
                            : InvoiceStatus.paid,
                      );
                    },
                  ),
                  _StatusOption(
                    label: 'Partially Paid',
                    selected: invoiceCtrl.statusFilter ==
                        InvoiceStatus.partiallyPaid,
                    onTap: () {
                      Navigator.of(ctx).pop(
                        invoiceCtrl.statusFilter == InvoiceStatus.partiallyPaid
                            ? InvoiceStatus.none
                            : InvoiceStatus.partiallyPaid,
                      );
                    },
                  ),
                  _StatusOption(
                    label: 'Overdue',
                    selected: invoiceCtrl.statusFilter == InvoiceStatus.overdue,
                    onTap: () {
                      Navigator.of(ctx).pop(
                        invoiceCtrl.statusFilter == InvoiceStatus.overdue
                            ? InvoiceStatus.none
                            : InvoiceStatus.overdue,
                      );
                    },
                  ),
                  _StatusOption(
                    label: 'Cancelled',
                    selected: invoiceCtrl.statusFilter ==
                        InvoiceStatus.cancelled,
                    onTap: () {
                      Navigator.of(ctx).pop(
                        invoiceCtrl.statusFilter == InvoiceStatus.cancelled
                            ? InvoiceStatus.none
                            : InvoiceStatus.cancelled,
                      );
                    },
                  ),
                  _StatusOption(
                    label: 'Void',
                    selected: invoiceCtrl.statusFilter == InvoiceStatus.voided,
                    onTap: () {
                      Navigator.of(ctx).pop(
                        invoiceCtrl.statusFilter == InvoiceStatus.voided
                            ? InvoiceStatus.none
                            : InvoiceStatus.voided,
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    if (!mounted || result == null) {
      return;
    }

    invoiceCtrl.setStatusFilter(result == InvoiceStatus.none ? null : result);
  }

  void _onBottomTap(int index) {
    if (index == 0) {
      Navigator.of(context).pushReplacementNamed(AppRoutes.dashboard);
      return;
    }
    if (index == 1) {
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
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final AuthController auth = context.watch<AuthController>();
        final Map<String, dynamic>? company = auth.myCompany;
        final String? companyId = (company?['_id'] ?? company?['id'])
            ?.toString()
            .trim();

        if (!_requestedInitialLoad && companyId != null && companyId.isNotEmpty) {
          _requestedInitialLoad = true;
          WidgetsBinding.instance.addPostFrameCallback((_) async {
            if (!mounted) return;
            await _reloadInvoices();
          });
        }

        final InvoiceController invoiceCtrl = context
            .watch<InvoiceController>();
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

        final List<Invoice> visibleInvoices = invoiceCtrl.visibleInvoices;
        final bool isLoading = invoiceCtrl.isLoading;

        return Scaffold(
          backgroundColor: const Color(0xFFF7FAFF),
          drawer: const AppDrawer(),
          appBar: AppBar(
            title: const Text('Invoices'),
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
          floatingActionButton: PrimaryAddFab(
            onPressed: () async {
              final ScaffoldMessengerState messenger = ScaffoldMessenger.of(
                context,
              );
              final InvoiceController invCtrl = context
                  .read<InvoiceController>();
              final Object? result = await Navigator.of(
                context,
              ).pushNamed(AppRoutes.createInvoice);

              if (!mounted || result == null || result is! Invoice) {
                return;
              }

              invCtrl.addInvoice(result);

              messenger.showSnackBar(
                SnackBar(
                  content: Text(
                    result.status == InvoiceStatus.draft
                        ? 'Invoice saved as draft'
                        : 'Invoice saved & sent',
                  ),
                ),
              );
            },
          ),
          body: SafeArea(
            child: RefreshIndicator(
              onRefresh: _reloadInvoices,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    _SearchField(
                      constraints: constraints,
                      controller: _searchController,
                      onChanged: (String v) {
                        invoiceCtrl.setSearchQuery(v);
                      },
                    ),
                    SizedBox(height: gap),
                    _FilterRow(
                      constraints: constraints,
                      index: _filterIndex,
                      onChanged: (int i) => setState(() => _filterIndex = i),
                      dateSelected: invoiceCtrl.dateRange != null,
                      onDate: _openDateFilter,
                      moreSelected: invoiceCtrl.statusFilter != null,
                      onMoreFilters: _openMoreFilters,
                    ),
                    SizedBox(height: gap),
                    Skeletonizer(
                      enabled: isLoading,
                      child: AbsorbPointer(
                        absorbing: isLoading,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: isLoading
                              ? List<Widget>.generate(6, (int i) {
                                  return _InvoiceCard(
                                    invoiceNo: '----',
                                    customer: 'Loading',
                                    date: '----',
                                    amount: '----',
                                    status: InvoiceStatus.draft,
                                    onTap: () {},
                                  );
                                })
                              : invoiceCtrl.errorMessage != null &&
                                      invoiceCtrl.errorMessage!
                                          .trim()
                                          .isNotEmpty
                                  ? <Widget>[
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 14,
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.stretch,
                                          children: <Widget>[
                                            Text(
                                              invoiceCtrl.errorMessage!,
                                              textAlign: TextAlign.center,
                                              style: const TextStyle(
                                                color: Color(0xFFD93025),
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                            const SizedBox(height: 12),
                                            ElevatedButton(
                                              onPressed: _reloadInvoices,
                                              child: const Text('Retry'),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ]
                                  : visibleInvoices.isEmpty
                                      ? <Widget>[
                                          const Padding(
                                            padding: EdgeInsets.symmetric(
                                              vertical: 28,
                                            ),
                                            child: Text(
                                              'No invoices found',
                                              textAlign: TextAlign.center,
                                              style: TextStyle(
                                                color: Color(0xFF6B7895),
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ),
                                        ]
                                      : visibleInvoices
                                          .map((Invoice inv) {
                                            return _InvoiceCard(
                                              invoiceNo: inv.invoiceNo,
                                              customer: inv.customer,
                                              date: invoiceCtrl
                                                  .dateLabel(inv.issueDate),
                                              amount:
                                                  invoiceCtrl.amountLabel(inv),
                                              status: inv.status,
                                              onTap: () {
                                                Navigator.of(context).push(
                                                  MaterialPageRoute<void>(
                                                    builder: (_) =>
                                                        InvoiceDetailsScreen(
                                                      invoice: inv,
                                                    ),
                                                  ),
                                                );
                                              },
                                            );
                                          })
                                          .toList(),
                        ),
                      ),
                    ),
                  ],
                ),
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
        hintText: 'Search invoices',
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
  final int index;
  final ValueChanged<int> onChanged;
  final bool dateSelected;
  final VoidCallback onDate;
  final bool moreSelected;
  final VoidCallback onMoreFilters;

  const _FilterRow({
    required this.constraints,
    required this.index,
    required this.onChanged,
    required this.dateSelected,
    required this.onDate,
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
            label: 'All Status',
            selected: index == 0,
            trailing: Icons.keyboard_arrow_down,
            onTap: () => onChanged(0),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _Pill(
            constraints: constraints,
            label: 'Date',
            selected: dateSelected,
            trailing: Icons.keyboard_arrow_down,
            onTap: onDate,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _Pill(
            constraints: constraints,
            label: 'More Filters',
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

enum _DateAction { pick, clear }

class _InvoiceCard extends StatelessWidget {
  final String invoiceNo;
  final String customer;
  final String date;
  final String amount;
  final InvoiceStatus status;
  final VoidCallback onTap;

  const _InvoiceCard({
    required this.invoiceNo,
    required this.customer,
    required this.date,
    required this.amount,
    required this.status,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final (_StatusStyle? style, String text) = _statusStyle(status);

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
                        'Invoice #$invoiceNo',
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    Text(
                      amount,
                      style: const TextStyle(
                        color: Color(0xFF0B1B4B),
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  customer,
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
                    if (style != null)
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

  (_StatusStyle?, String) _statusStyle(InvoiceStatus s) {
    switch (s) {
      case InvoiceStatus.draft:
        return (
          const _StatusStyle(bg: Color(0xFFF3F6FB), fg: Color(0xFF6B7895)),
          'Draft',
        );
      case InvoiceStatus.sent:
        return (
          const _StatusStyle(bg: Color(0xFFE7F1FF), fg: AppColors.primary),
          'Sent',
        );
      case InvoiceStatus.overdue:
        return (
          const _StatusStyle(bg: Color(0xFFFFE7E7), fg: Color(0xFFD93025)),
          'Overdue',
        );
      case InvoiceStatus.paid:
        return (
          const _StatusStyle(bg: Color(0xFFEFFAF3), fg: Color(0xFF1DB954)),
          'Paid',
        );
      case InvoiceStatus.partiallyPaid:
        return (
          const _StatusStyle(bg: Color(0xFFFFF7E6), fg: Color(0xFFB26A00)),
          'Partially Paid',
        );
      case InvoiceStatus.cancelled:
        return (
          const _StatusStyle(bg: Color(0xFFF3F6FB), fg: Color(0xFF6B7895)),
          'Cancelled',
        );
      case InvoiceStatus.voided:
        return (
          const _StatusStyle(bg: Color(0xFFF0F0F0), fg: Color(0xFF111827)),
          'Void',
        );
      case InvoiceStatus.none:
        return (null, '');
    }
  }
}

class _StatusStyle {
  final Color bg;
  final Color fg;

  const _StatusStyle({required this.bg, required this.fg});
}
