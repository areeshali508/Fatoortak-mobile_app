import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_responsive.dart';
import '../../../models/permission.dart';
import '../../../repositories/permission_repository.dart';
import '../../../repositories/role_repository.dart';

class NewRoleScreen extends StatefulWidget {
  const NewRoleScreen({super.key});

  @override
  State<NewRoleScreen> createState() => _NewRoleScreenState();
}

class _NewRoleScreenState extends State<NewRoleScreen> {
  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _descCtrl = TextEditingController();

  bool _requested = false;
  bool _loading = false;
  bool _submitting = false;
  String? _error;

  List<Permission> _permissions = const <Permission>[];
  String _selectedCategory = 'All';
  final Set<String> _selectedPermissionIds = <String>{};

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_requested) return;
    _requested = true;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await _loadPermissions();
    });
  }

  Future<void> _loadPermissions() async {
    if (_loading) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final PermissionRepository repo = context.read<PermissionRepository>();
      final List<Permission> list = await repo.listAll();
      if (!mounted) return;
      setState(() {
        _permissions = list.where((Permission p) => p.isActive).toList();
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _permissions = const <Permission>[];
        _error = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  void _togglePermission(String id) {
    setState(() {
      if (_selectedPermissionIds.contains(id)) {
        _selectedPermissionIds.remove(id);
      } else {
        _selectedPermissionIds.add(id);
      }
    });
  }

  Future<void> _submit() async {
    if (_submitting) return;

    final String name = _nameCtrl.text.trim();
    final String desc = _descCtrl.text.trim();
    final List<String> ids = _selectedPermissionIds
        .map((String s) => s.trim())
        .where((String s) => s.isNotEmpty)
        .toList();

    if (name.isEmpty) {
      setState(() {
        _error = 'Role name is required';
      });
      return;
    }

    if (ids.isEmpty) {
      setState(() {
        _error = 'Please select at least one permission';
      });
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      final RoleRepository repo = context.read<RoleRepository>();
      await repo.registerCreatedByMe(
        name: name,
        description: desc,
        permissionIds: ids,
      );

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _submitting = false;
        });
      }
    }
  }

  List<String> get _categories {
    final Set<String> set = <String>{};
    for (final Permission p in _permissions) {
      final String c = p.category.trim();
      if (c.isNotEmpty) set.add(c);
    }
    final List<String> list = set.toList()..sort();
    return <String>['All', ...list];
  }

  List<Permission> get _filteredPermissions {
    if (_selectedCategory == 'All') return _permissions;
    return _permissions
        .where((Permission p) => p.category.trim() == _selectedCategory)
        .toList();
  }

  Map<String, Map<String, List<Permission>>> get _grouped {
    return _groupByModuleAndResource(_filteredPermissions);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
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
          appBar: AppBar(
            title: const Text('New Role'),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            actions: <Widget>[
              TextButton(
                onPressed: (_loading || _submitting) ? null : _submit,
                child: const Text(
                  'Create',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
              const SizedBox(width: 6),
            ],
          ),
          body: SafeArea(
            child: ListView(
              padding: EdgeInsets.fromLTRB(hPad, gap, hPad, gap),
              children: <Widget>[
                _InfoCard(
                  title: 'Role Info',
                  icon: Icons.badge_outlined,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      const Text(
                        'Role Name*',
                        style: TextStyle(
                          color: Color(0xFF0B1B4B),
                          fontWeight: FontWeight.w900,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _nameCtrl,
                        decoration: InputDecoration(
                          hintText: 'e.g. Senior Accountant',
                          filled: true,
                          fillColor: const Color(0xFFF7FAFF),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(
                              color: Color(0xFFE9EEF5),
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(
                              color: Color(0xFFE9EEF5),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        'Description',
                        style: TextStyle(
                          color: Color(0xFF0B1B4B),
                          fontWeight: FontWeight.w900,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _descCtrl,
                        maxLines: 3,
                        decoration: InputDecoration(
                          hintText: 'Describe the responsibilities...',
                          filled: true,
                          fillColor: const Color(0xFFF7FAFF),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(
                              color: Color(0xFFE9EEF5),
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(
                              color: Color(0xFFE9EEF5),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: <Widget>[
                    const Expanded(
                      child: Text(
                        'Permissions',
                        style: TextStyle(
                          color: Color(0xFF0B1B4B),
                          fontWeight: FontWeight.w900,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF2FF),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: const Text(
                        'Step 2 of 2',
                        style: TextStyle(
                          color: Color(0xFF2F3A8F),
                          fontWeight: FontWeight.w900,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 38,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _categories.length,
                    separatorBuilder: (BuildContext context, int index) =>
                        const SizedBox(width: 8),
                    itemBuilder: (BuildContext context, int index) {
                      final String c = _categories[index];
                      final bool selected = _selectedCategory == c;
                      return ChoiceChip(
                        label: Text(c),
                        selected: selected,
                        onSelected: (_) {
                          setState(() => _selectedCategory = c);
                        },
                        selectedColor: AppColors.primary,
                        labelStyle: TextStyle(
                          color: selected ? Colors.white : const Color(0xFF0B1B4B),
                          fontWeight: FontWeight.w800,
                        ),
                        backgroundColor: Colors.white,
                        side: const BorderSide(color: Color(0xFFE9EEF5)),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 10),
                if (_loading)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 18),
                      child: SizedBox(
                        width: 26,
                        height: 26,
                        child: CircularProgressIndicator(strokeWidth: 2.5),
                      ),
                    ),
                  )
                else if (_error != null && _error!.trim().isNotEmpty)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      Text(
                        _error!.trim(),
                        style: const TextStyle(
                          color: Color(0xFF0B1B4B),
                          fontWeight: FontWeight.w700,
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 10),
                      OutlinedButton.icon(
                        onPressed: _loadPermissions,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry'),
                      ),
                    ],
                  )
                else
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: _grouped.entries.map((entry) {
                      final String module = entry.key;
                      final Map<String, List<Permission>> resources = entry.value;
                      final int total = resources.values.fold<int>(
                        0,
                        (int a, List<Permission> b) => a + b.length,
                      );

                      return _ModuleDrawer(
                        title: module,
                        subtitle: '$total permissions',
                        children: resources.entries.map((resEntry) {
                          final String resource = resEntry.key;
                          final List<Permission> actions = resEntry.value;
                          final int selected = actions
                              .where((Permission p) =>
                                  _selectedPermissionIds.contains(p.id))
                              .length;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _ResourceSelectCard(
                              title: resource,
                              module: module,
                              actions: actions,
                              selectedCount: selected,
                              onToggle: (String id) => _togglePermission(id),
                              isSelected: (String id) =>
                                  _selectedPermissionIds.contains(id),
                            ),
                          );
                        }).toList(),
                      );
                    }).toList(),
                  ),
                const SizedBox(height: 16),
                _BestPracticeCard(
                  title: 'Best Practice',
                  body:
                      "Limit 'Delete' permissions to admin roles to maintain data integrity and prevent accidental data loss.",
                ),
                const SizedBox(height: 16),
                _PreviewCard(
                  selectedCount: _selectedPermissionIds.length,
                  totalCount: _permissions.length,
                  categoryCount: _selectedCategory == 'All' ? _categories.length - 1 : 1,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

Map<String, Map<String, List<Permission>>> _groupByModuleAndResource(
  List<Permission> permissions,
) {
  final Map<String, Map<String, List<Permission>>> out =
      <String, Map<String, List<Permission>>>{};

  for (final Permission p in permissions) {
    final String module = p.category.trim().isEmpty ? 'General' : p.category.trim();
    final String resource = _permissionResource(p);

    out.putIfAbsent(module, () => <String, List<Permission>>{});
    out[module]!.putIfAbsent(resource, () => <Permission>[]);
    out[module]![resource]!.add(p);
  }

  return out;
}

String _permissionResource(Permission p) {
  final String ident = p.identifier.trim();
  if (ident.contains('.')) {
    final List<String> parts = ident
        .split('.')
        .map((String s) => s.trim())
        .where((String s) => s.isNotEmpty)
        .toList();
    if (parts.length >= 2) {
      return _titleCase(parts[parts.length - 2]);
    }
  }

  final String n = p.name.trim();
  if (n.isNotEmpty) return n;
  return 'Permissions';
}

String _permissionAction(Permission p) {
  final String ident = p.identifier.trim();
  if (ident.contains('.')) {
    final List<String> parts = ident
        .split('.')
        .map((String s) => s.trim())
        .where((String s) => s.isNotEmpty)
        .toList();
    if (parts.isNotEmpty) {
      return _titleCase(parts.last);
    }
  }

  final String n = p.name.trim();
  return n.isEmpty ? '-' : n;
}

String _titleCase(String raw) {
  final String s = raw.trim();
  if (s.isEmpty) return '-';
  if (s.length == 1) return s.toUpperCase();
  return '${s[0].toUpperCase()}${s.substring(1)}';
}

class _ModuleDrawer extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<Widget> children;

  const _ModuleDrawer({
    required this.title,
    required this.subtitle,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF7FAFF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE9EEF5)),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        collapsedShape:
            const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        title: Text(
          title.trim().isEmpty ? '-' : title.trim(),
          style: const TextStyle(
            color: Color(0xFF0B1B4B),
            fontWeight: FontWeight.w900,
            fontSize: 13,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(
            color: Color(0xFF6B7895),
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
        ),
        children: children,
      ),
    );
  }
}

class _ResourceSelectCard extends StatelessWidget {
  final String title;
  final String module;
  final List<Permission> actions;
  final int selectedCount;
  final ValueChanged<String> onToggle;
  final bool Function(String id) isSelected;

  const _ResourceSelectCard({
    required this.title,
    required this.module,
    required this.actions,
    required this.selectedCount,
    required this.onToggle,
    required this.isSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
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
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF2FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.list_alt_outlined,
                  color: Color(0xFF0B1B4B),
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Text(
                      title.trim().isEmpty ? '-' : title.trim(),
                      style: const TextStyle(
                        color: Color(0xFF0B1B4B),
                        fontWeight: FontWeight.w900,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${module.trim().isEmpty ? '-' : module.trim()} Module',
                      style: const TextStyle(
                        color: Color(0xFF6B7895),
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF2FF),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  actions.isEmpty ? '0/0' : '$selectedCount/${actions.length}',
                  style: const TextStyle(
                    color: Color(0xFF2F3A8F),
                    fontWeight: FontWeight.w900,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              final double gap = 10;
              final double itemW = (constraints.maxWidth - gap) / 2;

              return Wrap(
                spacing: gap,
                runSpacing: gap,
                children: actions.map((Permission p) {
                  final bool sel = isSelected(p.id);
                  final String label = _permissionAction(p);

                  return SizedBox(
                    width: itemW,
                    child: InkWell(
                      onTap: () => onToggle(p.id),
                      borderRadius: BorderRadius.circular(999),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF7FAFF),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: sel
                                ? AppColors.primary
                                : const Color(0xFFE9EEF5),
                          ),
                        ),
                        child: Row(
                          children: <Widget>[
                            Container(
                              width: 18,
                              height: 18,
                              decoration: BoxDecoration(
                                color: sel
                                    ? AppColors.primary
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: sel
                                      ? AppColors.primary
                                      : const Color(0xFF9AA5B6),
                                ),
                              ),
                              child: sel
                                  ? const Icon(
                                      Icons.check,
                                      color: Colors.white,
                                      size: 14,
                                    )
                                  : null,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                label,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Color(0xFF0B1B4B),
                                  fontWeight: FontWeight.w900,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const _InfoCard({
    required this.title,
    required this.icon,
    required this.child,
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
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF2FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: const Color(0xFF0B1B4B), size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF0B1B4B),
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _BestPracticeCard extends StatelessWidget {
  final String title;
  final String body;

  const _BestPracticeCard({required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF1E7),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFFFE0CC)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Icon(Icons.info_outline, color: Color(0xFFCC5A00)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFFCC5A00),
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  body,
                  style: const TextStyle(
                    color: Color(0xFFCC5A00),
                    fontWeight: FontWeight.w700,
                    height: 1.3,
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

class _PreviewCard extends StatelessWidget {
  final int selectedCount;
  final int totalCount;
  final int categoryCount;

  const _PreviewCard({
    required this.selectedCount,
    required this.totalCount,
    required this.categoryCount,
  });

  @override
  Widget build(BuildContext context) {
    final double progress = totalCount == 0 ? 0 : selectedCount / totalCount;

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
              const Expanded(
                child: Text(
                  'Role Preview',
                  style: TextStyle(
                    color: Color(0xFF0B1B4B),
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF2FF),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '${(progress * 100).round()}% Complete',
                  style: const TextStyle(
                    color: Color(0xFF2F3A8F),
                    fontWeight: FontWeight.w900,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    const Text(
                      'TOTAL PERMISSIONS',
                      style: TextStyle(
                        color: Color(0xFF9AA5B6),
                        fontWeight: FontWeight.w900,
                        fontSize: 10,
                        letterSpacing: 0.4,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$selectedCount / $totalCount',
                      style: const TextStyle(
                        color: Color(0xFF0B1B4B),
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    const Text(
                      'CATEGORIES',
                      style: TextStyle(
                        color: Color(0xFF9AA5B6),
                        fontWeight: FontWeight.w900,
                        fontSize: 10,
                        letterSpacing: 0.4,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      categoryCount.toString(),
                      style: const TextStyle(
                        color: Color(0xFF0B1B4B),
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: const Color(0xFFEFF2FF),
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}
