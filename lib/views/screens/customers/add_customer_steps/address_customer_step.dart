import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../controllers/create_customer_controller.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_responsive.dart';

class AddressCustomerStep extends StatelessWidget {
  final BoxConstraints constraints;

  const AddressCustomerStep({super.key, required this.constraints});

  InputDecoration _dec({required String label, String? hint, Widget? prefixIcon}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: prefixIcon,
      isDense: true,
      filled: true,
      fillColor: const Color(0xFFF7FAFF),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFE9EEF5)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.2),
      ),
    );
  }

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

  Future<void> _openAddContact(BuildContext context) async {
    final TextEditingController nameCtrl = TextEditingController();
    final TextEditingController emailCtrl = TextEditingController();
    final TextEditingController phoneCtrl = TextEditingController();

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Colors.white,
      builder: (BuildContext ctx) {
        final double bottomPad = MediaQuery.of(ctx).viewInsets.bottom;
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(16, 0, 16, 16 + bottomPad),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                const Text(
                  'Add Contact',
                  style: TextStyle(
                    color: Color(0xFF0B1B4B),
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: nameCtrl,
                  decoration: _dec(label: 'Name', hint: 'Contact person name'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: _dec(label: 'Email', hint: 'email@example.com'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: phoneCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: _dec(label: 'Phone', hint: '+966 XX XXX XXXX'),
                ),
                const SizedBox(height: 14),
                ElevatedButton(
                  onPressed: () {
                    final String n = nameCtrl.text.trim();
                    final String e = emailCtrl.text.trim();
                    final String p = phoneCtrl.text.trim();
                    if (n.isEmpty && e.isEmpty && p.isEmpty) {
                      Navigator.of(ctx).pop();
                      return;
                    }
                    context.read<CreateCustomerController>().addContactPerson(
                          CustomerContactPerson(name: n, email: e, phone: p),
                        );
                    Navigator.of(ctx).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    textStyle: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  child: const Text('Add'),
                ),
              ],
            ),
          ),
        );
      },
    );

    nameCtrl.dispose();
    emailCtrl.dispose();
    phoneCtrl.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final CreateCustomerController ctrl =
        context.watch<CreateCustomerController>();

    final double gap = AppResponsive.clamp(
      AppResponsive.scaledByHeight(constraints, 14),
      10,
      16,
    );

    Widget emptyBox({
      required String title,
      required String subtitle,
      required String action,
    }) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFF7FAFF),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE9EEF5)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            ElevatedButton(
              onPressed: () {
                FocusScope.of(context).unfocus();
                _openAddContact(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                textStyle: const TextStyle(fontWeight: FontWeight.w900),
              ),
              child: Text(action),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                color: Color(0xFF0B1B4B),
                fontWeight: FontWeight.w900,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(
                color: Color(0xFF9AA5B6),
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ],
        ),
      );
    }

    Widget contactList() {
      if (ctrl.contactPersons.isEmpty) {
        return emptyBox(
          title: 'No contact persons added yet.',
          subtitle: 'Click "Add Contact" to get started.',
          action: 'Add Contact',
        );
      }
      return Column(
        children: List<Widget>.generate(ctrl.contactPersons.length, (int i) {
          final CustomerContactPerson p = ctrl.contactPersons[i];
          final String line1 =
              p.name.trim().isNotEmpty ? p.name.trim() : 'Contact ${i + 1}';
          final String line2 = <String>[p.email.trim(), p.phone.trim()]
              .where((String s) => s.isNotEmpty)
              .join(' • ');
          return Container(
            margin: EdgeInsets.only(
              bottom: i == ctrl.contactPersons.length - 1 ? 0 : 10,
            ),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF7FAFF),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE9EEF5)),
            ),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      Text(
                        line1,
                        style: const TextStyle(
                          color: Color(0xFF0B1B4B),
                          fontWeight: FontWeight.w900,
                          fontSize: 13,
                        ),
                      ),
                      if (line2.isNotEmpty) ...<Widget>[
                        const SizedBox(height: 4),
                        Text(
                          line2,
                          style: const TextStyle(
                            color: Color(0xFF6B7895),
                            fontWeight: FontWeight.w700,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => context
                      .read<CreateCustomerController>()
                      .removeContactPersonAt(i),
                  icon: const Icon(Icons.delete_outline_rounded),
                  color: const Color(0xFF9AA5B6),
                  tooltip: 'Remove',
                ),
              ],
            ),
          );
        }),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _section(
          title: 'Address',
          children: <Widget>[
            TextField(
              controller: ctrl.address1Controller,
              decoration: _dec(
                label: 'Street Address *',
                hint: 'Enter street address',
                prefixIcon: const Icon(Icons.location_on_outlined),
              ),
            ),
            SizedBox(height: gap),
            TextField(
              controller: ctrl.cityController,
              decoration: _dec(
                label: 'City *',
                hint: 'Enter city',
                prefixIcon: const Icon(Icons.location_city_outlined),
              ),
            ),
            SizedBox(height: gap),
            TextField(
              controller: ctrl.districtController,
              decoration: _dec(
                label: 'District/Province *',
                hint: 'Enter district/province',
                prefixIcon: const Icon(Icons.map_outlined),
              ),
            ),
            SizedBox(height: gap),
            TextField(
              controller: ctrl.zipController,
              decoration: _dec(
                label: 'Postal Code *',
                hint: 'Enter postal code',
                prefixIcon: const Icon(Icons.markunread_mailbox_outlined),
              ),
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: gap),
            TextField(
              controller: ctrl.countryController,
              decoration: _dec(
                label: 'Country *',
                hint: 'Saudi Arabia',
                prefixIcon: const Icon(Icons.flag_outlined),
              ),
            ),
            SizedBox(height: gap),
            Row(
              children: <Widget>[
                Expanded(
                  child: TextField(
                    controller: ctrl.buildingNumberController,
                    decoration: _dec(
                      label: 'Building Number',
                      hint: 'Building number',
                      prefixIcon: const Icon(Icons.apartment_outlined),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: ctrl.additionalNumberController,
                    decoration: _dec(
                      label: 'Additional Number',
                      hint: 'Additional number',
                      prefixIcon:
                          const Icon(Icons.confirmation_number_outlined),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        SizedBox(height: gap),
        _section(
          title: 'Contact Persons',
          children: <Widget>[contactList()],
        ),
      ],
    );
  }
}
