import '../models/customer.dart';

class CustomerRepository {
  const CustomerRepository();

  Future<List<Customer>> listCustomers() async {
    return const <Customer>[
      Customer(
        id: 'CUST-001',
        name: 'Sarah Williams',
        email: 'sarah@example.com',
        phone: '+966500000001',
      ),
      Customer(
        id: 'CUST-002',
        name: 'Michael Chen',
        email: 'michael@example.com',
        phone: '+966500000002',
      ),
      Customer(
        id: 'CUST-003',
        name: 'John Doe Corp',
        email: 'john@example.com',
        phone: '+966500000003',
      ),
    ];
  }
}
