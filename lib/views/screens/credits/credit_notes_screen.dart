import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../../../app/app_routes.dart';
import '../../../controllers/auth_controller.dart';
import '../../../controllers/credit_notes_controller.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_responsive.dart';
import '../../../models/company.dart';
import '../../../models/credit_note.dart';
import '../../layout/app_drawer.dart';
import '../../widgets/buttons/primary_add_fab.dart';
import 'credit_note_details_screen.dart';

class CreditNotesScreen extends StatefulWidget {
  const CreditNotesScreen({super.key});

  @override
  State<CreditNotesScreen> createState() => _CreditNotesScreenState();
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

class _DashboardStatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color iconColor;

  const _DashboardStatCard({
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
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE9EEF5)),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x0A0B1B4B),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F6FB),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF9AA5B6),
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
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
        hintText: 'Search credit notes',
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

class _CreditNotesScreenState extends State<CreditNotesScreen> {
  final TextEditingController _searchController = TextEditingController();

  bool _requestedInitial = false;

  String _companyLabelById(String? id) {
    final String key = (id ?? '').trim();
    if (key.isEmpty) return '';
    try {
      final CreditNotesController ctrl = context.read<CreditNotesController>();
      final Company? c = ctrl.companyById(key);
      final String label = (c?.name ?? key).trim();
      return label.isEmpty ? key : label;
    } catch (_) {
      return key;
    }
  }

