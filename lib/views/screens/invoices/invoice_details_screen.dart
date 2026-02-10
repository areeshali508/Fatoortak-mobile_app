import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';
import 'package:skeletonizer/skeletonizer.dart';

import 'dart:convert';
import 'dart:typed_data';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_responsive.dart';
import '../../../controllers/zatca_controller.dart';
import '../../../models/invoice.dart';

class InvoiceDetailsScreen extends StatelessWidget {
  final Invoice invoice;

  const InvoiceDetailsScreen({super.key, required this.invoice});

  Future<void> _validateZatca(BuildContext context) async {
    final ZatcaController ctrl = context.read<ZatcaController>();
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);

    await ctrl.validateInvoice(invoiceId: invoice.id);

    if (!context.mounted) {
      return;
    }

    final String? err = ctrl.errorMessage;
    if (err != null && err.trim().isNotEmpty) {
      messenger.showSnackBar(SnackBar(content: Text(err)));
      return;
    }

    final Map<String, dynamic> res = ctrl.lastResult ?? const <String, dynamic>{};
    final bool? isValid = res['isValid'] is bool ? res['isValid'] as bool : null;

    List<String> toStringList(Object? raw) {
      if (raw is List) {
        return raw.map((Object? e) => e?.toString() ?? '').where((String e) => e.trim().isNotEmpty).toList();
      }
      if (raw == null) return <String>[];
      final String s = raw.toString().trim();
      return s.isEmpty ? <String>[] : <String>[s];
    }

    final List<String> errors = toStringList(res['errors']);
    final List<String> warnings = toStringList(res['warnings']);

