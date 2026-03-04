class Role {
  final String id;
  final String name;
  final String description;
  final List<String> permissionIds;
  final bool isActive;

  const Role({
    required this.id,
    required this.name,
    required this.description,
    required this.permissionIds,
    required this.isActive,
  });

  factory Role.fromJson(Map<String, dynamic> json) {
    final List<String> permIds = (json['permissionIds'] is List)
        ? (json['permissionIds'] as List)
            .map((Object? e) => e?.toString() ?? '')
            .where((String s) => s.trim().isNotEmpty)
            .toList()
        : <String>[];

    return Role(
      id: (json['_id'] ?? json['id'])?.toString() ?? '',
      name: (json['name'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      permissionIds: permIds,
      isActive: json['isActive'] == true,
    );
  }
}
