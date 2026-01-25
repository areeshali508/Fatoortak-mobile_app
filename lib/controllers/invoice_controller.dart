import 'package:flutter/material.dart';

import '../models/invoice.dart';

class InvoiceController extends ChangeNotifier {
  final List<Invoice> _invoices = <Invoice>[
    Invoice(
      invoiceNo: 'INV-1024',
      customer: 'Ahmed Traders',
      issueDate: DateTime(2026, 1, 12),
      dueDate: DateTime(2026, 1, 12),
      currency: 'SAR',
      status: InvoiceStatus.draft,
      company: 'Tech Solutions Ltd.',
      customerType: 'B2B (Business)',
      invoiceType: 'Tax Invoice (Standard)',
      paymentTerms: 'Immediate',
      items: const <InvoiceItem>[
        InvoiceItem(
          product: 'Services',
          qty: 1,
          price: 2500,
          discountPercent: 0,
          vatCategory: '-',
          taxPercent: 0,
        ),
      ],
      notes: '',
      terms: '',
    ),
    Invoice(
      invoiceNo: 'INV-1023',
      customer: 'Global Tech Ltd',
      issueDate: DateTime(2026, 1, 10),
      dueDate: DateTime(2026, 1, 10),
      currency: 'SAR',
      status: InvoiceStatus.sent,
      company: 'Tech Solutions Ltd.',
      customerType: 'B2B (Business)',
      invoiceType: 'Tax Invoice (Standard)',
      paymentTerms: 'Immediate',
      items: const <InvoiceItem>[
        InvoiceItem(
          product: 'Services',
          qty: 1,
          price: 8400,
          discountPercent: 0,
          vatCategory: '-',
          taxPercent: 0,
        ),
      ],
      notes: '',
      terms: '',
    ),
    Invoice(
      invoiceNo: 'INV-1021',
      customer: 'Logistics Co',
      issueDate: DateTime(2026, 1, 1),
      dueDate: DateTime(2026, 1, 1),
      currency: 'SAR',
      status: InvoiceStatus.overdue,
      company: 'Tech Solutions Ltd.',
      customerType: 'B2B (Business)',
      invoiceType: 'Tax Invoice (Standard)',
      paymentTerms: 'Immediate',
      items: const <InvoiceItem>[
        InvoiceItem(
          product: 'Services',
          qty: 1,
          price: 4500,
          discountPercent: 0,
          vatCategory: '-',
          taxPercent: 0,
        ),
      ],
      notes: '',
      terms: '',
    ),
    Invoice(
      invoiceNo: 'INV-1022',
      customer: 'Creative Studio',
      issueDate: DateTime(2026, 1, 5),
      dueDate: DateTime(2026, 1, 5),
      currency: 'SAR',
      status: InvoiceStatus.paid,
      company: 'Tech Solutions Ltd.',
      customerType: 'B2B (Business)',
      invoiceType: 'Tax Invoice (Standard)',
      paymentTerms: 'Immediate',
      items: const <InvoiceItem>[
        InvoiceItem(
          product: 'Services',
          qty: 1,
          price: 1200,
          discountPercent: 0,
          vatCategory: '-',
          taxPercent: 0,
        ),
      ],
      notes: '',
      terms: '',
    ),
    Invoice(
      invoiceNo: 'INV-1019',
      customer: 'Foodies Inc',
      issueDate: DateTime(2025, 12, 28),
      dueDate: DateTime(2025, 12, 28),
      currency: 'SAR',
      status: InvoiceStatus.none,
      company: 'Tech Solutions Ltd.',
      customerType: 'B2B (Business)',
      invoiceType: 'Tax Invoice (Standard)',
      paymentTerms: 'Immediate',
      items: const <InvoiceItem>[
        InvoiceItem(
          product: 'Services',
          qty: 1,
          price: 350,
          discountPercent: 0,
          vatCategory: '-',
          taxPercent: 0,
        ),
      ],
      notes: '',
      terms: '',
    ),
  ];

  InvoiceStatus? _statusFilter;
  DateTimeRange? _dateRange;
  String _searchQuery = '';

  List<Invoice> get invoices => List<Invoice>.unmodifiable(_invoices);
  InvoiceStatus? get statusFilter => _statusFilter;
  DateTimeRange? get dateRange => _dateRange;
  String get searchQuery => _searchQuery;

  void setSearchQuery(String q) {
    final String next = q.trim();
    if (next == _searchQuery) {
      return;
    }
    _searchQuery = next;
    notifyListeners();
  }

  void setStatusFilter(InvoiceStatus? status) {
    if (status == _statusFilter) {
      return;
    }
    _statusFilter = status;
    notifyListeners();
  }

  void setDateRange(DateTimeRange? range) {
    _dateRange = range;
    notifyListeners();
  }

  bool _inDateRange(DateTime d) {
    if (_dateRange == null) {
      return true;
    }
    return !d.isBefore(_dateRange!.start) && !d.isAfter(_dateRange!.end);
  }

  List<Invoice> get visibleInvoices {
    final String q = _searchQuery.toLowerCase();
    return _invoices.where((Invoice inv) {
      final bool statusOk = _statusFilter == null
          ? true
          : inv.status == _statusFilter;
      final bool dateOk = _inDateRange(inv.issueDate);
      final bool searchOk = q.isEmpty
          ? true
          : inv.invoiceNo.toLowerCase().contains(q) ||
                inv.customer.toLowerCase().contains(q);
      return statusOk && dateOk && searchOk;
    }).toList();
  }

  void addInvoice(Invoice invoice) {
    _invoices.insert(0, invoice);
    notifyListeners();
  }

  String dateLabel(DateTime d) {
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

  String amountLabel(Invoice inv) {
    return '${inv.currency} ${_formatNumber(inv.total)}';
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
}
