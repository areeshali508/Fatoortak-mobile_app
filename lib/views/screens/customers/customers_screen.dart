import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../../../app/app_routes.dart';
import '../../../controllers/auth_controller.dart';
import '../../../controllers/customer_controller.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_responsive.dart';
import '../../../models/customer.dart';
import '../../layout/app_drawer.dart';
import '../../widgets/buttons/primary_add_fab.dart';

class CustomersScreen extends StatefulWidget {
  const CustomersScreen({super.key});

  @override
  State<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends State<CustomersScreen> {
  int _filterIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final AuthController auth = context.read<AuthController>();
      final Map<String, dynamic>? company = auth.myCompany;
      final String? companyId =
          (company?['_id'] ?? company?['id'])?.toString().trim();
      if (companyId == null || companyId.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Company not loaded')),
        );
        return;
      }
      context.read<CustomerController>().refresh(companyId: companyId);
    });
  }

  void _comingSoon() {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Coming soon')));
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
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final CustomerController ctrl = context.watch<CustomerController>();
        final bool isLoading = ctrl.isLoading;

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

        final List<_CustomerVM> customers = isLoading
            ? List<_CustomerVM>.generate(
                6,
                (int i) => const _CustomerVM(
                  name: 'Loading',
                  company: '----',
                  active: true,
                  vip: true,
                  ytdAmount: 0,
                ),
              )
            : ctrl.customers
                .asMap()
                .entries
                .map(
                  (MapEntry<int, Customer> e) =>
                      _CustomerVM.fromCustomer(customer: e.value, index: e.key),
                )
                .where((_CustomerVM c) {
                  switch (_filterIndex) {
                    case 1:
                      return c.vip;
                    case 2:
                      return c.active;
                    case 3:
                      return !c.active;
                    default:
                      return true;
                  }
                })
                .toList();

        return Scaffold(
          backgroundColor: const Color(0xFFF7FAFF),
          drawer: const AppDrawer(),
          appBar: AppBar(
            title: const Text('Customers'),
            leading: Builder(
              builder: (BuildContext context) {
                return IconButton(
                  icon: const Icon(Icons.menu),
                  onPressed: () => Scaffold.of(context).openDrawer(),
                );
              },
            ),
            actions: <Widget>[
              IconButton(
                onPressed: _comingSoon,
                icon: const Icon(Icons.download_rounded),
              ),
              IconButton(
                onPressed: _comingSoon,
                icon: const Icon(Icons.search),
              ),
              IconButton(onPressed: _comingSoon, icon: const Icon(Icons.add)),
            ],
          ),
          body: SafeArea(
            child: Padding(
              padding: EdgeInsets.fromLTRB(hPad, gap, hPad, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: <Widget>[
                        _FilterChip(
                          constraints: constraints,
                          label: 'All',
                          selected: _filterIndex == 0,
                          onTap: () => setState(() => _filterIndex = 0),
                        ),
                        const SizedBox(width: 10),
                        _FilterChip(
                          constraints: constraints,
                          label: 'VIP',
                          selected: _filterIndex == 1,
                          onTap: () => setState(() => _filterIndex = 1),
                        ),
                        const SizedBox(width: 10),
                        _FilterChip(
                          constraints: constraints,
                          label: 'Active',
                          selected: _filterIndex == 2,
                          onTap: () => setState(() => _filterIndex = 2),
                        ),
                        const SizedBox(width: 10),
                        _FilterChip(
                          constraints: constraints,
                          label: 'Inactive',
                          selected: _filterIndex == 3,
                          onTap: () => setState(() => _filterIndex = 3),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: gap),
                  Expanded(
                    child: Skeletonizer(
                      enabled: isLoading,
                      child: AbsorbPointer(
                        absorbing: isLoading,
                        child: customers.isEmpty
                            ? const Center(
                                child: Text(
                                  'No customers',
                                  style: TextStyle(
                                    color: Color(0xFF9AA5B6),
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              )
                            : ListView.builder(
                                padding: EdgeInsets.only(bottom: gap + 110),
                                itemCount: customers.length,
                                itemBuilder: (BuildContext context, int i) {
                                  final _CustomerVM c = customers[i];
                                  return _CustomerCard(
                                    customer: c,
                                    onTap: _comingSoon,
                                  );
                                },
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          floatingActionButton: SizedBox(
            child: PrimaryAddFab(onPressed: _comingSoon),
          ),
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: 2,
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

class _FilterChip extends StatelessWidget {
  final BoxConstraints constraints;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.constraints,
    required this.label,
    required this.selected,
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
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : const Color(0xFF6B7895),
            fontWeight: FontWeight.w700,
            fontSize: AppResponsive.clamp(
              AppResponsive.sp(constraints, 12),
              11,
              13,
            ),
          ),
        ),
      ),
    );
  }
}

class _CustomerCard extends StatelessWidget {
  final _CustomerVM customer;
  final VoidCallback onTap;

  const _CustomerCard({required this.customer, required this.onTap});

  @override
  Widget build(BuildContext context) {
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
            child: Row(
              children: <Widget>[
                CircleAvatar(
                  radius: 22,
                  backgroundColor: customer.avatarBg,
                  child: Text(
                    customer.initials,
                    style: const TextStyle(
                      color: Color(0xFF0B1B4B),
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        customer.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF0B1B4B),
                          fontWeight: FontWeight.w900,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: <Widget>[
                          if (customer.active)
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Color(0xFF1DB954),
                                shape: BoxShape.circle,
                              ),
                            ),
                          if (customer.active) const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              customer.company,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Color(0xFF6B7895),
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: <Widget>[
                    Text(
                      customer.ytdAmountLabel,
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'YTD',
                      style: TextStyle(
                        color: Color(0xFF9AA5B6),
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
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
}

class _CustomerVM {
  final String name;
  final String company;
  final bool active;
  final bool vip;
  final double ytdAmount;

  const _CustomerVM({
    required this.name,
    required this.company,
    required this.active,
    required this.vip,
    required this.ytdAmount,
  });

  factory _CustomerVM.fromCustomer({
    required Customer customer,
    required int index,
  }) {
    final bool vip = index % 4 == 1;
    final bool active = index % 3 != 2;

    final List<String> sampleCompanies = <String>[
      'Tech Solutions Ltd',
      'Retail Group',
      'Individual',
      'Creative Agency',
      'Logistics Co.',
    ];

    final double ytd = <double>[45.2, 12.4, 3.1, 8.9, 21.5][index % 5] * 1000;

    return _CustomerVM(
      name: customer.name,
      company: sampleCompanies[index % sampleCompanies.length],
      active: active,
      vip: vip,
      ytdAmount: ytd,
    );
  }

  String get initials {
    final List<String> parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((String p) => p.isNotEmpty)
        .toList();
    if (parts.isEmpty) {
      return 'C';
    }
    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }
    return (parts[0].substring(0, 1) + parts[1].substring(0, 1)).toUpperCase();
  }

  Color get avatarBg {
    const List<Color> palette = <Color>[
      Color(0xFFFFE1C6),
      Color(0xFFFFD6D6),
      Color(0xFFE6F0FF),
      Color(0xFFEAF7EE),
      Color(0xFFEDEBFF),
    ];
    return palette[name.length % palette.length];
  }

  String get ytdAmountLabel {
    final double v = ytdAmount;
    if (v >= 1000) {
      final double k = v / 1000;
      return 'SAR ${k.toStringAsFixed(1)}K';
    }
    return 'SAR ${v.toStringAsFixed(0)}';
  }
}
