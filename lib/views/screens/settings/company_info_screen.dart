import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../controllers/companies_controller.dart';
import '../../../core/constants/app_responsive.dart';

class CompanyInfoScreen extends StatefulWidget {
  const CompanyInfoScreen({super.key});

  @override
  State<CompanyInfoScreen> createState() => _CompanyInfoScreenState();
}

class _CompanyInfoScreenState extends State<CompanyInfoScreen> {
  _CompanyStatus? _filter;

  List<Map<String, dynamic>> _applyFilter(
    List<Map<String, dynamic>> companies,
    _CompanyStatus? filter,
  ) {
    if (filter == null) return companies;
    return companies
        .where((Map<String, dynamic> c) => _companyStatusFromJson(c) == filter)
        .toList();
  }

  static String _str(Object? v) => v?.toString().trim() ?? '';

  static _CompanyStatus _companyStatusFromJson(Map<String, dynamic> c) {
    final String status = _str(c['status']).toLowerCase();
    switch (status) {
      case 'active':
        return _CompanyStatus.active;
      case 'inactive':
        return _CompanyStatus.inactive;
      case 'suspended':
        return _CompanyStatus.suspended;
      case 'pending':
        return _CompanyStatus.pending;
      default:
        return _CompanyStatus.active;
    }
  }

  static _ZatcaSeverity _zatcaSeverityFromJson(Map<String, dynamic> c) {
    final Object? creds = c['zatcaCredentials'];
    final String status = creds is Map<String, dynamic>
        ? _str(creds['status']).toLowerCase()
        : _str(c['zatcaStatus']).toLowerCase();

    if (status.contains('expired') || status.contains('rejected') || status.contains('error')) {
      return _ZatcaSeverity.bad;
    }
    if (status.contains('pending') || status.contains('onboarding') || status.contains('required')) {
      return _ZatcaSeverity.warn;
    }
    return _ZatcaSeverity.good;
  }

  static String _zatcaTextFromJson(Map<String, dynamic> c) {
    final Object? creds = c['zatcaCredentials'];
    final String raw = creds is Map<String, dynamic>
        ? _str(creds['status'])
        : _str(c['zatcaStatus']);
    return raw.isEmpty ? 'Not started' : raw;
  }

  static String _taxIdFromJson(Map<String, dynamic> c) {
    return _str(c['taxId']).isNotEmpty
        ? _str(c['taxId'])
        : (_str(c['vatNumber']).isNotEmpty ? _str(c['vatNumber']) : _str(c['vat']));
  }

  static String _locationFromJson(Map<String, dynamic> c) {
    final String city = _str(c['city']);
    final String state = _str(c['state']);
    final String country = _str(c['country']);
    final List<String> parts = <String>[city, state, country]
        .where((String s) => s.trim().isNotEmpty)
        .toList();
    if (parts.isNotEmpty) return parts.join(', ');
    return _str(c['address']);
  }

  static String _nameFromJson(Map<String, dynamic> c) {
    final String name = _str(c['companyName']);
    if (name.isNotEmpty) return name;
    return _str(c['name']);
  }

