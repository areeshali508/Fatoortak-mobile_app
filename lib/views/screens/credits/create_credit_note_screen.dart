import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../../../controllers/create_credit_note_controller.dart';
import '../../../controllers/invoice_controller.dart';
import '../../../controllers/auth_controller.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_responsive.dart';
import '../../../models/credit_note.dart';
import '../../../models/invoice.dart';
import '../../../repositories/credit_note_repository.dart';

class CreateCreditNoteScreen extends StatefulWidget {
  const CreateCreditNoteScreen({super.key});

  @override
  State<CreateCreditNoteScreen> createState() => _CreateCreditNoteScreenState();
}

class _CreditNotePreviewSheet extends StatefulWidget {
  final String company;
  final String creditNoteNumber;
  final String issueDate;
  final String customer;
  final String customerType;
  final String originalInvoiceNo;
  final String reasonType;
  final String reasonDescription;
  final String currency;
  final List<CreditNoteItem> items;
  final String terms;
  final double subtotal;
  final double vat;
  final double total;

  const _CreditNotePreviewSheet({
    required this.company,
    required this.creditNoteNumber,
    required this.issueDate,
    required this.customer,
    required this.customerType,
    required this.originalInvoiceNo,
    required this.reasonType,
    required this.reasonDescription,
    required this.currency,
    required this.items,
    required this.terms,
    required this.subtotal,
    required this.vat,
    required this.total,
  });

  @override
  State<_CreditNotePreviewSheet> createState() => _CreditNotePreviewSheetState();
}

