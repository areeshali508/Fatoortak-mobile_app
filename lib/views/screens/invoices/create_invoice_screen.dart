import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../../../controllers/create_invoice_controller.dart';
import '../../../controllers/auth_controller.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_responsive.dart';
import '../../../models/company.dart';
import '../../../models/customer.dart';
import '../../../models/invoice.dart';
import '../../../models/product.dart';
import '../../../repositories/product_repository.dart';
import '../../layout/app_drawer.dart';

class CreateInvoiceScreen extends StatefulWidget {
  const CreateInvoiceScreen({super.key});

  @override
  State<CreateInvoiceScreen> createState() => _CreateInvoiceScreenState();
}

class _CreateInvoiceScreenState extends State<CreateInvoiceScreen> {
  bool _isCompanyVerified(Map<String, dynamic>? company) {
    final Object? raw = company;
    if (raw is! Map<String, dynamic>) return false;

    final Object? flag = raw['isVerified'] ?? raw['verified'] ?? raw['isCompanyVerified'];
    if (flag is bool) return flag;

    final Object? status = raw['verificationStatus'] ??
        raw['verification_state'] ??
        raw['verification'] ??
        raw['status'];
    if (status is String) {
      final String s = status.trim().toLowerCase();
      return s == 'verified' || s == 'active' || s == 'approved';
    }
    if (status is Map<String, dynamic>) {
      final Object? s = status['status'] ?? status['state'];
      if (s is String) {
        final String lower = s.trim().toLowerCase();
        return lower == 'verified' || lower == 'active' || lower == 'approved';
      }
    }

    return false;
  }

