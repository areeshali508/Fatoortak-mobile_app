import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../controllers/create_credit_note_controller.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_responsive.dart';
import '../../../models/credit_note.dart';

class CreateCreditNoteScreen extends StatefulWidget {
  const CreateCreditNoteScreen({super.key});

  @override
  State<CreateCreditNoteScreen> createState() => _CreateCreditNoteScreenState();
}

class _CreateCreditNoteScreenState extends State<CreateCreditNoteScreen> {
  void _nextStep() {
    final CreateCreditNoteController ctrl =
        context.read<CreateCreditNoteController>();
    final bool ok = ctrl.nextStep();
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please complete this step to continue')),
      );
    }
  }

  void _prevStep() {
    context.read<CreateCreditNoteController>().prevStep();
  }

  void _goToStep(int step) {
    context.read<CreateCreditNoteController>().goToStep(step);
  }

  Future<void> _pickIssueDate() async {
    final CreateCreditNoteController ctrl =
        context.read<CreateCreditNoteController>();
    final DateTime now = DateTime.now();
    final DateTime initial = ctrl.issueDate ?? now;

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020, 1, 1),
      lastDate: DateTime(now.year + 3, 12, 31),
    );

    if (!mounted || picked == null) {
      return;
    }

    ctrl.setIssueDate(picked);
  }

  String _fmtDate(DateTime? d) {
    if (d == null) {
      return 'mm/dd/yyyy';
    }
    final String mm = d.month.toString().padLeft(2, '0');
    final String dd = d.day.toString().padLeft(2, '0');
    return '$mm/$dd/${d.year}';
  }

  Future<void> _openAddItemSheet() async {
    final CreateCreditNoteController ctrl =
        context.read<CreateCreditNoteController>();
    final CreditNoteItem? item = await showModalBottomSheet<CreditNoteItem>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (_) => _AddItemSheet(currency: ctrl.currency),
    );

    if (!mounted || item == null) {
      return;
    }

    ctrl.addItem(item);
  }

  void _submit() {
    final CreateCreditNoteController ctrl =
        context.read<CreateCreditNoteController>();
    final String? msg = ctrl.validateSubmit();
    if (msg != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      return;
    }
    Navigator.of(context).pop(ctrl.buildCreditNote());
  }

  InputDecoration _dec({required String label, String? hint, Widget? prefix}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: prefix,
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

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final CreateCreditNoteController ctrl =
            context.watch<CreateCreditNoteController>();

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

        final List<String> titles = <String>['Details', 'Items', 'Summary'];

        Widget itemsBlock({required bool editable}) {
          if (ctrl.items.isEmpty) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 18),
              decoration: BoxDecoration(
                color: const Color(0xFFF7FAFF),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE9EEF5)),
              ),
              child: Column(
                children: <Widget>[
                  const Icon(Icons.receipt_long_outlined,
                      color: Color(0xFF9AA5B6)),
                  const SizedBox(height: 10),
                  const Text(
                    'No items added yet',
                    style: TextStyle(
                      color: Color(0xFF9AA5B6),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: editable ? _openAddItemSheet : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFEDEBFF),
                      foregroundColor: AppColors.primary,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    icon: const Icon(Icons.add),
                    label: const Text(
                      'Add Item',
                      style: TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: <Widget>[
              ...ctrl.items.asMap().entries.map((e) {
                final CreditNoteItem it = e.value;
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE9EEF5)),
                  ),
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              it.description,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Color(0xFF0B1B4B),
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${it.qty} x ${it.price.toStringAsFixed(2)}',
                              style: const TextStyle(
                                color: Color(0xFF6B7895),
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${it.total.toStringAsFixed(2)} ${ctrl.currency}',
                        style: const TextStyle(
                          color: Color(0xFF0B1B4B),
                          fontWeight: FontWeight.w900,
                          fontSize: 12,
                        ),
                      ),
                      if (editable) ...<Widget>[
                        const SizedBox(width: 6),
                        IconButton(
                          onPressed: () => ctrl.removeItemAt(e.key),
                          icon: const Icon(Icons.close, size: 18),
                          color: const Color(0xFF9AA5B6),
                        ),
                      ],
                    ],
                  ),
                );
              }),
              const SizedBox(height: 6),
              Row(
                children: <Widget>[
                  const Expanded(
                    child: Text(
                      'Subtotal',
                      style: TextStyle(
                        color: Color(0xFF6B7895),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Text(
                    '${ctrl.subtotal.toStringAsFixed(2)} ${ctrl.currency}',
                    style: const TextStyle(
                      color: Color(0xFF6B7895),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: <Widget>[
                  const Expanded(
                    child: Text(
                      'VAT (15%)',
                      style: TextStyle(
                        color: Color(0xFF6B7895),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Text(
                    '${ctrl.vatAmount.toStringAsFixed(2)} ${ctrl.currency}',
                    style: const TextStyle(
                      color: Color(0xFF6B7895),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: <Widget>[
                  const Expanded(
                    child: Text(
                      'Total Credit',
                      style: TextStyle(
                        color: Color(0xFF0B1B4B),
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  Text(
                    '${ctrl.total.toStringAsFixed(2)} ${ctrl.currency}',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ],
          );
        }

        Widget content() {
          if (ctrl.currentStep == 1) {
            return _SectionCard(
              title: 'Items',
              trailing: TextButton.icon(
                onPressed: _openAddItemSheet,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add Item'),
              ),
              child: itemsBlock(editable: true),
            );
          }

          if (ctrl.currentStep == 2) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                _SectionCard(
                  title: 'Summary',
                  child: Column(
                    children: <Widget>[
                      _SummaryRow(
                        label: 'Credit Note #',
                        value: ctrl.creditNoteNumberController.text.trim(),
                      ),
                      _SummaryRow(
                        label: 'Issue Date',
                        value: _fmtDate(ctrl.issueDate),
                      ),
                      _SummaryRow(
                        label: 'Original Invoice',
                        value: ctrl.originalInvoiceController.text.trim(),
                      ),
                      _SummaryRow(
                        label: 'Customer',
                        value: ctrl.customerController.text.trim(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                _SectionCard(
                  title: 'Items',
                  child: itemsBlock(editable: false),
                ),
              ],
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              _SectionCard(
                title: 'Credit Note Details',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    _LabeledDropdown<String>(
                      label: 'Company*',
                      value: ctrl.company,
                      items: const <String>[
                        'Tech Solutions Ltd.',
                        'Fatoortak Business',
                      ],
                      onChanged: (String v) => ctrl.company = v,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: TextField(
                            controller: ctrl.creditNoteNumberController,
                            decoration: _dec(label: 'Credit Note #'),
                            style: const TextStyle(
                              color: Color(0xFF0B1B4B),
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _DateField(
                            label: 'Issue Date*',
                            value: _fmtDate(ctrl.issueDate),
                            onTap: _pickIssueDate,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _LabeledDropdown<String>(
                      label: 'Currency',
                      value: ctrl.currency,
                      items: const <String>['SAR', 'USD', 'EUR'],
                      onChanged: (String v) => ctrl.currency = v,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _WarningCard(
                title: 'Original Invoice*',
                helper: 'Required for ZATCA compliance',
                child: TextField(
                  controller: ctrl.originalInvoiceController,
                  decoration: _dec(
                    label: '',
                    hint: 'Search or select invoice number',
                    prefix: const Icon(Icons.search, color: Color(0xFF9AA5B6)),
                  ).copyWith(labelText: null),
                  style: const TextStyle(
                    color: Color(0xFF0B1B4B),
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _SectionCard(
                title: 'Customer',
                child: TextField(
                  controller: ctrl.customerController,
                  decoration: _dec(
                    label: 'Customer',
                    hint: 'Search customer',
                    prefix: const Icon(Icons.search, color: Color(0xFF9AA5B6)),
                  ),
                  style: const TextStyle(
                    color: Color(0xFF0B1B4B),
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _SectionCard(
                title: 'Items',
                trailing: TextButton.icon(
                  onPressed: _openAddItemSheet,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add Item'),
                ),
                child: itemsBlock(editable: true),
              ),
              const SizedBox(height: 12),
              _SectionCard(
                title: 'Reason & Notes',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    _LabeledDropdown<String>(
                      label: 'Reason Type*',
                      value: ctrl.reasonType,
                      items: const <String>[
                        'Select Reason',
                        'Refund',
                        'Invoice Correction',
                        'Discount Adjustment',
                      ],
                      onChanged: (String v) => ctrl.reasonType = v,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: ctrl.reasonDescriptionController,
                      maxLines: 3,
                      decoration: _dec(
                        label: 'Reason Description',
                        hint: 'Enter reason details...',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: ctrl.termsController,
                      maxLines: 3,
                      decoration: _dec(
                        label: 'Terms & Conditions',
                        hint: 'Specific terms for this credit note...',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        }

        return Scaffold(
          backgroundColor: const Color(0xFFF7FAFF),
          appBar: AppBar(
            title: const Text('Create Credit Note'),
            leading: const BackButton(),
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                hPad,
                gap,
                hPad,
                AppResponsive.clamp(
                  AppResponsive.scaledByHeight(constraints, 140),
                  130,
                  180,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  _TabsHeader(
                    titles: titles,
                    current: ctrl.currentStep,
                    maxStepReached: ctrl.maxStepReached,
                    onTap: _goToStep,
                  ),
                  SizedBox(height: gap),
                  content(),
                ],
              ),
            ),
          ),
          bottomNavigationBar: SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(
                  top: BorderSide(color: Color(0xFFE9EEF5)),
                ),
              ),
              child: ctrl.currentStep == 2
                  ? ElevatedButton(
                      onPressed: _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        textStyle: const TextStyle(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      child: const Text('Save Credit Note'),
                    )
                  : Row(
                      children: <Widget>[
                        Expanded(
                          child: OutlinedButton(
                            onPressed: ctrl.currentStep == 0 ? null : _prevStep,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF0B1B4B),
                              side:
                                  const BorderSide(color: Color(0xFFE9EEF5)),
                              padding:
                                  const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              textStyle: const TextStyle(
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            child: const Text('Back'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _nextStep,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              padding:
                                  const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              textStyle: const TextStyle(
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            child: const Text('Next'),
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

class _TabsHeader extends StatelessWidget {
  final List<String> titles;
  final int current;
  final int maxStepReached;
  final ValueChanged<int> onTap;

  const _TabsHeader({
    required this.titles,
    required this.current,
    required this.maxStepReached,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Color(0xFFE9EEF5)),
        ),
      ),
      child: Row(
        children: List<Widget>.generate(titles.length, (int i) {
          final bool isActive = i == current;
          final bool isEnabled = i <= maxStepReached;
          return Expanded(
            child: InkWell(
              onTap: isEnabled ? () => onTap(i) : null,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      titles[i],
                      style: TextStyle(
                        color: isActive
                            ? AppColors.primary
                            : const Color(0xFF9AA5B6),
                        fontWeight: FontWeight.w900,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 6),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      height: 3,
                      width: 46,
                      decoration: BoxDecoration(
                        color:
                            isActive ? AppColors.primary : Colors.transparent,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;
  final Widget? trailing;

  const _SectionCard({
    required this.title,
    required this.child,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE9EEF5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 3,
                height: 18,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF0B1B4B),
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                  ),
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _LabeledDropdown<T> extends StatelessWidget {
  final String label;
  final T value;
  final List<T> items;
  final ValueChanged<T> onChanged;

  const _LabeledDropdown({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      key: ValueKey<T>(value),
      initialValue: value,
      items: items
          .map((T e) => DropdownMenuItem<T>(
                value: e,
                child: Text(
                  e.toString(),
                  overflow: TextOverflow.ellipsis,
                ),
              ))
          .toList(),
      onChanged: (T? v) {
        if (v == null) return;
        onChanged(v);
      },
      decoration: InputDecoration(
        labelText: label,
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
      ),
      icon: const Icon(Icons.keyboard_arrow_down_rounded),
      borderRadius: BorderRadius.circular(12),
      dropdownColor: Colors.white,
    );
  }
}

class _DateField extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onTap;

  const _DateField({
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Colors.white,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE9EEF5)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.primary, width: 1.4),
          ),
          suffixIcon: const Icon(
            Icons.calendar_today_outlined,
            size: 18,
            color: Color(0xFF9AA5B6),
          ),
        ),
        child: Text(
          value,
          style: TextStyle(
            color: value == 'mm/dd/yyyy'
                ? const Color(0xFF9AA5B6)
                : const Color(0xFF0B1B4B),
            fontWeight: FontWeight.w800,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

class _WarningCard extends StatelessWidget {
  final String title;
  final String helper;
  final Widget child;

  const _WarningCard({
    required this.title,
    required this.helper,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF4E5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFFE1B8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              const Icon(Icons.warning_amber_rounded, color: Color(0xFFB35A00)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFFB35A00),
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          child,
          const SizedBox(height: 6),
          Text(
            helper,
            style: const TextStyle(
              color: Color(0xFFB35A00),
              fontWeight: FontWeight.w700,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;

  const _SummaryRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: <Widget>[
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFF6B7895),
                fontWeight: FontWeight.w800,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              value.isEmpty ? '-' : value,
              style: const TextStyle(
                color: Color(0xFF0B1B4B),
                fontWeight: FontWeight.w900,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AddItemSheet extends StatefulWidget {
  final String currency;

  const _AddItemSheet({required this.currency});

  @override
  State<_AddItemSheet> createState() => _AddItemSheetState();
}

class _AddItemSheetState extends State<_AddItemSheet> {
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _qtyController = TextEditingController(text: '1');
  final TextEditingController _priceController = TextEditingController(text: '0');

  @override
  void dispose() {
    _descController.dispose();
    _qtyController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  int _parseInt(String v, {int fallback = 1}) {
    return int.tryParse(v.trim()) ?? fallback;
  }

  double _parseDouble(String v, {double fallback = 0}) {
    return double.tryParse(v.trim()) ?? fallback;
  }

  @override
  Widget build(BuildContext context) {
    final double bottomPad = MediaQuery.of(context).viewInsets.bottom;

    InputDecoration dec({required String label, String? hint}) {
      return InputDecoration(
        labelText: label,
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFF9AA5B6)),
        filled: true,
        fillColor: Colors.white,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
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

    return Padding(
      padding: EdgeInsets.fromLTRB(18, 6, 18, 18 + bottomPad),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          const Text(
            'Add Item',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF0B1B4B),
              fontWeight: FontWeight.w900,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _descController,
            decoration: dec(label: 'Description', hint: 'Product or service'),
          ),
          const SizedBox(height: 12),
          Row(
            children: <Widget>[
              Expanded(
                child: TextField(
                  controller: _qtyController,
                  keyboardType: TextInputType.number,
                  decoration: dec(label: 'Qty'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _priceController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: dec(label: 'Price (${widget.currency})'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              final CreditNoteItem item = CreditNoteItem(
                description: _descController.text.trim().isEmpty
                    ? 'Custom item'
                    : _descController.text.trim(),
                qty: _parseInt(_qtyController.text, fallback: 1),
                price: _parseDouble(_priceController.text, fallback: 0),
                discountPercent: 0,
                vatCategory: 'S - 15%',
                taxPercent: 15,
              );
              Navigator.of(context).pop(item);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              textStyle: const TextStyle(fontWeight: FontWeight.w900),
            ),
            child: const Text('Add Item'),
          ),
        ],
      ),
    );
  }
}