  static _CompanyItem _toItem(Map<String, dynamic> c) {
    final _CompanyStatus st = _companyStatusFromJson(c);

    String actionText = 'View Details';
    if (st == _CompanyStatus.pending) actionText = 'Complete Setup';
    if (st == _CompanyStatus.suspended) actionText = 'Resolve Issue';

    return _CompanyItem(
      name: _nameFromJson(c).isEmpty ? 'Company' : _nameFromJson(c),
      status: st,
      zatcaStatus: _zatcaTextFromJson(c),
      zatcaSeverity: _zatcaSeverityFromJson(c),
      taxId: _taxIdFromJson(c),
      location: _locationFromJson(c),
      primaryTag: _str(c['isDefault']).toLowerCase() == 'true' ? 'DEFAULT' : null,
      actionText: actionText,
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final CompaniesController ctrl = context.watch<CompaniesController>();

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

        final List<Map<String, dynamic>> visibleCompanyMaps =
            _applyFilter(ctrl.companies, _filter);
        final List<_CompanyItem> visibleCompanies = visibleCompanyMaps
            .map(_toItem)
            .toList();

        return Scaffold(
          backgroundColor: const Color(0xFFF7FAFF),
          appBar: AppBar(
            title: const Text('Companies'),
            leading: const BackButton(),
            actions: <Widget>[
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.notifications_none_outlined),
              ),
            ],
          ),
          body: RefreshIndicator(
            onRefresh: () => context.read<CompaniesController>().refresh(),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.fromLTRB(hPad, sectionGap, hPad, sectionGap),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      const Expanded(
                        child: Text(
                          'Manage and view all your registered\nbusiness entities',
                          style: TextStyle(
                            color: Color(0xFF6B7895),
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            height: 1.25,
                          ),
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: <Widget>[
                          Text(
                            '${ctrl.companies.length}/10',
                            style: const TextStyle(
                              color: Color(0xFF0B1B4B),
                              fontWeight: FontWeight.w900,
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'USED',
                            style: TextStyle(
                              color: Color(0xFF9AA5B6),
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.2,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  SizedBox(height: sectionGap),
                  SizedBox(
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: ctrl.isLoading
                          ? null
                          : () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Add Company is not connected yet'),
                                ),
                              );
                            },
                      icon: const Icon(Icons.add_circle_outline),
                      label: const Text('Add Company'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0A1F6D),
                        foregroundColor: Colors.white,
                        elevation: 10,
                        shadowColor: const Color(0x330A1F6D),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        textStyle: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                    ),
                  ),
                  SizedBox(height: sectionGap),
                  _StatusFilterChips(
                    value: _filter,
                    onChanged: (_CompanyStatus? v) => setState(() => _filter = v),
                  ),
                  SizedBox(height: sectionGap),
                  if (ctrl.isLoading) ...<Widget>[
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.only(top: 18),
                        child: CircularProgressIndicator(),
                      ),
                    ),
                  ] else if ((ctrl.errorMessage ?? '').trim().isNotEmpty) ...<Widget>[
                    _EmptyState(
                      title: 'Failed to load companies',
                      subtitle: ctrl.errorMessage!,
                      actionText: 'Retry',
                      onAction: () => context.read<CompaniesController>().load(),
                    ),
                  ] else if (ctrl.companies.isEmpty) ...<Widget>[
                    _EmptyState(
                      title: 'No companies yet',
                      subtitle: 'Tap Add Company to register your first business entity.',
                      actionText: 'Refresh',
                      onAction: () => context.read<CompaniesController>().load(),
                    ),
                  ] else if (visibleCompanies.isEmpty) ...<Widget>[
                    _EmptyState(
                      title: 'No results',
                      subtitle: 'Try changing the status filter.',
                      actionText: 'Clear filter',
                      onAction: () => setState(() => _filter = null),
                    ),
                  ] else ...<Widget>[
                    for (final _CompanyItem c in visibleCompanies) ...<Widget>[
                      _CompanyCard(item: c, radius: cardRadius),
                      const SizedBox(height: 14),
                    ],
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

enum _CompanyStatus { active, inactive, suspended, pending }

enum _ZatcaSeverity { good, warn, bad }

class _CompanyItem {
  final String name;
  final _CompanyStatus status;
  final String zatcaStatus;
  final _ZatcaSeverity zatcaSeverity;
  final String taxId;
  final String location;
  final String? primaryTag;
  final String actionText;

  const _CompanyItem({
    required this.name,
    required this.status,
    required this.zatcaStatus,
    required this.zatcaSeverity,
    required this.taxId,
    required this.location,
    required this.primaryTag,
    required this.actionText,
  });
}

class _StatusFilterChips extends StatelessWidget {
  final _CompanyStatus? value;
  final ValueChanged<_CompanyStatus?> onChanged;

  const _StatusFilterChips({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: <Widget>[
          _Chip(
            text: 'All Status',
            selected: value == null,
            onTap: () => onChanged(null),
          ),
          const SizedBox(width: 10),
          _Chip(
            text: 'Active',
            selected: value == _CompanyStatus.active,
            onTap: () => onChanged(_CompanyStatus.active),
          ),
          const SizedBox(width: 10),
          _Chip(
            text: 'Inactive',
            selected: value == _CompanyStatus.inactive,
            onTap: () => onChanged(_CompanyStatus.inactive),
          ),
          const SizedBox(width: 10),
          _Chip(
            text: 'Suspended',
            selected: value == _CompanyStatus.suspended,
            onTap: () => onChanged(_CompanyStatus.suspended),
          ),
          const SizedBox(width: 10),
          _Chip(
            text: 'Pending',
            selected: value == _CompanyStatus.pending,
            onTap: () => onChanged(_CompanyStatus.pending),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String text;
  final bool selected;
  final VoidCallback onTap;

  const _Chip({required this.text, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    const Color navy = Color(0xFF0A1F6D);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? navy : Colors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: selected ? navy : const Color(0xFFE9EEF5)),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: selected ? Colors.white : const Color(0xFF0B1B4B),
            fontWeight: FontWeight.w900,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}

class _CompanyCard extends StatelessWidget {
  final _CompanyItem item;
  final double radius;

  const _CompanyCard({required this.item, required this.radius});

  @override
  Widget build(BuildContext context) {
    final Color statusBg;
    final Color statusFg;
    final String statusText;

    switch (item.status) {
      case _CompanyStatus.active:
        statusBg = const Color(0xFFE7F5EC);
        statusFg = const Color(0xFF137333);
        statusText = 'ACTIVE';
      case _CompanyStatus.inactive:
        statusBg = const Color(0xFFF3F6FB);
        statusFg = const Color(0xFF6B7895);
        statusText = 'INACTIVE';
      case _CompanyStatus.suspended:
        statusBg = const Color(0xFFF3F6FB);
        statusFg = const Color(0xFF6B7895);
        statusText = 'SUSPENDED';
      case _CompanyStatus.pending:
        statusBg = const Color(0xFFFFF5E6);
        statusFg = const Color(0xFFB26A00);
        statusText = 'PENDING';
    }

    final Color zatcaDot;
    switch (item.zatcaSeverity) {
      case _ZatcaSeverity.good:
        zatcaDot = const Color(0xFF00B46E);
      case _ZatcaSeverity.warn:
        zatcaDot = const Color(0xFFFF9800);
      case _ZatcaSeverity.bad:
        zatcaDot = const Color(0xFFD93025);
    }

    final Color leftAccent;
    switch (item.status) {
      case _CompanyStatus.active:
        leftAccent = const Color(0xFF0A1F6D);
      case _CompanyStatus.pending:
        leftAccent = const Color(0xFFFF9800);
      case _CompanyStatus.suspended:
        leftAccent = const Color(0xFFD93025);
      case _CompanyStatus.inactive:
        leftAccent = const Color(0xFF9AA5B6);
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x110B1B4B),
            blurRadius: 18,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Container(
              width: 4,
              decoration: BoxDecoration(
                color: leftAccent,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(radius),
                  bottomLeft: Radius.circular(radius),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF3F6FB),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.apartment_outlined,
                            color: Color(0xFF0B1B4B),
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            item.name,
                            style: const TextStyle(
                              color: Color(0xFF0B1B4B),
                              fontWeight: FontWeight.w900,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        DecoratedBox(
                          decoration: BoxDecoration(
                            color: statusBg,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            child: Text(
                              statusText,
                              style: TextStyle(
                                color: statusFg,
                                fontWeight: FontWeight.w900,
                                fontSize: 11,
                                letterSpacing: 0.6,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF7FAFF),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFE9EEF5)),
                      ),
                      child: Row(
                        children: <Widget>[
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(color: zatcaDot, shape: BoxShape.circle),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'ZATCA Status: ${item.zatcaStatus}',
                              style: const TextStyle(
                                color: Color(0xFF0B1B4B),
                                fontWeight: FontWeight.w800,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    _InfoRow(label: 'Tax ID', value: item.taxId),
                    const SizedBox(height: 10),
                    _InfoRow(label: 'Location', value: item.location, icon: Icons.location_on_outlined),
                    const SizedBox(height: 14),
                    Row(
                      children: <Widget>[
                        if (item.primaryTag != null)
                          DecoratedBox(
                            decoration: BoxDecoration(
                              color: const Color(0xFFF3F6FB),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              child: Text(
                                item.primaryTag!,
                                style: const TextStyle(
                                  color: Color(0xFF0B1B4B),
                                  fontWeight: FontWeight.w900,
                                  fontSize: 10,
                                  letterSpacing: 0.6,
                                ),
                              ),
                            ),
                          ),
                        const Spacer(),
                        TextButton(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('${item.actionText} is not connected yet')),
                            );
                          },
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              Text(
                                item.actionText,
                                style: const TextStyle(fontWeight: FontWeight.w900),
                              ),
                              const SizedBox(width: 6),
                              const Icon(Icons.chevron_right, size: 18),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData? icon;

  const _InfoRow({required this.label, required this.value, this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        SizedBox(
          width: 64,
          child: Text(
            label,
            style: const TextStyle(
              color: Color(0xFF9AA5B6),
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
        ),
        if (icon != null) ...<Widget>[
          Icon(icon, size: 16, color: const Color(0xFF9AA5B6)),
          const SizedBox(width: 6),
        ],
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: Color(0xFF0B1B4B),
              fontWeight: FontWeight.w900,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String title;
  final String subtitle;
  final String actionText;
  final VoidCallback onAction;

  const _EmptyState({
    required this.title,
    required this.subtitle,
    required this.actionText,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: Column(
        children: <Widget>[
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF0B1B4B),
              fontWeight: FontWeight.w900,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF6B7895),
              fontWeight: FontWeight.w700,
              fontSize: 13,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 14),
          OutlinedButton(
            onPressed: onAction,
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF0A1F6D),
              side: const BorderSide(color: Color(0xFF0A1F6D), width: 2),
              backgroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 18),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              textStyle: const TextStyle(fontWeight: FontWeight.w900),
            ),
            child: Text(actionText),
          ),
        ],
      ),
    );
  }
}
