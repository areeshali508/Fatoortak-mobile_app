import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_responsive.dart';
import '../../../models/debit_note.dart';

class CreateDebitNoteScreen extends StatefulWidget {
  const CreateDebitNoteScreen({super.key});

  @override
  State<CreateDebitNoteScreen> createState() => _CreateDebitNoteScreenState();
}

class _CreateDebitNoteScreenState extends State<CreateDebitNoteScreen> {
  final TextEditingController _numberCtrl =
      TextEditingController(text: 'DN-2024-NEW');
  final TextEditingController _customerCtrl =
      TextEditingController(text: 'New Customer');
  final TextEditingController _invoiceCtrl =
      TextEditingController(text: 'INV-2024-XXXX');
  final TextEditingController _amountCtrl = TextEditingController(text: '0');

  String _customerType = 'B2C';

  void _save(DebitNoteStatus status) {
    final String id = _numberCtrl.text.trim();
    final String customer = _customerCtrl.text.trim();
    final String invoice = _invoiceCtrl.text.trim();

    if (id.isEmpty || customer.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill required fields')),
      );
      return;
    }

    final double amount = double.tryParse(_amountCtrl.text.trim()) ?? 0;

    final DebitNote note = DebitNote(
      id: id,
      customer: customer,
      customerType: _customerType,
      issueDate: DateTime.now(),
      currency: 'SAR',
      amount: amount,
      status: status,
      paymentStatus: DebitNotePaymentStatus.pending,
      originalInvoiceNo: invoice.isEmpty ? null : invoice,
      originalInvoiceCustomerType: _customerType,
      zatcaUuid: status == DebitNoteStatus.submitted ? 'dn-uuid-new' : null,
      zatcaHash: status == DebitNoteStatus.submitted ? 'dn-hash-new' : null,
      items: <DebitNoteItem>[
        DebitNoteItem(
          description: 'Debit Adjustment',
          qty: 1,
          price: amount,
          discountPercent: 0,
          vatCategory: 'Standard',
          taxPercent: 15,
        ),
      ],
    );

    Navigator.of(context).pop(note);
  }

  @override
  void dispose() {
    _numberCtrl.dispose();
    _customerCtrl.dispose();
    _invoiceCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
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
            title: const Text('Create Debit Note'),
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
                  _SectionCard(
                    title: 'Details',
                    child: Column(
                      children: <Widget>[
                        _Field(
                          controller: _numberCtrl,
                          label: 'Debit Note #',
                          hint: 'DN-2024-001',
                        ),
                        SizedBox(height: gap),
                        _Field(
                          controller: _invoiceCtrl,
                          label: 'Original Invoice',
                          hint: 'INV-2024-XXXX',
                        ),
                        SizedBox(height: gap),
                        _Field(
                          controller: _customerCtrl,
                          label: 'Customer',
                          hint: 'Customer name',
                        ),
                        SizedBox(height: gap),
                        _DropdownField(
                          label: 'Customer Type',
                          value: _customerType,
                          items: const <String>['B2C', 'B2B'],
                          onChanged: (String? v) {
                            if (v == null) return;
                            setState(() => _customerType = v);
                          },
                        ),
                        SizedBox(height: gap),
                        _Field(
                          controller: _amountCtrl,
                          label: 'Amount (SAR)',
                          hint: '0',
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                        ),
                      ],
                    ),
                  ),
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
                border: Border(
                  top: BorderSide(color: Color(0xFFE9EEF5)),
                ),
              ),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _save(DebitNoteStatus.draft),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(color: AppColors.primary),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        textStyle: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                      child: const Text('Save Draft'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _save(DebitNoteStatus.submitted),
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
      padding: const EdgeInsets.all(16),
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

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final TextInputType? keyboardType;

  const _Field({
    required this.controller,
    required this.label,
    required this.hint,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF6B7895),
            fontWeight: FontWeight.w800,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Color(0xFF9AA5B6)),
            filled: true,
            fillColor: const Color(0xFFF7FAFF),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFFE9EEF5)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.primary, width: 1.4),
            ),
          ),
        ),
      ],
    );
  }
}

class _DropdownField extends StatelessWidget {
  final String label;
  final String value;
  final List<String> items;
  final ValueChanged<String?> onChanged;

  const _DropdownField({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF6B7895),
            fontWeight: FontWeight.w800,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFF7FAFF),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE9EEF5)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              items: items
                  .map(
                    (String e) => DropdownMenuItem<String>(
                      value: e,
                      child: Text(
                        e,
                        style: const TextStyle(
                          color: Color(0xFF0B1B4B),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  )
                  .toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}
