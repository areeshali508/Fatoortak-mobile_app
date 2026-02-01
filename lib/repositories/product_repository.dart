import '../core/services/api_client.dart';
import '../models/product.dart';

class ProductRepository {
  ApiClient _api;
  final List<Product> _localProducts = <Product>[];

  bool _isObjectId(String v) {
    final String s = v.trim();
    if (s.length != 24) return false;
    final RegExp re = RegExp(r'^[a-fA-F0-9]{24}$');
    return re.hasMatch(s);
  }

  String _normalizeUnit(String v) {
    final String s = v.trim();
    if (s.isEmpty) return s;
    return s.toLowerCase();
  }

  Future<List<Map<String, dynamic>>> _listCategories({
    required String companyId,
  }) async {
    final Map<String, dynamic> res = await _api.getJson(
      '/api/categories',
      queryParameters: <String, String>{'companyId': companyId},
    );

    final Object? data = res['data'] ?? res['categories'];
    Object? raw;
    if (data is Map<String, dynamic> && data['categories'] is List) {
      raw = data['categories'];
    } else {
      raw = data;
    }

    final List<dynamic> list = raw is List ? raw : <dynamic>[];
    return list
        .whereType<Map>()
        .map((Map e) => e.cast<String, dynamic>())
        .toList();
  }

  String? _categoryIdFromJson(Map<String, dynamic> json) {
    final Object? idRaw = json['_id'] ?? json['id'];
    final String id = idRaw?.toString().trim() ?? '';
    return id.isEmpty ? null : id;
  }

  String _norm(String s) => s.trim().toLowerCase();

  String? _parentIdFromJson(Map<String, dynamic> json) {
    final Object? raw = json['parentId'] ?? json['parent'];
    if (raw == null) return null;
    if (raw is Map) {
      final String id = (raw['_id'] ?? raw['id'])?.toString().trim() ?? '';
      return id.isEmpty ? null : id;
    }
    final String id = raw.toString().trim();
    return id.isEmpty ? null : id;
  }

  Future<String?> _ensureCategoryId({
    required String name,
    required String companyId,
    String? parentId,
  }) async {
    final String n = name.trim();
    if (n.isEmpty) return null;

    final List<Map<String, dynamic>> categories =
        await _listCategories(companyId: companyId);
    final String wantName = _norm(n);
    final String? wantParent = parentId?.trim().isEmpty == true ? null : parentId;

    for (final Map<String, dynamic> c in categories) {
      final String cname = _norm((c['name'] ?? c['nameAr'] ?? '').toString());
      if (cname != wantName) continue;
      final String? cParent = _parentIdFromJson(c);
      if ((wantParent == null && (cParent == null || cParent.trim().isEmpty)) ||
          (wantParent != null && cParent == wantParent)) {
        return _categoryIdFromJson(c);
      }
    }

    final Map<String, dynamic> body = <String, dynamic>{
      'name': n,
      'description': n,
      'companyId': companyId,
      if (wantParent != null) 'parentId': wantParent,
    };

    final Map<String, dynamic> created = await _api.postJson(
      '/api/categories',
      body: body,
    );

    final Object? createdData = created['data'] ?? created['category'];
    if (createdData is Map<String, dynamic>) {
      return _categoryIdFromJson(createdData);
    }
    if (createdData is Map) {
      return _categoryIdFromJson(createdData.cast<String, dynamic>());
    }

    return null;
  }

  ProductRepository({required ApiClient api}) : _api = api;

  void updateApi(ApiClient api) {
    _api = api;
  }

  Future<List<Product>> listProducts({
    String? companyId,
    String? categoryId,
    int page = 1,
    int limit = 50,
    String? search,
  }) async {
    final String companyFilter = (companyId ?? '').trim();
    final String categoryFilter = (categoryId ?? '').trim();
    final Map<String, String> qp = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
    };
    if (companyFilter.isNotEmpty) {
      qp['companyId'] = companyFilter;
    }
    if (categoryFilter.isNotEmpty) {
      qp['categoryId'] = categoryFilter;
    }
    if (search != null && search.trim().isNotEmpty) {
      qp['search'] = search.trim();
    }

    final Map<String, dynamic> res = await _api.getJson(
      '/api/products',
      queryParameters: qp,
    );

    final Object? data = res['data'];
    Object? raw;
    if (data is Map<String, dynamic> && data['products'] is List) {
      raw = data['products'];
    } else {
      raw = data;
    }

    final List<dynamic> list = raw is List ? raw : <dynamic>[];
    final List<Product> remote = list
        .whereType<Map<String, dynamic>>()
        .where((Map<String, dynamic> json) {
          if (companyFilter.isEmpty) return true;
          final Object? rawCompanyId = json['companyId'];
          if (rawCompanyId == null) return true;
          final String cid = rawCompanyId.toString().trim();
          if (cid.isEmpty) return true;
          return cid == companyFilter;
        })
        .map(Product.fromJson)
        .where((Product p) => p.id.trim().isNotEmpty)
        .toList();

