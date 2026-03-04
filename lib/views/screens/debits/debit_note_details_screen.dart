import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_responsive.dart';
import '../../../models/debit_note.dart';
import '../../../repositories/debit_note_repository.dart';

class DebitNoteDetailsScreen extends StatefulWidget {
  final String? debitNoteId;
  final DebitNote initialNote;

  const DebitNoteDetailsScreen({
    super.key,
    required this.initialNote,
    this.debitNoteId,
  });

  @override
  State<DebitNoteDetailsScreen> createState() => _DebitNoteDetailsScreenState();
}

class _DebitNoteDetailsScreenState extends State<DebitNoteDetailsScreen> {
  late Future<DebitNote> _future;
  bool _isValidating = false;

  @override
  void initState() {
    super.initState();
    final String id = (widget.debitNoteId ?? '').trim();
    if (id.isNotEmpty) {
      _future = context.read<DebitNoteRepository>().getDebitNoteById(id);
    } else {
      _future = Future<DebitNote>.value(widget.initialNote);
    }
  }

  Future<void> _validateZatca(DebitNote note) async {
    if (_isValidating) return;
    final String id =
        (note.backendId.trim().isNotEmpty ? note.backendId : note.id).trim();
    if (id.isEmpty) return;

    setState(() {
      _isValidating = true;
    });

    final DebitNoteRepository repo = context.read<DebitNoteRepository>();
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);

