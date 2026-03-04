import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';
import 'package:skeletonizer/skeletonizer.dart';

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_responsive.dart';
import '../../../controllers/invoice_controller.dart';
import '../../../controllers/zatca_controller.dart';
import '../../../models/invoice.dart';

class InvoiceDetailsScreen extends StatefulWidget {
  final Invoice invoice;

  const InvoiceDetailsScreen({super.key, required this.invoice});

  @override
  State<InvoiceDetailsScreen> createState() => _InvoiceDetailsScreenState();
}

class _InvoiceDetailsScreenState extends State<InvoiceDetailsScreen> {
  late Invoice _invoice;
  bool _isZatcaPolling = false;
  bool _isSendingInvoice = false;
  Timer? _zatcaPollTimer;
  DateTime? _zatcaPollStartedAt;

  @override
  void initState() {
    super.initState();
    _invoice = widget.invoice;
  }

  @override
  void dispose() {
    _zatcaPollTimer?.cancel();
    _zatcaPollTimer = null;
    super.dispose();
  }

  Future<void> _sendInvoice(BuildContext context) async {
    if (_isSendingInvoice) return;
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    final InvoiceController invoiceCtrl = context.read<InvoiceController>();

    if (_invoice.id.trim().isEmpty) {
      messenger.showSnackBar(const SnackBar(content: Text('Invoice ID is required')));
      return;
    }

    setState(() {
      _isSendingInvoice = true;
    });

    try {
      final Invoice? updated = await invoiceCtrl.updateInvoiceStatus(
        invoiceId: _invoice.id,
        status: InvoiceStatus.sent,
      );
      if (!mounted) return;
      if (updated != null) {
        setState(() {
          _invoice = updated;
        });
        messenger.showSnackBar(const SnackBar(content: Text('Invoice sent')));
        return;
      }

      final String msg = (invoiceCtrl.errorMessage ?? 'Failed to send invoice').trim();
      if (msg.isNotEmpty) {
        messenger.showSnackBar(SnackBar(content: Text(msg)));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSendingInvoice = false;
        });
      }
    }
  }

  bool _isZatcaReady(Invoice inv) {
    final String st = inv.zatca.status.trim().toLowerCase();
    if (st.contains('cleared') || st.contains('reported') || st.contains('accepted')) {
      return true;
    }

    if (inv.zatca.clearedAt != null) {
      return true;
    }

    if (inv.zatca.qrCode.trim().isNotEmpty) {
      return true;
    }

    if (inv.zatca.pdfUrl.trim().isNotEmpty) {
      return true;
    }

    return false;
  }

  Future<void> _startZatcaBackgroundPolling({
    required InvoiceController invoiceCtrl,
    required String invoiceId,
    required ScaffoldMessengerState messenger,
    Duration tick = const Duration(seconds: 4),
    Duration timeout = const Duration(minutes: 10),
  }) async {
    _zatcaPollTimer?.cancel();
    _zatcaPollTimer = null;
    _zatcaPollStartedAt = DateTime.now();

    if (mounted) {
      setState(() {
        _isZatcaPolling = true;
      });
    }

    Future<void> tickOnce() async {
      final DateTime? startedAt = _zatcaPollStartedAt;
      if (startedAt == null) return;

      final Duration elapsed = DateTime.now().difference(startedAt);
      if (elapsed >= timeout) {
        _zatcaPollTimer?.cancel();
        _zatcaPollTimer = null;
        if (mounted) {
          setState(() {
            _isZatcaPolling = false;
          });
        }
        messenger.showSnackBar(
          const SnackBar(
            content: Text(
              'ZATCA is still processing this invoice. Please wait and refresh again.',
            ),
          ),
        );
        return;
      }

      final Invoice? latest = await invoiceCtrl.refreshInvoiceById(
        invoiceId: invoiceId,
      );
      if (!mounted) return;

      if (latest != null) {
        setState(() {
          _invoice = latest;
        });

        if (_isZatcaReady(latest)) {
          _zatcaPollTimer?.cancel();
          _zatcaPollTimer = null;
          setState(() {
            _isZatcaPolling = false;
          });
        }
      }
    }

    await tickOnce();
    if (!mounted) return;

    _zatcaPollTimer = Timer.periodic(tick, (_) {
      unawaited(tickOnce());
    });
  }

  Future<void> _validateZatca(BuildContext context) async {
    final ZatcaController ctrl = context.read<ZatcaController>();
    final InvoiceController invoiceCtrl = context.read<InvoiceController>();
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);

    await ctrl.validateInvoice(invoiceId: _invoice.id);

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
    final bool? success =
        res['success'] is bool ? res['success'] as bool : null;

    final String msg = (res['message'] ?? res['msg'] ?? '').toString().trim();
    if (msg.isNotEmpty) {
      messenger.showSnackBar(SnackBar(content: Text(msg)));
    }

    if (isValid == true || success == true) {
      try {
        await ctrl.submitOrClearInvoice(invoiceId: _invoice.id);
        if (!context.mounted) return;

        final String? submitErr = ctrl.errorMessage;
        if (submitErr != null && submitErr.trim().isNotEmpty) {
          messenger.showSnackBar(SnackBar(content: Text(submitErr)));
        } else {
          final Map<String, dynamic> submitRes =
              ctrl.lastResult ?? const <String, dynamic>{};
          final String submitMsg =
              (submitRes['message'] ?? submitRes['msg'] ?? '').toString().trim();
          if (submitMsg.isNotEmpty) {
            messenger.showSnackBar(SnackBar(content: Text(submitMsg)));
          }
        }

        await _startZatcaBackgroundPolling(
          invoiceCtrl: invoiceCtrl,
          invoiceId: _invoice.id,
          messenger: messenger,
        );
      } finally {
      }
    }

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

    if (!context.mounted) {
      return;
    }

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
      invoiceId: _invoice.id,
      fallbackBase64: _invoice.zatca.pdfUrl,
    );

    if (!context.mounted) return;

    final String? err = ctrl.errorMessage;
    if (bytes == null) {
      if (err != null && err.trim().isNotEmpty) {
        messenger.showSnackBar(SnackBar(content: Text(err)));
      }
      return;
    }

    final String name = _invoice.invoiceNo.trim().isEmpty
      ? 'invoice.pdf'
      : '${_invoice.invoiceNo.trim()}.pdf';
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
    return '${_invoice.currency} ${_formatNumber(_invoice.total)}';
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
        final bool isLoading = zatcaCtrl.isLoading || _isSendingInvoice;
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
          _invoice.status,
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
                                'Invoice #${_invoice.invoiceNo}',
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
                          _invoice.customer,
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
                                _fmtDate(_invoice.issueDate),
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
                          value: _invoice.invoiceNo,
                        ),
                        _SummaryRow(label: 'Customer', value: _invoice.customer),
                        _SummaryRow(
                          label: 'Issue Date',
                          value: _fmtDate(_invoice.issueDate),
                        ),
                        _SummaryRow(
                          label: 'Due Date',
                          value: _invoice.dueDate == null
                              ? '-'
                              : _fmtDate(_invoice.dueDate!),
                        ),
                        _SummaryRow(label: 'Company', value: _invoice.company),
                        _SummaryRow(
                          label: 'Customer Type',
                          value: _invoice.customerType,
                        ),
                        _SummaryRow(
                          label: 'Invoice Type',
                          value: _invoice.invoiceType,
                        ),
                        _SummaryRow(
                          label: 'Payment Terms',
                          value: _invoice.paymentTerms,
                        ),
                        _SummaryRow(label: 'Currency', value: _invoice.currency),
                        _SummaryRow(
                          label: 'Subtotal',
                          value: _formatNumber(_invoice.subtotal),
                        ),
                        _SummaryRow(
                          label: 'VAT',
                          value: _formatNumber(_invoice.vatAmount),
                        ),
                        _SummaryRow(label: 'Total', value: _amountLabel()),
                      ],
                    ),
                  ),
                  SizedBox(height: gap),
                  _SectionCard(
                    title: 'Items',
                    child: _invoice.items.isEmpty
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
                            children: _invoice.items.map((InvoiceItem it) {
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
                                            'Qty ${it.qty}  •  ${_invoice.currency} ${it.price.toStringAsFixed(2)}',
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
                                      '${_invoice.currency} $formatted',
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
                  if (_invoice.notes.trim().isNotEmpty) ...<Widget>[
                    SizedBox(height: gap),
                    _SectionCard(
                      title: 'Notes',
                      child: Text(
                        _invoice.notes,
                        style: const TextStyle(
                          color: Color(0xFF0B1B4B),
                          fontWeight: FontWeight.w700,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                  if (_invoice.terms.trim().isNotEmpty) ...<Widget>[
                    SizedBox(height: gap),
                    _SectionCard(
                      title: 'Terms',
                      child: Text(
                        _invoice.terms,
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
                        if (_isZatcaPolling) ...<Widget>[
                          const SizedBox(height: 6),
                          Row(
                            children: <Widget>[
                              const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                              const SizedBox(width: 10),
                              const Expanded(
                                child: Text(
                                  'Generating ZATCA QR/PDF…',
                                  style: TextStyle(
                                    color: Color(0xFF6B7895),
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                        ],
                        if (_invoice.zatca.hasAny) ...<Widget>[
                          _SummaryRow(
                            label: 'Status',
                            value: _invoice.zatca.status.trim().isEmpty
                                ? '-'
                                : _invoice.zatca.status.trim(),
                          ),
                          _SummaryRow(
                            label: 'Validation',
                            value: _invoice.zatca.validationStatus.trim().isEmpty
                                ? '-'
                                : _invoice.zatca.validationStatus.trim(),
                          ),
                          _SummaryRow(
                            label: 'UUID',
                            value: _invoice.zatca.uuid.trim().isEmpty
                                ? '-'
                                : _invoice.zatca.uuid.trim(),
                          ),
                          _SummaryRow(
                            label: 'Last Validated',
                            value: _fmtDateTime(_invoice.zatca.lastValidatedAt),
                          ),
                          _SummaryRow(
                            label: 'Cleared At',
                            value: _fmtDateTime(_invoice.zatca.clearedAt),
                          ),
                          _SummaryRow(
                            label: 'Category',
                            value: _invoice.zatca.invoiceCategory.trim().isEmpty
                                ? '-'
                                : _invoice.zatca.invoiceCategory.trim(),
                          ),
                          _SummaryRow(
                            label: 'Hash Chain #',
                            value: _invoice.zatca.hashChainNumber == null
                                ? '-'
                                : _invoice.zatca.hashChainNumber.toString(),
                          ),
                          _SummaryRow(
                            label: 'Previous Hash',
                            value: _invoice.zatca.previousInvoiceHash.trim().isEmpty
                                ? '-'
                                : _invoice.zatca.previousInvoiceHash.trim(),
                          ),
                        ],
                        Text(
                          _invoice.id.isEmpty
                              ? 'Invoice ID not available'
                              : 'Invoice ID: ${_invoice.id}',
                          style: const TextStyle(
                            color: Color(0xFF6B7895),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if ((_invoice.zatca.hash).trim().isNotEmpty) ...<Widget>[
                          const SizedBox(height: 10),
                          SelectableText(
                            'Hash: ${_invoice.zatca.hash.trim()}',
                            style: const TextStyle(
                              color: Color(0xFF6B7895),
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                        ],
                        const SizedBox(height: 10),
                        OutlinedButton(
                          onPressed: _invoice.id.trim().isEmpty
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
                        if (_invoice.status == InvoiceStatus.draft &&
                            !_invoice.zatca.hasAny &&
                            _invoice.zatca.lastValidatedAt == null &&
                            _invoice.zatca.validationStatus.trim().isEmpty) ...<Widget>[
                          const SizedBox(height: 10),
                          ElevatedButton(
                            onPressed: (_invoice.id.trim().isEmpty || _isZatcaPolling)
                                ? null
                                : () => _sendInvoice(context),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                            ),
                            child: const Text('Send Invoice'),
                          ),
                        ],
                        if ((_invoice.zatca.qrCode).trim().isNotEmpty) ...<Widget>[
                          const SizedBox(height: 12),
                          Builder(
                            builder: (BuildContext context) {
                              final Uint8List? bytes =
                                  _tryDecodeBase64(_invoice.zatca.qrCode);
                              if (bytes == null) {
                                return SelectableText(
                                  'QR (base64): ${_invoice.zatca.qrCode.trim()}',
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
                          onPressed: (_invoice.id.isEmpty || _isZatcaPolling)
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