  bool _isZatcaVerified(Map<String, dynamic>? company) {
    final Object? raw = company;
    if (raw is! Map<String, dynamic>) return true;
    final Object? creds = raw['zatcaCredentials'];
    if (creds is! Map<String, dynamic>) return true;
    final Object? status = creds['status'];
    if (status is! String) return true;
    final String s = status.trim().toLowerCase();
    return s == 'verified' || s == 'active' || s == 'approved' || s == 'completed';
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final AuthController auth = context.read<AuthController>();
      final CreateInvoiceController ctrl = context.read<CreateInvoiceController>();
      final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
      Map<String, dynamic>? company = auth.myCompany;
      String? companyId = (company?['_id'] ?? company?['id'])?.toString().trim();
      String companyName = (company?['companyName'] ?? company?['name'])
              ?.toString()
              .trim() ??
          '';

      if (companyId == null || companyId.isEmpty) {
        await auth.refreshMyCompany();
        company = auth.myCompany;
        companyId = (company?['_id'] ?? company?['id'])?.toString().trim();
        companyName = (company?['companyName'] ?? company?['name'])
                ?.toString()
                .trim() ??
            '';
      }
      if (companyId == null || companyId.isEmpty) {
        if (!mounted) return;
        messenger.showSnackBar(
          const SnackBar(content: Text('Company not loaded')),
        );
        return;
      }

      await ctrl.loadCompanies(
        onlyCompany:
            Company(id: companyId.trim(), name: companyName.trim()),
        page: 1,
        limit: 50,
      );
      if (companyName.isNotEmpty) {
        ctrl.setCompany(companyId: companyId, companyName: companyName);
      } else {
        ctrl.setCompany(companyId: companyId, companyName: ctrl.company);
      }
      await ctrl.loadCustomers(companyId: companyId);
      if (!mounted) return;
      if (ctrl.errorMessage != null && ctrl.errorMessage!.trim().isNotEmpty) {
        messenger.showSnackBar(
          SnackBar(content: Text(ctrl.errorMessage!)),
        );
      }
    });
  }

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
    () async {
      final AuthController auth = context.read<AuthController>();
      final CreateInvoiceController ctrl = context.read<CreateInvoiceController>();
      final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
      Map<String, dynamic>? company = auth.myCompany;
      String? companyId = (company?['_id'] ?? company?['id'])?.toString().trim();
      if (companyId == null || companyId.isEmpty) {
        await auth.refreshMyCompany();
        company = auth.myCompany;
        companyId = (company?['_id'] ?? company?['id'])?.toString().trim();
      }

      if (companyId == null || companyId.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Company not loaded')),
        );
        return;
      }

      final String safeCompanyId = companyId.trim();
      final bool companyVerified = _isCompanyVerified(company);
      final bool zatcaVerified = _isZatcaVerified(company);
      if (!companyVerified) {
        if (!mounted) return;
        messenger.showSnackBar(
          const SnackBar(
            content: Text(
              'Company is not ready for invoice generation. Please complete company verification and ZATCA setup then try again.',
            ),
          ),
        );
        return;
      }

      if (!zatcaVerified && !draft) {
        if (!mounted) return;
        messenger.showSnackBar(
          const SnackBar(
            content: Text(
              'ZATCA setup is pending. You can save a draft invoice, but you cannot send/validate invoices until ZATCA is completed.',
            ),
          ),
        );
        return;
      }

      if (!zatcaVerified && draft) {
        if (!mounted) return;
        messenger.showSnackBar(
          const SnackBar(
            content: Text(
              'ZATCA setup is pending. Saving draft only.',
            ),
          ),
        );
      }
      if ((ctrl.companyId ?? '').trim().isEmpty) {
        final String companyName = (company?['companyName'] ?? company?['name'])
                ?.toString()
                .trim() ??
            '';
        ctrl.setCompany(
          companyId: safeCompanyId,
          companyName: companyName.isNotEmpty ? companyName : ctrl.company,
        );
      }
      final Invoice? created = await ctrl.submit(draft: draft);
      if (!mounted) return;
      if (created != null) {
        Navigator.of(context).pop(created);
        return;
      }
      final String msg = (ctrl.errorMessage ?? 'Failed to create invoice');
      if (msg.toLowerCase().contains('company is not verified')) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text(
              'Company is not ready for invoice generation. Please complete company verification and ZATCA setup then try again.',
            ),
          ),
        );
        return;
      }
      if (msg.trim().isNotEmpty) {
        messenger.showSnackBar(SnackBar(content: Text(msg)));
      }
    }();
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
        return _AddItemSheet(
          currency: ctrl.currency,
          controller: ctrl,
        );
      },
    );

    if (!mounted || item == null) {
      return;
    }

    ctrl.addItem(item);
  }

  Future<void> _openEditItemSheet({
    required int index,
    required InvoiceItem item,
  }) async {
    final CreateInvoiceController ctrl = context
        .read<CreateInvoiceController>();
    final InvoiceItem? edited = await showModalBottomSheet<InvoiceItem>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (BuildContext ctx) {
        return _EditItemSheet(
          currency: ctrl.currency,
          item: item,
        );
      },
    );

    if (!mounted || edited == null) {
      return;
    }

    ctrl.updateItemAt(index, edited);
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
                    Builder(
                      builder: (BuildContext context) {
                        final List<Company> companies = <Company>[
                          ...ctrl.companies,
                        ];
                        final String? selectedCompanyId = ctrl.companyId;

                        if (companies.isEmpty &&
                            selectedCompanyId != null &&
                            selectedCompanyId.trim().isNotEmpty) {
                          companies.add(
                            Company(id: selectedCompanyId.trim(), name: ctrl.company),
                          );
                        }

                        final List<String> ids = companies
                            .map((Company c) => c.id.trim())
                            .where((String s) => s.isNotEmpty)
                            .toSet()
                            .toList();

                        final String? safeSelected =
                            (selectedCompanyId != null && ids.contains(selectedCompanyId))
                                ? selectedCompanyId
                                : (ids.isNotEmpty ? ids.first : null);

                        return _LabeledDropdown<String>(
                          label: 'Select Company',
                          value: safeSelected,
                          items: ids,
                          itemBuilder: (String id) {
                            try {
                              final Company c = companies.firstWhere(
                                (Company c) => c.id == id,
                              );
                              return c.name.trim().isEmpty ? id : c.name;
                            } catch (_) {
                              return id;
                            }
                          },
                          onChanged: (String id) {
                            () async {
                              final Company? next = companies
                                  .cast<Company?>()
                                  .firstWhere(
                                    (Company? c) => c?.id == id,
                                    orElse: () => null,
                                  );
                              if (next == null) return;
                              ctrl.setCompany(
                                companyId: next.id,
                                companyName: next.name,
                              );
                              ctrl.selectCustomer(null);
                              await ctrl.loadCustomers(companyId: next.id);
                            }();
                          },
                        );
                      },
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
                      items: ctrl.zatcaInvoiceTypeOptions,
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
                    if (ctrl.isLoadingCustomers)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: CircularProgressIndicator(
                            color: AppColors.primary,
                          ),
                        ),
                      )
                    else
                      Builder(
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

                          return _LabeledDropdown<String>(
                            label: 'Select Customer',
                            value: safeSelected,
                            items: ids,
                            itemBuilder: (String id) {
                              final Customer? c = ctrl.customers
                                  .cast<Customer?>()
                                  .firstWhere(
                                    (Customer? c) => c?.id == id,
                                    orElse: () => null,
                                  );
                              return c == null ? id : '${c.name} (${c.id})';
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
                          );
                        },
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
                              onEdit: () {
                                _openEditItemSheet(index: idx, item: item);
                              },
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

class _EditItemSheet extends StatefulWidget {
  final String currency;
  final InvoiceItem item;

  const _EditItemSheet({required this.currency, required this.item});

  @override
  State<_EditItemSheet> createState() => _EditItemSheetState();
}

class _EditItemSheetState extends State<_EditItemSheet> {
  late final TextEditingController _qtyController;
  late final TextEditingController _priceController;
  late final TextEditingController _discountController;
  late final TextEditingController _taxController;
  late String _vatCategory;

  @override
  void initState() {
    super.initState();
    _qtyController = TextEditingController(text: widget.item.qty.toString());
    _priceController = TextEditingController(text: widget.item.price.toString());
    _discountController = TextEditingController(
      text: widget.item.discount.toString(),
    );
    _taxController = TextEditingController(text: widget.item.taxPercent.toString());
    _vatCategory = widget.item.vatCategory;
  }

  @override
  void dispose() {
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
    final int qty = _parseInt(_qtyController.text, fallback: 1);
    return InvoiceItem(
      productId: widget.item.productId,
      product: widget.item.product,
      qty: qty <= 0 ? 1 : qty,
      price: _parseDouble(_priceController.text, fallback: 0),
      discount: _parseDouble(_discountController.text, fallback: 0),
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
            'Edit Item',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF0B1B4B),
              fontWeight: FontWeight.w900,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            widget.item.product,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF0B1B4B),
              fontWeight: FontWeight.w900,
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
                  decoration: inputDec(label: 'Discount', hint: '0'),
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
                  child: const Text('Save'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ItemCard extends StatelessWidget {
  final InvoiceItem item;
  final String currency;
  final VoidCallback? onEdit;
  final VoidCallback? onDecrementQty;
  final VoidCallback? onIncrementQty;
  final bool showQtyStepper;
  final VoidCallback onRemove;
  final bool showRemove;

  const _ItemCard({
    required this.item,
    required this.currency,
    this.onEdit,
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
              if (onEdit != null) ...<Widget>[
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
                    onPressed: onEdit,
                    icon: const Icon(
                      Icons.edit,
                      size: 18,
                      color: Color(0xFF9AA5B6),
                    ),
                  ),
                ),
              ],
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
              _MetaPill(label: 'Discount', value: _fmt(item.discount)),
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

class _InvoicePreviewSheet extends StatefulWidget {
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
  State<_InvoicePreviewSheet> createState() => _InvoicePreviewSheetState();
}

class _InvoicePreviewSheetState extends State<_InvoicePreviewSheet> {
  bool _isPdfBusy = false;

  Future<void> _yieldToUi() async {
    await Future<void>.delayed(Duration.zero);
    await WidgetsBinding.instance.endOfFrame;
  }

  String _formatNumber(double v) {
    final bool asInt = (v - v.truncateToDouble()).abs() < 0.000001;
    return asInt ? v.toStringAsFixed(0) : v.toStringAsFixed(2);
  }

  Future<Uint8List> _buildPdfBytes() async {
    final pw.Document doc = pw.Document();

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context ctx) {
          return <pw.Widget>[
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: <pw.Widget>[
                pw.Text(
                  'Invoice Preview',
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.Text(
                  widget.invoiceNumber.isEmpty ? '' : widget.invoiceNumber,
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 10),
            pw.Text('Company: ${widget.company}'),
            pw.Text('Customer: ${widget.customer}'),
            pw.SizedBox(height: 6),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: <pw.Widget>[
                pw.Text('Issue Date: ${widget.issueDate}'),
                pw.Text('Due Date: ${widget.dueDate}'),
              ],
            ),
            pw.SizedBox(height: 6),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: <pw.Widget>[
                pw.Text('Invoice Type: ${widget.invoiceType}'),
                pw.Text('Customer Type: ${widget.customerType}'),
              ],
            ),
            pw.SizedBox(height: 6),
            pw.Text('Payment Terms: ${widget.paymentTerms}'),
            pw.SizedBox(height: 14),
            pw.Text(
              'Items',
              style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 6),
            if (widget.items.isEmpty)
              pw.Text('No items')
            else
              pw.Table(
                border: pw.TableBorder.all(width: 0.5, color: PdfColors.grey400),
                columnWidths: <int, pw.TableColumnWidth>{
                  0: const pw.FlexColumnWidth(4),
                  1: const pw.FlexColumnWidth(1),
                  2: const pw.FlexColumnWidth(2),
                  3: const pw.FlexColumnWidth(2),
                },
                children: <pw.TableRow>[
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                    children: <pw.Widget>[
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text('Description', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text('Qty', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text('Unit Price', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text('Total', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ),
                    ],
                  ),
                  ...widget.items.map((InvoiceItem it) {
                    final String lineTotal = _formatNumber(it.total);
                    return pw.TableRow(
                      children: <pw.Widget>[
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text(it.product.isEmpty ? '-' : it.product),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text(it.qty.toString()),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text('${_formatNumber(it.price)} ${widget.currency}'),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text('$lineTotal ${widget.currency}'),
                        ),
                      ],
                    );
                  }),
                ],
              ),
            pw.SizedBox(height: 14),
            pw.Align(
              alignment: pw.Alignment.centerRight,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: <pw.Widget>[
                  pw.Text('Subtotal: ${_formatNumber(widget.subtotal)} ${widget.currency}'),
                  pw.Text('VAT: ${_formatNumber(widget.vat)} ${widget.currency}'),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    'Total: ${_formatNumber(widget.total)} ${widget.currency}',
                    style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
                  ),
                ],
              ),
            ),
            if (widget.notes.isNotEmpty || widget.terms.isNotEmpty) ...<pw.Widget>[
              pw.SizedBox(height: 16),
              pw.Text(
                'Additional Info',
                style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
              ),
              if (widget.notes.isNotEmpty) pw.Text('Notes: ${widget.notes}'),
              if (widget.terms.isNotEmpty) pw.Text('Terms: ${widget.terms}'),
            ],
          ];
        },
      ),
    );

    return doc.save();
  }

  Future<void> _downloadPdf(BuildContext context) async {
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    try {
      if (_isPdfBusy) return;
      setState(() => _isPdfBusy = true);
      await _yieldToUi();
      final Uint8List bytes = await _buildPdfBytes();
      final String name = widget.invoiceNumber.trim().isEmpty
          ? 'invoice-preview.pdf'
          : '${widget.invoiceNumber.trim()}.pdf';
      await Printing.sharePdf(bytes: bytes, filename: name);
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _isPdfBusy = false);
    }
  }

  Future<void> _printPdf(BuildContext context) async {
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    try {
      if (_isPdfBusy) return;
      setState(() => _isPdfBusy = true);
      await _yieldToUi();
      final Uint8List bytes = await _buildPdfBytes();
      await Printing.layoutPdf(
        onLayout: (_) async => bytes,
      );
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _isPdfBusy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final double bottomPad = MediaQuery.of(context).viewInsets.bottom;

    return Skeletonizer(
      enabled: _isPdfBusy,
      child: AbsorbPointer(
        absorbing: _isPdfBusy,
        child: Padding(
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
                const SizedBox(height: 6),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _downloadPdf(context),
                        icon: const Icon(Icons.download_rounded),
                        label: const Text('Download PDF'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF0B1B4B),
                          side: const BorderSide(color: Color(0xFFE9EEF5)),
                          backgroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          textStyle: const TextStyle(fontWeight: FontWeight.w900),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _printPdf(context),
                        icon: const Icon(Icons.print_rounded),
                        label: const Text('Print'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          textStyle: const TextStyle(fontWeight: FontWeight.w900),
                          elevation: 0,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                _SectionCard(
                  title: 'Invoice Details',
                  child: Column(
                    children: <Widget>[
                      _PreviewRow(label: 'Company', value: widget.company),
                      _PreviewRow(label: 'Customer Type', value: widget.customerType),
                      _PreviewRow(label: 'Invoice Type', value: widget.invoiceType),
                      _PreviewRow(label: 'Invoice Number', value: widget.invoiceNumber),
                      _PreviewRow(label: 'Issue Date', value: widget.issueDate),
                      _PreviewRow(label: 'Due Date', value: widget.dueDate),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                _SectionCard(
                  title: 'Customer & Payment',
                  child: Column(
                    children: <Widget>[
                      _PreviewRow(label: 'Customer', value: widget.customer),
                      _PreviewRow(label: 'Currency', value: widget.currency),
                      _PreviewRow(label: 'Payment Terms', value: widget.paymentTerms),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                _SectionCard(
                  title: 'Items',
                  child: widget.items.isEmpty
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
                          children: widget.items
                              .map(
                                (InvoiceItem item) => _ItemCard(
                                  item: item,
                                  currency: widget.currency,
                                  onRemove: () {},
                                  showRemove: false,
                                ),
                              )
                              .toList(),
                        ),
                ),
                const SizedBox(height: 12),
                if (widget.notes.isNotEmpty || widget.terms.isNotEmpty)
                  _SectionCard(
                    title: 'Additional Info',
                    child: Column(
                      children: <Widget>[
                        if (widget.notes.isNotEmpty)
                          _PreviewRow(label: 'Notes', value: widget.notes),
                        if (widget.terms.isNotEmpty)
                          _PreviewRow(label: 'Terms & Conditions', value: widget.terms),
                      ],
                    ),
                  ),
                const SizedBox(height: 12),
                _TotalsSummary(
                  subtotal: widget.subtotal,
                  vat: widget.vat,
                  total: widget.total,
                  currency: widget.currency,
                ),
              ],
            ),
          ),
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
      isDense: true,
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
  final CreateInvoiceController controller;

  const _AddItemSheet({required this.currency, required this.controller});

  @override
  State<_AddItemSheet> createState() => _AddItemSheetState();
}

class _AddItemSheetState extends State<_AddItemSheet> {
  final TextEditingController _productSearchController = TextEditingController();
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

  String? _lastCompanyId;

  @override
  void initState() {
    super.initState();
    _lastCompanyId = (widget.controller.companyId ?? '').trim();
    widget.controller.addListener(_onCompanyChanged);
  }

  void _onCompanyChanged() {
    final String next = (widget.controller.companyId ?? '').trim();
    if (_lastCompanyId == next) return;
    _lastCompanyId = next;
    if (!mounted) return;
    _searchDebounce?.cancel();
    setState(() {
      _selectedProduct = null;
      _suggestions = const <Product>[];
      _productError = null;
      _productSearchController.text = '';
      _priceController.text = '0';
      _taxController.text = '15';
    });
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onCompanyChanged);
    _searchDebounce?.cancel();
    _productSearchController.dispose();
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

    final String? activeCompanyId = widget.controller.companyId;
    if (activeCompanyId == null || activeCompanyId.trim().isEmpty) {
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
            companyId: activeCompanyId,
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
    setState(() {
      _selectedProduct = p;
      _suggestions = const <Product>[];
      _productError = null;
      _productSearchController.text = p.name;
      _priceController.text = p.price.toString();
      _taxController.text = p.taxRate.toString();
    });
  }

  int _parseInt(String v, {int fallback = 0}) {
    return int.tryParse(v.trim()) ?? fallback;
  }

  double _parseDouble(String v, {double fallback = 0}) {
    return double.tryParse(v.trim()) ?? fallback;
  }

  InvoiceItem _buildItem() {
    return InvoiceItem(
      productId: _selectedProduct?.id ?? '',
      product: _selectedProduct?.name ?? 'Product',
      qty: _parseInt(_qtyController.text, fallback: 1),
      price: _parseDouble(_priceController.text, fallback: 0),
      discount: _parseDouble(_discountController.text, fallback: 0),
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
            controller: _productSearchController,
            onChanged: _onSearchChanged,
            decoration: inputDec(
              label: 'Product',
              hint: 'Search by name or SKU...',
            ),
            style: const TextStyle(
              color: Color(0xFF0B1B4B),
              fontWeight: FontWeight.w800,
              fontSize: 13,
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
                    trailing: TextButton(
                      onPressed: () {
                        _selectProduct(p);
                        final InvoiceItem item = _buildItem();
                        Navigator.of(context).pop(item);
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        textStyle: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                      child: const Text('Add to cart'),
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
                  decoration: inputDec(label: 'Discount', hint: '0'),
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
                    if (_selectedProduct == null) {
                      setState(
                        () => _productError = 'Please select a product',
                      );
                      return;
                    }
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
