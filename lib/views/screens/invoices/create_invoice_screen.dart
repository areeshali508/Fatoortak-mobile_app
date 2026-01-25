import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../controllers/create_invoice_controller.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_responsive.dart';
import '../../../models/invoice.dart';
import '../../layout/app_drawer.dart';

class CreateInvoiceScreen extends StatefulWidget {
  const CreateInvoiceScreen({super.key});

  @override
  State<CreateInvoiceScreen> createState() => _CreateInvoiceScreenState();
}

class _CreateInvoiceScreenState extends State<CreateInvoiceScreen> {
  void _nextStep() {
    final CreateInvoiceController ctrl = context
        .read<CreateInvoiceController>();
    final bool ok = ctrl.nextStep();
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please complete this step to continue')),
      );
    }
  }

  void _prevStep() {
    final CreateInvoiceController ctrl = context
        .read<CreateInvoiceController>();
    ctrl.prevStep();
  }

  void _goToStep(int step) {
    final CreateInvoiceController ctrl = context
        .read<CreateInvoiceController>();
    ctrl.goToStep(step);
  }

  void _submitInvoice({required bool draft}) {
    final CreateInvoiceController ctrl = context
        .read<CreateInvoiceController>();
    final String? message = ctrl.validateSubmit(draft: draft);
    if (message != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
      return;
    }

    final InvoiceStatus status = draft
        ? InvoiceStatus.draft
        : InvoiceStatus.sent;
    final Invoice invoice = ctrl.buildInvoice(status: status);
    Navigator.of(context).pop(invoice);
  }

  Future<void> _openPreviewSheet() async {
    final CreateInvoiceController ctrl = context
        .read<CreateInvoiceController>();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (BuildContext ctx) {
        return _InvoicePreviewSheet(
          company: ctrl.company,
          customerType: ctrl.customerType,
          invoiceType: ctrl.invoiceType,
          invoiceNumber: ctrl.invoiceNumberController.text.trim(),
          issueDate: _fmtDate(ctrl.issueDate),
          dueDate: _fmtDate(ctrl.dueDate),
          customer: ctrl.customerController.text.trim(),
          currency: ctrl.currency,
          paymentTerms: ctrl.paymentTerms,
          items: List<InvoiceItem>.unmodifiable(ctrl.items),
          notes: ctrl.notesController.text.trim(),
          terms: ctrl.termsController.text.trim(),
          subtotal: ctrl.subtotal,
          vat: ctrl.vatAmount,
          total: ctrl.total,
        );
      },
    );
  }

  Future<void> _openAddItemSheet() async {
    final CreateInvoiceController ctrl = context
        .read<CreateInvoiceController>();
    final InvoiceItem? item = await showModalBottomSheet<InvoiceItem>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (BuildContext ctx) {
        return _AddItemSheet(currency: ctrl.currency);
      },
    );

    if (!mounted || item == null) {
      return;
    }

    ctrl.addItem(item);
  }

  Future<void> _pickDate({required bool issue}) async {
    final CreateInvoiceController ctrl = context
        .read<CreateInvoiceController>();
    final DateTime now = DateTime.now();
    final DateTime initial = (issue ? ctrl.issueDate : ctrl.dueDate) ?? now;

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020, 1, 1),
      lastDate: DateTime(now.year + 3, 12, 31),
    );

    if (!mounted || picked == null) {
      return;
    }

    if (issue) {
      ctrl.setIssueDate(picked);
    } else {
      ctrl.setDueDate(picked);
    }
  }

  String _fmtDate(DateTime? d) {
    if (d == null) {
      return 'mm/dd/yyyy';
    }
    final String mm = d.month.toString().padLeft(2, '0');
    final String dd = d.day.toString().padLeft(2, '0');
    return '$mm/$dd/${d.year}';
  }

  InputDecoration _decoration({
    required String label,
    Widget? prefix,
    Widget? suffix,
    String? hint,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: prefix,
      suffixIcon: suffix,
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
        final CreateInvoiceController ctrl = context
            .watch<CreateInvoiceController>();
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

        final List<String> stepTitles = <String>[
          'Invoice Details',
          'Customer',
          'Items',
          'Review',
        ];

        Widget stepContent() {
          switch (ctrl.currentStep) {
            case 0:
              return _SectionCard(
                title: 'Invoice Details',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    _LabeledDropdown<String>(
                      label: 'Select Company',
                      value: ctrl.company,
                      items: const <String>[
                        'Tech Solutions Ltd.',
                        'Fatoortak Business',
                      ],
                      onChanged: (String v) => ctrl.company = v,
                    ),
                    const SizedBox(height: 12),
                    _LabeledDropdown<String>(
                      label: 'Customer Type',
                      value: ctrl.customerType,
                      items: const <String>[
                        'B2B (Business)',
                        'B2C (Individual)',
                      ],
                      onChanged: (String v) => ctrl.customerType = v,
                    ),
                    const SizedBox(height: 12),
                    _LabeledDropdown<String>(
                      label: 'Invoice Type (ZATCA)',
                      value: ctrl.invoiceType,
                      items: const <String>[
                        'Tax Invoice (Standard)',
                        'Simplified Tax Invoice',
                      ],
                      onChanged: (String v) => ctrl.invoiceType = v,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: ctrl.invoiceNumberController,
                      onChanged: (_) => ctrl.refresh(),
                      decoration: _decoration(
                        label: 'Invoice Number',
                        suffix: IconButton(
                          onPressed: () {
                            ctrl.invoiceNumberController.text =
                                'INV-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
                            ctrl.refresh();
                          },
                          icon: const Icon(
                            Icons.refresh,
                            size: 20,
                            color: Color(0xFF9AA5B6),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: _DateField(
                            label: 'Issue Date',
                            value: _fmtDate(ctrl.issueDate),
                            onTap: () => _pickDate(issue: true),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _DateField(
                            label: 'Due Date',
                            value: _fmtDate(ctrl.dueDate),
                            onTap: () => _pickDate(issue: false),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            case 1:
              return _SectionCard(
                title: 'Customer & Payment',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    TextField(
                      controller: ctrl.customerController,
                      onChanged: (_) => ctrl.refresh(),
                      decoration: _decoration(
                        label: 'Search Customer',
                        hint: 'Type name or ID...',
                        prefix: const Icon(
                          Icons.search,
                          color: Color(0xFF9AA5B6),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: _LabeledDropdown<String>(
                            label: 'Currency',
                            value: ctrl.currency,
                            items: const <String>['SAR', 'USD', 'EUR'],
                            onChanged: (String v) => ctrl.currency = v,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _LabeledDropdown<String>(
                            label: 'Payment Terms',
                            value: ctrl.paymentTerms,
                            items: const <String>[
                              'Immediate',
                              'Net 7',
                              'Net 15',
                              'Net 30',
                            ],
                            onChanged: (String v) => ctrl.paymentTerms = v,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            case 2:
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
                child: ctrl.items.isEmpty
                    ? Container(
                        height: 100,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: const Color(0xFFE9EEF5),
                            width: 1,
                          ),
                        ),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              Container(
                                width: 44,
                                height: 44,
                                decoration: const BoxDecoration(
                                  color: Color(0xFFF3F6FB),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.shopping_cart_outlined,
                                  color: Color(0xFF9AA5B6),
                                ),
                              ),
                              const SizedBox(height: 10),
                              const Text(
                                'No items added yet',
                                style: TextStyle(
                                  color: Color(0xFF9AA5B6),
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          ...ctrl.items.asMap().entries.map((
                            MapEntry<int, InvoiceItem> entry,
                          ) {
                            final int idx = entry.key;
                            final InvoiceItem item = entry.value;
                            return _ItemCard(
                              item: item,
                              currency: ctrl.currency,
                              onDecrementQty: () {
                                ctrl.decrementQtyAt(idx);
                              },
                              onIncrementQty: () {
                                ctrl.incrementQtyAt(idx);
                              },
                              showQtyStepper: true,
                              onRemove: () {
                                ctrl.removeItemAt(idx);
                              },
                            );
                          }),
                        ],
                      ),
              );
            case 3:
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  _SectionCard(
                    title: 'Additional Info',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        TextField(
                          controller: ctrl.notesController,
                          maxLines: 3,
                          onChanged: (_) => ctrl.refresh(),
                          decoration: _decoration(
                            label: 'Notes',
                            hint: 'Enter notes visible to customer...',
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: ctrl.termsController,
                          maxLines: 3,
                          onChanged: (_) => ctrl.refresh(),
                          decoration: _decoration(
                            label: 'Terms & Conditions',
                            hint: 'Enter legal terms...',
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: gap),
                  _TotalsSummary(
                    subtotal: ctrl.subtotal,
                    vat: ctrl.vatAmount,
                    total: ctrl.total,
                    currency: ctrl.currency,
                  ),
                ],
              );
            default:
              return const SizedBox.shrink();
          }
        }

        return Scaffold(
          backgroundColor: const Color(0xFFF7FAFF),
          drawer: const AppDrawer(),
          appBar: AppBar(
            title: const Text('Create Invoice'),
            leading: Builder(
              builder: (BuildContext context) {
                return IconButton(
                  icon: const Icon(Icons.menu),
                  onPressed: () => Scaffold.of(context).openDrawer(),
                );
              },
            ),
            actions: <Widget>[
              IconButton(
                onPressed: () {},
                icon: Stack(
                  clipBehavior: Clip.none,
                  children: <Widget>[
                    const Icon(Icons.notifications_none_rounded),
                    Positioned(
                      right: -1,
                      top: -1,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Color(0xFFE53935),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: CircleAvatar(
                  radius: 14,
                  backgroundColor: const Color(0xFFEAF0FF),
                  child: const Icon(
                    Icons.person,
                    size: 18,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
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
                  170,
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
          bottomNavigationBar: SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Color(0xFFE9EEF5))),
              ),
              child: ctrl.currentStep == 3
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
                            onPressed: _openPreviewSheet,
                            icon: const Icon(
                              Icons.remove_red_eye_outlined,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => _submitInvoice(draft: true),
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
                            child: const Text('Save Draft'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => _submitInvoice(draft: false),
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
                            child: const Text('Save & Send'),
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

class _ItemCard extends StatelessWidget {
  final InvoiceItem item;
  final String currency;
  final VoidCallback? onDecrementQty;
  final VoidCallback? onIncrementQty;
  final bool showQtyStepper;
  final VoidCallback onRemove;
  final bool showRemove;

  const _ItemCard({
    required this.item,
    required this.currency,
    this.onDecrementQty,
    this.onIncrementQty,
    this.showQtyStepper = false,
    required this.onRemove,
    this.showRemove = true,
  });

  String _fmt(double v) => v.toStringAsFixed(2);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
              Expanded(
                child: Text(
                  item.product,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF0B1B4B),
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '$currency ${_fmt(item.total)}',
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                ),
              ),
              if (showRemove) ...<Widget>[
                const SizedBox(width: 8),
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F6FB),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFE9EEF5)),
                  ),
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    onPressed: onRemove,
                    icon: const Icon(
                      Icons.close,
                      size: 18,
                      color: Color(0xFF9AA5B6),
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: <Widget>[
              if (showQtyStepper)
                _QtyStepper(
                  qty: item.qty,
                  onDecrement: onDecrementQty,
                  onIncrement: onIncrementQty,
                )
              else
                _MetaPill(label: 'Qty', value: '${item.qty}'),
              _MetaPill(label: 'Price', value: _fmt(item.price)),
              _MetaPill(label: 'Discount %', value: _fmt(item.discountPercent)),
              _MetaPill(label: 'VAT', value: item.vatCategory),
              _MetaPill(label: 'Tax %', value: _fmt(item.taxPercent)),
            ],
          ),
        ],
      ),
    );
  }
}

class _QtyStepper extends StatelessWidget {
  final int qty;
  final VoidCallback? onDecrement;
  final VoidCallback? onIncrement;

  const _QtyStepper({
    required this.qty,
    required this.onDecrement,
    required this.onIncrement,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF7FAFF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE9EEF5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const Text(
            'Qty',
            style: TextStyle(
              color: Color(0xFF6B7895),
              fontWeight: FontWeight.w800,
              fontSize: 11,
            ),
          ),
          const SizedBox(width: 10),
          Container(
            height: 28,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE9EEF5)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 28,
                    minHeight: 28,
                  ),
                  onPressed: onDecrement,
                  icon: const Icon(
                    Icons.remove,
                    size: 16,
                    color: Color(0xFF6B7895),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Text(
                    '$qty',
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
                    minWidth: 28,
                    minHeight: 28,
                  ),
                  onPressed: onIncrement,
                  icon: const Icon(
                    Icons.add,
                    size: 16,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MetaPill extends StatelessWidget {
  final String label;
  final String value;

  const _MetaPill({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF7FAFF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE9EEF5)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF6B7895),
              fontWeight: FontWeight.w800,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFF0B1B4B),
              fontWeight: FontWeight.w900,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _InvoicePreviewSheet extends StatelessWidget {
  final String company;
  final String customerType;
  final String invoiceType;
  final String invoiceNumber;
  final String issueDate;
  final String dueDate;
  final String customer;
  final String currency;
  final String paymentTerms;
  final List<InvoiceItem> items;
  final String notes;
  final String terms;
  final double subtotal;
  final double vat;
  final double total;

  const _InvoicePreviewSheet({
    required this.company,
    required this.customerType,
    required this.invoiceType,
    required this.invoiceNumber,
    required this.issueDate,
    required this.dueDate,
    required this.customer,
    required this.currency,
    required this.paymentTerms,
    required this.items,
    required this.notes,
    required this.terms,
    required this.subtotal,
    required this.vat,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    final double bottomPad = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 10, 16, 16 + bottomPad),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Row(
              children: <Widget>[
                const Expanded(
                  child: Text(
                    'Invoice Preview',
                    style: TextStyle(
                      color: Color(0xFF0B1B4B),
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _SectionCard(
              title: 'Invoice Details',
              child: Column(
                children: <Widget>[
                  _PreviewRow(label: 'Company', value: company),
                  _PreviewRow(label: 'Customer Type', value: customerType),
                  _PreviewRow(label: 'Invoice Type', value: invoiceType),
                  _PreviewRow(label: 'Invoice Number', value: invoiceNumber),
                  _PreviewRow(label: 'Issue Date', value: issueDate),
                  _PreviewRow(label: 'Due Date', value: dueDate),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _SectionCard(
              title: 'Customer & Payment',
              child: Column(
                children: <Widget>[
                  _PreviewRow(label: 'Customer', value: customer),
                  _PreviewRow(label: 'Currency', value: currency),
                  _PreviewRow(label: 'Payment Terms', value: paymentTerms),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _SectionCard(
              title: 'Items',
              child: items.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        'No items added yet',
                        style: TextStyle(
                          color: Color(0xFF9AA5B6),
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: items
                          .map(
                            (InvoiceItem item) => _ItemCard(
                              item: item,
                              currency: currency,
                              onRemove: () {},
                              showRemove: false,
                            ),
                          )
                          .toList(),
                    ),
            ),
            const SizedBox(height: 12),
            if (notes.isNotEmpty || terms.isNotEmpty)
              _SectionCard(
                title: 'Additional Info',
                child: Column(
                  children: <Widget>[
                    if (notes.isNotEmpty)
                      _PreviewRow(label: 'Notes', value: notes),
                    if (terms.isNotEmpty)
                      _PreviewRow(label: 'Terms & Conditions', value: terms),
                  ],
                ),
              ),
            const SizedBox(height: 12),
            _TotalsSummary(
              subtotal: subtotal,
              vat: vat,
              total: total,
              currency: currency,
            ),
          ],
        ),
      ),
    );
  }
}

class _PreviewRow extends StatelessWidget {
  final String label;
  final String value;

  const _PreviewRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: 120,
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
          .map(
            (T e) => DropdownMenuItem<T>(
              value: e,
              child: Text(e.toString(), overflow: TextOverflow.ellipsis),
            ),
          )
          .toList(),
      onChanged: (T? v) {
        if (v == null) {
          return;
        }
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

class _TotalsSummary extends StatelessWidget {
  final double subtotal;
  final double vat;
  final double total;
  final String currency;

  const _TotalsSummary({
    required this.subtotal,
    required this.vat,
    required this.total,
    required this.currency,
  });

  String _fmt(double v) {
    return v.toStringAsFixed(2);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
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
              '${_fmt(subtotal)} $currency',
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
              '${_fmt(vat)} $currency',
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
                'Total',
                style: TextStyle(
                  color: Color(0xFF0B1B4B),
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                ),
              ),
            ),
            Text(
              '${_fmt(total)} $currency',
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
}

class _AddItemSheet extends StatefulWidget {
  final String currency;

  const _AddItemSheet({required this.currency});

  @override
  State<_AddItemSheet> createState() => _AddItemSheetState();
}

class _AddItemSheetState extends State<_AddItemSheet> {
  final TextEditingController _productController = TextEditingController();
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

  @override
  void dispose() {
    _productController.dispose();
    _qtyController.dispose();
    _priceController.dispose();
    _discountController.dispose();
    _taxController.dispose();
    super.dispose();
  }

  int _parseInt(String v, {int fallback = 0}) {
    return int.tryParse(v.trim()) ?? fallback;
  }

  double _parseDouble(String v, {double fallback = 0}) {
    return double.tryParse(v.trim()) ?? fallback;
  }

  InvoiceItem _buildItem() {
    return InvoiceItem(
      product: _productController.text.trim().isEmpty
          ? 'Custom product'
          : _productController.text.trim(),
      qty: _parseInt(_qtyController.text, fallback: 1),
      price: _parseDouble(_priceController.text, fallback: 0),
      discountPercent: _parseDouble(_discountController.text, fallback: 0),
      vatCategory: _vatCategory,
      taxPercent: _parseDouble(_taxController.text, fallback: 15),
    );
  }

  String _fmt(double v) => v.toStringAsFixed(2);

  @override
  Widget build(BuildContext context) {
    final double bottomPad = MediaQuery.of(context).viewInsets.bottom;
    final InvoiceItem preview = _buildItem();

    InputDecoration inputDec({required String label, String? hint}) {
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
            controller: _productController,
            onChanged: (_) => setState(() {}),
            decoration: inputDec(
              label: 'Product',
              hint: 'Search products or type custom...',
            ),
            style: const TextStyle(
              color: Color(0xFF0B1B4B),
              fontWeight: FontWeight.w800,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: <Widget>[
              Expanded(
                child: TextField(
                  controller: _qtyController,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  onChanged: (_) => setState(() {}),
                  decoration: inputDec(label: 'Qty', hint: '1'),
                  style: const TextStyle(
                    color: Color(0xFF0B1B4B),
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _priceController,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  onChanged: (_) => setState(() {}),
                  decoration: inputDec(label: 'Price', hint: '0'),
                  style: const TextStyle(
                    color: Color(0xFF0B1B4B),
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                  ),
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
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  onChanged: (_) => setState(() {}),
                  decoration: inputDec(label: 'Discount %', hint: '0'),
                  style: const TextStyle(
                    color: Color(0xFF0B1B4B),
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<String>(
                  key: ValueKey<String>(_vatCategory),
                  initialValue: _vatCategory,
                  items: const <String>['S - 15%', 'Z - 0%', 'E - Exempt']
                      .map(
                        (String e) => DropdownMenuItem<String>(
                          value: e,
                          child: Text(
                            e,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (String? v) {
                    if (v == null) {
                      return;
                    }
                    setState(() => _vatCategory = v);
                  },
                  decoration: inputDec(label: 'VAT Category'),
                  icon: const Icon(Icons.keyboard_arrow_down_rounded),
                  borderRadius: BorderRadius.circular(12),
                  dropdownColor: Colors.white,
                  style: const TextStyle(
                    color: Color(0xFF0B1B4B),
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: <Widget>[
              Expanded(
                child: TextField(
                  controller: _taxController,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  onChanged: (_) => setState(() {}),
                  decoration: inputDec(label: 'Tax %', hint: '15'),
                  style: const TextStyle(
                    color: Color(0xFF0B1B4B),
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  height: 52,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF7FAFF),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE9EEF5)),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      const Text(
                        'Total',
                        style: TextStyle(
                          color: Color(0xFF6B7895),
                          fontWeight: FontWeight.w800,
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${widget.currency} ${_fmt(preview.total)}',
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w900,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: <Widget>[
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF0B1B4B),
                    side: const BorderSide(color: Color(0xFFE9EEF5)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    textStyle: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    final InvoiceItem item = _buildItem();
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
              ),
            ],
          ),
        ],
      ),
    );
  }
}
