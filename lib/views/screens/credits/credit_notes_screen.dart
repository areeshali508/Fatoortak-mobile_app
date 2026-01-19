import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/app_routes.dart';
import '../../../controllers/credit_notes_controller.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_responsive.dart';
import '../../../models/credit_note.dart';
import '../../layout/app_drawer.dart';

class CreditNotesScreen extends StatefulWidget {
  const CreditNotesScreen({super.key});

  @override
  State<CreditNotesScreen> createState() => _CreditNotesScreenState();
}

class _CreditNotesScreenState extends State<CreditNotesScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<CreditNotesController>().refresh();
    });
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
        final CreditNotesController ctrl =
            context.watch<CreditNotesController>();
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
            title: const Text('Credit Notes'),
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
          floatingActionButtonLocation:
              FloatingActionButtonLocation.endFloat,
          floatingActionButton: FloatingActionButton(
            onPressed: () async {
              final ScaffoldMessengerState messenger =
                  ScaffoldMessenger.of(context);
              final CreditNotesController notesCtrl =
                  context.read<CreditNotesController>();
              final Object? result = await Navigator.of(context)
                  .pushNamed(AppRoutes.createCreditNote);

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
            },
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            child: const Icon(Icons.add, size: 26),
          ),
          body: SafeArea(
            child: SingleChildScrollView(
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
                  _StatsGrid(
                    constraints: constraints,
                    totalNotes: ctrl.totalNotesCount.toString(),
                    draft: ctrl.draftCount.toString(),
                    applied: ctrl.appliedCount.toString(),
                    credits: ctrl.creditsLabel,
                  ),
                  SizedBox(height: gap),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          onChanged: ctrl.setSearchQuery,
                          decoration: InputDecoration(
                            hintText: 'Search credit notes...',
                            hintStyle:
                                const TextStyle(color: Color(0xFF9AA5B6)),
                            prefixIcon: const Icon(
                              Icons.search,
                              color: Color(0xFF9AA5B6),
                            ),
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding:
                                const EdgeInsets.symmetric(vertical: 14),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(18),
                              borderSide:
                                  const BorderSide(color: Color(0xFFE9EEF5)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(18),
                              borderSide: const BorderSide(
                                color: AppColors.primary,
                                width: 1.4,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: const Color(0xFFE9EEF5)),
                        ),
                        child: IconButton(
                          onPressed: _showComingSoon,
                          icon: const Icon(
                            Icons.tune,
                            color: Color(0xFF0B1B4B),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: gap),
                  if (ctrl.visibleNotes.isEmpty)
                    _EmptyState(
                      constraints: constraints,
                      onGetStarted: _showComingSoon,
                    )
                  else
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: ctrl.visibleNotes.map((CreditNote n) {
                        return _CreditNoteTile(
                          constraints: constraints,
                          id: n.id,
                          customer: n.customer,
                          amount: '${n.currency} ${n.amount.toStringAsFixed(2)}',
                        );
                      }).toList(),
                    ),
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
                label: 'Clients',
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
  final String totalNotes;
  final String draft;
  final String applied;
  final String credits;

  const _StatsGrid({
    required this.constraints,
    required this.totalNotes,
    required this.draft,
    required this.applied,
    required this.credits,
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
                title: 'Applied',
                value: applied,
                icon: Icons.check_circle,
                iconColor: const Color(0xFF1DB954),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                title: 'Credits',
                value: credits,
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

class _CreditNoteTile extends StatelessWidget {
  final BoxConstraints constraints;
  final String id;
  final String customer;
  final String amount;

  const _CreditNoteTile({
    required this.constraints,
    required this.id,
    required this.customer,
    required this.amount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
              color: const Color(0xFFF3F6FB),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE9EEF5)),
            ),
            child: const Icon(
              Icons.description_outlined,
              color: Color(0xFF6B7895),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  customer,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF0B1B4B),
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  id,
                  style: const TextStyle(
                    color: Color(0xFF9AA5B6),
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Text(
            amount,
            style: const TextStyle(
              color: Color(0xFF0B1B4B),
              fontWeight: FontWeight.w900,
              fontSize: 13,
            ),
          ),
        ],
      ),
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
            'No Credit Notes Yet',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF0B1B4B),
              fontWeight: FontWeight.w900,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Create your first credit note for refunds or\nadjustments to start managing your balance.',
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