class _CreditNotePreviewSheetState extends State<_CreditNotePreviewSheet> {
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
                  'Credit Note Preview',
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.Text(
                  widget.creditNoteNumber.trim().isEmpty
                      ? ''
                      : widget.creditNoteNumber.trim(),
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
            pw.Text('Issue Date: ${widget.issueDate}'),
            pw.SizedBox(height: 6),
            pw.Text('Customer Type: ${widget.customerType}'),
            pw.Text('Original Invoice: ${widget.originalInvoiceNo}'),
            pw.SizedBox(height: 6),
            pw.Text('Reason: ${widget.reasonType}'),
            if (widget.reasonDescription.trim().isNotEmpty)
              pw.Text('Reason Description: ${widget.reasonDescription.trim()}'),
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
                        child: pw.Text(
                          'Description',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text(
                          'Qty',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text(
                          'Unit Price',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text(
                          'Total',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  ...widget.items.map((CreditNoteItem it) {
                    final String lineTotal = _formatNumber(it.total);
                    return pw.TableRow(
                      children: <pw.Widget>[
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text(
                            it.description.trim().isEmpty
                                ? '-'
                                : it.description.trim(),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text(it.qty.toString()),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text(
                            '${_formatNumber(it.price)} ${widget.currency}',
                          ),
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
                  pw.Text(
                    'Subtotal: ${_formatNumber(widget.subtotal)} ${widget.currency}',
                  ),
                  pw.Text(
                    'VAT: ${_formatNumber(widget.vat)} ${widget.currency}',
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    'Total Credit: ${_formatNumber(widget.total)} ${widget.currency}',
                    style: pw.TextStyle(
                      fontSize: 14,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            if (widget.terms.trim().isNotEmpty) ...<pw.Widget>[
              pw.SizedBox(height: 16),
              pw.Text(
                'Terms & Conditions',
                style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
              ),
              pw.Text(widget.terms.trim()),
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
      final String name = widget.creditNoteNumber.trim().isEmpty
          ? 'credit-note-preview.pdf'
          : '${widget.creditNoteNumber.trim()}.pdf';
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
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(18, 6, 18, 18 + bottomPad),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      const Expanded(
                        child: Text(
                          'Credit Note Preview',
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
                            textStyle:
                                const TextStyle(fontWeight: FontWeight.w900),
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
                            textStyle:
                                const TextStyle(fontWeight: FontWeight.w900),
                            elevation: 0,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _SectionCard(
                    title: 'Summary',
                    child: Column(
                      children: <Widget>[
                        _SummaryRow(
                          label: 'Company',
                          value: widget.company.trim().isEmpty
                              ? '-'
                              : widget.company.trim(),
                        ),
                        _SummaryRow(
                          label: 'Credit Note #',
                          value: widget.creditNoteNumber.trim().isEmpty
                              ? '-'
                              : widget.creditNoteNumber.trim(),
                        ),
                        _SummaryRow(
                          label: 'Issue Date',
                          value: widget.issueDate.trim().isEmpty
                              ? '-'
                              : widget.issueDate.trim(),
                        ),
                        _SummaryRow(
                          label: 'Customer',
                          value: widget.customer.trim().isEmpty
                              ? '-'
                              : widget.customer.trim(),
                        ),
                        _SummaryRow(
                          label: 'Customer Type',
                          value: widget.customerType.trim().isEmpty
                              ? '-'
                              : widget.customerType.trim(),
                        ),
                        _SummaryRow(
                          label: 'Original Invoice',
                          value: widget.originalInvoiceNo.trim().isEmpty
                              ? '-'
                              : widget.originalInvoiceNo.trim(),
                        ),
                        _SummaryRow(
                          label: 'Reason',
                          value: widget.reasonType.trim().isEmpty
                              ? '-'
                              : widget.reasonType.trim(),
                        ),
                        if (widget.reasonDescription.trim().isNotEmpty)
                          _SummaryRow(
                            label: 'Reason Description',
                            value: widget.reasonDescription.trim(),
                          ),
                      ],
                    ),
                  ),
              const SizedBox(height: 12),
              _SectionCard(
                title: 'Items',
                child: widget.items.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.symmetric(vertical: 10),
                        child: Text(
                          'No items',
                          style: TextStyle(
                            color: Color(0xFF6B7895),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      )
                    : Column(
                        children: widget.items.map((CreditNoteItem it) {
                          final double lineTotal = it.total;
                          final bool asInt =
                              (lineTotal - lineTotal.truncateToDouble()).abs() <
                                  0.000001;
                          final String formatted = asInt
                              ? lineTotal.toStringAsFixed(0)
                              : lineTotal.toStringAsFixed(2);

                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF7FAFF),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: const Color(0xFFE9EEF5),
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: <Widget>[
                                      Text(
                                        it.description,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: Color(0xFF0B1B4B),
                                          fontWeight: FontWeight.w800,
                                          fontSize: 14,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        'Qty ${it.qty}  •  ${widget.currency} ${it.price.toStringAsFixed(2)}',
                                        style: const TextStyle(
                                          color: Color(0xFF6B7895),
                                          fontWeight: FontWeight.w700,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  '${widget.currency} $formatted',
                                  style: const TextStyle(
                                    color: Color(0xFF0B1B4B),
                                    fontWeight: FontWeight.w900,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
              ),
              const SizedBox(height: 12),
              _SectionCard(
                title: 'Totals',
                child: Column(
                  children: <Widget>[
                    _SummaryRow(
                      label: 'Subtotal',
                      value:
                          '${widget.currency} ${widget.subtotal.toStringAsFixed(2)}',
                    ),
                    _SummaryRow(
                      label: 'VAT',
                      value:
                          '${widget.currency} ${widget.vat.toStringAsFixed(2)}',
                    ),
                    _SummaryRow(
                      label: 'Total Credit',
                      value:
                          '${widget.currency} ${widget.total.toStringAsFixed(2)}',
                    ),
                  ],
                ),
              ),
              if (widget.terms.trim().isNotEmpty) ...<Widget>[
                const SizedBox(height: 12),
                _SectionCard(
                  title: 'Terms & Conditions',
                  child: Text(
                    widget.terms.trim(),
                    style: const TextStyle(
                      color: Color(0xFF0B1B4B),
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SheetOptionTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final String trailing;
  final VoidCallback onTap;

  const _SheetOptionTile({
    required this.title,
    required this.subtitle,
    required this.trailing,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: const Color(0xFFF7FAFF),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        title,
                        style: const TextStyle(
                          color: Color(0xFF0B1B4B),
                          fontWeight: FontWeight.w900,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF6B7895),
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  trailing,
                  style: const TextStyle(
                    color: Color(0xFF0B1B4B),
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.chevron_right, color: Color(0xFF9AA5B6)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CreateCreditNoteScreenState extends State<CreateCreditNoteScreen> {
  bool _isSaving = false;
  bool _requestedInitial = false;

  CreditNote? _createdDraft;

  Future<void> _openPreviewSheet() async {
    final CreateCreditNoteController ctrl = context
        .read<CreateCreditNoteController>();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (BuildContext ctx) {
        return _CreditNotePreviewSheet(
          company: ctrl.company,
          creditNoteNumber: ctrl.creditNoteNumberController.text.trim(),
          issueDate: _fmtDate(ctrl.issueDate),
          customer: ctrl.customerController.text.trim(),
          customerType: ctrl.customerType,
          originalInvoiceNo: ctrl.originalInvoiceController.text.trim(),
          reasonType: ctrl.reasonType,
          reasonDescription: ctrl.reasonDescriptionController.text.trim(),
          currency: ctrl.currency,
          items: List<CreditNoteItem>.unmodifiable(ctrl.items),
          terms: ctrl.termsController.text.trim(),
          subtotal: ctrl.subtotal,
          vat: ctrl.vatAmount,
          total: ctrl.total,
        );
      },
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_requestedInitial) return;
    _requestedInitial = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final CreateCreditNoteController ctrl =
          context.read<CreateCreditNoteController>();
      final AuthController auth = context.read<AuthController>();
      final InvoiceController invCtrl = context.read<InvoiceController>();

      await ctrl.loadCompanies(page: 1, limit: 50);
      final String? activeId = auth.activeCompanyId;
      final List companies = ctrl.companies;
      if (companies.isEmpty) return;

      final selected = (activeId == null || activeId.trim().isEmpty)
          ? companies.first
          : ctrl.companyById(activeId) ?? companies.first;

      ctrl.setCompany(companyId: selected.id, companyName: selected.name);
      await Future.wait<void>(<Future<void>>[
        ctrl.loadNextNumber(),
        invCtrl.loadInvoices(companyId: selected.id),
      ]);
    });
  }

  void _nextStep() {
    final CreateCreditNoteController ctrl = context
        .read<CreateCreditNoteController>();
    final bool ok = ctrl.nextStep();
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please complete this step to continue')),
      );
    }
  }

  Future<void> _selectInvoice() async {
    final CreateCreditNoteController creditCtrl =
        context.read<CreateCreditNoteController>();
    final InvoiceController invCtrl = context.read<InvoiceController>();
    final String selectedCompanyId = (creditCtrl.companyId ?? '').trim();
    final List<Invoice> invoices = invCtrl.invoices.where((Invoice i) {
      if (selectedCompanyId.isEmpty) return true;
      final String invCompanyId = (i.companyId ?? '').trim();
      if (invCompanyId.isEmpty) return true;
      return invCompanyId == selectedCompanyId;
    }).toList();

    if (invoices.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No cleared invoices available')),
      );
      return;
    }

    final Invoice? picked = await showModalBottomSheet<Invoice>(
      context: context,
      showDragHandle: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (BuildContext ctx) {
        return SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 6, 18, 18),
            shrinkWrap: true,
            children: <Widget>[
              const Text(
                'Select Cleared Invoice',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF0B1B4B),
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 10),
              ...invoices.map((Invoice inv) {
                return _SheetOptionTile(
                  title: 'Invoice #${inv.invoiceNo}',
                  subtitle: inv.customer,
                  trailing: '${inv.currency} ${inv.total.toStringAsFixed(2)}',
                  onTap: () => Navigator.of(ctx).pop(inv),
                );
              }),
            ],
          ),
        );
      },
    );

    if (!mounted || picked == null) {
      return;
    }

    context.read<CreateCreditNoteController>().loadFromInvoice(picked);
  }

  void _prevStep() {
    context.read<CreateCreditNoteController>().prevStep();
  }

  void _goToStep(int step) {
    context.read<CreateCreditNoteController>().goToStep(step);
  }

  Future<void> _pickIssueDate() async {
    final CreateCreditNoteController ctrl = context
        .read<CreateCreditNoteController>();
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
    final CreateCreditNoteController ctrl = context
        .read<CreateCreditNoteController>();
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

  Future<void> _openEditItemSheet(int index, CreditNoteItem initial) async {
    final CreateCreditNoteController ctrl = context
        .read<CreateCreditNoteController>();
    final CreditNoteItem? item = await showModalBottomSheet<CreditNoteItem>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (_) => _AddItemSheet(currency: ctrl.currency, initialItem: initial),
    );

    if (!mounted || item == null) {
      return;
    }

    ctrl.updateItemAt(index, item);
  }

  Future<void> _saveDraft() async {
    if (_isSaving) return;
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    final CreateCreditNoteController ctrl =
        context.read<CreateCreditNoteController>();
    try {
      final Map<String, dynamic> payload =
          ctrl.buildCreatePayload(status: 'draft');
      setState(() => _isSaving = true);
      final CreditNoteRepository repo = context.read<CreditNoteRepository>();
      final CreditNote created = await repo.createCreditNote(payload: payload);
      if (!mounted) return;
      Navigator.of(context).pop(created);
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<CreditNote> _ensureDraftCreated() async {
    if (_createdDraft != null) {
      return _createdDraft!;
    }
    final CreateCreditNoteController ctrl =
        context.read<CreateCreditNoteController>();
    final CreditNoteRepository repo = context.read<CreditNoteRepository>();
    final Map<String, dynamic> payload = ctrl.buildCreatePayload(status: 'draft');
    final CreditNote created = await repo.createCreditNote(payload: payload);
    _createdDraft = created;
    return created;
  }

  Future<void> _validateZatca() async {
    if (_isSaving) return;
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    final CreateCreditNoteController ctrl =
        context.read<CreateCreditNoteController>();
    final CreditNoteRepository repo = context.read<CreditNoteRepository>();

    setState(() => _isSaving = true);
    try {
      final CreditNote draft = await _ensureDraftCreated();
      final Map<String, dynamic> res =
          await repo.validateZatca(id: draft.id.trim());

      final Object? dataObj = res['data'];
      final Map<String, dynamic> data = dataObj is Map<String, dynamic>
          ? dataObj
          : <String, dynamic>{};

      final bool isValid = (data['isValid'] == true);
      final List<String> errors = (data['errors'] is List)
          ? (data['errors'] as List)
              .map((Object? e) => e?.toString() ?? '')
              .where((String e) => e.trim().isNotEmpty)
              .toList()
          : <String>[];
      final List<String> warnings = (data['warnings'] is List)
          ? (data['warnings'] as List)
              .map((Object? e) => e?.toString() ?? '')
              .where((String e) => e.trim().isNotEmpty)
              .toList()
          : <String>[];

      ctrl.setZatcaValidated(isValid && errors.isEmpty);

      if (!mounted) return;
      if (errors.isNotEmpty) {
        messenger.showSnackBar(SnackBar(content: Text(errors.first)));
        return;
      }

      if (warnings.isNotEmpty) {
        messenger.showSnackBar(
          SnackBar(
            content: Text('ZATCA validation passed with warnings: ${warnings.first}'),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 4),
          ),
        );
        return;
      }

      messenger.showSnackBar(
        SnackBar(
          content: Text(
            ctrl.zatcaValidated
                ? 'ZATCA validation successful. You can now submit.'
                : 'ZATCA validation returned not valid',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text(e.toString())));
      ctrl.setZatcaValidated(false);
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _submitToZatca() async {
    if (_isSaving) return;
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    final CreateCreditNoteController ctrl =
        context.read<CreateCreditNoteController>();
    final CreditNoteRepository repo = context.read<CreditNoteRepository>();
    if (!ctrl.zatcaValidated) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Please validate before submitting to ZATCA')),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final CreditNote draft = await _ensureDraftCreated();
      await repo.sendToZatca(id: draft.id.trim());
      final CreditNote latest = await repo.getCreditNoteById(id: draft.id.trim());
      if (!mounted) return;
      Navigator.of(context).pop(latest);
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
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
        final CreateCreditNoteController ctrl = context
            .watch<CreateCreditNoteController>();

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
                                  'Discount: ${it.discount.toStringAsFixed(2)} ${ctrl.currency}',
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
                      Text(
                        '${it.total.toStringAsFixed(2)} ${ctrl.currency}',
                        style: const TextStyle(
                          color: Color(0xFF0B1B4B),
                          fontWeight: FontWeight.w900,
                          fontSize: 12,
                        ),
                      ),
                      if (editable) ...<Widget>[
                        const SizedBox(width: 10),
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
                            border: Border.all(color: const Color(0xFFE9EEF5)),
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

        Widget stepContent() {
          switch (ctrl.currentStep) {
            case 0:
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  _SectionCard(
                    title: 'Credit Note Details',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        DropdownButtonFormField<String>(
                          key: ValueKey<String>(ctrl.companyId ?? ''),
                          initialValue: (ctrl.companyId ?? '').trim().isEmpty
                              ? null
                              : ctrl.companyId,
                          items: ctrl.companies
                              .map(
                                (c) => DropdownMenuItem<String>(
                                  value: c.id,
                                  child: Text(
                                    c.name,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: ctrl.isLoadingCompanies
                              ? null
                              : (String? id) {
                                  if (id == null) return;
                                  final c = ctrl.companyById(id);
                                  if (c == null) return;
                                  ctrl.setCompany(
                                    companyId: c.id,
                                    companyName: c.name,
                                  );
                                  setState(() => _createdDraft = null);
                                  ctrl.loadNextNumber();
                                  final InvoiceController invCtrl =
                                      context.read<InvoiceController>();
                                  invCtrl.loadInvoices(companyId: c.id);
                                },
                          decoration: _dec(label: 'Company*'),
                          icon: const Icon(Icons.keyboard_arrow_down_rounded),
                          borderRadius: BorderRadius.circular(12),
                          dropdownColor: Colors.white,
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
                      readOnly: true,
                      decoration: _dec(
                        label: '',
                        hint: 'Search or select invoice number',
                        prefix: const Icon(
                          Icons.search,
                          color: Color(0xFF9AA5B6),
                        ),
                      ).copyWith(labelText: null),
                      onTap: _selectInvoice,
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
                      readOnly: true,
                      decoration: _dec(
                        label: 'Customer',
                        hint: 'Search customer',
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
                  ),
                  const SizedBox(height: 12),
                  _SectionCard(
                    title: 'Customer Type',
                    child: _SummaryRow(label: 'Type', value: ctrl.customerType),
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
                            'Product Return',
                            'Discount Adjustment',
                            'Invoice Correction',
                            'Cancellation',
                            'Other',
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
                        _SummaryRow(
                          label: 'Customer Type',
                          value: ctrl.customerType,
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
                            onPressed: _openPreviewSheet,
                            icon: const Icon(
                              Icons.remove_red_eye_outlined,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _saveDraft,
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
                            child: const Text('Save Draft'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: ctrl.zatcaValidated
                                ? _submitToZatca
                                : _validateZatca,
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
                            child: Text(
                              ctrl.zatcaValidated
                                  ? 'Submit to ZATCA'
                                  : 'Validate',
                            ),
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
  final CreditNoteItem? initialItem;

  const _AddItemSheet({required this.currency, this.initialItem});

  @override
  State<_AddItemSheet> createState() => _AddItemSheetState();
}

class _AddItemSheetState extends State<_AddItemSheet> {
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

  @override
  void initState() {
    super.initState();
    final CreditNoteItem? it = widget.initialItem;
    if (it == null) return;
    _descController.text = it.description;
    _qtyController.text = it.qty.toString();
    _priceController.text = it.price.toString();
    _discountController.text = it.discount.toString();
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
    _descController.dispose();
    _qtyController.dispose();
    _priceController.dispose();
    _discountController.dispose();
    _taxController.dispose();
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
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: dec(label: 'Discount', hint: '0'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<String>(
                  key: ValueKey<String>(_vatCategory),
                  initialValue: _vatCategory,
                  items: const <String>[
                    'S - 15%',
                    'Z - 0%',
                    'E - Exempt',
                  ]
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
              final CreditNoteItem item = CreditNoteItem(
                description: _descController.text.trim().isEmpty
                    ? 'Custom item'
                    : _descController.text.trim(),
                qty: _parseInt(_qtyController.text, fallback: 1),
                price: _parseDouble(_priceController.text, fallback: 0),
                discount: _parseDouble(_discountController.text, fallback: 0),
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
