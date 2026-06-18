import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../../../app/app_routes.dart';
import '../../../controllers/users_controller.dart';
import '../../../core/constants/app_responsive.dart';
import '../../../models/user_model.dart';
import '../../layout/app_drawer.dart';
import '../../widgets/buttons/primary_add_fab.dart';

class TeamMembersScreen extends StatefulWidget {
  const TeamMembersScreen({super.key});

  @override
  State<TeamMembersScreen> createState() => _TeamMembersScreenState();
}

class _TeamMembersScreenState extends State<TeamMembersScreen> {
  bool _requestedInitial = false;
  final TextEditingController _searchCtrl = TextEditingController();
  String _query = '';

  // PERF: debounce timer to avoid setState on every keystroke
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      final String next = _searchCtrl.text;
      if (next == _query || !mounted) return;
      setState(() {
        _query = next;
      });
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.removeListener(_onSearchChanged);
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _reload() async {
    await context.read<UsersController>().refresh();
  }

  Future<void> _openAddUser() async {
    final Object? res = await Navigator.of(context).pushNamed(
      AppRoutes.addNewUser,
    );
    if (!mounted) return;

    if (res == true) {
      await _reload();
    }
  }

  Future<void> _previewUser(UserModel u) async {
    await showModalBottomSheet<void>(
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
                Row(
                  children: <Widget>[
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: const Color(0xFFE6F0FF),
                      child: Text(
                        u.initials,
                        style: const TextStyle(
                          color: Color(0xFF0B1B4B),
                          fontWeight: FontWeight.w900,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          Text(
                            u.fullName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xFF0B1B4B),
                              fontWeight: FontWeight.w900,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            u.roleName.trim().isEmpty ? '-' : u.roleName.trim(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xFF6B7895),
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: u.isActive
                            ? const Color(0xFFEFFAF3)
                            : const Color(0xFFFFE7E7),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        u.isActive ? 'ACTIVE' : 'INACTIVE',
                        style: TextStyle(
                          color: u.isActive
                              ? const Color(0xFF1DB954)
                              : const Color(0xFFFF3B30),
                          fontWeight: FontWeight.w900,
                          fontSize: 11,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _PreviewRow(label: 'Email', value: u.email.trim()),
                const SizedBox(height: 10),
                _PreviewRow(label: 'Phone', value: u.phone.trim()),
                const SizedBox(height: 10),
                _PreviewRow(label: 'Role', value: u.roleName.trim()),
                const SizedBox(height: 10),
                _PreviewRow(label: 'User ID', value: u.id.trim()),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Close'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _editUser(UserModel u) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Coming soon')),
    );
  }

  Future<void> _deleteUser(UserModel u) async {
    final bool? ok = await showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) {
        return AlertDialog(
          title: const Text('Delete user'),
          content: Text(
            'Delete ${u.fullName}?',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (!mounted || ok != true) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Coming soon')),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_requestedInitial) return;
    _requestedInitial = true;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final UsersController ctrl = context.read<UsersController>();
      if (!ctrl.isLoading && ctrl.users.isEmpty && ctrl.errorMessage == null) {
        await ctrl.load();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        // PERF: select only what we need — avoids rebuilding the whole screen on unrelated changes
        final bool isLoading = context.select<UsersController, bool>(
          (UsersController c) => c.isLoading,
        );
        final List<UserModel> users = context.select<UsersController, List<UserModel>>(
          (UsersController c) => c.users,
        );
        final String? errorMessage = context.select<UsersController, String?>(
          (UsersController c) => c.errorMessage,
        );
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

        final bool showSkeleton = isLoading && users.isEmpty;
        final bool showRefreshingBar = isLoading && users.isNotEmpty;
        final bool showError =
            errorMessage != null && errorMessage.trim().isNotEmpty;

        final String q = _query.trim().toLowerCase();
        final List<UserModel> filteredUsers = q.isEmpty
            ? users
            : users.where((UserModel u) {
                final String name = u.fullName.toLowerCase();
                final String email = u.email.toLowerCase();
                final String role = u.roleName.toLowerCase();
                final String phone = u.phone.toLowerCase();
                return name.contains(q) ||
                    email.contains(q) ||
                    role.contains(q) ||
                    phone.contains(q);
              }).toList();

        return Scaffold(
          backgroundColor: const Color(0xFFF7FAFF),
          drawer: const AppDrawer(),
          appBar: AppBar(
            title: const Text('Add Users'),
            leading: Builder(
              builder: (BuildContext context) {
                return IconButton(
                  icon: const Icon(Icons.menu),
                  onPressed: () => Scaffold.of(context).openDrawer(),
                );
              },
            ),
          ),
          floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
          floatingActionButton: PrimaryAddFab(onPressed: _openAddUser),
          body: SafeArea(
            child: RefreshIndicator(
              onRefresh: _reload,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.fromLTRB(
                  hPad,
                  gap,
                  hPad,
                  gap + 90,
                ),
                children: <Widget>[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE9EEF5)),
                    ),
                    child: Row(
                      children: <Widget>[
                        const Icon(
                          Icons.search,
                          color: Color(0xFF9AA5B6),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: _searchCtrl,
                            textInputAction: TextInputAction.search,
                            decoration: const InputDecoration(
                              hintText: 'Search users',
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                        if (_query.trim().isNotEmpty)
                          IconButton(
                            onPressed: () => _searchCtrl.clear(),
                            icon: const Icon(
                              Icons.close,
                              color: Color(0xFF9AA5B6),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (showRefreshingBar)
                    const Padding(
                      padding: EdgeInsets.only(bottom: 10),
                      child: ClipRRect(
                        borderRadius: BorderRadius.all(Radius.circular(999)),
                        child: LinearProgressIndicator(minHeight: 3),
                      ),
                    ),
                  _SectionCard(
                    title: 'Team Members',
                    child: Builder(
                      builder: (BuildContext context) {
                        if (showError && users.isEmpty) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: <Widget>[
                              Text(
                                errorMessage.trim(),
                                style: const TextStyle(
                                  color: Color(0xFF0B1B4B),
                                  fontWeight: FontWeight.w700,
                                  height: 1.35,
                                ),
                              ),
                              const SizedBox(height: 12),
                              OutlinedButton.icon(
                                onPressed: isLoading ? null : _reload,
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
                                if (users.isEmpty && !showSkeleton) {
                                  return Column(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: <Widget>[
                                      const Text(
                                        'No users found',
                                        style: TextStyle(
                                          color: Color(0xFF0B1B4B),
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      OutlinedButton.icon(
                                        onPressed: _openAddUser,
                                        icon: const Icon(
                                          Icons.person_add_alt_1_outlined,
                                        ),
                                        label: const Text('Add your first user'),
                                      ),
                                    ],
                                  );
                                }

                                if (filteredUsers.isEmpty && !showSkeleton) {
                                  return Column(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: <Widget>[
                                      const Text(
                                        'No results',
                                        style: TextStyle(
                                          color: Color(0xFF0B1B4B),
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      OutlinedButton.icon(
                                        onPressed: () => _searchCtrl.clear(),
                                        icon: const Icon(Icons.close),
                                        label: const Text('Clear search'),
                                      ),
                                    ],
                                  );
                                }

                                final List<Widget> tiles = <Widget>[];
                                final int count = showSkeleton ? 6 : filteredUsers.length;
                                for (int i = 0; i < count; i++) {
                                  final UserModel u = showSkeleton
                                      ? UserModel(
                                          id: '----',
                                          firstName: 'Loading',
                                          lastName: 'User',
                                          email: 'loading@example.com',
                                          phone: '----',
                                          roleName: 'Loading',
                                          roleId: '----',
                                          isActive: true,
                                        )
                                      : filteredUsers[i];

                                  tiles.add(
                                    _UserTile(
                                      initials: u.initials,
                                      name: u.fullName,
                                      email: u.email.trim().isEmpty
                                          ? '-'
                                          : u.email.trim(),
                                      role: u.roleName.trim().isEmpty
                                          ? '-'
                                          : u.roleName.trim(),
                                      active: u.isActive,
                                      onAction: (_UserAction a) {
                                        if (showSkeleton) return;
                                        if (a == _UserAction.preview) {
                                          _previewUser(u);
                                          return;
                                        }
                                        if (a == _UserAction.edit) {
                                          _editUser(u);
                                          return;
                                        }
                                        if (a == _UserAction.delete) {
                                          _deleteUser(u);
                                          return;
                                        }
                                      },
                                    ),
                                  );
                                  if (i != count - 1) {
                                    tiles.add(const SizedBox(height: 10));
                                  }
                                }

                                return Column(children: tiles);
                              },
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  if (showError && users.isNotEmpty) ...<Widget>[
                    const SizedBox(height: 12),
                    Text(
                      errorMessage.trim(),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Color(0xFFD93025),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
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

enum _UserAction { preview, edit, delete }

class _UserTile extends StatelessWidget {
  final String initials;
  final String name;
  final String email;
  final String role;
  final bool active;
  final ValueChanged<_UserAction> onAction;

  const _UserTile({
    required this.initials,
    required this.name,
    required this.email,
    required this.role,
    required this.active,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final Color badgeBg = active ? const Color(0xFFEFFAF3) : const Color(0xFFFFE7E7);
    final Color badgeText =
        active ? const Color(0xFF1DB954) : const Color(0xFFFF3B30);

    return Material(
      color: const Color(0xFFF7FAFF),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: () => onAction(_UserAction.preview),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE9EEF5)),
          ),
          child: Row(
            children: <Widget>[
              CircleAvatar(
                radius: 22,
                backgroundColor: const Color(0xFFE6F0FF),
                child: Text(
                  initials,
                  style: const TextStyle(
                    color: Color(0xFF0B1B4B),
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Text(
                      name,
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
                      '$role • $email',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF6B7895),
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: badgeBg,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  active ? 'ACTIVE' : 'INACTIVE',
                  style: TextStyle(
                    color: badgeText,
                    fontWeight: FontWeight.w900,
                    fontSize: 11,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              PopupMenuButton<_UserAction>(
                onSelected: onAction,
                icon: const Icon(
                  Icons.more_vert,
                  color: Color(0xFF9AA5B6),
                ),
                itemBuilder: (BuildContext context) {
                  return <PopupMenuEntry<_UserAction>>[
                    const PopupMenuItem<_UserAction>(
                      value: _UserAction.preview,
                      child: Text('Preview'),
                    ),
                    const PopupMenuItem<_UserAction>(
                      value: _UserAction.edit,
                      child: Text('Edit'),
                    ),
                    const PopupMenuItem<_UserAction>(
                      value: _UserAction.delete,
                      child: Text('Delete'),
                    ),
                  ];
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PreviewRow extends StatelessWidget {
  final String label;
  final String value;

  const _PreviewRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final String v = value.trim().isEmpty ? '-' : value.trim();
    return Row(
      children: <Widget>[
        SizedBox(
          width: 90,
          child: Text(
            label,
            style: const TextStyle(
              color: Color(0xFF9AA5B6),
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            v,
            style: const TextStyle(
              color: Color(0xFF0B1B4B),
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }
}
