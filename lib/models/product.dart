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

  factory Product.fromJson(Map<String, dynamic> json) {
    final Object? categoryRaw = json['category'];
    final Object? subcategoryRaw = json['subcategory'];
    final Object? tagsRaw = json['tags'];
    final Object? dimsRaw = json['dimensions'];
    final Object? imagesRaw = json['images'];

    final String id = (json['_id'] ?? json['id'])?.toString() ?? '';
    final String name = (json['name'] ?? json['productName'])?.toString() ?? '';
    final String sku = (json['sku'] ?? '').toString();
    final String barcode = (json['barcode'] ?? '').toString();
    final String shortDescription =
        (json['shortDescription'] ?? '').toString();
    final String description = (json['description'] ?? '').toString();

    final String category = categoryRaw is Map<String, dynamic>
        ? (categoryRaw['name'] ?? categoryRaw['_id'])?.toString() ?? ''
        : categoryRaw?.toString() ?? '';
    final String subcategory = subcategoryRaw is Map<String, dynamic>
        ? (subcategoryRaw['name'] ?? subcategoryRaw['_id'])?.toString() ?? ''
        : subcategoryRaw?.toString() ?? '';

    final String status = (json['status'] ?? '').toString().toLowerCase();
    final bool active = status.isEmpty ? true : status == 'active';

    final double price = json['price'] is num
        ? (json['price'] as num).toDouble()
        : double.tryParse(json['price']?.toString() ?? '0') ?? 0;
    final double cost = json['costPrice'] is num
        ? (json['costPrice'] as num).toDouble()
        : double.tryParse(json['costPrice']?.toString() ?? '0') ?? 0;
    final double taxRate = json['taxRate'] is num
        ? (json['taxRate'] as num).toDouble()
        : double.tryParse(json['taxRate']?.toString() ?? '0') ?? 0;

    final int units = json['stock'] is num
        ? (json['stock'] as num).toInt()
        : int.tryParse(json['stock']?.toString() ?? '0') ?? 0;

    final double weightKg = json['weight'] is num
        ? (json['weight'] as num).toDouble()
        : double.tryParse(json['weight']?.toString() ?? '0') ?? 0;

    double lengthCm = 0;
    double widthCm = 0;
    double heightCm = 0;
    if (dimsRaw is Map<String, dynamic>) {
      lengthCm = dimsRaw['length'] is num
          ? (dimsRaw['length'] as num).toDouble()
          : double.tryParse(dimsRaw['length']?.toString() ?? '0') ?? 0;
      widthCm = dimsRaw['width'] is num
          ? (dimsRaw['width'] as num).toDouble()
          : double.tryParse(dimsRaw['width']?.toString() ?? '0') ?? 0;
      heightCm = dimsRaw['height'] is num
          ? (dimsRaw['height'] as num).toDouble()
          : double.tryParse(dimsRaw['height']?.toString() ?? '0') ?? 0;
    }

    final List<String> tags = tagsRaw is List
        ? tagsRaw.map((Object? e) => e?.toString() ?? '').where((String e) => e.trim().isNotEmpty).toList()
        : const <String>[];

    final List<String> imagePaths = imagesRaw is List
        ? imagesRaw.map((Object? e) => e?.toString() ?? '').where((String e) => e.trim().isNotEmpty).toList()
        : const <String>[];

    return Product(
      id: id,
      name: name,
      sku: sku,
      barcode: barcode,
      shortDescription: shortDescription,
      description: description,
      category: category,
      subcategory: subcategory,
      active: active,
      units: units,
      price: price,
      cost: cost,
      currency: 'SAR',
      unit: (json['unit'] ?? '').toString(),
      taxRate: taxRate,
      tags: tags,
      weightKg: weightKg,
      lengthCm: lengthCm,
      widthCm: widthCm,
      heightCm: heightCm,
      customAttributes: const <String, String>{},
      imagePaths: imagePaths,
    );
  }
}
