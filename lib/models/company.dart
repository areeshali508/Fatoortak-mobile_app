class Company {
  final String id;
  final String name;

  const Company({required this.id, required this.name});

  factory Company.fromJson(Map<String, dynamic> json) {
    return Company(
      id: (json['_id'] ?? json['id'])?.toString() ?? '',
      name: (json['companyName'] ?? json['name'])?.toString() ?? '',
    );
  }
}
