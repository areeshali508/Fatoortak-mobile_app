class UserModel {
  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final String phone;
  final bool isActive;
  final String roleId;
  final String roleName;

  const UserModel({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phone,
    required this.isActive,
    required this.roleId,
    required this.roleName,
  });

  String get fullName {
    final String f = firstName.trim();
    final String l = lastName.trim();
    final String out = '$f $l'.trim();
    return out.isEmpty ? '-' : out;
  }

  String get initials {
    final String f = firstName.trim();
    final String l = lastName.trim();
    final String a = f.isNotEmpty ? f[0].toUpperCase() : '';
    final String b = l.isNotEmpty ? l[0].toUpperCase() : '';
    final String out = '$a$b'.trim();
    return out.isEmpty ? '--' : out;
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    final Object? roleObj = json['role'];
    final Map<String, dynamic> roleMap =
        roleObj is Map<String, dynamic> ? roleObj : const <String, dynamic>{};

    final String roleId = (roleMap['_id'] ?? roleMap['id'] ?? json['roleId'])
            ?.toString() ??
        '';
    final String roleName = (roleMap['name'] ?? '')?.toString() ?? '';

    return UserModel(
      id: (json['_id'] ?? json['id'])?.toString() ?? '',
      firstName: (json['firstName'] ?? '').toString(),
      lastName: (json['lastName'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      phone: (json['phone'] ?? '').toString(),
      isActive: json['isActive'] == true,
      roleId: roleId,
      roleName: roleName,
    );
  }
}
