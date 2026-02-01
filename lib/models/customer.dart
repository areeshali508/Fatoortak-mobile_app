class Customer {
  final String id;
  final String companyId;
  final String name;
  final String email;
  final String phone;

  const Customer({
    required this.id,
    this.companyId = '',
    required this.name,
    required this.email,
    required this.phone,
  });
}
