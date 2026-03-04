class Permission {
  final String id;
  final String name;
  final String description;
  final String category;
  final String identifier;
  final bool isActive;

  const Permission({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.identifier,
    required this.isActive,
  });

  factory Permission.fromJson(Map<String, dynamic> json) {
    return Permission(
      id: (json['id'] ?? json['_id'])?.toString() ?? '',
      name: (json['name'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      category: (json['category'] ?? '').toString(),
      identifier: (json['identifier'] ?? '').toString(),
      isActive: json['isActive'] == true,
    );
  }
}