    showDialog<void>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        title: const Text('ZATCA Validation'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                isValid == null ? 'Result: -' : (isValid ? 'Result: Valid' : 'Result: Invalid'),
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 10),
              Text(
                'Errors (${errors.length})',
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
              if (errors.isEmpty)
                const Text('None')
              else
                ...errors.map(
                  (String e) => Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text('- $e'),
                  ),
                ),
              const SizedBox(height: 12),
              Text(
                'Warnings (${warnings.length})',
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
              if (warnings.isEmpty)
                const Text('None')
              else
                ...warnings.map(
                  (String e) => Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text('- $e'),
                  ),
                ),
            ],
          ),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _sharePdf(BuildContext context) async {
    final ZatcaController ctrl = context.read<ZatcaController>();
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);

    final Uint8List? bytes = await ctrl.getInvoicePdfBytes(
      invoiceId: invoice.id,
      fallbackBase64: invoice.zatca.pdfUrl,
    );

    if (!context.mounted) return;

    final String? err = ctrl.errorMessage;
    if (bytes == null) {
      if (err != null && err.trim().isNotEmpty) {
        messenger.showSnackBar(SnackBar(content: Text(err)));
      }
      return;
    }

    final String name = invoice.invoiceNo.trim().isEmpty
        ? 'invoice.pdf'
        : '${invoice.invoiceNo.trim()}.pdf';
    await Printing.sharePdf(bytes: bytes, filename: name);
  }

  String _fmtDate(DateTime d) {
    const List<String> months = <String>[
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${d.day.toString().padLeft(2, '0')} ${months[d.month - 1]} ${d.year}';
  }

  String _formatNumber(double v) {
    final bool asInt = (v - v.truncateToDouble()).abs() < 0.000001;
    final String s = asInt ? v.toStringAsFixed(0) : v.toStringAsFixed(2);
    final List<String> parts = s.split('.');
    final String intPart = parts[0];
    final String frac = parts.length > 1 ? '.${parts[1]}' : '';
    final String withCommas = intPart.replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (Match m) => ',',
    );
    return '$withCommas$frac';
  }

  String _amountLabel() {
    return '${invoice.currency} ${_formatNumber(invoice.total)}';
  }

  String _fmtDateTime(DateTime? dt) {
    if (dt == null) return '-';
    String two(int v) => v.toString().padLeft(2, '0');
    return '${dt.year}-${two(dt.month)}-${two(dt.day)} ${two(dt.hour)}:${two(dt.minute)}';
  }

  Uint8List? _tryDecodeBase64(String raw) {
    final String s = raw.trim();
    if (s.isEmpty) return null;
    try {
      return base64Decode(s);
    } catch (_) {
      return null;
    }
  }

  (_ChipStyle?, String) _statusStyle(InvoiceStatus s) {
    switch (s) {
      case InvoiceStatus.draft:
        return (
          const _ChipStyle(bg: Color(0xFFF3F6FB), fg: Color(0xFF6B7895)),
          'Draft',
        );
      case InvoiceStatus.sent:
        return (
          const _ChipStyle(bg: Color(0xFFE7F1FF), fg: AppColors.primary),
          'Sent',
        );
      case InvoiceStatus.overdue:
        return (
          const _ChipStyle(bg: Color(0xFFFFE7E7), fg: Color(0xFFD93025)),
          'Overdue',
        );
      case InvoiceStatus.paid:
        return (
          const _ChipStyle(bg: Color(0xFFEFFAF3), fg: Color(0xFF1DB954)),
          'Paid',
        );
      case InvoiceStatus.partiallyPaid:
        return (
          const _ChipStyle(bg: Color(0xFFFFF7E6), fg: Color(0xFFB26A00)),
          'Partially Paid',
        );
      case InvoiceStatus.cancelled:
        return (
          const _ChipStyle(bg: Color(0xFFF3F6FB), fg: Color(0xFF6B7895)),
          'Cancelled',
        );
      case InvoiceStatus.voided:
        return (
          const _ChipStyle(bg: Color(0xFFF0F0F0), fg: Color(0xFF111827)),
          'Void',
        );
      case InvoiceStatus.none:
        return (null, '');
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final ZatcaController zatcaCtrl = context.watch<ZatcaController>();
        final bool isLoading = zatcaCtrl.isLoading;
        final double hPad = AppResponsive.clamp(
          AppResponsive.vw(constraints, 5.5),
          16,
          22,
        );

        final double gap = AppResponsive.clamp(
          AppResponsive.scaledByHeight(constraints, 16),
          12,
          18,
        );

        final (_ChipStyle? stStyle, String stText) = _statusStyle(
          invoice.status,
        );

        return Scaffold(
          backgroundColor: const Color(0xFFF7FAFF),
          appBar: AppBar(title: const Text('Invoice Details')),
          body: SafeArea(
            child: Skeletonizer(
              enabled: isLoading,
              child: AbsorbPointer(
                absorbing: isLoading,
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(hPad, gap, hPad, gap),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFFE9EEF5)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        Row(
                          children: <Widget>[
                            Expanded(
                              child: Text(
                                'Invoice #${invoice.invoiceNo}',
                                style: const TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            Text(
                              _amountLabel(),
                              style: const TextStyle(
                                color: Color(0xFF0B1B4B),
                                fontWeight: FontWeight.w900,
                                fontSize: 18,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          invoice.customer,
                          style: const TextStyle(
                            color: Color(0xFF0B1B4B),
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: <Widget>[
                            Expanded(
                              child: Text(
                                _fmtDate(invoice.issueDate),
                                style: const TextStyle(
                                  color: Color(0xFF9AA5B6),
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            if (stStyle != null)
                              _Chip(text: stText, style: stStyle),
                          ],
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: gap),
                  _SectionCard(
                    title: 'Summary',
                    child: Column(
                      children: <Widget>[
                        _SummaryRow(
                          label: 'Invoice #',
                          value: invoice.invoiceNo,
                        ),
                        _SummaryRow(label: 'Customer', value: invoice.customer),
                        _SummaryRow(
                          label: 'Issue Date',
                          value: _fmtDate(invoice.issueDate),
                        ),
                        _SummaryRow(
                          label: 'Due Date',
                          value: invoice.dueDate == null
                              ? '-'
                              : _fmtDate(invoice.dueDate!),
                        ),
                        _SummaryRow(label: 'Company', value: invoice.company),
                        _SummaryRow(
                          label: 'Customer Type',
                          value: invoice.customerType,
                        ),
                        _SummaryRow(
                          label: 'Invoice Type',
                          value: invoice.invoiceType,
                        ),
                        _SummaryRow(
                          label: 'Payment Terms',
                          value: invoice.paymentTerms,
                        ),
                        _SummaryRow(label: 'Currency', value: invoice.currency),
                        _SummaryRow(
                          label: 'Subtotal',
                          value: _formatNumber(invoice.subtotal),
                        ),
                        _SummaryRow(
                          label: 'VAT',
                          value: _formatNumber(invoice.vatAmount),
                        ),
                        _SummaryRow(label: 'Total', value: _amountLabel()),
                      ],
                    ),
                  ),
                  SizedBox(height: gap),
                  _SectionCard(
                    title: 'Items',
                    child: invoice.items.isEmpty
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
                            children: invoice.items.map((InvoiceItem it) {
                              final double lineTotal = it.total;
                              final bool asInt =
                                  (lineTotal - lineTotal.truncateToDouble())
                                      .abs() <
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
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: <Widget>[
                                          Text(
                                            it.product,
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
                                            'Qty ${it.qty}  •  ${invoice.currency} ${it.price.toStringAsFixed(2)}',
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
                                      '${invoice.currency} $formatted',
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
                  if (invoice.notes.trim().isNotEmpty) ...<Widget>[
                    SizedBox(height: gap),
                    _SectionCard(
                      title: 'Notes',
                      child: Text(
                        invoice.notes,
                        style: const TextStyle(
                          color: Color(0xFF0B1B4B),
                          fontWeight: FontWeight.w700,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                  if (invoice.terms.trim().isNotEmpty) ...<Widget>[
                    SizedBox(height: gap),
                    _SectionCard(
                      title: 'Terms',
                      child: Text(
                        invoice.terms,
                        style: const TextStyle(
                          color: Color(0xFF0B1B4B),
                          fontWeight: FontWeight.w700,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                  SizedBox(height: gap),
                  _SectionCard(
                    title: 'ZATCA',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        if (invoice.zatca.hasAny) ...<Widget>[
                          _SummaryRow(
                            label: 'Status',
                            value: invoice.zatca.status.trim().isEmpty
                                ? '-'
                                : invoice.zatca.status.trim(),
                          ),
                          _SummaryRow(
                            label: 'Validation',
                            value: invoice.zatca.validationStatus.trim().isEmpty
                                ? '-'
                                : invoice.zatca.validationStatus.trim(),
                          ),
                          _SummaryRow(
                            label: 'UUID',
                            value: invoice.zatca.uuid.trim().isEmpty
                                ? '-'
                                : invoice.zatca.uuid.trim(),
                          ),
                          _SummaryRow(
                            label: 'Last Validated',
                            value: _fmtDateTime(invoice.zatca.lastValidatedAt),
                          ),
                          _SummaryRow(
                            label: 'Cleared At',
                            value: _fmtDateTime(invoice.zatca.clearedAt),
                          ),
                          _SummaryRow(
                            label: 'Category',
                            value: invoice.zatca.invoiceCategory.trim().isEmpty
                                ? '-'
                                : invoice.zatca.invoiceCategory.trim(),
                          ),
                          _SummaryRow(
                            label: 'Hash Chain #',
                            value: invoice.zatca.hashChainNumber == null
                                ? '-'
                                : invoice.zatca.hashChainNumber.toString(),
                          ),
                          _SummaryRow(
                            label: 'Previous Hash',
                            value: invoice.zatca.previousInvoiceHash.trim().isEmpty
                                ? '-'
                                : invoice.zatca.previousInvoiceHash.trim(),
                          ),
                        ],
                        Text(
                          invoice.id.isEmpty
                              ? 'Invoice ID not available'
                              : 'Invoice ID: ${invoice.id}',
                          style: const TextStyle(
                            color: Color(0xFF6B7895),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if ((invoice.zatca.hash).trim().isNotEmpty) ...<Widget>[
                          const SizedBox(height: 10),
                          SelectableText(
                            'Hash: ${invoice.zatca.hash.trim()}',
                            style: const TextStyle(
                              color: Color(0xFF6B7895),
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                        ],
                        const SizedBox(height: 10),
                        OutlinedButton(
                          onPressed: invoice.id.trim().isEmpty
                              ? null
                              : () => _sharePdf(context),
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
                          child: const Text('Download / Share PDF'),
                        ),
                        if ((invoice.zatca.qrCode).trim().isNotEmpty) ...<Widget>[
                          const SizedBox(height: 12),
                          Builder(
                            builder: (BuildContext context) {
                              final Uint8List? bytes =
                                  _tryDecodeBase64(invoice.zatca.qrCode);
                              if (bytes == null) {
                                return SelectableText(
                                  'QR (base64): ${invoice.zatca.qrCode.trim()}',
                                  style: const TextStyle(
                                    color: Color(0xFF6B7895),
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12,
                                  ),
                                );
                              }
                              return Center(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.memory(
                                    bytes,
                                    width: 180,
                                    height: 180,
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                        const SizedBox(height: 10),
                        ElevatedButton(
                          onPressed: invoice.id.isEmpty
                              ? null
                              : () => _validateZatca(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                          ),
                          child: const Text('Validate with ZATCA'),
                        ),
                      ],
                    ),
                  ),
                ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE9EEF5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF0B1B4B),
              fontWeight: FontWeight.w900,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 12),
          child,
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
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFF6B7895),
                fontWeight: FontWeight.w700,
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
      ),
    );
  }
}

class _ChipStyle {
  final Color bg;
  final Color fg;

  const _ChipStyle({required this.bg, required this.fg});
}

class _Chip extends StatelessWidget {
  final String text;
  final _ChipStyle style;

  const _Chip({required this.text, required this.style});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: style.bg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: style.fg,
          fontWeight: FontWeight.w800,
          fontSize: 12,
        ),
      ),
    );
  }
}
