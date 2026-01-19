import '../models/product.dart';

class ProductRepository {
  const ProductRepository();

  Future<List<Product>> listProducts() async {
    return const <Product>[
      Product(
        id: 'PROD-001',
        name: 'Consulting Service',
        price: 2500,
        currency: 'SAR',
      ),
      Product(
        id: 'PROD-002',
        name: 'Website Development',
        price: 8400,
        currency: 'SAR',
      ),
      Product(
        id: 'PROD-003',
        name: 'Support Plan',
        price: 350,
        currency: 'SAR',
      ),
    ];
  }
}