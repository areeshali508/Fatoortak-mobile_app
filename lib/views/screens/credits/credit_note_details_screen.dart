import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_responsive.dart';
import '../../../models/credit_note.dart';

class CreditNoteDetailsScreen extends StatelessWidget {
  final CreditNote note;

  const CreditNoteDetailsScreen({super.key, required this.note});

  String _fmtDate(DateTime d) {
    final String day = d.day.toString().padLeft(2, '0');
    final String month = d.month.toString().padLeft(2, '0');
    return '$day/$month/${d.year}';
  }

  String _amountLabel() {
    final double total = note.amount;
    final bool asInt = (total - total.truncateToDouble()).abs() < 0.000001;
    final String formatted =
        asInt ? total.toStringAsFixed(0) : total.toStringAsFixed(2);
    return '${note.currency} $formatted';
  }

  (_ChipStyle, String) _statusStyle(CreditNoteStatus s) {
    switch (s) {
      case CreditNoteStatus.draft:
        return (
          const _ChipStyle(bg: Color(0xFFF3F6FB), fg: Color(0xFF6B7895)),
          'Draft',
        );
      case CreditNoteStatus.sent:
        return (
          const _ChipStyle(bg: Color(0xFFE7F1FF), fg: AppColors.primary),
          'Sent',
        );
      case CreditNoteStatus.applied:
        return (
          const _ChipStyle(bg: Color(0xFFEFFAF3), fg: Color(0xFF1DB954)),
          'Applied',
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
        final (_ChipStyle payStyle, String payText) =
            _paymentStyle(note.paymentStatus);

        return Scaffold(
          backgroundColor: const Color(0xFFF7FAFF),
          appBar: AppBar(
            title: const Text('Credit Note Details'),
          ),
          body: SafeArea(
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
                                'Credit Note #${note.id}',
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
                        _SummaryRow(label: 'Credit Note #', value: note.id),
                        _SummaryRow(label: 'Customer', value: note.customer),
                        _SummaryRow(
                          label: 'Issue Date',
                          value: _fmtDate(note.issueDate),
                        ),
                        _SummaryRow(label: 'Currency', value: note.currency),
                        _SummaryRow(label: 'Total', value: _amountLabel()),
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
                            children: note.items.map((CreditNoteItem it) {
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
                                            'Qty ${it.qty}  •  ${note.currency} ${it.price.toStringAsFixed(2)}',
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
                                      '${note.currency} $formatted',
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
                ],
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
