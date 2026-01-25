import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../models/quotation.dart';

class QuotationDetailsScreen extends StatelessWidget {
  final Quotation quotation;

  const QuotationDetailsScreen({super.key, required this.quotation});

  String _fmtDate(DateTime? d) {
    if (d == null) {
      return '-';
    }
    final String mm = d.month.toString().padLeft(2, '0');
    final String dd = d.day.toString().padLeft(2, '0');
    return '$dd/$mm/${d.year}';
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
    return '${quotation.currency} ${_formatNumber(quotation.amount)}';
  }

  _ChipStyle _statusStyle(QuotationStatus status) {
    switch (status) {
      case QuotationStatus.draft:
        return const _ChipStyle(bg: Color(0xFFF3F6FB), fg: Color(0xFF6B7895));
      case QuotationStatus.sent:
        return const _ChipStyle(bg: Color(0xFFE7F1FF), fg: AppColors.primary);
    }
  }

  String _statusText(QuotationStatus status) {
    switch (status) {
      case QuotationStatus.draft:
        return 'Draft';
      case QuotationStatus.sent:
        return 'Sent';
    }
  }

  _ChipStyle _outcomeStyle(QuotationOutcomeStatus status) {
    switch (status) {
      case QuotationOutcomeStatus.pending:
        return const _ChipStyle(bg: Color(0xFFF3F6FB), fg: Color(0xFF6B7895));
      case QuotationOutcomeStatus.accepted:
        return const _ChipStyle(bg: Color(0xFFEFFAF3), fg: Color(0xFF1DB954));
      case QuotationOutcomeStatus.declined:
        return const _ChipStyle(bg: Color(0xFFFFE7E7), fg: Color(0xFFD93025));
      case QuotationOutcomeStatus.expired:
        return const _ChipStyle(bg: Color(0xFFFFF4E5), fg: Color(0xFFB35A00));
    }
  }

  String _outcomeText(QuotationOutcomeStatus status) {
    switch (status) {
      case QuotationOutcomeStatus.pending:
        return 'Pending';
      case QuotationOutcomeStatus.accepted:
        return 'Accepted';
      case QuotationOutcomeStatus.declined:
        return 'Declined';
      case QuotationOutcomeStatus.expired:
        return 'Expired';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7FAFF),
      appBar: AppBar(title: const Text('Quotation Details')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
          children: <Widget>[
            _SectionCard(
              title: 'Quotation',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          'Quotation #${quotation.id}',
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      Text(
                        _amountLabel(),
                        style: const TextStyle(
                          color: Color(0xFF0B1B4B),
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    quotation.customer,
                    style: const TextStyle(
                      color: Color(0xFF0B1B4B),
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          'Issued: ${_fmtDate(quotation.issueDate)}',
                          style: const TextStyle(
                            color: Color(0xFF9AA5B6),
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      _Chip(
                        text: _statusText(quotation.status),
                        style: _statusStyle(quotation.status),
                      ),
                      const SizedBox(width: 8),
                      _Chip(
                        text: _outcomeText(quotation.outcomeStatus),
                        style: _outcomeStyle(quotation.outcomeStatus),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            _SectionCard(
              title: 'Summary',
              child: Column(
                children: <Widget>[
                  _SummaryRow(
                    label: 'Valid Until',
                    value: _fmtDate(quotation.validUntil),
                  ),
                  _SummaryRow(label: 'Notes', value: quotation.notes),
                  _SummaryRow(label: 'Terms', value: quotation.terms),
                ],
              ),
            ),
            const SizedBox(height: 14),
            _SectionCard(
              title: 'Items',
              child: quotation.items.isEmpty
                  ? const Text(
                      '-',
                      style: TextStyle(
                        color: Color(0xFF6B7895),
                        fontWeight: FontWeight.w700,
                      ),
                    )
                  : Column(
                      children: <Widget>[
                        ...quotation.items.map((QuotationItem it) {
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
                              children: <Widget>[
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: <Widget>[
                                      Text(
                                        it.description,
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
                                  _formatNumber(it.total),
                                  style: const TextStyle(
                                    color: Color(0xFF0B1B4B),
                                    fontWeight: FontWeight.w900,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
            ),
          ],
        ),
      ),
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
            ],
          ),
          const SizedBox(height: 14),
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
