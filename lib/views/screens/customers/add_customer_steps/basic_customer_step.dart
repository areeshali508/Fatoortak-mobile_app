import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../controllers/create_customer_controller.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_responsive.dart';

class BasicCustomerStep extends StatelessWidget {
  final BoxConstraints constraints;

  const BasicCustomerStep({super.key, required this.constraints});

  InputDecoration _dec({
    required String label,
    String? hint,
    Widget? prefixIcon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
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

  Future<void> _pickFromList(
    BuildContext context, {
    required String title,
    required List<String> options,
    required ValueChanged<String> onSelect,
  }) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: Colors.white,
      builder: (BuildContext ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF0B1B4B),
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                  ),
                ),
              ),
              const Divider(height: 1),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: options.length,
                  separatorBuilder: (BuildContext context, int index) =>
                      const Divider(height: 1),
                  itemBuilder: (BuildContext context, int i) {
                    return ListTile(
                      title: Text(
                        options[i],
                        style: const TextStyle(
                          color: Color(0xFF0B1B4B),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      onTap: () {
                        onSelect(options[i]);
                        Navigator.of(ctx).pop();
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _segmented(BuildContext context) {
    final CreateCustomerController ctrl = context.watch<CreateCustomerController>();

    Widget item({
      required bool selected,
      required String label,
      required IconData icon,
      required VoidCallback onTap,
    }) {
      return Expanded(
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(999),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: selected ? AppColors.primary : Colors.white,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: selected ? Colors.transparent : const Color(0xFFE9EEF5),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Icon(
                  icon,
                  size: 18,
                  color: selected ? Colors.white : const Color(0xFF6B7895),
                ),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    color: selected ? Colors.white : const Color(0xFF6B7895),
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFE9EEF5)),
      ),
      child: Row(
        children: <Widget>[
          item(
            selected: ctrl.isBusiness,
            label: 'Business',
            icon: Icons.business_center_rounded,
            onTap: () => context
                .read<CreateCustomerController>()
                .setCustomerKind(business: true),
          ),
          const SizedBox(width: 8),
          item(
            selected: !ctrl.isBusiness,
            label: 'Individual',
            icon: Icons.person_rounded,
            onTap: () => context
                .read<CreateCustomerController>()
                .setCustomerKind(business: false),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final CreateCustomerController ctrl = context.watch<CreateCustomerController>();

    final double gap = AppResponsive.clamp(
      AppResponsive.scaledByHeight(constraints, 14),
      10,
      16,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _section(
          title: 'Customer Type',
          children: <Widget>[
            _segmented(context),
            const SizedBox(height: 10),
            Text(
              ctrl.isBusiness ? 'Company or organization' : 'Personal account',
              style: const TextStyle(
                color: Color(0xFF9AA5B6),
                fontWeight: FontWeight.w700,
                fontSize: 11,
              ),
            ),
          ],
        ),
        SizedBox(height: gap),
        _section(
          title: 'Basic Information',
          children: <Widget>[
            TextField(
              controller: ctrl.companyNameController,
              decoration: _dec(
                label: ctrl.isBusiness ? 'Company Name *' : 'Full Name *',
                hint: ctrl.isBusiness ? 'Enter company name' : 'Enter full name',
                prefixIcon: Icon(
                  ctrl.isBusiness ? Icons.business_outlined : Icons.person_outline,
                ),
              ),
            ),
            if (ctrl.isBusiness) ...<Widget>[
              SizedBox(height: gap),
              TextField(
                controller: ctrl.crNumberController,
                decoration: _dec(
                  label: 'CR Number',
                  hint: 'Enter CR number',
                  prefixIcon: const Icon(Icons.badge_outlined),
                ),
              ),
            ],
            SizedBox(height: gap),
            TextField(
              controller: ctrl.vatNumberController,
              keyboardType: TextInputType.number,
              decoration: _dec(
                label: 'VAT Number *',
                hint: '300XXXXXXXXXX003',
                prefixIcon: const Icon(Icons.receipt_long_outlined),
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Must be 15 digits',
              style: TextStyle(
                color: Color(0xFF9AA5B6),
                fontWeight: FontWeight.w700,
                fontSize: 11,
              ),
            ),
            SizedBox(height: gap),
            TextField(
              controller: ctrl.taxIdController,
              decoration: _dec(
                label: 'Tax ID',
                hint: 'Tax identification number',
                prefixIcon: const Icon(Icons.description_outlined),
              ),
            ),
            if (ctrl.isBusiness) ...<Widget>[
              SizedBox(height: gap),
              TextField(
                controller: ctrl.industryController,
                readOnly: true,
                decoration: _dec(
                  label: 'Industry',
                  hint: 'Select industry',
                  prefixIcon: const Icon(Icons.category_outlined),
                  suffixIcon: const Icon(Icons.keyboard_arrow_down_rounded),
                ),
                onTap: () {
                  FocusScope.of(context).unfocus();
                  _pickFromList(
                    context,
                    title: 'Select Industry',
                    options: const <String>[
                      'Retail',
                      'Wholesale',
                      'Services',
                      'Manufacturing',
                      'Other',
                    ],
                    onSelect: context.read<CreateCustomerController>().setIndustry,
                  );
                },
              ),
            ],
          ],
        ),
        SizedBox(height: gap),
        _section(
          title: 'Contact & Classification',
          children: <Widget>[
            TextField(
              controller: ctrl.emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: _dec(
                label: 'Email Address *',
                hint: 'email@example.com',
                prefixIcon: const Icon(Icons.mail_outline_rounded),
              ),
            ),
            SizedBox(height: gap),
            TextField(
              controller: ctrl.phoneController,
              keyboardType: TextInputType.phone,
              decoration: _dec(
                label: 'Phone Number *',
                hint: '+966 XX XXX XXXX',
                prefixIcon: const Icon(Icons.phone_outlined),
              ),
            ),
            SizedBox(height: gap),
            TextField(
              controller: ctrl.contactPersonController,
              decoration: _dec(
                label: 'Contact Person',
                hint: 'Primary contact person name',
                prefixIcon: const Icon(Icons.person_outline_rounded),
              ),
            ),
            SizedBox(height: gap),
            TextField(
              controller: ctrl.websiteController,
              keyboardType: TextInputType.url,
              decoration: _dec(
                label: 'Website',
                hint: 'https://www.example.com',
                prefixIcon: const Icon(Icons.language_rounded),
              ),
            ),
            SizedBox(height: gap),
            TextField(
              controller: ctrl.customerGroupController,
              readOnly: true,
              decoration: _dec(
                label: 'Customer Group',
                hint: 'Select group',
                prefixIcon: const Icon(Icons.groups_outlined),
                suffixIcon: const Icon(Icons.keyboard_arrow_down_rounded),
              ),
              onTap: () {
                FocusScope.of(context).unfocus();
                _pickFromList(
                  context,
                  title: 'Select Customer Group',
                  options: const <String>[
                    'Regular',
                    'VIP',
                    'Wholesale',
                    'Government',
                  ],
                  onSelect:
                      context.read<CreateCustomerController>().setCustomerGroup,
                );
              },
            ),
          ],
        ),
      ],
    );
  }
}
