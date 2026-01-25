import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../controllers/create_product_controller.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_responsive.dart';

class AddProductScreen extends StatefulWidget {
  const AddProductScreen({super.key});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  InputDecoration _dec({required String label, String? hint, Widget? suffix}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      suffixIcon: suffix,
      hintStyle: const TextStyle(color: Color(0xFF9AA5B6)),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE9EEF5)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.4),
      ),
    );
  }

  void _onBackPressed() {
    final CreateProductController ctrl = context.read<CreateProductController>();
    if (ctrl.currentStep == 0) {
      Navigator.of(context).pop();
      return;
    }
    ctrl.prevStep();
  }

  void _saveDraft() {
    final CreateProductController ctrl = context.read<CreateProductController>();
    final String? msg = ctrl.validateSubmit();
    if (msg != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      return;
    }
    Navigator.of(context).pop(ctrl.buildProduct());
  }

  void _nextOrSave() {
    final CreateProductController ctrl = context.read<CreateProductController>();
    if (ctrl.currentStep < 4) {
      final bool ok = ctrl.nextStep();
      if (!ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please complete required fields')),
        );
      }
      return;
    }

    final String? msg = ctrl.validateSubmit();
    if (msg != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      return;
    }

    Navigator.of(context).pop(ctrl.buildProduct());
  }

  List<String> _categories() {
    return const <String>[
      'General',
      'Electronics',
      'Furniture',
      'Supplies',
      'Accessories',
      'Services',
    ];
  }

  List<String> _subcategoriesFor(String cat) {
    switch (cat.toLowerCase()) {
      case 'electronics':
        return const <String>['Phones', 'Computers', 'Audio', 'Other'];
      case 'furniture':
        return const <String>['Office', 'Home', 'Other'];
      case 'supplies':
        return const <String>['Stationery', 'Printing', 'Other'];
      case 'accessories':
        return const <String>['Computer', 'Phone', 'Other'];
      case 'services':
        return const <String>['Consulting', 'Development', 'Support', 'Other'];
      default:
        return const <String>[];
    }
  }

  Widget _stepTab({
    required BoxConstraints constraints,
    required int index,
    required IconData icon,
    required String label,
    required bool selected,
    required bool enabled,
    required VoidCallback onTap,
  }) {
    final double iconSize = AppResponsive.clamp(
      AppResponsive.sp(constraints, 18),
      16,
      20,
    );

    final Color fg = selected ? AppColors.primary : const Color(0xFF9AA5B6);

    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: 86,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(icon, size: iconSize, color: fg),
            const SizedBox(height: 6),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: fg,
                fontWeight: FontWeight.w800,
                fontSize: 11,
              ),
            ),
            const SizedBox(height: 8),
            AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              height: 2.5,
              width: selected ? 46 : 0,
              decoration: BoxDecoration(
                color: selected ? AppColors.primary : Colors.transparent,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _basicStep(CreateProductController ctrl) {
    final List<String> cats = _categories();
    final List<String> subs = _subcategoriesFor(ctrl.category);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        TextField(
          controller: ctrl.nameController,
          decoration: _dec(label: 'Product Name *', hint: 'e.g., Wireless Headphone'),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: ctrl.skuController,
          decoration: _dec(
            label: 'SKU *',
            hint: 'Scan or enter SKU',
            suffix: IconButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Coming soon')),
                );
              },
              icon: const Icon(Icons.qr_code_scanner_rounded),
              color: const Color(0xFF6B7895),
            ),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: ctrl.shortDescriptionController,
          maxLines: 3,
          decoration: _dec(
            label: 'Short Description',
            hint: 'Brief summary of the product...',
          ),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          initialValue: cats.contains(ctrl.category) ? ctrl.category : cats.first,
          items: cats
              .map(
                (String e) => DropdownMenuItem<String>(
                  value: e,
                  child: Text(e, overflow: TextOverflow.ellipsis),
                ),
              )
              .toList(),
          onChanged: (String? v) {
            if (v == null) return;
            ctrl.category = v;
          },
          decoration: _dec(label: 'Category *', hint: 'Select category'),
          icon: const Icon(Icons.keyboard_arrow_down_rounded),
          borderRadius: BorderRadius.circular(12),
          dropdownColor: Colors.white,
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          initialValue: ctrl.subcategory.isEmpty
              ? (subs.isEmpty ? null : subs.first)
              : (subs.contains(ctrl.subcategory) ? ctrl.subcategory : subs.first),
          items: subs
              .map(
                (String e) => DropdownMenuItem<String>(
                  value: e,
                  child: Text(e, overflow: TextOverflow.ellipsis),
                ),
              )
              .toList(),
          onChanged: subs.isEmpty
              ? null
              : (String? v) {
                  if (v == null) return;
                  ctrl.subcategory = v;
                },
          decoration: _dec(label: 'Subcategory', hint: 'Select subcategory'),
          icon: const Icon(Icons.keyboard_arrow_down_rounded),
          borderRadius: BorderRadius.circular(12),
          dropdownColor: Colors.white,
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE9EEF5)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const Text(
                'Product Images',
                style: TextStyle(
                  color: Color(0xFF0B1B4B),
                  fontWeight: FontWeight.w900,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 10),
              InkWell(
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Image upload coming soon')),
                  );
                },
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  height: 120,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF7FAFF),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFFE9EEF5),
                      style: BorderStyle.solid,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const <Widget>[
                      CircleAvatar(
                        radius: 22,
                        backgroundColor: Color(0xFFEDEBFF),
                        child: Icon(Icons.cloud_upload_outlined,
                            color: AppColors.primary),
                      ),
                      SizedBox(height: 10),
                      Text(
                        'Tap to upload images',
                        style: TextStyle(
                          color: Color(0xFF0B1B4B),
                          fontWeight: FontWeight.w900,
                          fontSize: 12,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'JPG, PNG up to 5MB',
                        style: TextStyle(
                          color: Color(0xFF9AA5B6),
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _pricingStep(CreateProductController ctrl) {
    final List<String> units = const <String>[
      'Piece',
      'Meter',
      'Hour',
      'Kg',
      'Litre',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        TextField(
          controller: ctrl.priceController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: _dec(
            label: 'Selling Price (${ctrl.currency}) *',
            hint: '0',
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: ctrl.costController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: _dec(
            label: 'Cost Price (${ctrl.currency})',
            hint: '0',
          ),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          initialValue: units.contains(ctrl.unit) ? ctrl.unit : units.first,
          items: units
              .map(
                (String e) => DropdownMenuItem<String>(
                  value: e,
                  child: Text(e, overflow: TextOverflow.ellipsis),
                ),
              )
              .toList(),
          onChanged: (String? v) {
            if (v == null) return;
            ctrl.unit = v;
          },
          decoration: _dec(label: 'Unit', hint: 'Select unit'),
          icon: const Icon(Icons.keyboard_arrow_down_rounded),
          borderRadius: BorderRadius.circular(12),
          dropdownColor: Colors.white,
        ),
        const SizedBox(height: 12),
        TextField(
          controller: ctrl.taxRateController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: _dec(label: 'Tax Rate (%)', hint: '0'),
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE9EEF5)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const Text(
                'Profit Analysis',
                style: TextStyle(
                  color: Color(0xFF0B1B4B),
                  fontWeight: FontWeight.w900,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 10),
              _kvRow(
                label: 'Profit:',
                value: '${ctrl.currency} ${ctrl.profit.toStringAsFixed(2)}',
              ),
              const SizedBox(height: 6),
              _kvRow(
                label: 'Margin:',
                value: '${ctrl.marginPercent.toStringAsFixed(1)}%',
              ),
              const SizedBox(height: 6),
              _kvRow(
                label: 'Markup:',
                value: '${ctrl.markupPercent.toStringAsFixed(1)}%',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _kvRow({required String label, required String value}) {
    return Row(
      children: <Widget>[
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: Color(0xFF6B7895),
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Color(0xFF0B1B4B),
            fontWeight: FontWeight.w900,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _inventoryStep(CreateProductController ctrl) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        TextField(
          controller: ctrl.unitsController,
          keyboardType: TextInputType.number,
          decoration: _dec(label: 'Stock', hint: '0'),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: ctrl.barcodeController,
          keyboardType: TextInputType.number,
          decoration: _dec(label: 'Barcode', hint: '12345678'),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE9EEF5)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const Text(
                'Status',
                style: TextStyle(
                  color: Color(0xFF0B1B4B),
                  fontWeight: FontWeight.w900,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF7FAFF),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE9EEF5)),
                ),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: InkWell(
                        onTap: () => ctrl.active = true,
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: ctrl.active
                                ? Colors.white
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                            border: ctrl.active
                                ? Border.all(
                                    color: const Color(0xFFE9EEF5),
                                  )
                                : null,
                          ),
                          child: Text(
                            'Active',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: ctrl.active
                                  ? AppColors.primary
                                  : const Color(0xFF6B7895),
                              fontWeight: FontWeight.w900,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: InkWell(
                        onTap: () => ctrl.active = false,
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: !ctrl.active
                                ? Colors.white
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                            border: !ctrl.active
                                ? Border.all(
                                    color: const Color(0xFFE9EEF5),
                                  )
                                : null,
                          ),
                          child: Text(
                            'Inactive',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: !ctrl.active
                                  ? AppColors.primary
                                  : const Color(0xFF6B7895),
                              fontWeight: FontWeight.w900,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _detailsStep(CreateProductController ctrl) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE9EEF5)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const Text(
                'Tags',
                style: TextStyle(
                  color: Color(0xFF0B1B4B),
                  fontWeight: FontWeight.w900,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: <Widget>[
                  Expanded(
                    child: TextField(
                      controller: ctrl.tagController,
                      decoration: _dec(label: 'Add a tag', hint: 'Add a tag'),
                      onSubmitted: (String v) {
                        ctrl.addTag(v);
                        ctrl.tagController.clear();
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () {
                        ctrl.addTag(ctrl.tagController.text);
                        ctrl.tagController.clear();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                      ),
                      child: const Text(
                        'Add',
                        style: TextStyle(fontWeight: FontWeight.w900),
                      ),
                    ),
                  ),
                ],
              ),
              if (ctrl.tags.isNotEmpty) ...<Widget>[
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: <Widget>[
                    for (int i = 0; i < ctrl.tags.length; i++)
                      Chip(
                        label: Text(
                          ctrl.tags[i],
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                        onDeleted: () => ctrl.removeTagAt(i),
                        deleteIconColor: const Color(0xFF6B7895),
                        backgroundColor: const Color(0xFFF7FAFF),
                        side: const BorderSide(color: Color(0xFFE9EEF5)),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: ctrl.weightKgController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: _dec(label: 'Weight (kg)', hint: '0'),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE9EEF5)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const Text(
                'Dimensions (cm)',
                style: TextStyle(
                  color: Color(0xFF0B1B4B),
                  fontWeight: FontWeight.w900,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: <Widget>[
                  Expanded(
                    child: TextField(
                      controller: ctrl.lengthCmController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: _dec(label: 'L', hint: '10'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: ctrl.widthCmController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: _dec(label: 'W', hint: '10'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: ctrl.heightCmController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: _dec(label: 'H', hint: '10'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: ctrl.descriptionController,
          maxLines: 6,
          decoration: _dec(
            label: 'Details',
            hint: 'Add full product details...',
          ),
        ),
      ],
    );
  }

  Widget _advancedStepRedesign(CreateProductController ctrl) {
    final List<MapEntry<String, String>> attrs = ctrl.customAttributes.entries
        .map((MapEntry<String, String> e) => MapEntry<String, String>(e.key, e.value))
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE9EEF5)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const Text(
                'Custom Attributes',
                style: TextStyle(
                  color: Color(0xFF0B1B4B),
                  fontWeight: FontWeight.w900,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF7FAFF),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE9EEF5)),
                ),
                child: Row(
                  children: const <Widget>[
                    Expanded(
                      flex: 4,
                      child: Text(
                        'Attribute Name',
                        style: TextStyle(
                          color: Color(0xFF6B7895),
                          fontWeight: FontWeight.w900,
                          fontSize: 11,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 4,
                      child: Text(
                        'Value',
                        style: TextStyle(
                          color: Color(0xFF6B7895),
                          fontWeight: FontWeight.w900,
                          fontSize: 11,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        'Action',
                        textAlign: TextAlign.end,
                        style: TextStyle(
                          color: Color(0xFF6B7895),
                          fontWeight: FontWeight.w900,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              if (attrs.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    'No attributes added yet',
                    style: TextStyle(
                      color: Color(0xFF9AA5B6),
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                  ),
                )
              else
                ...attrs.map((MapEntry<String, String> e) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE9EEF5)),
                    ),
                    child: Row(
                      children: <Widget>[
                        Expanded(
                          flex: 4,
                          child: Text(
                            e.key,
                            style: const TextStyle(
                              color: Color(0xFF0B1B4B),
                              fontWeight: FontWeight.w800,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 4,
                          child: Text(
                            e.value,
                            style: const TextStyle(
                              color: Color(0xFF0B1B4B),
                              fontWeight: FontWeight.w800,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: IconButton(
                              onPressed: () => ctrl.removeCustomAttribute(e.key),
                              icon: const Icon(Icons.delete_outline_rounded),
                              color: const Color(0xFFE53935),
                              tooltip: 'Delete',
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              const SizedBox(height: 12),
              TextField(
                controller: ctrl.attributeNameController,
                decoration: _dec(label: 'Attribute name', hint: 'Attribute name'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: ctrl.attributeValueController,
                decoration:
                    _dec(label: 'Attribute value', hint: 'Attribute value'),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: () {
                    ctrl.addCustomAttribute(
                      name: ctrl.attributeNameController.text,
                      value: ctrl.attributeValueController.text,
                    );
                    ctrl.attributeNameController.clear();
                    ctrl.attributeValueController.clear();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Add Attribute',
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _stepBody(CreateProductController ctrl) {
    switch (ctrl.currentStep) {
      case 0:
        return _basicStep(ctrl);
      case 1:
        return _pricingStep(ctrl);
      case 2:
        return _inventoryStep(ctrl);
      case 3:
        return _detailsStep(ctrl);
      case 4:
      default:
        return _advancedStepRedesign(ctrl);
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final CreateProductController ctrl =
            context.watch<CreateProductController>();

        final double hPad = AppResponsive.clamp(
          AppResponsive.vw(constraints, 5.5),
          16,
          22,
        );

        final double gap = AppResponsive.clamp(
          AppResponsive.scaledByHeight(constraints, 14),
          12,
          18,
        );

        final int step = ctrl.currentStep + 1;
        final int totalSteps = 5;
        final double progress = step / totalSteps;
        final int percent = (progress * 100).round();

        return Scaffold(
          backgroundColor: const Color(0xFFF7FAFF),
          appBar: AppBar(
            title: const Text('Add Product'),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: _onBackPressed,
            ),
          ),
          body: SafeArea(
            child: Padding(
              padding: EdgeInsets.fromLTRB(hPad, gap, hPad, 0),
              child: Column(
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          'Step $step of $totalSteps',
                          style: const TextStyle(
                            color: Color(0xFF0B1B4B),
                            fontWeight: FontWeight.w900,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      Text(
                        '$percent%',
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w900,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 6,
                      backgroundColor: const Color(0xFFE9EEF5),
                      valueColor:
                          const AlwaysStoppedAnimation<Color>(AppColors.primary),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: <Widget>[
                        _stepTab(
                          constraints: constraints,
                          index: 0,
                          icon: Icons.info_outline,
                          label: 'Basic',
                          selected: ctrl.currentStep == 0,
                          enabled: 0 <= ctrl.maxStepReached,
                          onTap: () => ctrl.goToStep(0),
                        ),
                        _stepTab(
                          constraints: constraints,
                          index: 1,
                          icon: Icons.local_offer_outlined,
                          label: 'Pricing',
                          selected: ctrl.currentStep == 1,
                          enabled: 1 <= ctrl.maxStepReached,
                          onTap: () => ctrl.goToStep(1),
                        ),
                        _stepTab(
                          constraints: constraints,
                          index: 2,
                          icon: Icons.inventory_2_outlined,
                          label: 'Inventory',
                          selected: ctrl.currentStep == 2,
                          enabled: 2 <= ctrl.maxStepReached,
                          onTap: () => ctrl.goToStep(2),
                        ),
                        _stepTab(
                          constraints: constraints,
                          index: 3,
                          icon: Icons.description_outlined,
                          label: 'Details',
                          selected: ctrl.currentStep == 3,
                          enabled: 3 <= ctrl.maxStepReached,
                          onTap: () => ctrl.goToStep(3),
                        ),
                        _stepTab(
                          constraints: constraints,
                          index: 4,
                          icon: Icons.tune_rounded,
                          label: 'Advanced',
                          selected: ctrl.currentStep == 4,
                          enabled: 4 <= ctrl.maxStepReached,
                          onTap: () => ctrl.goToStep(4),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: gap),
                  Expanded(
                    child: ListView(
                      padding: EdgeInsets.only(bottom: gap),
                      children: <Widget>[
                        _stepBody(ctrl),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          bottomNavigationBar: SafeArea(
            child: Padding(
              padding: EdgeInsets.fromLTRB(hPad, 10, hPad, 10),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _saveDraft,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF0B1B4B),
                        side: const BorderSide(color: Color(0xFFE9EEF5)),
                        backgroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        textStyle: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                      child: const Text('Save Draft'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _nextOrSave,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        textStyle: const TextStyle(fontWeight: FontWeight.w900),
                        elevation: 0,
                      ),
                      child:
                          Text(ctrl.currentStep < 4 ? 'Next' : 'Save Product'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
