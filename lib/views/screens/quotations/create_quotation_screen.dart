import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';

import '../../../controllers/create_quotation_controller.dart';
import '../../../models/customer.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_responsive.dart';
import '../../../models/product.dart';
import '../../../models/quotation.dart';
import '../../../repositories/product_repository.dart';

class CreateQuotationScreen extends StatefulWidget {
  const CreateQuotationScreen({super.key});

  @override
  State<CreateQuotationScreen> createState() => _CreateQuotationScreenState();
}

class _QuickAddCustomerSheet extends StatefulWidget {
  const _QuickAddCustomerSheet();

  @override
  State<_QuickAddCustomerSheet> createState() => _QuickAddCustomerSheetState();
}

class _QuickAddCustomerSheetState extends State<_QuickAddCustomerSheet> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _taxIdController = TextEditingController();
  String _type = 'B2B';

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _taxIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final CreateQuotationController ctrl = context.watch<CreateQuotationController>();

    InputDecoration dec({required String label, String? hint}) {
      return InputDecoration(
        labelText: label,
        hintText: hint,
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

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          16,
          8,
          16,
          16 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const Text(
                'New Customer',
                style: TextStyle(
                  color: Color(0xFF0B1B4B),
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _nameController,
                decoration: dec(label: 'Customer Name*'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _type,
                isExpanded: true,
                items: const <String>['B2B', 'B2C']
                    .map(
                      (String e) => DropdownMenuItem<String>(
                        value: e,
                        child: Text(e),
                      ),
                    )
                    .toList(),
                onChanged: (String? v) {
                  if (v == null) return;
                  setState(() => _type = v);
                },
                decoration: dec(label: 'Customer Type*'),
                icon: const Icon(Icons.keyboard_arrow_down_rounded),
                borderRadius: BorderRadius.circular(12),
                dropdownColor: Colors.white,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _emailController,
                decoration: dec(label: 'Email', hint: 'Optional'),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _phoneController,
                decoration: dec(label: 'Phone', hint: 'Optional'),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _taxIdController,
                decoration: dec(label: 'Tax ID', hint: 'Optional'),
                keyboardType: TextInputType.number,
              ),
              if ((ctrl.errorMessage ?? '').trim().isNotEmpty) ...<Widget>[
                const SizedBox(height: 10),
                Text(
                  ctrl.errorMessage!.trim(),
                  style: const TextStyle(
                    color: Color(0xFFD93025),
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
              ],
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: ctrl.isCreatingCustomer
                    ? null
                    : () async {
                        final String name = _nameController.text.trim();
                        if (name.isEmpty) return;
                        final Customer? created = await context
                            .read<CreateQuotationController>()
                            .createCustomerQuick(
                              customerName: name,
                              customerType: _type,
                              email: _emailController.text.trim(),
                              phone: _phoneController.text.trim(),
                              taxId: _taxIdController.text.trim(),
                            );
                        if (!mounted) return;
                        if (created != null) {
                          Navigator.of(context).pop();
                        }
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
                child: ctrl.isCreatingCustomer
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Create Customer'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CreateQuotationScreenState extends State<CreateQuotationScreen> {
  bool _requestedInitial = false;

  Future<void> _openQuickAddCustomerSheet() async {
    final CreateQuotationController ctrl =
        context.read<CreateQuotationController>();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (_) => ChangeNotifierProvider<CreateQuotationController>.value(
        value: ctrl,
        child: const _QuickAddCustomerSheet(),
      ),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_requestedInitial) return;
    _requestedInitial = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await context.read<CreateQuotationController>().loadCustomers();
    });
  }

  void _nextStep() {
    final CreateQuotationController ctrl = context
        .read<CreateQuotationController>();
    final bool ok = ctrl.nextStep();
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please complete this step to continue')),
      );
    }
  }

  void _prevStep() {
    context.read<CreateQuotationController>().prevStep();
  }

  void _goToStep(int step) {
    context.read<CreateQuotationController>().goToStep(step);
  }

  Future<void> _pickIssueDate() async {
    final CreateQuotationController ctrl = context
        .read<CreateQuotationController>();
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

  Future<void> _pickValidUntil() async {
    final CreateQuotationController ctrl = context
        .read<CreateQuotationController>();
    final DateTime now = DateTime.now();
    final DateTime initial = ctrl.validUntil ?? ctrl.issueDate ?? now;

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020, 1, 1),
      lastDate: DateTime(now.year + 3, 12, 31),
    );

    if (!mounted) {
      return;
    }

    ctrl.setValidUntil(picked);
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
    final CreateQuotationController ctrl = context
        .read<CreateQuotationController>();
    final QuotationItem? item = await showModalBottomSheet<QuotationItem>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (_) => _AddItemSheet(
        currency: ctrl.currency,
        companyId: ctrl.companyId ?? '',
      ),
    );

    if (!mounted || item == null) {
      return;
    }

    ctrl.addItem(item);
  }

  Future<void> _openEditItemSheet(int index, QuotationItem initial) async {
    final CreateQuotationController ctrl = context
        .read<CreateQuotationController>();
    final QuotationItem? item = await showModalBottomSheet<QuotationItem>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (_) => _AddItemSheet(
        currency: ctrl.currency,
        initialItem: initial,
        companyId: ctrl.companyId ?? '',
      ),
    );

    if (!mounted || item == null) {
      return;
    }

    ctrl.updateItemAt(index, item);
  }

  void _submit() {
    () async {
      final CreateQuotationController ctrl = context
          .read<CreateQuotationController>();
      final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
      final Quotation? created = await ctrl.submit();
      if (!mounted) return;
      if (created != null) {
        Navigator.of(context).pop(created);
        return;
      }
      final String msg = ctrl.errorMessage ?? 'Failed to create quotation';
      if (msg.trim().isNotEmpty) {
        messenger.showSnackBar(SnackBar(content: Text(msg)));
      }
    }();
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
        final CreateQuotationController ctrl = context
            .watch<CreateQuotationController>();

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

        final List<String> stepTitles = <String>['Details', 'Items', 'Review'];

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
                  const Icon(
                    Icons.receipt_long_outlined,
                    color: Color(0xFF9AA5B6),
                  ),
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
                final QuotationItem it = e.value;
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
                            Wrap(
                              spacing: 10,
                              runSpacing: 6,
                              children: <Widget>[
                                Text(
                                  'Qty: ${it.qty}',
                                  style: const TextStyle(
                                    color: Color(0xFF6B7895),
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12,
                                  ),
                                ),
                                Text(
                                  'Price: ${it.price.toStringAsFixed(2)} ${ctrl.currency}',
                                  style: const TextStyle(
                                    color: Color(0xFF6B7895),
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12,
                                  ),
                                ),
                                Text(
                                  'Discount: ${it.discountPercent.toStringAsFixed(2)}%',
                                  style: const TextStyle(
                                    color: Color(0xFF6B7895),
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12,
                                  ),
                                ),
                                Text(
                                  'VAT: ${it.vatCategory}',
                                  style: const TextStyle(
                                    color: Color(0xFF6B7895),
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12,
                                  ),
                                ),
                                Text(
                                  'Tax: ${it.taxPercent.toStringAsFixed(2)}%',
                                  style: const TextStyle(
                                    color: Color(0xFF6B7895),
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: <Widget>[
                          Text(
                            '${it.total.toStringAsFixed(2)} ${ctrl.currency}',
                            style: const TextStyle(
                              color: Color(0xFF0B1B4B),
                              fontWeight: FontWeight.w900,
                              fontSize: 12,
                            ),
                          ),
                          if (editable) ...<Widget>[
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              alignment: WrapAlignment.end,
                              children: <Widget>[
                                IconButton(
                                  onPressed: () => _openEditItemSheet(e.key, it),
                                  icon: const Icon(Icons.edit_outlined, size: 18),
                                  color: const Color(0xFF9AA5B6),
                                ),
                                Container(
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF7FAFF),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: const Color(0xFFE9EEF5),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: <Widget>[
                                      IconButton(
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(
                                          minWidth: 32,
                                          minHeight: 32,
                                        ),
                                        onPressed: () => ctrl.decrementQtyAt(e.key),
                                        icon: const Icon(
                                          Icons.remove,
                                          size: 18,
                                          color: Color(0xFF6B7895),
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                        ),
                                        child: Text(
                                          '${it.qty}',
                                          style: const TextStyle(
                                            color: Color(0xFF0B1B4B),
                                            fontWeight: FontWeight.w900,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                      IconButton(
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(
                                          minWidth: 32,
                                          minHeight: 32,
                                        ),
                                        onPressed: () => ctrl.incrementQtyAt(e.key),
                                        icon: const Icon(
                                          Icons.add,
                                          size: 18,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  onPressed: () => ctrl.removeItemAt(e.key),
                                  icon: const Icon(Icons.close, size: 18),
                                  color: const Color(0xFF9AA5B6),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
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
              const SizedBox(height: 10),
              Row(
                children: <Widget>[
                  const Expanded(
                    child: Text(
                      'Total',
                      style: TextStyle(
                        color: Color(0xFF0B1B4B),
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  Flexible(
                    child: Text(
                      '${ctrl.total.toStringAsFixed(2)} ${ctrl.currency}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          );
        }

        Widget stepContent() {
          switch (ctrl.currentStep) {
            case 0:
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  _SectionCard(
                    title: 'Quotation Details',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        _LabeledDropdown<String>(
                          label: 'Company*',
                          value: ctrl.company,
                          items: <String>[ctrl.company],
                          onChanged: (String v) => ctrl.company = v,
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: <Widget>[
                            Expanded(
                              child: TextField(
                                controller: ctrl.quotationNumberController,
                                decoration: _dec(label: 'Quotation #'),
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
                        Row(
                          children: <Widget>[
                            Expanded(
                              child: _DateField(
                                label: 'Valid Until',
                                value: _fmtDate(ctrl.validUntil),
                                onTap: _pickValidUntil,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _LabeledDropdown<String>(
                                label: 'Currency',
                                value: ctrl.currency,
                                items: const <String>['SAR', 'USD', 'EUR'],
                                onChanged: (String v) => ctrl.currency = v,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _LabeledDropdown<String>(
                          label: 'Payment Terms',
                          value: ctrl.paymentTerms,
                          items: const <String>[
                            'Due on Receipt',
                            'Net 15 days',
                            'Net 30 days',
                            'Net 45 days',
                            'Net 60 days',
                          ],
                          onChanged: (String v) => ctrl.paymentTerms = v,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  _SectionCard(
                    title: 'Customer',
                    child: ctrl.isLoadingCustomers
                        ? const Center(
                            child: Padding(
                              padding: EdgeInsets.symmetric(vertical: 10),
                              child: CircularProgressIndicator(
                                color: AppColors.primary,
                              ),
                            ),
                          )
                        : Builder(
                            builder: (BuildContext context) {
                              final String q =
                                  ctrl.customerController.text.trim().toLowerCase();
                              final List<Customer> filtered = ctrl.customers
                                  .where((Customer c) {
                                    if (q.isEmpty) return true;
                                    return c.name.toLowerCase().contains(q) ||
                                        c.id.toLowerCase().contains(q);
                                  })
                                  .toList();
                              final List<String> ids = filtered
                                  .map((Customer c) => c.id)
                                  .where((String id) => id.trim().isNotEmpty)
                                  .toList();
                              final String? selected = ctrl.selectedCustomerId;
                              final String? safeSelected =
                                  (selected != null && ids.contains(selected))
                                      ? selected
                                      : null;

                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: <Widget>[
                                  TextField(
                                    controller: ctrl.customerController,
                                    onChanged: (_) => setState(() {}),
                                    decoration: _dec(
                                      label: 'Search Customer',
                                      hint: 'Type name or ID...',
                                      prefix: const Icon(
                                        Icons.search,
                                        color: Color(0xFF9AA5B6),
                                      ),
                                    ),
                                    style: const TextStyle(
                                      color: Color(0xFF0B1B4B),
                                      fontWeight: FontWeight.w800,
                                      fontSize: 13,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: TextButton.icon(
                                      onPressed: ctrl.isCreatingCustomer
                                          ? null
                                          : _openQuickAddCustomerSheet,
                                      icon: ctrl.isCreatingCustomer
                                          ? const SizedBox(
                                              width: 16,
                                              height: 16,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: AppColors.primary,
                                              ),
                                            )
                                          : const Icon(Icons.add, size: 18),
                                      label: const Text('New Customer'),
                                      style: TextButton.styleFrom(
                                        foregroundColor: AppColors.primary,
                                        textStyle: const TextStyle(
                                          fontWeight: FontWeight.w900,
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 6,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  _LabeledDropdown<String>(
                                    label: 'Select Customer*',
                                    value: safeSelected,
                                    items: ids,
                                    itemBuilder: (String id) {
                                      final Customer? c = ctrl.customers
                                          .cast<Customer?>()
                                          .firstWhere(
                                            (Customer? c) => c?.id == id,
                                            orElse: () => null,
                                          );
                                      return c == null
                                          ? id
                                          : '${c.name} (${c.id})';
                                    },
                                    onChanged: (String v) {
                                      final Customer? c = ctrl.customers
                                          .cast<Customer?>()
                                          .firstWhere(
                                            (Customer? c) => c?.id == v,
                                            orElse: () => null,
                                          );
                                      ctrl.selectCustomer(c);
                                    },
                                  ),
                                ],
                              );
                            },
                          ),
                  ),
                  const SizedBox(height: 12),
                  _SectionCard(
                    title: 'Notes & Terms',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        TextField(
                          controller: ctrl.notesController,
                          maxLines: 3,
                          decoration: _dec(
                            label: 'Notes',
                            hint: 'Optional notes for customer...',
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: ctrl.termsController,
                          maxLines: 3,
                          decoration: _dec(
                            label: 'Terms & Conditions',
                            hint: 'Optional terms for this quotation...',
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            case 1:
              return _SectionCard(
                title: 'Items',
                trailing: TextButton.icon(
                  onPressed: _openAddItemSheet,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add Item'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    textStyle: const TextStyle(fontWeight: FontWeight.w800),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                ),
                child: itemsBlock(editable: true),
              );
            case 2:
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  _SectionCard(
                    title: 'Summary',
                    child: Column(
                      children: <Widget>[
                        _SummaryRow(
                          label: 'Quotation #',
                          value: ctrl.quotationNumberController.text.trim(),
                        ),
                        _SummaryRow(
                          label: 'Issue Date',
                          value: _fmtDate(ctrl.issueDate),
                        ),
                        _SummaryRow(
                          label: 'Valid Until',
                          value: _fmtDate(ctrl.validUntil),
                        ),
                        _SummaryRow(
                          label: 'Customer',
                          value: ctrl.customerController.text.trim(),
                        ),
                        _SummaryRow(
                          label: 'Payment Terms',
                          value: ctrl.paymentTerms,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: gap),
                  _SectionCard(
                    title: 'Items',
                    child: itemsBlock(editable: false),
                  ),
                ],
              );
            default:
              return const SizedBox.shrink();
          }
        }

        return Scaffold(
          backgroundColor: const Color(0xFFF7FAFF),
          appBar: AppBar(
            title: const Text('Create Quotation'),
            leading: const BackButton(),
          ),
          body: SafeArea(
            child: AbsorbPointer(
              absorbing: ctrl.isSubmitting,
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
                  _WizardHeader(
                    titles: stepTitles,
                    currentStep: ctrl.currentStep,
                    maxStepReached: ctrl.maxStepReached,
                    onTapStep: _goToStep,
                  ),
                  SizedBox(height: gap),
                  stepContent(),
                ],
              ),
            ),
            ),
          ),
          bottomNavigationBar: SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Color(0xFFE9EEF5))),
              ),
              child: ctrl.currentStep == 2
                  ? Row(
                      children: <Widget>[
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFFE9EEF5)),
                            color: Colors.white,
                          ),
                          child: IconButton(
                            onPressed: () {},
                            icon: const Icon(
                              Icons.remove_red_eye_outlined,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: ctrl.isSubmitting ? null : _submit,
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
                            child: ctrl.isSubmitting
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text('Save Quotation'),
                          ),
                        ),
                      ],
                    )
                  : Row(
                      children: <Widget>[
                        Expanded(
                          child: OutlinedButton(
                            onPressed: ctrl.currentStep == 0 ? null : _prevStep,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF0B1B4B),
                              side: const BorderSide(color: Color(0xFFE9EEF5)),
                              padding: const EdgeInsets.symmetric(vertical: 14),
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
                              padding: const EdgeInsets.symmetric(vertical: 14),
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

class _WizardHeader extends StatelessWidget {
  final List<String> titles;
  final int currentStep;
  final int maxStepReached;
  final ValueChanged<int> onTapStep;

  const _WizardHeader({
    required this.titles,
    required this.currentStep,
    required this.maxStepReached,
    required this.onTapStep,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE9EEF5)),
      ),
      child: Row(
        children: List<Widget>.generate(titles.length, (int i) {
          final bool isActive = i == currentStep;
          final bool isDone = i < currentStep;
          final bool isEnabled = i <= maxStepReached;

          return Expanded(
            child: InkWell(
              onTap: isEnabled ? () => onTapStep(i) : null,
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: isDone || isActive
                            ? AppColors.primary
                            : const Color(0xFFF3F6FB),
                        borderRadius: BorderRadius.circular(999),
                        border: isActive
                            ? Border.all(color: AppColors.primary, width: 2)
                            : null,
                      ),
                      child: Center(
                        child: Text(
                          '${i + 1}',
                          style: TextStyle(
                            color: isDone || isActive
                                ? Colors.white
                                : const Color(0xFF9AA5B6),
                            fontWeight: FontWeight.w900,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      titles[i],
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: isActive
                            ? const Color(0xFF0B1B4B)
                            : const Color(0xFF9AA5B6),
                        fontWeight: FontWeight.w800,
                        fontSize: 11,
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

  const _SectionCard({required this.title, required this.child, this.trailing});

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
  final T? value;
  final List<T> items;
  final ValueChanged<T> onChanged;
  final String Function(T v)? itemBuilder;

  const _LabeledDropdown({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
    this.itemBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      key: ValueKey<T?>(value),
      initialValue: value,
      isExpanded: true,
      items: items
          .map(
            (T e) => DropdownMenuItem<T>(
              value: e,
              child: Text(
                itemBuilder == null ? e.toString() : itemBuilder!(e),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          )
          .toList(),
      onChanged: (T? v) {
        if (v == null) return;
        onChanged(v);
      },
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
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
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 14,
          ),
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
  final QuotationItem? initialItem;
  final String companyId;

  const _AddItemSheet({
    required this.currency,
    required this.companyId,
    this.initialItem,
  });

  @override
  State<_AddItemSheet> createState() => _AddItemSheetState();
}

class _AddItemSheetState extends State<_AddItemSheet> {
  final TextEditingController _productSearchController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _qtyController = TextEditingController(text: '1');
  final TextEditingController _priceController = TextEditingController(
    text: '0',
  );
  final TextEditingController _discountController = TextEditingController(
    text: '0',
  );
  final TextEditingController _taxController = TextEditingController(
    text: '15',
  );

  String _vatCategory = 'S - 15%';

  Timer? _searchDebounce;
  Product? _selectedProduct;
  List<Product> _suggestions = const <Product>[];
  bool _isSearching = false;
  String? _productError;

  @override
  void initState() {
    super.initState();
    final QuotationItem? it = widget.initialItem;
    if (it == null) return;
    if (it.productId.trim().isNotEmpty) {
      _productSearchController.text = it.description;
    }
    _descController.text = it.description;
    _qtyController.text = it.qty.toString();
    _priceController.text = it.price.toString();
    _discountController.text = it.discountPercent.toString();
    _taxController.text = it.taxPercent.toString();
    _vatCategory = it.vatCategory;
    const List<String> vatOptions = <String>[
      'S - 15%',
      'Z - 0%',
      'E - Exempt',
    ];
    if (!vatOptions.contains(_vatCategory)) {
      _vatCategory = 'S - 15%';
    }
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _productSearchController.dispose();
    _descController.dispose();
    _qtyController.dispose();
    _priceController.dispose();
    _discountController.dispose();
    _taxController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String _) {
    _searchDebounce?.cancel();
    setState(() {
      _selectedProduct = null;
      _productError = null;
    });
    _searchDebounce = Timer(const Duration(milliseconds: 350), () {
      _searchProducts();
    });
  }

  Future<void> _searchProducts() async {
    final String q = _productSearchController.text.trim();
    if (q.isEmpty) {
      if (!mounted) return;
      setState(() {
        _suggestions = const <Product>[];
        _isSearching = false;
        _productError = null;
      });
      return;
    }

    final String companyId = widget.companyId.trim();
    if (companyId.isEmpty) {
      if (!mounted) return;
      setState(() {
        _suggestions = const <Product>[];
        _isSearching = false;
        _productError = 'Please select a company first';
      });
      return;
    }

    if (!mounted) return;
    setState(() {
      _isSearching = true;
      _productError = null;
    });

    try {
      final List<Product> products = await context.read<ProductRepository>().listProducts(
            companyId: companyId,
            page: 1,
            limit: 20,
            search: q,
          );
      if (!mounted) return;
      setState(() {
        _suggestions = products;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _suggestions = const <Product>[];
        _productError = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() => _isSearching = false);
      }
    }
  }

  void _selectProduct(Product p) {
    final double tax = p.taxRate;
    setState(() {
      _selectedProduct = p;
      _suggestions = const <Product>[];
      _productError = null;
      _productSearchController.text = p.name;
      _descController.text = p.name;
      _priceController.text = p.price.toString();
      _taxController.text = tax.toString();
      if (tax.abs() < 0.000001) {
        _vatCategory = 'Z - 0%';
      } else {
        _vatCategory = 'S - 15%';
      }
    });
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
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
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
          Text(
            widget.initialItem == null ? 'Add Item' : 'Edit Item',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF0B1B4B),
              fontWeight: FontWeight.w900,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _productSearchController,
            onChanged: _onSearchChanged,
            decoration: dec(
              label: 'Product',
              hint: 'Search by name or SKU...',
            ),
          ),
          const SizedBox(height: 8),
          if (_isSearching)
            const SizedBox(
              height: 28,
              child: Center(
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else if (_suggestions.isNotEmpty)
            Container(
              constraints: const BoxConstraints(maxHeight: 180),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE9EEF5)),
              ),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: _suggestions.length,
                separatorBuilder: (BuildContext context, int index) =>
                    const Divider(height: 1),
                itemBuilder: (BuildContext context, int index) {
                  final Product p = _suggestions[index];
                  final String sku = p.sku.trim();
                  return ListTile(
                    dense: true,
                    title: Text(
                      p.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF0B1B4B),
                        fontWeight: FontWeight.w900,
                        fontSize: 13,
                      ),
                    ),
                    subtitle: sku.isEmpty
                        ? null
                        : Text(
                            'SKU: $sku',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xFF6B7895),
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                    onTap: () => _selectProduct(p),
                  );
                },
              ),
            )
          else if (_productSearchController.text.trim().isNotEmpty)
            const Text(
              'No products found',
              style: TextStyle(
                color: Color(0xFF6B7895),
                fontWeight: FontWeight.w800,
                fontSize: 12,
              ),
            ),
          if (_selectedProduct != null) ...<Widget>[
            const SizedBox(height: 8),
            Text(
              'Selected: ${_selectedProduct!.name}',
              style: const TextStyle(
                color: Color(0xFF6B7895),
                fontWeight: FontWeight.w800,
                fontSize: 12,
              ),
            ),
          ],
          if (_productError != null && _productError!.trim().isNotEmpty) ...<Widget>[
            const SizedBox(height: 8),
            Text(
              _productError!,
              style: const TextStyle(
                color: Color(0xFFD93025),
                fontWeight: FontWeight.w800,
                fontSize: 12,
              ),
            ),
          ],
          const SizedBox(height: 12),
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
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: dec(label: 'Price (${widget.currency})'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: <Widget>[
              Expanded(
                child: TextField(
                  controller: _discountController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: dec(label: 'Discount %', hint: '0'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<String>(
                  key: ValueKey<String>(_vatCategory),
                  initialValue: _vatCategory,
                  isExpanded: true,
                  items: const <String>['S - 15%', 'Z - 0%', 'E - Exempt']
                      .map(
                        (String e) => DropdownMenuItem<String>(
                          value: e,
                          child: Text(e, overflow: TextOverflow.ellipsis),
                        ),
                      )
                      .toList(),
                  onChanged: (String? v) {
                    if (v == null) return;
                    setState(() => _vatCategory = v);
                  },
                  decoration: dec(label: 'VAT Category'),
                  icon: const Icon(Icons.keyboard_arrow_down_rounded),
                  borderRadius: BorderRadius.circular(12),
                  dropdownColor: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _taxController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: dec(label: 'Tax %', hint: '15'),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              final QuotationItem item = QuotationItem(
                productId: _selectedProduct?.id ?? widget.initialItem?.productId ?? '',
                description: _descController.text.trim().isEmpty
                    ? 'Custom item'
                    : _descController.text.trim(),
                qty: _parseInt(_qtyController.text, fallback: 1),
                price: _parseDouble(_priceController.text, fallback: 0),
                discountPercent: _parseDouble(
                  _discountController.text,
                  fallback: 0,
                ),
                vatCategory: _vatCategory,
                taxPercent: _parseDouble(_taxController.text, fallback: 15),
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
            child: Text(widget.initialItem == null ? 'Add Item' : 'Save Changes'),
          ),
        ],
      ),
    );
  }
}
