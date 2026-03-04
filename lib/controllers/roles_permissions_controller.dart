import 'package:flutter/material.dart';

import '../models/permission.dart';
import '../models/role.dart';
import '../repositories/permission_repository.dart';
import '../repositories/role_repository.dart';

class RolesPermissionsController extends ChangeNotifier {
  final RoleRepository _roleRepository;
  final PermissionRepository _permissionRepository;

  bool _isLoading = false;
  String? _errorMessage;

  List<Role> _roles = const <Role>[];
  List<Permission> _permissions = const <Permission>[];

  Role? _selectedRole;

  String? _selectedModule;
  String? _selectedSubModule;

  RolesPermissionsController({
    required RoleRepository roleRepository,
    required PermissionRepository permissionRepository,
  })  : _roleRepository = roleRepository,
        _permissionRepository = permissionRepository;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  List<Role> get roles => _roles;
  List<Permission> get permissions => _permissions;

  Role? get selectedRole => _selectedRole;

  String? get selectedModule => _selectedModule;
  String? get selectedSubModule => _selectedSubModule;

  Future<void> loadInitial() async {
    if (_isLoading) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final List<dynamic> res = await Future.wait<dynamic>(<Future<dynamic>>[
        _roleRepository.listCreatedByMe(),
        _permissionRepository.listAll(),
      ]);

      _roles = (res[0] as List<Role>).where((Role r) => r.isActive).toList();
      _permissions =
          (res[1] as List<Permission>).where((Permission p) => p.isActive).toList();

      if (_selectedRole == null && _roles.isNotEmpty) {
        _selectedRole = _roles.first;
      }

      _ensureDefaults();
    } catch (e) {
      _roles = const <Role>[];
      _permissions = const <Permission>[];
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refresh() async {
    _selectedRole = null;
    _selectedModule = null;
    _selectedSubModule = null;
    await loadInitial();
  }

  void setRole(Role role) {
    _selectedRole = role;
    _selectedModule = null;
    _selectedSubModule = null;
    _ensureDefaults();
    notifyListeners();
  }

  void setModule(String module) {
    _selectedModule = module;
    _selectedSubModule = null;
    _ensureDefaults();
    notifyListeners();
  }

  void setSubModule(String subModule) {
    _selectedSubModule = subModule;
    notifyListeners();
  }

  List<Permission> get permissionsForSelectedRole {
    final Set<String> ids = _selectedRole?.permissionIds.toSet() ?? <String>{};
    if (ids.isEmpty) return const <Permission>[];

    return _permissions.where((Permission p) => ids.contains(p.id)).toList();
  }

  Map<String, Map<String, List<Permission>>> get groupedPermissions {
    return _groupByModuleAndSubModule(permissionsForSelectedRole);
  }

  List<String> get modules {
    final List<String> list = groupedPermissions.keys.toList()..sort();
    return list;
  }

  List<String> get subModules {
    final String module = _selectedModule ?? '';
    final Map<String, List<Permission>>? map = groupedPermissions[module];
    if (map == null) return const <String>[];
    final List<String> list = map.keys.toList()..sort();
    return list;
  }

  List<Permission> get actionsForSelectedSubModule {
    final String module = _selectedModule ?? '';
    final String sub = _selectedSubModule ?? '';
    final Map<String, List<Permission>>? map = groupedPermissions[module];
    if (map == null) return const <Permission>[];
    final List<Permission>? list = map[sub];
    if (list == null) return const <Permission>[];
    return List<Permission>.from(list);
  }

  void _ensureDefaults() {
    final Map<String, Map<String, List<Permission>>> grouped = groupedPermissions;
    if (grouped.isEmpty) {
      _selectedModule = null;
      _selectedSubModule = null;
      return;
    }

    final List<String> moduleKeys = grouped.keys.toList()..sort();
    final String firstModule = moduleKeys.first;
    if (_selectedModule == null || !grouped.containsKey(_selectedModule)) {
      _selectedModule = firstModule;
    }

    final Map<String, List<Permission>>? resMap = grouped[_selectedModule];
    final List<String> subKeys = (resMap?.keys.toList() ?? <String>[])..sort();
    if (subKeys.isEmpty) {
      _selectedSubModule = null;
      return;
    }
    final String firstSub = subKeys.first;
    if (_selectedSubModule == null || !(resMap?.containsKey(_selectedSubModule) ?? false)) {
      _selectedSubModule = firstSub;
    }
  }

  Map<String, Map<String, List<Permission>>> _groupByModuleAndSubModule(
    List<Permission> permissions,
  ) {
    final Map<String, Map<String, List<Permission>>> out =
        <String, Map<String, List<Permission>>>{};

    for (final Permission p in permissions) {
      final String module =
          p.category.trim().isEmpty ? 'General' : p.category.trim();
      final String subModule = _permissionSubModule(p);

      out.putIfAbsent(module, () => <String, List<Permission>>{});
      out[module]!.putIfAbsent(subModule, () => <Permission>[]);
      out[module]![subModule]!.add(p);
    }

    return out;
  }

  String _permissionSubModule(Permission p) {
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

  String actionLabel(Permission p) {
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

    final List<String> parts = s
        .replaceAll('-', ' ')
        .replaceAll('_', ' ')
        .split(' ')
        .map((String p) => p.trim())
        .where((String p) => p.isNotEmpty)
        .toList();

    if (parts.isEmpty) return '-';

    final List<String> cap = parts.map((String p) {
      if (p.length == 1) return p.toUpperCase();
      return '${p[0].toUpperCase()}${p.substring(1)}';
    }).toList();

    return cap.join(' ');
  }
}