    if (_localProducts.isEmpty) {
      return remote;
    }

    final Map<String, Product> byId = <String, Product>{
      for (final Product p in remote) p.id: p,
    };
    for (final Product p in _localProducts) {
      if (p.id.trim().isEmpty) continue;
      byId[p.id] = p;
    }

    return byId.values.toList();
  }

  Future<Product> getProductById(String id) async {
    final String trimmed = id.trim();
    if (trimmed.isEmpty) {
      throw const ApiClientException('Product id is required');
    }

    final Map<String, dynamic> res = await _api.getJson(
      '/api/products/$trimmed',
    );

    final Object? data = res['data'];
    if (data is Map<String, dynamic>) {
      return Product.fromJson(data);
    }
    throw const ApiClientException('Invalid product response');
  }

  Future<Product> createProduct({
    required Product draft,
    required String companyId,
  }) async {
    final String cid = companyId.trim();
    if (cid.isEmpty) {
      throw const ApiClientException('Company id is required');
    }
    if (draft.name.trim().isEmpty || draft.sku.trim().isEmpty) {
      throw const ApiClientException('Product name and SKU are required');
    }

    String? categoryId;
    final String catRaw = draft.category.trim();
    if (catRaw.isNotEmpty) {
      categoryId = _isObjectId(catRaw)
          ? catRaw
          : await _ensureCategoryId(name: catRaw, companyId: cid);
    }

    String? subcategoryId;
    final String subRaw = draft.subcategory.trim();
    if (subRaw.isNotEmpty) {
      subcategoryId = _isObjectId(subRaw)
          ? subRaw
          : await _ensureCategoryId(
              name: subRaw,
              companyId: cid,
              parentId: categoryId,
            );
    }

    final Map<String, dynamic> body = <String, dynamic>{
      'companyId': cid,
      'name': draft.name.trim(),
      'description': draft.description.trim(),
      'shortDescription': draft.shortDescription.trim(),
      'sku': draft.sku.trim(),
      'barcode': draft.barcode.trim(),
      'category': categoryId,
      'subcategory': subcategoryId,
      'price': draft.price,
      'costPrice': draft.cost,
      'unit': _normalizeUnit(draft.unit),
      'taxRate': draft.taxRate,
      'stock': draft.units,
      'status': draft.active ? 'active' : 'inactive',
      'tags': draft.tags,
      'weight': draft.weightKg,
      'dimensions': <String, dynamic>{
        'length': draft.lengthCm,
        'width': draft.widthCm,
        'height': draft.heightCm,
      },
      'images': draft.imagePaths,
    };

    body.removeWhere((String k, dynamic v) {
      if (v == null) return true;
      if (v is String && v.trim().isEmpty) return true;
      if (v is List && v.isEmpty) return true;
      if (v is Map && v.isEmpty) return true;
      return false;
    });

    Map<String, dynamic> res;
    try {
      res = await _api.postJson(
        '/api/products',
        body: body,
      );
    } on ApiClientException catch (e) {
      final String msg = e.toString();
      if (msg.toLowerCase().contains('unit') &&
          msg.toLowerCase().contains('enum') &&
          body.containsKey('unit')) {
        final Map<String, dynamic> retryBody =
            Map<String, dynamic>.from(body)..remove('unit');
        res = await _api.postJson(
          '/api/products',
          body: retryBody,
        );
      } else {
        rethrow;
      }
    }

    Map<String, dynamic>? productJson;
    final Object? rootProduct = res['product'];
    final Object? data = res['data'];

    if (rootProduct is Map) {
      productJson = rootProduct.cast<String, dynamic>();
    } else if (data is Map<String, dynamic>) {
      final Object? nestedProduct = data['product'];
      final Object? nestedData = data['data'];
      if (nestedProduct is Map) {
        productJson = nestedProduct.cast<String, dynamic>();
      } else if (nestedData is Map) {
        productJson = nestedData.cast<String, dynamic>();
      } else if (data.containsKey('_id') || data.containsKey('id')) {
        productJson = data;
      }
    } else if (data is Map) {
      final Map<String, dynamic> casted = data.cast<String, dynamic>();
      if (casted.containsKey('_id') || casted.containsKey('id')) {
        productJson = casted;
      }
    }

    if (productJson != null) {
      return Product.fromJson(productJson);
    }

    throw const ApiClientException('Invalid product create response');
  }

  Future<void> addProduct(Product product) async {
    if (product.id.trim().isEmpty) return;
    _localProducts.removeWhere((Product p) => p.id == product.id);
    _localProducts.insert(0, product);
  }
}
