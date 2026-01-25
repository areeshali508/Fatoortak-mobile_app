import 'package:flutter/material.dart';

import '../models/product.dart';

class CreateProductController extends ChangeNotifier {
  CreateProductController() {
    priceController.addListener(_onPricingChanged);
    costController.addListener(_onPricingChanged);
    taxRateController.addListener(_onPricingChanged);
  }

  int _currentStep = 0;
  int _maxStepReached = 0;

  int get currentStep => _currentStep;
  int get maxStepReached => _maxStepReached;

  final TextEditingController nameController = TextEditingController();
  final TextEditingController skuController = TextEditingController();
  final TextEditingController barcodeController = TextEditingController();
  final TextEditingController shortDescriptionController =
      TextEditingController();
  final TextEditingController descriptionController = TextEditingController();

  final TextEditingController priceController = TextEditingController(text: '0');
  final TextEditingController costController = TextEditingController(text: '0');
  final TextEditingController unitsController = TextEditingController(text: '0');
  final TextEditingController taxRateController =
      TextEditingController(text: '15');

  final TextEditingController tagController = TextEditingController();
  final TextEditingController weightKgController =
      TextEditingController(text: '0');
  final TextEditingController lengthCmController =
      TextEditingController(text: '10');
  final TextEditingController widthCmController =
      TextEditingController(text: '10');
  final TextEditingController heightCmController =
      TextEditingController(text: '10');

  final TextEditingController attributeNameController = TextEditingController();
  final TextEditingController attributeValueController = TextEditingController();

  final Map<String, String> _customAttributes = <String, String>{};
  Map<String, String> get customAttributes =>
      Map<String, String>.unmodifiable(_customAttributes);

  void addCustomAttribute({required String name, required String value}) {
    final String k = name.trim();
    final String v = value.trim();
    if (k.isEmpty || v.isEmpty) return;
    _customAttributes[k] = v;
    notifyListeners();
  }

  void removeCustomAttribute(String name) {
    final String k = name.trim();
    if (k.isEmpty) return;
    if (!_customAttributes.containsKey(k)) return;
    _customAttributes.remove(k);
    notifyListeners();
  }

  final List<String> _tags = <String>[];
  List<String> get tags => List<String>.unmodifiable(_tags);

  void addTag(String raw) {
    final String t = raw.trim();
    if (t.isEmpty) return;
    final bool exists = _tags.any((String e) => e.toLowerCase() == t.toLowerCase());
    if (exists) return;
    _tags.add(t);
    notifyListeners();
  }

  void removeTagAt(int index) {
    if (index < 0 || index >= _tags.length) return;
    _tags.removeAt(index);
    notifyListeners();
  }

  String _category = 'General';
  String _subcategory = '';
  String _currency = 'SAR';
  String _unit = 'Meter';
  bool _active = true;

  String get category => _category;
  String get subcategory => _subcategory;
  String get currency => _currency;
  String get unit => _unit;
  bool get active => _active;

  set category(String v) {
    if (v == _category) return;
    _category = v;
    if (_subcategory.isNotEmpty) {
      _subcategory = '';
    }
    notifyListeners();
  }

  set subcategory(String v) {
    if (v == _subcategory) return;
    _subcategory = v;
    notifyListeners();
  }

  set currency(String v) {
    if (v == _currency) return;
    _currency = v;
    notifyListeners();
  }

  set unit(String v) {
    if (v == _unit) return;
    _unit = v;
    notifyListeners();
  }

  set active(bool v) {
    if (v == _active) return;
    _active = v;
    notifyListeners();
  }

  final List<String> _imagePaths = <String>[];
  List<String> get imagePaths => List<String>.unmodifiable(_imagePaths);

  void addImagePath(String path) {
    _imagePaths.add(path);
    notifyListeners();
  }

