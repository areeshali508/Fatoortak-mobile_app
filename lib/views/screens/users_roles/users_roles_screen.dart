import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../../../app/app_routes.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_responsive.dart';
import '../../../controllers/roles_permissions_controller.dart';
import '../../../models/permission.dart';
import '../../../models/role.dart';

class UsersRolesScreen extends StatelessWidget {
  const UsersRolesScreen({super.key});

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
            title: const Text('Roles & Permissions'),
          ),
          body: SafeArea(
            child: ListView(
              padding: EdgeInsets.fromLTRB(hPad, gap, hPad, gap + 80),
              children: <Widget>[
                _SectionCard(
                  title: 'Roles & Permissions',
                  child: Builder(
                    builder: (BuildContext context) {
                      final RolesPermissionsController ctrl =
                          context.watch<RolesPermissionsController>();

                      final bool showSkeleton =
                          ctrl.isLoading && ctrl.roles.isEmpty;
                      final bool showRefreshingBar = ctrl.isLoading &&
                          (ctrl.roles.isNotEmpty || ctrl.permissions.isNotEmpty);

                      if (ctrl.errorMessage != null &&
                          ctrl.errorMessage!.trim().isNotEmpty &&
                          ctrl.roles.isEmpty) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: <Widget>[
                            Text(
                              ctrl.errorMessage!.trim(),
                              style: const TextStyle(
                                color: Color(0xFF0B1B4B),
                                fontWeight: FontWeight.w700,
                                height: 1.35,
                              ),
                            ),
                            const SizedBox(height: 12),
                            OutlinedButton.icon(
                              onPressed: ctrl.isLoading
                                  ? null
                                  : () => context
                                      .read<RolesPermissionsController>()
                                      .refresh(),
                              icon: const Icon(Icons.refresh),
                              label: const Text('Retry'),
                            ),
                          ],
                        );
                      }

                      return Skeletonizer(
                        enabled: showSkeleton,
                        child: AbsorbPointer(
                          absorbing: showSkeleton,
                          child: Builder(
                            builder: (BuildContext context) {
                              final Role? selectedRole = ctrl.selectedRole;
                              final String roleName =
                                  (selectedRole?.name ?? '').trim().isEmpty
                                      ? '-'
                                      : (selectedRole?.name ?? '').trim();

                              final String moduleName =
                                  (ctrl.selectedModule ?? '').trim().isEmpty
                                      ? '-'
                                      : (ctrl.selectedModule ?? '').trim();

                              final String subModuleName = (ctrl.selectedSubModule ?? '')
                                      .trim()
                                      .isEmpty
                                  ? '-'
                                  : (ctrl.selectedSubModule ?? '').trim();

                              final List<Permission> actions =
                                  ctrl.actionsForSelectedSubModule;

                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: <Widget>[
                                  if (showRefreshingBar)
                                    const Padding(
                                      padding: EdgeInsets.only(bottom: 10),
                                      child: ClipRRect(
                                        borderRadius:
                                            BorderRadius.all(Radius.circular(999)),
                                        child:
                                            LinearProgressIndicator(minHeight: 3),
                                      ),
                                    ),
                                  _DropdownCard(
                                    label: 'Role',
                                    value: roleName,
                                    onTap: () async {
                                      if (ctrl.roles.isEmpty) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text('No roles available'),
                                          ),
                                        );
                                        return;
                                      }

                                      await showModalBottomSheet<void>(
                                        context: context,
                                        showDragHandle: true,
                                        backgroundColor: Colors.white,
                                        shape: const RoundedRectangleBorder(
                                          borderRadius: BorderRadius.vertical(
                                            top: Radius.circular(18),
                                          ),
                                        ),
                                        builder: (BuildContext ctx) {
                                          return SafeArea(
                                            child: ListView(
                                              shrinkWrap: true,
                                              padding: const EdgeInsets.fromLTRB(
                                                18,
                                                6,
                                                18,
                                                18,
                                              ),
                                              children: <Widget>[
                                                const Text(
                                                  'Select Role',
                                                  textAlign: TextAlign.center,
                                                  style: TextStyle(
                                                    color: Color(0xFF0B1B4B),
                                                    fontWeight: FontWeight.w900,
                                                    fontSize: 16,
                                                  ),
                                                ),
                                                const SizedBox(height: 10),
                                                ...ctrl.roles.map((Role r) {
                                                  final bool isSel =
                                                      ctrl.selectedRole?.id == r.id;
                                                  final String name =
                                                      r.name.trim().isEmpty
                                                          ? '-'
                                                          : r.name.trim();
                                                  return ListTile(
                                                    title: Text(
                                                      name,
                                                      style: const TextStyle(
                                                        color: Color(0xFF0B1B4B),
                                                        fontWeight: FontWeight.w800,
                                                      ),
                                                    ),
                                                    subtitle:
                                                        r.description.trim().isEmpty
                                                            ? null
                                                            : Text(
                                                                r.description.trim(),
                                                                style: const TextStyle(
                                                                  color:
                                                                      Color(0xFF6B7895),
                                                                  fontWeight:
                                                                      FontWeight.w700,
                                                                  fontSize: 12,
                                                                ),
                                                              ),
                                                    trailing: Icon(
                                                      isSel
                                                          ? Icons.check_circle
                                                          : Icons.circle_outlined,
                                                      color: isSel
                                                          ? AppColors.primary
                                                          : const Color(0xFF9AA5B6),
                                                    ),
                                                    onTap: () {
                                                      Navigator.of(ctx).pop();
                                                      context
                                                          .read<RolesPermissionsController>()
                                                          .setRole(r);
                                                    },
                                                  );
                                                }),
                                                const SizedBox(height: 10),
                                                OutlinedButton.icon(
                                                  onPressed: () async {
                                                    Navigator.of(ctx).pop();
                                                    final Object? res =
                                                        await Navigator.of(context)
                                                            .pushNamed(AppRoutes.newRole);
                                                    if (res == true &&
                                                        context.mounted) {
                                                      await context
                                                          .read<RolesPermissionsController>()
                                                          .refresh();
                                                    }
                                                  },
                                                  icon: const Icon(
                                                    Icons.add_circle_outline,
                                                  ),
                                                  label:
                                                      const Text('Create New Role'),
                                                ),
                                              ],
                                            ),
                                          );
                                        },
                                      );
                                    },
                                  ),
                                  const SizedBox(height: 12),
                                  _DropdownCard(
                                    label: 'Main Module',
                                    value: moduleName,
                                    onTap: () async {
                                      if (ctrl.modules.isEmpty) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text('No modules available'),
                                          ),
                                        );
                                        return;
                                      }

                                      await showModalBottomSheet<void>(
                                        context: context,
                                        showDragHandle: true,
                                        backgroundColor: Colors.white,
                                        shape: const RoundedRectangleBorder(
                                          borderRadius: BorderRadius.vertical(
                                            top: Radius.circular(18),
                                          ),
                                        ),
                                        builder: (BuildContext ctx) {
                                          return SafeArea(
                                            child: ListView(
                                              shrinkWrap: true,
                                              padding: const EdgeInsets.fromLTRB(
                                                18,
                                                6,
                                                18,
                                                18,
                                              ),
                                              children: <Widget>[
                                                const Text(
                                                  'Select Main Module',
                                                  textAlign: TextAlign.center,
                                                  style: TextStyle(
                                                    color: Color(0xFF0B1B4B),
                                                    fontWeight: FontWeight.w900,
                                                    fontSize: 16,
                                                  ),
                                                ),
                                                const SizedBox(height: 10),
                                                ...ctrl.modules.map((String m) {
                                                  final bool isSel =
                                                      ctrl.selectedModule == m;
                                                  final String name =
                                                      m.trim().isEmpty
                                                          ? '-'
                                                          : m.trim();
                                                  return ListTile(
                                                    title: Text(
                                                      name,
                                                      style: const TextStyle(
                                                        color: Color(0xFF0B1B4B),
                                                        fontWeight: FontWeight.w800,
                                                      ),
                                                    ),
                                                    trailing: Icon(
                                                      isSel
                                                          ? Icons.check_circle
                                                          : Icons.circle_outlined,
                                                      color: isSel
                                                          ? AppColors.primary
                                                          : const Color(0xFF9AA5B6),
                                                    ),
                                                    onTap: () {
                                                      Navigator.of(ctx).pop();
                                                      context
                                                          .read<RolesPermissionsController>()
                                                          .setModule(m);
                                                    },
                                                  );
                                                }),
                                              ],
                                            ),
                                          );
                                        },
                                      );
                                    },
                                  ),
                                  const SizedBox(height: 10),
                                  _DropdownCard(
                                    label: 'Sub Module',
                                    value: subModuleName,
                                    onTap: () async {
                                      if (ctrl.subModules.isEmpty) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text('No sub-modules available'),
                                          ),
                                        );
                                        return;
                                      }

                                      await showModalBottomSheet<void>(
                                        context: context,
                                        showDragHandle: true,
                                        backgroundColor: Colors.white,
                                        shape: const RoundedRectangleBorder(
                                          borderRadius: BorderRadius.vertical(
                                            top: Radius.circular(18),
                                          ),
                                        ),
                                        builder: (BuildContext ctx) {
                                          return SafeArea(
                                            child: ListView(
                                              shrinkWrap: true,
                                              padding: const EdgeInsets.fromLTRB(
                                                18,
                                                6,
                                                18,
                                                18,
                                              ),
                                              children: <Widget>[
                                                const Text(
                                                  'Select Sub Module',
                                                  textAlign: TextAlign.center,
                                                  style: TextStyle(
                                                    color: Color(0xFF0B1B4B),
                                                    fontWeight: FontWeight.w900,
                                                    fontSize: 16,
                                                  ),
                                                ),
                                                const SizedBox(height: 10),
                                                ...ctrl.subModules.map((String s) {
                                                  final bool isSel =
                                                      ctrl.selectedSubModule == s;
                                                  final String name =
                                                      s.trim().isEmpty
                                                          ? '-'
                                                          : s.trim();
                                                  return ListTile(
                                                    title: Text(
                                                      name,
                                                      style: const TextStyle(
                                                        color: Color(0xFF0B1B4B),
                                                        fontWeight: FontWeight.w800,
                                                      ),
                                                    ),
                                                    trailing: Icon(
                                                      isSel
                                                          ? Icons.check_circle
                                                          : Icons.circle_outlined,
                                                      color: isSel
                                                          ? AppColors.primary
                                                          : const Color(0xFF9AA5B6),
                                                    ),
                                                    onTap: () {
                                                      Navigator.of(ctx).pop();
                                                      context
                                                          .read<RolesPermissionsController>()
                                                          .setSubModule(s);
                                                    },
                                                  );
                                                }),
                                              ],
                                            ),
                                          );
                                        },
                                      );
                                    },
                                  ),
                                  Row(
                                    children: <Widget>[
                                      const Expanded(
                                        child: Text(
                                          'Permissions',
                                          style: TextStyle(
                                            color: Color(0xFF0B1B4B),
                                            fontWeight: FontWeight.w900,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ),
                                      TextButton.icon(
                                        onPressed: () async {
                                          final Object? res =
                                              await Navigator.of(context)
                                                  .pushNamed(AppRoutes.newRole);
                                          if (res == true && context.mounted) {
                                            await context
                                                .read<RolesPermissionsController>()
                                                .refresh();
                                          }
                                        },
                                        icon: const Icon(Icons.add, size: 18),
                                        label: const Text('New Role'),
                                        style: TextButton.styleFrom(
                                          foregroundColor: AppColors.primary,
                                          textStyle: const TextStyle(
                                            fontWeight: FontWeight.w900,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (ctrl.permissionsForSelectedRole.isEmpty)
                                    const Text(
                                      'No permissions assigned',
                                      style: TextStyle(
                                        color: Color(0xFF6B7895),
                                        fontWeight: FontWeight.w700,
                                      ),
                                    )
                                  else if (actions.isEmpty)
                                    const Text(
                                      'No permissions in this sub-module',
                                      style: TextStyle(
                                        color: Color(0xFF6B7895),
                                        fontWeight: FontWeight.w700,
                                      ),
                                    )
                                  else
                                    Wrap(
                                      spacing: 10,
                                      runSpacing: 10,
                                      children: actions.map((Permission p) {
                                        final String label = ctrl.actionLabel(p);
                                        return Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 10,
                                          ),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFF7FAFF),
                                            borderRadius:
                                                BorderRadius.circular(999),
                                            border: Border.all(
                                              color: const Color(0xFFE9EEF5),
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: <Widget>[
                                              Container(
                                                width: 18,
                                                height: 18,
                                                decoration: BoxDecoration(
                                                  color: AppColors.primary,
                                                  borderRadius:
                                                      BorderRadius.circular(6),
                                                ),
                                                child: const Icon(
                                                  Icons.check,
                                                  color: Colors.white,
                                                  size: 14,
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                label,
                                                style: const TextStyle(
                                                  color: Color(0xFF0B1B4B),
                                                  fontWeight: FontWeight.w900,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                ],
                              );
                            },
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}


class _DropdownCard extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onTap;

  const _DropdownCard({
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFF7FAFF),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE9EEF5)),
        ),
        child: Row(
          children: <Widget>[
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Text(
                    label,
                    style: const TextStyle(
                      color: Color(0xFF9AA5B6),
                      fontWeight: FontWeight.w800,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value.trim().isEmpty ? '-' : value.trim(),
                    style: const TextStyle(
                      color: Color(0xFF0B1B4B),
                      fontWeight: FontWeight.w900,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.keyboard_arrow_down_rounded,
              color: Color(0xFF6B7895),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _SectionCard({required this.title, required this.child});

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
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF0B1B4B),
              fontWeight: FontWeight.w900,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}
