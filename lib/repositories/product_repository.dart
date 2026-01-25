import '../models/product.dart';

class ProductRepository {
  const ProductRepository();

  static final List<Product> _products = <Product>[
    const Product(
      id: 'PROD-001',
      name: 'Consulting Service',
      sku: '9001',
      category: 'Services',
      subcategory: '',
      active: true,
      units: 0,
      price: 2500,
      cost: 0,
      currency: 'SAR',
    ),
    const Product(
      id: 'PROD-002',
      name: 'Website Development',
      sku: '9002',
      category: 'Services',
      subcategory: '',
      active: true,
      units: 0,
      price: 8400,
      cost: 0,
      currency: 'SAR',
    ),
    const Product(
      id: 'PROD-003',
      name: 'Support Plan',
      sku: '9003',
      category: 'Services',
      subcategory: '',
      active: true,
      units: 0,
      price: 350,
      cost: 0,
      currency: 'SAR',
    ),
  ];

  Future<List<Product>> listProducts() async {
    return List<Product>.unmodifiable(_products);
  }

  Future<void> addProduct(Product product) async {
    _products.insert(0, product);
  }
}
