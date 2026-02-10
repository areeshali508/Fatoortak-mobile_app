import 'package:flutter/material.dart';

import '../../../core/constants/app_responsive.dart';
import '../../../models/customer.dart';

class CustomerPreviewScreen extends StatelessWidget {
  final Customer customer;

  const CustomerPreviewScreen({super.key, required this.customer});

  Widget _section({required String title, required List<Widget> children}) {
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
          ...children,
        ],
      ),
    );
  }

  String get _typeLabel {
    final String t = customer.customerType.trim().toLowerCase();
    if (t == 'company' || t == 'business' || t == 'b2b') return 'Business';
    if (t == 'individual' || t == 'person' || t == 'b2c') return 'Individual';
    return customer.customerType.trim().isEmpty ? '-' : customer.customerType.trim();
  }

  String _fmtDateTime(DateTime? dt) {
    if (dt == null) return '-';
    String two(int v) => v.toString().padLeft(2, '0');
    return '${dt.year}-${two(dt.month)}-${two(dt.day)} ${two(dt.hour)}:${two(dt.minute)}';
  }

  String _fmtNum(num v) {
    final num n = v;
    if (n == 0) return '0';
    final String s = n.toString();
    if (s.endsWith('.0')) return s.substring(0, s.length - 2);
    return s;
  }

  String get _addressLabel {
    final List<String> parts = <String>[
      customer.street.trim(),
      if (customer.district.trim().isNotEmpty) customer.district.trim(),
      if (customer.buildingNumber.trim().isNotEmpty)
        'Bldg ${customer.buildingNumber.trim()}',
      if (customer.city.trim().isNotEmpty) customer.city.trim(),
      if (customer.state.trim().isNotEmpty) customer.state.trim(),
      if (customer.postalCode.trim().isNotEmpty)
        'Postal ${customer.postalCode.trim()}',
      if (customer.country.trim().isNotEmpty) customer.country.trim(),
      if (customer.addressAdditionalNumber.trim().isNotEmpty)
        'Addl ${customer.addressAdditionalNumber.trim()}',
    ].where((String s) => s.isNotEmpty).toList();

    if (parts.isEmpty) return '-';
    return parts.join(', ');
  }

  Widget _infoRow({required String label, required String value, IconData? icon}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF7FAFF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE9EEF5)),
      ),
      child: Row(
        children: <Widget>[
          if (icon != null) ...<Widget>[
            Icon(icon, size: 18, color: const Color(0xFF6B7895)),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Text(
                  label,
                  style: const TextStyle(
                    color: Color(0xFF9AA5B6),
                    fontWeight: FontWeight.w800,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value.trim().isEmpty ? '-' : value.trim(),
                  style: const TextStyle(
                    color: Color(0xFF0B1B4B),
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String get _initials {
    final List<String> parts = customer.name
        .trim()
        .split(RegExp(r'\s+'))
        .where((String p) => p.isNotEmpty)
        .toList();
    if (parts.isEmpty) return 'C';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts[0].substring(0, 1) + parts[1].substring(0, 1)).toUpperCase();
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

        return Scaffold(
          backgroundColor: const Color(0xFFF7FAFF),
          appBar: AppBar(
            title: const Text('Customer Preview'),
          ),
          body: SafeArea(
            child: ListView(
              padding: EdgeInsets.fromLTRB(hPad, gap, hPad, gap),
              children: <Widget>[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFFE9EEF5)),
                  ),
                  child: Row(
                    children: <Widget>[
                      CircleAvatar(
                        radius: 26,
                        backgroundColor: const Color(0xFFE6F0FF),
                        child: Text(
                          _initials,
                          style: const TextStyle(
                            color: Color(0xFF0B1B4B),
                            fontWeight: FontWeight.w900,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: <Widget>[
                            Text(
                              customer.name.trim().isEmpty
                                  ? 'Customer'
                                  : customer.name.trim(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Color(0xFF0B1B4B),
                                fontWeight: FontWeight.w900,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              customer.companyId.trim().isEmpty
                                  ? 'Company: -'
                                  : 'Company: ${customer.companyId.trim()}',
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
                    ],
                  ),
                ),
                SizedBox(height: gap),
                _section(
                  title: 'Customer Information',
                  children: <Widget>[
                    _infoRow(
                      label: 'Customer Type',
                      value: _typeLabel,
                      icon: Icons.badge_outlined,
                    ),
                    const SizedBox(height: 10),
                    _infoRow(
                      label: 'Customer Group',
                      value: customer.customerGroup,
                      icon: Icons.groups_outlined,
                    ),
                    const SizedBox(height: 10),
                    _infoRow(
                      label: 'Customer Name (Arabic)',
                      value: customer.nameAr,
                      icon: Icons.translate,
                    ),
                    const SizedBox(height: 10),
                    _infoRow(
                      label: 'VAT / Tax ID',
                      value: customer.taxId,
                      icon: Icons.receipt_long_outlined,
                    ),
                    const SizedBox(height: 10),
                    _infoRow(
                      label: 'Commercial Registration',
                      value: customer.commercialRegistrationNumber,
                      icon: Icons.business_outlined,
                    ),
                    const SizedBox(height: 10),
                    _infoRow(
                      label: 'Reference Number',
                      value: customer.referenceNumber,
                      icon: Icons.confirmation_number_outlined,
                    ),
                  ],
                ),
                SizedBox(height: gap),
                _section(
                  title: 'Contact Information',
                  children: <Widget>[
                    _infoRow(
                      label: 'Email',
                      value: customer.email,
                      icon: Icons.mail_outline_rounded,
                    ),
                    const SizedBox(height: 10),
                    _infoRow(
                      label: 'Phone',
                      value: customer.phone,
                      icon: Icons.phone_outlined,
                    ),
                    const SizedBox(height: 10),
                    _infoRow(
                      label: 'Contact Person',
                      value: customer.contactPerson,
                      icon: Icons.person_outline,
                    ),
                  ],
                ),
                SizedBox(height: gap),
                _section(
                  title: 'Business Details',
                  children: <Widget>[
                    _infoRow(
                      label: 'Industry',
                      value: customer.industry,
                      icon: Icons.factory_outlined,
                    ),
                    const SizedBox(height: 10),
                    _infoRow(
                      label: 'Website',
                      value: customer.website,
                      icon: Icons.language,
                    ),
                    const SizedBox(height: 10),
                    _infoRow(
                      label: 'Notes',
                      value: customer.notes,
                      icon: Icons.notes_outlined,
                    ),
                  ],
                ),
                SizedBox(height: gap),
                _section(
                  title: 'Address',
                  children: <Widget>[
                    _infoRow(
                      label: 'Full Address',
                      value: _addressLabel,
                      icon: Icons.location_on_outlined,
                    ),
                    const SizedBox(height: 10),
                    _infoRow(
                      label: 'City',
                      value: customer.city,
                      icon: Icons.location_city_outlined,
                    ),
                    const SizedBox(height: 10),
                    _infoRow(
                      label: 'Country',
                      value: customer.country,
                      icon: Icons.public,
                    ),
                  ],
                ),
                SizedBox(height: gap),
                _section(
                  title: 'Banking',
                  children: <Widget>[
                    _infoRow(
                      label: 'Bank Name',
                      value: customer.bankName,
                      icon: Icons.account_balance_outlined,
                    ),
                    const SizedBox(height: 10),
                    _infoRow(
                      label: 'IBAN',
                      value: customer.iban,
                      icon: Icons.credit_card_outlined,
                    ),
                    const SizedBox(height: 10),
                    _infoRow(
                      label: 'Account Number',
                      value: customer.accountNumber,
                      icon: Icons.numbers,
                    ),
                    const SizedBox(height: 10),
                    _infoRow(
                      label: 'SWIFT Code',
                      value: customer.swiftCode,
                      icon: Icons.swap_horiz,
                    ),
                    const SizedBox(height: 10),
                    _infoRow(
                      label: 'Currency',
                      value: customer.currency,
                      icon: Icons.currency_exchange,
                    ),
                  ],
                ),
                SizedBox(height: gap),
                _section(
                  title: 'Limits & Payments',
                  children: <Widget>[
                    _infoRow(
                      label: 'Credit Limit',
                      value: _fmtNum(customer.creditLimit),
                      icon: Icons.credit_score_outlined,
                    ),
                    const SizedBox(height: 10),
                    _infoRow(
                      label: 'Discount',
                      value: _fmtNum(customer.discount),
                      icon: Icons.percent,
                    ),
                    const SizedBox(height: 10),
                    _infoRow(
                      label: 'Daily Limit',
                      value: _fmtNum(customer.dailyLimit),
                      icon: Icons.calendar_today_outlined,
                    ),
                    const SizedBox(height: 10),
                    _infoRow(
                      label: 'Monthly Limit',
                      value: _fmtNum(customer.monthlyLimit),
                      icon: Icons.date_range_outlined,
                    ),
                    const SizedBox(height: 10),
                    _infoRow(
                      label: 'Per Transaction Limit',
                      value: _fmtNum(customer.perTransactionLimit),
                      icon: Icons.payments_outlined,
                    ),
                    const SizedBox(height: 10),
                    _infoRow(
                      label: 'Total Payments Received',
                      value: _fmtNum(customer.totalPaymentsReceived),
                      icon: Icons.savings_outlined,
                    ),
                    const SizedBox(height: 10),
                    _infoRow(
                      label: 'Payment Count',
                      value: _fmtNum(customer.paymentCount),
                      icon: Icons.format_list_numbered,
                    ),
                    const SizedBox(height: 10),
                    _infoRow(
                      label: 'Last Payment Date',
                      value: _fmtDateTime(customer.lastPaymentDate),
                      icon: Icons.event_outlined,
                    ),
                  ],
                ),
                SizedBox(height: gap),
                _section(
                  title: 'Tags & Meta',
                  children: <Widget>[
                    _infoRow(
                      label: 'Tags',
                      value: customer.tags.isEmpty ? '-' : customer.tags.join(', '),
                      icon: Icons.sell_outlined,
                    ),
                    const SizedBox(height: 10),
                    _infoRow(
                      label: 'Source',
                      value: customer.source,
                      icon: Icons.source_outlined,
                    ),
                    const SizedBox(height: 10),
                    _infoRow(
                      label: 'Priority',
                      value: customer.priority,
                      icon: Icons.priority_high,
                    ),
                    const SizedBox(height: 10),
                    _infoRow(
                      label: 'Assigned To',
                      value: customer.assignedTo,
                      icon: Icons.assignment_ind_outlined,
                    ),
                  ],
                ),
                SizedBox(height: gap),
                _section(
                  title: 'Status',
                  children: <Widget>[
                    _infoRow(
                      label: 'Status',
                      value: customer.status,
                      icon: Icons.info_outline,
                    ),
                    const SizedBox(height: 10),
                    _infoRow(
                      label: 'Verification Status',
                      value: customer.verificationStatus,
                      icon: Icons.verified_outlined,
                    ),
                    const SizedBox(height: 10),
                    _infoRow(
                      label: 'Active',
                      value: customer.isActive ? 'Yes' : 'No',
                      icon: Icons.toggle_on_outlined,
                    ),
                  ],
                ),
                SizedBox(height: gap),
                _section(
                  title: 'System Information',
                  children: <Widget>[
                    _infoRow(
                      label: 'Customer ID',
                      value: customer.id,
                      icon: Icons.fingerprint,
                    ),
                    const SizedBox(height: 10),
                    _infoRow(
                      label: 'Company ID',
                      value: customer.companyId,
                      icon: Icons.apartment_outlined,
                    ),
                    const SizedBox(height: 10),
                    _infoRow(
                      label: 'Created At',
                      value: _fmtDateTime(customer.createdAt),
                      icon: Icons.schedule,
                    ),
                    const SizedBox(height: 10),
                    _infoRow(
                      label: 'Updated At',
                      value: _fmtDateTime(customer.updatedAt),
                      icon: Icons.update,
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
