import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/company.dart';
import '../models/permission.dart';
import '../models/role.dart';
import '../repositories/company_repository.dart';
import '../repositories/permission_repository.dart';
import '../repositories/role_repository.dart';
import '../repositories/user_repository.dart';

class AddNewUserController extends ChangeNotifier {
  final RoleRepository roleRepository;
  final PermissionRepository permissionRepository;
  final CompanyRepository companyRepository;
  final UserRepository userRepository;

  AddNewUserController({
    required this.roleRepository,
    required this.permissionRepository,
    required this.companyRepository,
    required this.userRepository,
  });

  bool _loading = false;
  String? _error;

  bool _submitting = false;

  List<Role> _roles = <Role>[];
  List<Permission> _permissions = <Permission>[];
  List<Company> _companies = <Company>[];

  Role? _selectedRole;
  final Set<String> _selectedPermissionIds = <String>{};
  final Set<String> _selectedCompanyIds = <String>{};

  bool get loading => _loading;
  bool get submitting => _submitting;
  String? get error => _error;

  List<Role> get roles => _roles;
  List<Permission> get permissions => _permissions;
  List<Company> get companies => _companies;

  Role? get selectedRole => _selectedRole;
  Set<String> get selectedPermissionIds => _selectedPermissionIds;
  Set<String> get selectedCompanyIds => _selectedCompanyIds;

  Future<void> createUser({
    required String firstName,
    required String lastName,
    required String email,
    required String phone,
    required String password,
    required String confirmPassword,
    required bool isActive,
  }) async {
    if (_submitting) return;

    _error = null;

    final String roleId = _selectedRole?.id.trim() ?? '';
    if (roleId.isEmpty) {
      _error = 'Please select a role';
      notifyListeners();
      return;
    }

    final String companyId = _selectedCompanyIds.isNotEmpty
        ? _selectedCompanyIds.first.trim()
        : '';
    if (companyId.isEmpty) {
      _error = 'Please assign at least one company';
      notifyListeners();
      return;
    }

    _submitting = true;
    notifyListeners();

    try {
      await userRepository.registerCreatedByMe(
        firstName: firstName,
        lastName: lastName,
        email: email,
        phone: phone,
        password: password,
        confirmPassword: confirmPassword,
        companyId: companyId,
        roleId: roleId,
        isActive: isActive,
      );
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _submitting = false;
      notifyListeners();
    }
  }

  Future<void> loadInitial() async {
    if (_loading) return;

    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final List<dynamic> res = await Future.wait<dynamic>(<Future<dynamic>>[
        roleRepository.listCreatedByMe(),
        permissionRepository.listAll(),
        companyRepository.listCompanies(page: 1, limit: 50),
      ]);

      _roles = (res[0] as List<Role>)
          .where((Role r) => r.isActive)
          .toList();
      _permissions = (res[1] as List<Permission>)
          .where((Permission p) => p.isActive)
          .toList();
      _companies = (res[2] as List<Company>);

      if (_selectedRole == null && _roles.isNotEmpty) {
        setRole(_roles.first);
      }

      if (_selectedCompanyIds.isEmpty && _companies.isNotEmpty) {
        _selectedCompanyIds.add(_companies.first.id);
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  void setRole(Role role) {
    _selectedRole = role;
    _selectedPermissionIds
      ..clear()
      ..addAll(role.permissionIds);
    notifyListeners();
  }

  void togglePermission(String id) {
    if (_selectedPermissionIds.contains(id)) {
      _selectedPermissionIds.remove(id);
    } else {
      _selectedPermissionIds.add(id);
    }
    notifyListeners();
  }

  void toggleCompany(String companyId) {
    if (_selectedCompanyIds.contains(companyId)) {
      _selectedCompanyIds.remove(companyId);
    } else {
      _selectedCompanyIds.add(companyId);
    }
    notifyListeners();
  }

  String companyLabel(String companyId) {
    try {
      final Company c = _companies.firstWhere((Company c) => c.id == companyId);
      final String name = c.name.trim();
      return name.isEmpty ? '-' : name;
    } catch (_) {
      return '-';
    }
  }

  List<String> get selectedCompanyNames {
    return _selectedCompanyIds.map(companyLabel).toList();
  }

  List<String> get permissionsForSelectedRole {
    if (_selectedRole == null) return <String>[];
    return _selectedRole!.permissionIds;
  }
}