  void removeImagePathAt(int index) {
    if (index < 0 || index >= _imagePaths.length) return;
    _imagePaths.removeAt(index);
    notifyListeners();
  }

  int _parseInt(String v, {int fallback = 0}) {
    return int.tryParse(v.trim()) ?? fallback;
  }

  double _parseDouble(String v, {double fallback = 0}) {
    return double.tryParse(v.trim()) ?? fallback;
  }

  void _onPricingChanged() {
    notifyListeners();
  }

  double get sellingPrice => _parseDouble(priceController.text, fallback: 0);
  double get costPrice => _parseDouble(costController.text, fallback: 0);

  double get profit => sellingPrice - costPrice;

  double get marginPercent {
    final double selling = sellingPrice;
    if (selling <= 0) return 0;
    return (profit / selling) * 100;
  }

  double get markupPercent {
    final double cost = costPrice;
    if (cost <= 0) return 0;
    return (profit / cost) * 100;
  }

  bool isStepValid(int step) {
    switch (step) {
      case 0:
        return nameController.text.trim().isNotEmpty &&
            skuController.text.trim().isNotEmpty &&
            _category.trim().isNotEmpty;
      case 1:
        return sellingPrice > 0;
      case 2:
        return true;
      case 3:
        return true;
      case 4:
        return true;
      default:
        return false;
    }
  }

  bool nextStep() {
    if (!isStepValid(_currentStep)) {
      return false;
    }
    if (_currentStep >= 4) {
      return false;
    }
    _currentStep++;
    if (_currentStep > _maxStepReached) {
      _maxStepReached = _currentStep;
    }
    notifyListeners();
    return true;
  }

  void prevStep() {
    if (_currentStep == 0) return;
    _currentStep--;
    notifyListeners();
  }

  void goToStep(int step) {
    if (step < 0 || step > 4) return;
    if (step > _maxStepReached) return;
    _currentStep = step;
    notifyListeners();
  }

  String? validateSubmit() {
    if (nameController.text.trim().isEmpty ||
        skuController.text.trim().isEmpty ||
        _category.trim().isEmpty) {
      return 'Please complete required fields before saving';
    }
    return null;
  }

  Product buildProduct() {
    final int now = DateTime.now().millisecondsSinceEpoch;
    final String id = 'PROD-$now';

    return Product(
      id: id,
      name: nameController.text.trim(),
      sku: skuController.text.trim(),
      barcode: barcodeController.text.trim(),
      shortDescription: shortDescriptionController.text.trim(),
      description: descriptionController.text.trim(),
      category: _category,
      subcategory: _subcategory,
      active: _active,
      units: _parseInt(unitsController.text, fallback: 0),
      price: _parseDouble(priceController.text, fallback: 0),
      cost: _parseDouble(costController.text, fallback: 0),
      currency: _currency,
      unit: _unit,
      taxRate: _parseDouble(taxRateController.text, fallback: 0),
      tags: List<String>.unmodifiable(_tags),
      weightKg: _parseDouble(weightKgController.text, fallback: 0),
      lengthCm: _parseDouble(lengthCmController.text, fallback: 0),
      widthCm: _parseDouble(widthCmController.text, fallback: 0),
      heightCm: _parseDouble(heightCmController.text, fallback: 0),
      customAttributes: Map<String, String>.unmodifiable(_customAttributes),
      imagePaths: List<String>.unmodifiable(_imagePaths),
    );
  }

  @override
  void dispose() {
    nameController.dispose();
    skuController.dispose();
    barcodeController.dispose();
    shortDescriptionController.dispose();
    descriptionController.dispose();
    priceController.dispose();
    costController.dispose();
    unitsController.dispose();
    taxRateController.dispose();
    tagController.dispose();
    weightKgController.dispose();
    lengthCmController.dispose();
    widthCmController.dispose();
    heightCmController.dispose();
    attributeNameController.dispose();
    attributeValueController.dispose();
    super.dispose();
  }
}
