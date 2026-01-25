class Product {
  final String id;
  final String name;
  final String sku;
  final String barcode;
  final String shortDescription;
  final String description;
  final String category;
  final String subcategory;
  final bool active;
  final int units;
  final double price;
  final double cost;
  final String currency;
  final String unit;
  final double taxRate;
  final List<String> tags;
  final double weightKg;
  final double lengthCm;
  final double widthCm;
  final double heightCm;
  final Map<String, String> customAttributes;
  final List<String> imagePaths;

  const Product({
    required this.id,
    required this.name,
    required this.sku,
    this.barcode = '',
    this.shortDescription = '',
    this.description = '',
    this.category = 'General',
    this.subcategory = '',
    this.active = true,
    this.units = 0,
    required this.price,
    this.cost = 0,
    required this.currency,
    this.unit = 'Unit',
    this.taxRate = 0,
    this.tags = const <String>[],
    this.weightKg = 0,
    this.lengthCm = 0,
    this.widthCm = 0,
    this.heightCm = 0,
    this.customAttributes = const <String, String>{},
    this.imagePaths = const <String>[],
  });
}