  Future<void> _openCompanyPicker() async {
    final CreditNotesController ctrl = context.read<CreditNotesController>();
    if (ctrl.isLoadingCompanies || ctrl.companies.isEmpty) return;

    final String? selected = await showModalBottomSheet<String>(
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
            children: <Widget>[
              const Text(
                'Select Company',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF0B1B4B),
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 10),
              ...ctrl.companies.map((Company c) {
                final bool isSelected = c.id == ctrl.companyId;
                final String label = c.name.trim().isEmpty ? c.id : c.name.trim();

                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Material(
                    color: const Color(0xFFF7FAFF),
                    borderRadius: BorderRadius.circular(14),
                    child: InkWell(
                      onTap: () => Navigator.of(ctx).pop(c.id),
                      borderRadius: BorderRadius.circular(14),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        child: Row(
                          children: <Widget>[
                            Expanded(
                              child: Text(
                                label,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Color(0xFF0B1B4B),
                                  fontWeight: FontWeight.w800,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            Icon(
                              isSelected
                                  ? Icons.radio_button_checked
                                  : Icons.radio_button_off,
                              color: isSelected
                                  ? AppColors.primary
                                  : const Color(0xFF9AA5B6),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        );
      },
    );

    final String next = (selected ?? '').trim();
    if (next.isEmpty || next == (ctrl.companyId ?? '').trim()) return;
    ctrl.setCompanyId(next);
    await ctrl.refresh();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final CreditNotesController ctrl = context.read<CreditNotesController>();
      final AuthController auth = context.read<AuthController>();

      if (!_requestedInitial) {
        _requestedInitial = true;
        final String? activeId = auth.activeCompanyId?.trim();

        if (activeId != null && activeId.isNotEmpty) {
          ctrl.setCompanyId(activeId);
          await Future.wait<void>(<Future<void>>[
            ctrl.loadCompanies(page: 1, limit: 50),
            ctrl.refresh(),
          ]);
          if (!mounted) return;

          final List<Company> companies = ctrl.companies;
          if (companies.isNotEmpty) {
            final Company selected = ctrl.companyById(activeId) ?? companies.first;
            if (selected.id != (ctrl.companyId ?? '').trim()) {
              ctrl.setCompanyId(selected.id);
              await ctrl.refresh();
            }
          }
          return;
        }

        await ctrl.loadCompanies(page: 1, limit: 50);
        final List<Company> companies = ctrl.companies;
        if (companies.isNotEmpty) {
          ctrl.setCompanyId(companies.first.id);
        }
      }

      await ctrl.refresh();
    });
  }

  void _showComingSoon() {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Coming soon')));
  }

  Future<void> _openDateFilter() async {
    final CreditNotesController notesCtrl = context
        .read<CreditNotesController>();
    final _DateAction? action = await showModalBottomSheet<_DateAction>(
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
    final CreditNotesController notesCtrl = context
        .read<CreditNotesController>();
    final CreditNoteStatus?
    result = await showModalBottomSheet<CreditNoteStatus?>(
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
            children: <Widget>[
              const Text(
                'Credit Note Status',
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
                selected: notesCtrl.statusFilter == CreditNoteStatus.draft,
                onTap: () {
                  Navigator.of(ctx).pop(
                    notesCtrl.statusFilter == CreditNoteStatus.draft
                        ? null
                        : CreditNoteStatus.draft,
                  );
                },
              ),
              _StatusOption(
                label: 'Submitted',
                selected: notesCtrl.statusFilter == CreditNoteStatus.submitted,
                onTap: () {
                  Navigator.of(ctx).pop(
                    notesCtrl.statusFilter == CreditNoteStatus.submitted
                        ? null
                        : CreditNoteStatus.submitted,
                  );
                },
              ),
              _StatusOption(
                label: 'Cleared',
                selected: notesCtrl.statusFilter == CreditNoteStatus.cleared,
                onTap: () {
                  Navigator.of(ctx).pop(
                    notesCtrl.statusFilter == CreditNoteStatus.cleared
                        ? null
                        : CreditNoteStatus.cleared,
                  );
                },
              ),
              _StatusOption(
                label: 'Reported',
                selected: notesCtrl.statusFilter == CreditNoteStatus.reported,
                onTap: () {
                  Navigator.of(ctx).pop(
                    notesCtrl.statusFilter == CreditNoteStatus.reported
                        ? null
                        : CreditNoteStatus.reported,
                  );
                },
              ),
              _StatusOption(
                label: 'Rejected',
                selected: notesCtrl.statusFilter == CreditNoteStatus.rejected,
                onTap: () {
                  Navigator.of(ctx).pop(
                    notesCtrl.statusFilter == CreditNoteStatus.rejected
                        ? null
                        : CreditNoteStatus.rejected,
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
    final CreditNotesController notesCtrl = context
        .read<CreditNotesController>();
    final CreditNotePaymentStatus? result =
        await showModalBottomSheet<CreditNotePaymentStatus?>(
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
                    selected: notesCtrl.paymentStatusFilter ==
                        CreditNotePaymentStatus.pending,
                    onTap: () {
                      Navigator.of(ctx).pop(
                        notesCtrl.paymentStatusFilter ==
                                CreditNotePaymentStatus.pending
                            ? null
                            : CreditNotePaymentStatus.pending,
                      );
                    },
                  ),
                  _StatusOption(
                    label: 'Refunded',
                    selected: notesCtrl.paymentStatusFilter ==
                        CreditNotePaymentStatus.refunded,
                    onTap: () {
                      Navigator.of(ctx).pop(
                        notesCtrl.paymentStatusFilter ==
                                CreditNotePaymentStatus.refunded
                            ? null
                            : CreditNotePaymentStatus.refunded,
                      );
                    },
                  ),
                  _StatusOption(
                    label: 'Applied',
                    selected: notesCtrl.paymentStatusFilter ==
                        CreditNotePaymentStatus.applied,
                    onTap: () {
                      Navigator.of(ctx).pop(
                        notesCtrl.paymentStatusFilter ==
                                CreditNotePaymentStatus.applied
                            ? null
                            : CreditNotePaymentStatus.applied,
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

  Future<void> _openCreateCreditNote() async {
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    final CreditNotesController notesCtrl = context
        .read<CreditNotesController>();
    final Object? result = await Navigator.of(
      context,
    ).pushNamed(AppRoutes.createCreditNote);

    if (!mounted || result == null || result is! CreditNote) {
      return;
    }

    await notesCtrl.addCreditNote(result);

    messenger.showSnackBar(
      SnackBar(
        content: Text(
          result.status == CreditNoteStatus.draft
              ? 'Credit note saved as draft'
              : 'Credit note saved',
        ),
      ),
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
        final CreditNotesController ctrl = context
            .watch<CreditNotesController>();
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

        final List<CreditNote> visibleNotes = ctrl.visibleNotes;
        final bool isLoading = ctrl.isLoading;
        final bool isLoadingStats = ctrl.isLoadingStats;
        final bool showSkeleton = isLoading && visibleNotes.isEmpty;
        final bool showRefreshingBar = isLoading && visibleNotes.isNotEmpty;

        return Scaffold(
          backgroundColor: const Color(0xFFF7FAFF),
          drawer: const AppDrawer(),
          appBar: AppBar(
            title: const Text('Credit Notes'),
            bottom: ctrl.companies.isEmpty
                ? null
                : PreferredSize(
                    preferredSize: const Size.fromHeight(66),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                      child: InkWell(
                        onTap: _openCompanyPicker,
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFFE9EEF5)),
                            boxShadow: const <BoxShadow>[
                              BoxShadow(
                                color: Color(0x0A0B1B4B),
                                blurRadius: 10,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            children: <Widget>[
                              Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF2F6FF),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Icons.apartment_rounded,
                                  color: AppColors.primary,
                                  size: 18,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    const Text(
                                      'Company',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: Color(0xFF9AA5B6),
                                        fontWeight: FontWeight.w700,
                                        fontSize: 11,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      _companyLabelById(ctrl.companyId),
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
                              const Icon(
                                Icons.keyboard_arrow_down_rounded,
                                color: Color(0xFF9AA5B6),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
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
          floatingActionButton: PrimaryAddFab(onPressed: _openCreateCreditNote),
          body: SafeArea(
            child: RefreshIndicator(
              onRefresh: ctrl.refresh,
              child: Skeletonizer(
                enabled: showSkeleton,
                child: AbsorbPointer(
                  absorbing: showSkeleton,
                  child: ListView.builder(
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
                    itemCount: () {
                      final int headerCount = 5 + (showRefreshingBar ? 1 : 0);
                      if (showSkeleton) return headerCount + 6;
                      if (visibleNotes.isEmpty) return headerCount + 1;
                      return headerCount + visibleNotes.length;
                    }(),
                    itemBuilder: (BuildContext context, int index) {
                      final List<Widget> header = <Widget>[
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
                        if (showRefreshingBar)
                          const Padding(
                            padding: EdgeInsets.only(bottom: 10),
                            child: ClipRRect(
                              borderRadius:
                                  BorderRadius.all(Radius.circular(999)),
                              child: LinearProgressIndicator(minHeight: 3),
                            ),
                          ),
                        Skeletonizer(
                          enabled: isLoadingStats,
                          child: AbsorbPointer(
                            absorbing: isLoadingStats,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: <Widget>[
                                Row(
                                  children: <Widget>[
                                    Expanded(
                                      child: _DashboardStatCard(
                                        title: 'Total Credit Notes',
                                        value: ctrl.statsTotalNotes.toString(),
                                        icon: Icons.receipt_long_outlined,
                                        iconColor: AppColors.primary,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: _DashboardStatCard(
                                        title: 'Draft',
                                        value: ctrl.statsDraftCount.toString(),
                                        icon: Icons.edit_note,
                                        iconColor: const Color(0xFFF39C12),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: <Widget>[
                                    Expanded(
                                      child: _DashboardStatCard(
                                        title: 'Applied',
                                        value: ctrl.statsAppliedCount.toString(),
                                        icon: Icons.check_circle_outline,
                                        iconColor: const Color(0xFF1DB954),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: _DashboardStatCard(
                                        title: 'Total Credits',
                                        value: ctrl.statsCreditsLabel,
                                        icon:
                                            Icons.account_balance_wallet_outlined,
                                        iconColor: const Color(0xFF6C63FF),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(height: gap),
                      ];

                      if (index < header.length) return header[index];
                      final int i = index - header.length;

                      if (showSkeleton) {
                        return _CreditNoteCard(
                          id: '----',
                          customer: 'Loading',
                          date: '----',
                          amount: '----',
                          status: CreditNoteStatus.draft,
                          onTap: () {},
                        );
                      }

                      if (visibleNotes.isEmpty) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 28),
                          child: Text(
                            'No credit notes found',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Color(0xFF6B7895),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        );
                      }

                      final CreditNote n = visibleNotes[i];
                      return _CreditNoteCard(
                        id: (n.number ?? n.id),
                        customer: n.customer,
                        date: ctrl.dateLabel(n.issueDate),
                        amount: ctrl.amountLabel(n),
                        status: n.status,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => CreditNoteDetailsScreen(note: n),
                            ),
                          );
                        },
                      );
                    },
                  ),
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

class _CreditNoteCard extends StatelessWidget {
  final String id;
  final String customer;
  final String date;
  final String amount;
  final CreditNoteStatus status;
  final VoidCallback onTap;

  const _CreditNoteCard({
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
                        'Credit Note #$id',
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

  (_StatusStyle, String) _statusStyle(CreditNoteStatus s) {
    switch (s) {
      case CreditNoteStatus.draft:
        return (
          const _StatusStyle(bg: Color(0xFFF3F6FB), fg: Color(0xFF6B7895)),
          'Draft',
        );
      case CreditNoteStatus.submitted:
        return (
          const _StatusStyle(bg: Color(0xFFE7F1FF), fg: AppColors.primary),
          'Submitted',
        );
      case CreditNoteStatus.cleared:
        return (
          const _StatusStyle(bg: Color(0xFFEFFAF3), fg: Color(0xFF1DB954)),
          'Cleared',
        );
      case CreditNoteStatus.reported:
        return (
          const _StatusStyle(bg: Color(0xFFEFFAF3), fg: Color(0xFF1DB954)),
          'Reported',
        );
      case CreditNoteStatus.rejected:
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

enum _DateAction { pick, clear }
