import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_responsive.dart';
import '../../../models/credit_note.dart';
import '../../../repositories/credit_note_repository.dart';
import 'package:provider/provider.dart';

class CreditNoteDetailsScreen extends StatefulWidget {
  final CreditNote note;

  const CreditNoteDetailsScreen({super.key, required this.note});

  @override
  State<CreditNoteDetailsScreen> createState() => _CreditNoteDetailsScreenState();
}

class _CreditNoteDetailsScreenState extends State<CreditNoteDetailsScreen> {
  late CreditNote _note;
  bool _isLoading = false;
  bool _isApplying = false;
  bool _isValidating = false;
  bool _isSending = false;
  bool _isDownloadingPdf = false;
  bool _zatcaIsValid = false;
  String? _error;

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
    return '${_note.currency} ${_formatNumber(_note.amount)}';
  }

  String _fmtDateTime(DateTime? dt) {
    if (dt == null) return '-';
    String two(int v) => v.toString().padLeft(2, '0');
    return '${dt.year}-${two(dt.month)}-${two(dt.day)} ${two(dt.hour)}:${two(dt.minute)}';
  }

  double _subtotal() => _note.items.fold<double>(
        0,
        (double p, CreditNoteItem e) => p + e.taxableAmount,
      );

  double _vatAmount() => _note.items.fold<double>(
        0,
        (double p, CreditNoteItem e) => p + e.taxAmount,
      );

  (_ChipStyle, String) _statusStyle(CreditNoteStatus s) {
    switch (s) {
      case CreditNoteStatus.draft:
        return (
          const _ChipStyle(bg: Color(0xFFF3F6FB), fg: Color(0xFF6B7895)),
          'Draft',
        );
      case CreditNoteStatus.submitted:
        return (
          const _ChipStyle(bg: Color(0xFFE7F1FF), fg: AppColors.primary),
          'Submitted',
        );
      case CreditNoteStatus.cleared:
        return (
          const _ChipStyle(bg: Color(0xFFEFFAF3), fg: Color(0xFF1DB954)),
          'Cleared',
        );
      case CreditNoteStatus.reported:
        return (
          const _ChipStyle(bg: Color(0xFFEFFAF3), fg: Color(0xFF1DB954)),
          'Reported',
        );
      case CreditNoteStatus.rejected:
        return (
          const _ChipStyle(bg: Color(0xFFFFE7E7), fg: Color(0xFFD93025)),
          'Rejected',
        );
    }
  }

  (_ChipStyle, String) _paymentStyle(CreditNotePaymentStatus s) {
    switch (s) {
      case CreditNotePaymentStatus.pending:
        return (
          const _ChipStyle(bg: Color(0xFFFFF4E5), fg: Color(0xFFB26A00)),
          'Pending',
        );
      case CreditNotePaymentStatus.refunded:
        return (
          const _ChipStyle(bg: Color(0xFFFFE7E7), fg: Color(0xFFD93025)),
          'Refunded',
        );
      case CreditNotePaymentStatus.applied:
        return (
          const _ChipStyle(bg: Color(0xFFEFFAF3), fg: Color(0xFF1DB954)),
          'Applied',
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final bool isBusy =
            _isLoading || _isApplying || _isValidating || _isSending;

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

        final (_ChipStyle stStyle, String stText) = _statusStyle(_note.status);
        final (_ChipStyle payStyle, String payText) =
            _paymentStyle(_note.paymentStatus);

        final bool canApply =
            _note.paymentStatus != CreditNotePaymentStatus.applied &&
            _note.status != CreditNoteStatus.draft;
        final bool canValidate = _note.id.trim().isNotEmpty && !_isValidating;
        final bool canSend =
            _note.id.trim().isNotEmpty &&
            _note.status == CreditNoteStatus.draft &&
            _zatcaIsValid &&
            !_isSending;

        return Scaffold(
          backgroundColor: const Color(0xFFF7FAFF),
          appBar: AppBar(title: const Text('Credit Note Details')),
          body: SafeArea(
            child: Skeletonizer(
              enabled: isBusy,
              child: AbsorbPointer(
                absorbing: isBusy,
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
                                    'Credit Note #${_note.number ?? _note.id}',
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
                              _note.customer,
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
                                    _fmtDate(_note.issueDate),
                                    style: const TextStyle(
                                      color: Color(0xFF9AA5B6),
                                      fontWeight: FontWeight.w700,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
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
                              label: 'Credit Note #',
                              value: _note.number ?? _note.id,
                            ),
                            _SummaryRow(
                              label: 'Customer',
                              value: _note.customer,
                            ),
                            _SummaryRow(
                              label: 'Payment Status',
                              value: payText,
                            ),
                            _SummaryRow(
                              label: 'Customer Type',
                              value: _note.customerType,
                            ),
                            _SummaryRow(
                              label: 'Invoice Ref',
                              value: _note.originalInvoiceNo ?? '-',
                            ),
                            _SummaryRow(
                              label: 'Issue Date',
                              value: _fmtDate(_note.issueDate),
                            ),
                            _SummaryRow(
                              label: 'Currency',
                              value: _note.currency,
                            ),
                            _SummaryRow(
                              label: 'Subtotal',
                              value: _formatNumber(_subtotal()),
                            ),
                            _SummaryRow(
                              label: 'VAT',
                              value: _formatNumber(_vatAmount()),
                            ),
                            _SummaryRow(
                              label: 'Total',
                              value: _amountLabel(),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: gap),
                      _SectionCard(
                        title: 'Items',
                        child: _note.items.isEmpty
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
                                children: _note.items.map((CreditNoteItem it) {
                                  final double lineTotal = it.total;
                                  final bool asInt =
                                      (lineTotal -
                                                  lineTotal
                                                      .truncateToDouble())
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
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: <Widget>[
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
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
                                                'Qty ${it.qty}  •  ${_note.currency} ${it.price.toStringAsFixed(2)}',
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
                                          '${_note.currency} $formatted',
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
                      if (canApply) ...<Widget>[
                        SizedBox(height: gap),
                        ElevatedButton(
                          onPressed: _isApplying ? null : _apply,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: const Text(
                            'Apply Credit Note',
                            style: TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ),
                      ],
                      SizedBox(height: gap),
                      _SectionCard(
                        title: 'ZATCA',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: <Widget>[
                            _SummaryRow(
                              label: 'Status',
                              value: (_note.zatcaStatus ?? '').trim().isEmpty
                                  ? '-'
                                  : _note.zatcaStatus!.trim(),
                            ),
                            _SummaryRow(
                              label: 'Validation',
                              value: (_note.zatcaValidationStatus ?? '').trim().isEmpty
                                  ? '-'
                                  : _note.zatcaValidationStatus!.trim(),
                            ),
                            _SummaryRow(
                              label: 'UUID',
                              value: (_note.zatcaUuid ?? '').trim().isEmpty
                                  ? '-'
                                  : _note.zatcaUuid!.trim(),
                            ),
                            _SummaryRow(
                              label: 'Last Validated',
                              value: _fmtDateTime(_note.zatcaLastValidatedAt),
                            ),
                            _SummaryRow(
                              label: 'Cleared At',
                              value: _fmtDateTime(_note.zatcaClearedAt),
                            ),
                            _SummaryRow(
                              label: 'Hash',
                              value: (_note.zatcaHash ?? '').trim().isEmpty
                                  ? '-'
                                  : _note.zatcaHash!.trim(),
                            ),
                            if ((_note.zatcaErrorMessage ?? '')
                                .trim()
                                .isNotEmpty)
                              _SummaryRow(
                                label: 'Error',
                                value: _note.zatcaErrorMessage!.trim(),
                              ),
                            if ((_error ?? '').trim().isNotEmpty) ...<Widget>[
                              const SizedBox(height: 10),
                              Text(
                                _error!.trim(),
                                style: const TextStyle(
                                  color: Color(0xFFD93025),
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                            const SizedBox(height: 10),
                            Row(
                              children: <Widget>[
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed:
                                        canValidate ? _validateZatca : null,
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor:
                                          const Color(0xFF0B1B4B),
                                      side: const BorderSide(
                                        color: Color(0xFFE9EEF5),
                                      ),
                                      backgroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 12,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(14),
                                      ),
                                      textStyle: const TextStyle(
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                    child: const Text('Validate (ZATCA)'),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed:
                                        canSend ? _sendToZatca : null,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.primary,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 12,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(14),
                                      ),
                                      textStyle: const TextStyle(
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                    child: const Text('Send (ZATCA)'),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            OutlinedButton(
                              onPressed: (_note.id.trim().isEmpty ||
                                      _isDownloadingPdf)
                                  ? null
                                  : _sharePdf,
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFF0B1B4B),
                                side: const BorderSide(color: Color(0xFFE9EEF5)),
                                backgroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                textStyle: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              child: Text(
                                _isDownloadingPdf
                                    ? 'Preparing PDF…'
                                    : 'Download / Share PDF',
                              ),
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

  @override
  void initState() {
    super.initState();
    _note = widget.note;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _refresh();
    });
  }

  Future<void> _refresh() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final CreditNoteRepository repo = context.read<CreditNoteRepository>();
      final CreditNote latest = await repo.getCreditNoteById(id: _note.id);
      if (!mounted) return;
      setState(() {
        _note = latest;
        _zatcaIsValid = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _apply() async {
    if (_note.status == CreditNoteStatus.draft) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Credit note must be sent before applying')),
      );
      return;
    }
    if (_isApplying) return;
    setState(() {
      _isApplying = true;
      _error = null;
    });

    final String? invoiceId = _note.originalInvoiceId;
    if ((invoiceId ?? '').trim().isEmpty) {
      setState(() {
        _isApplying = false;
        _error = 'Original invoice id is missing for this credit note';
      });
      return;
    }

    try {
      final CreditNoteRepository repo = context.read<CreditNoteRepository>();
      final CreditNote? updated = await repo.applyCreditNote(
        id: _note.id,
        payload: <String, dynamic>{
          'invoiceId': invoiceId!.trim(),
        },
      );
      if (!mounted) return;

      if (updated != null) {
        setState(() {
          _note = updated;
        });
      } else {
        await _refresh();
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Credit note applied successfully')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isApplying = false;
        });
      }
    }
  }

  Future<void> _validateZatca() async {
    if (_isValidating) return;

    setState(() {
      _isValidating = true;
      _error = null;
    });

    try {
      final CreditNoteRepository repo = context.read<CreditNoteRepository>();
      final Map<String, dynamic> res =
          await repo.validateZatca(id: _note.id.trim());

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

      if (!mounted) return;
      setState(() {
        _zatcaIsValid = isValid && errors.isEmpty;
      });

      if (!mounted) return;
      if (errors.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errors.first)),
        );
        return;
      }

      if (warnings.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(warnings.first)),
        );
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _zatcaIsValid
                ? 'ZATCA validation successful'
                : 'ZATCA validation returned not valid',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _zatcaIsValid = false;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isValidating = false;
        });
      }
    }
  }

  Future<void> _sendToZatca() async {
    if (_isSending) return;
    if (!_zatcaIsValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please validate with ZATCA first')),
      );
      return;
    }

    if (_note.status != CreditNoteStatus.draft) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Only draft credit notes can be sent')),
      );
      return;
    }

    setState(() {
      _isSending = true;
      _error = null;
    });

    try {
      final CreditNoteRepository repo = context.read<CreditNoteRepository>();
      await repo.sendToZatca(id: _note.id.trim());
      if (!mounted) return;

      await _refresh();
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Credit note sent to ZATCA')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }

  Future<void> _sharePdf() async {
    if (_isDownloadingPdf) return;
    if (_note.id.trim().isEmpty) return;

    setState(() {
      _isDownloadingPdf = true;
      _error = null;
    });

    try {
      final CreditNoteRepository repo = context.read<CreditNoteRepository>();
      final Uint8List? bytes =
          await repo.getCreditNotePdfBytes(id: _note.id.trim());
      if (!mounted) return;

      if (bytes == null || bytes.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('PDF not available')),
        );
        return;
      }

      final String base = (_note.number ?? '').trim();
      final String name = base.isEmpty ? 'credit_note.pdf' : '$base.pdf';
      await Printing.sharePdf(bytes: bytes, filename: name);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isDownloadingPdf = false;
        });
      }
    }
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
