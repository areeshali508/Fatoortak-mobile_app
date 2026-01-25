import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/app_routes.dart';
import '../../../controllers/debit_notes_controller.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_responsive.dart';
import '../../../models/debit_note.dart';
import '../../layout/app_drawer.dart';
import 'debit_note_details_screen.dart';

enum _DateAction { pick, clear }

class DebitNotesScreen extends StatefulWidget {
  const DebitNotesScreen({super.key});

  @override
  State<DebitNotesScreen> createState() => _DebitNotesScreenState();
}

class _DebitNotesScreenState extends State<DebitNotesScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<DebitNotesController>().refresh();
    });
  }

  void _showComingSoon() {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Coming soon')));
  }

  Future<void> _openDateFilter() async {
    final DebitNotesController notesCtrl = context.read<DebitNotesController>();
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
                if (notesCtrl.dateRange != null)
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
      notesCtrl.setDateRange(null);
      return;
    }

    final DateTime now = DateTime.now();
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020, 1, 1),
      lastDate: DateTime(now.year + 2, 12, 31),
      initialDateRange: notesCtrl.dateRange,
      helpText: 'Select date range',
    );

    if (!mounted || picked == null) {
      return;
    }

    notesCtrl.setDateRange(picked);
  }

  Future<void> _openStatusFilter() async {
    final DebitNotesController notesCtrl = context.read<DebitNotesController>();
    final DebitNoteStatus?
    result = await showModalBottomSheet<DebitNoteStatus?>(
      context: context,
      showDragHandle: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (BuildContext ctx) {
        return SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 6, 18, 18),
            shrinkWrap: true,
            children: <Widget>[
              const Text(
                'Debit Note Status',
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
                selected: notesCtrl.statusFilter == null,
                onTap: () => Navigator.of(ctx).pop(null),
              ),
              _StatusOption(
                label: 'Draft',
                selected: notesCtrl.statusFilter == DebitNoteStatus.draft,
                onTap: () {
                  Navigator.of(ctx).pop(
                    notesCtrl.statusFilter == DebitNoteStatus.draft
                        ? null
                        : DebitNoteStatus.draft,
                  );
                },
              ),
              _StatusOption(
                label: 'Submitted',
                selected: notesCtrl.statusFilter == DebitNoteStatus.submitted,
                onTap: () {
                  Navigator.of(ctx).pop(
                    notesCtrl.statusFilter == DebitNoteStatus.submitted
                        ? null
                        : DebitNoteStatus.submitted,
                  );
                },
              ),
              _StatusOption(
                label: 'Cleared',
                selected: notesCtrl.statusFilter == DebitNoteStatus.cleared,
                onTap: () {
                  Navigator.of(ctx).pop(
                    notesCtrl.statusFilter == DebitNoteStatus.cleared
                        ? null
                        : DebitNoteStatus.cleared,
                  );
                },
              ),
              _StatusOption(
                label: 'Reported',
                selected: notesCtrl.statusFilter == DebitNoteStatus.reported,
                onTap: () {
                  Navigator.of(ctx).pop(
                    notesCtrl.statusFilter == DebitNoteStatus.reported
                        ? null
                        : DebitNoteStatus.reported,
                  );
                },
              ),
              _StatusOption(
                label: 'Rejected',
                selected: notesCtrl.statusFilter == DebitNoteStatus.rejected,
                onTap: () {
                  Navigator.of(ctx).pop(
                    notesCtrl.statusFilter == DebitNoteStatus.rejected
                        ? null
                        : DebitNoteStatus.rejected,
                  );
                },
              ),
            ],
          ),
        );
      },
    );

    if (!mounted) {
      return;
    }

    notesCtrl.setStatusFilter(result);
  }

  Future<void> _openPaymentStatusFilter() async {
    final DebitNotesController notesCtrl = context.read<DebitNotesController>();
    final DebitNotePaymentStatus? result =
        await showModalBottomSheet<DebitNotePaymentStatus?>(
          context: context,
          showDragHandle: true,
          backgroundColor: Colors.white,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
          ),
          builder: (BuildContext ctx) {
            return SafeArea(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(18, 6, 18, 18),
                shrinkWrap: true,
                children: <Widget>[
                  const Text(
                    'Payment Status',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFF0B1B4B),
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _StatusOption(
                    label: 'All Payment Status',
                    selected: notesCtrl.paymentStatusFilter == null,
                    onTap: () => Navigator.of(ctx).pop(null),
                  ),
                  _StatusOption(
                    label: 'Pending',
                    selected:
                        notesCtrl.paymentStatusFilter ==
                        DebitNotePaymentStatus.pending,
                    onTap: () {
                      Navigator.of(ctx).pop(
                        notesCtrl.paymentStatusFilter ==
                                DebitNotePaymentStatus.pending
                            ? null
                            : DebitNotePaymentStatus.pending,
                      );
                    },
                  ),
                  _StatusOption(
                    label: 'Paid',
                    selected:
                        notesCtrl.paymentStatusFilter ==
                        DebitNotePaymentStatus.paid,
                    onTap: () {
                      Navigator.of(ctx).pop(
                        notesCtrl.paymentStatusFilter ==
                                DebitNotePaymentStatus.paid
                            ? null
                            : DebitNotePaymentStatus.paid,
                      );
                    },
                  ),
                  _StatusOption(
                    label: 'Cancelled',
                    selected:
                        notesCtrl.paymentStatusFilter ==
                        DebitNotePaymentStatus.cancelled,
                    onTap: () {
                      Navigator.of(ctx).pop(
                        notesCtrl.paymentStatusFilter ==
                                DebitNotePaymentStatus.cancelled
                            ? null
                            : DebitNotePaymentStatus.cancelled,
                      );
                    },
                  ),
                ],
              ),
            );
          },
        );

    if (!mounted) {
      return;
    }

    notesCtrl.setPaymentStatusFilter(result);
  }

  Future<void> _openCreateDebitNote() async {
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    final DebitNotesController notesCtrl = context.read<DebitNotesController>();
    final Object? result = await Navigator.of(
      context,
    ).pushNamed(AppRoutes.createDebitNote);

    if (!mounted || result == null || result is! DebitNote) {
      return;
    }

    await notesCtrl.addDebitNote(result);

    messenger.showSnackBar(
      SnackBar(
        content: Text(
          result.status == DebitNoteStatus.draft
              ? 'Debit note saved as draft'
              : 'Debit note saved',
        ),
      ),
    );
  }

  void _clearFilters() {
    final DebitNotesController ctrl = context.read<DebitNotesController>();
    _searchController.clear();
    ctrl.setSearchQuery('');
    ctrl.setDateRange(null);
    ctrl.setStatusFilter(null);
    ctrl.setPaymentStatusFilter(null);
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
        final DebitNotesController ctrl = context.watch<DebitNotesController>();
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
            title: const Text('Debit Notes'),
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
          floatingActionButton: FloatingActionButton(
            onPressed: _openCreateDebitNote,
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            child: const Icon(Icons.add, size: 26),
          ),
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
                    totalNotes: ctrl.totalNotesCount.toString(),
                    draft: ctrl.draftCount.toString(),
                    clearedOrReported: ctrl.clearedOrReportedCount.toString(),
                    debits: ctrl.debitsLabel,
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
                    moreLabel: ctrl.paymentStatusFilterLabel,
                    moreSelected: ctrl.paymentStatusFilter != null,
                    onMoreFilters: _openPaymentStatusFilter,
                  ),
                  SizedBox(height: gap),
                  if (ctrl.isLoading && ctrl.notes.isEmpty)
                    const Padding(
                      padding: EdgeInsets.only(top: 28),
                      child: Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primary,
                        ),
                      ),
                    )
                  else if (ctrl.visibleNotes.isEmpty &&
                      (ctrl.searchQuery.isNotEmpty ||
                          ctrl.dateRange != null ||
                          ctrl.statusFilter != null ||
                          ctrl.paymentStatusFilter != null))
                    _NoResultsState(onClear: _clearFilters)
                  else if (ctrl.visibleNotes.isEmpty)
                    _EmptyState(
                      constraints: constraints,
                      onGetStarted: _openCreateDebitNote,
                    )
                  else
                    ...ctrl.visibleNotes.map((DebitNote n) {
                      return _DebitNoteCard(
                        id: n.id,
                        customer: n.customer,
                        date: ctrl.dateLabel(n.issueDate),
                        amount: ctrl.amountLabel(n),
                        status: n.status,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => DebitNoteDetailsScreen(note: n),
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
        hintText: 'Search debit notes',
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

class _StatsGrid extends StatelessWidget {
  final BoxConstraints constraints;
  final String totalNotes;
  final String draft;
  final String clearedOrReported;
  final String debits;

  const _StatsGrid({
    required this.constraints,
    required this.totalNotes,
    required this.draft,
    required this.clearedOrReported,
    required this.debits,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: _StatCard(
                title: 'Total Notes',
                value: totalNotes,
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
                title: 'Cleared/Reported',
                value: clearedOrReported,
                icon: Icons.check_circle,
                iconColor: const Color(0xFF1DB954),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                title: 'Debits',
                value: debits,
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

class _DebitNoteCard extends StatelessWidget {
  final String id;
  final String customer;
  final String date;
  final String amount;
  final DebitNoteStatus status;
  final VoidCallback onTap;

  const _DebitNoteCard({
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
                        'Debit Note #$id',
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

  (_StatusStyle, String) _statusStyle(DebitNoteStatus s) {
    switch (s) {
      case DebitNoteStatus.draft:
        return (
          const _StatusStyle(bg: Color(0xFFF3F6FB), fg: Color(0xFF6B7895)),
          'Draft',
        );
      case DebitNoteStatus.submitted:
        return (
          const _StatusStyle(bg: Color(0xFFE7F1FF), fg: AppColors.primary),
          'Submitted',
        );
      case DebitNoteStatus.cleared:
        return (
          const _StatusStyle(bg: Color(0xFFEFFAF3), fg: Color(0xFF1DB954)),
          'Cleared',
        );
      case DebitNoteStatus.reported:
        return (
          const _StatusStyle(bg: Color(0xFFEFFAF3), fg: Color(0xFF1DB954)),
          'Reported',
        );
      case DebitNoteStatus.rejected:
        return (
          const _StatusStyle(bg: Color(0xFFFFE7E7), fg: Color(0xFFD93025)),
          'Rejected',
        );
    }
  }
}

class _StatusStyle {
  final Color bg;
  final Color fg;

  const _StatusStyle({required this.bg, required this.fg});
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
            decoration: BoxDecoration(
              color: const Color(0xFFEDEBFF),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Icon(
                Icons.receipt_long,
                color: Color(0xFF8A7CFF),
                size: 44,
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'No Debit Notes Yet',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF0B1B4B),
              fontWeight: FontWeight.w900,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Create your first debit note for extra charges or\nadjustments to start managing your balance.',
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