    try {
      final Map<String, dynamic> res = await repo.validateZatca(id: id);
      final Object? dataObj = res['data'];
      final Map<String, dynamic> data =
          dataObj is Map<String, dynamic> ? dataObj : <String, dynamic>{};

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

      if (errors.isNotEmpty) {
        messenger.showSnackBar(SnackBar(content: Text(errors.first)));
      } else if (warnings.isNotEmpty) {
        messenger.showSnackBar(SnackBar(content: Text(warnings.first)));
      } else {
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              isValid
                  ? 'ZATCA validation successful'
                  : 'ZATCA validation returned not valid',
            ),
          ),
        );
      }

      final String fetchId = id;
      if (fetchId.isNotEmpty) {
        setState(() {
          _future = repo.getDebitNoteById(fetchId);
        });
      }
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) {
        setState(() {
          _isValidating = false;
        });
      }
    }
  }

  String _fmtDate(DateTime d) {
    final String day = d.day.toString().padLeft(2, '0');
    final String month = d.month.toString().padLeft(2, '0');
    return '$day/$month/${d.year}';
  }

  String _amountLabel(DebitNote note) {
    final double total = note.amount;
    final bool asInt = (total - total.truncateToDouble()).abs() < 0.000001;
    final String formatted = asInt
        ? total.toStringAsFixed(0)
        : total.toStringAsFixed(2);
    return '${note.currency} $formatted';
  }

  (_ChipStyle, String) _statusStyle(DebitNoteStatus s) {
    switch (s) {
      case DebitNoteStatus.draft:
        return (
          const _ChipStyle(bg: Color(0xFFF3F6FB), fg: Color(0xFF6B7895)),
          'Draft',
        );
      case DebitNoteStatus.submitted:
        return (
          const _ChipStyle(bg: Color(0xFFE7F1FF), fg: AppColors.primary),
          'Submitted',
        );
      case DebitNoteStatus.cleared:
        return (
          const _ChipStyle(bg: Color(0xFFEFFAF3), fg: Color(0xFF1DB954)),
          'Cleared',
        );
      case DebitNoteStatus.reported:
        return (
          const _ChipStyle(bg: Color(0xFFEFFAF3), fg: Color(0xFF1DB954)),
          'Reported',
        );
      case DebitNoteStatus.rejected:
        return (
          const _ChipStyle(bg: Color(0xFFFFE7E7), fg: Color(0xFFD93025)),
          'Rejected',
        );
    }
  }

  (_ChipStyle, String) _paymentStyle(DebitNotePaymentStatus s) {
    switch (s) {
      case DebitNotePaymentStatus.pending:
        return (
          const _ChipStyle(bg: Color(0xFFFFF4E5), fg: Color(0xFFB26A00)),
          'Pending',
        );
      case DebitNotePaymentStatus.paid:
        return (
          const _ChipStyle(bg: Color(0xFFEFFAF3), fg: Color(0xFF1DB954)),
          'Paid',
        );
      case DebitNotePaymentStatus.cancelled:
        return (
          const _ChipStyle(bg: Color(0xFFFFE7E7), fg: Color(0xFFD93025)),
          'Cancelled',
        );
    }
  }

  Widget _body(BuildContext context, BoxConstraints constraints, DebitNote note) {
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

    final (_ChipStyle stStyle, String stText) = _statusStyle(note.status);
    final (_ChipStyle payStyle, String payText) = _paymentStyle(
      note.paymentStatus,
    );

    return SafeArea(
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
                          'Debit Note #${note.id}',
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w900,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      Text(
                        _amountLabel(note),
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
                    note.customer,
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
                          _fmtDate(note.issueDate),
                          style: const TextStyle(
                            color: Color(0xFF9AA5B6),
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      _Chip(text: stText, style: stStyle),
                      const SizedBox(width: 8),
                      _Chip(text: payText, style: payStyle),
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
                  _SummaryRow(label: 'Debit Note #', value: note.id),
                  _SummaryRow(label: 'Customer', value: note.customer),
                  _SummaryRow(
                    label: 'Customer Type',
                    value: note.customerType,
                  ),
                  _SummaryRow(
                    label: 'Invoice Ref',
                    value: note.originalInvoiceNo ?? '-',
                  ),
                  _SummaryRow(
                    label: 'Issue Date',
                    value: _fmtDate(note.issueDate),
                  ),
                  _SummaryRow(label: 'Currency', value: note.currency),
                  _SummaryRow(label: 'Total', value: _amountLabel(note)),
                  _SummaryRow(
                    label: 'ZATCA UUID',
                    value: note.zatcaUuid ?? '-',
                  ),
                  _SummaryRow(
                    label: 'ZATCA Hash',
                    value: note.zatcaHash ?? '-',
                  ),
                  if ((note.zatcaErrorMessage ?? '').trim().isNotEmpty)
                    _SummaryRow(
                      label: 'ZATCA Error',
                      value: note.zatcaErrorMessage!.trim(),
                    ),
                ],
              ),
            ),
            SizedBox(height: gap),
            _SectionCard(
              title: 'Items',
              child: note.items.isEmpty
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
                      children: note.items.map((DebitNoteItem it) {
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
                                      'Qty: ${it.qty} | VAT: ${it.taxPercent.toStringAsFixed(0)}%',
                                      style: const TextStyle(
                                        color: Color(0xFF6B7895),
                                        fontWeight: FontWeight.w700,
                                        fontSize: 12,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Unit: ${it.price.toStringAsFixed(2)} ${note.currency}',
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
                                '$formatted ${note.currency}',
                                style: const TextStyle(
                                  color: Color(0xFF0B1B4B),
                                  fontWeight: FontWeight.w900,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
            ),
            SizedBox(height: gap),
            OutlinedButton(
              onPressed: _isValidating ? null : () => _validateZatca(note),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF0B1B4B),
                side: const BorderSide(color: Color(0xFFE9EEF5)),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                textStyle: const TextStyle(fontWeight: FontWeight.w900),
                backgroundColor: Colors.white,
              ),
              child: Text(
                _isValidating ? 'Validating…' : 'Validate (ZATCA)',
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        return Scaffold(
          backgroundColor: const Color(0xFFF7FAFF),
          appBar: AppBar(title: const Text('Debit Note Details')),
          body: FutureBuilder<DebitNote>(
            future: _future,
            builder: (BuildContext context, AsyncSnapshot<DebitNote> snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                );
              }
              if (snap.hasError) {
                return _body(context, constraints, widget.initialNote);
              }
              final DebitNote note = snap.data ?? widget.initialNote;
              return _body(context, constraints, note);
            },
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

class _ChipStyle {
  final Color bg;
  final Color fg;

  const _ChipStyle({required this.bg, required this.fg});
}
