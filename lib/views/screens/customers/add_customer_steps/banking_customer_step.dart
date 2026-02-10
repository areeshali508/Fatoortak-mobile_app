import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../controllers/create_customer_controller.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_responsive.dart';

class BankingCustomerStep extends StatelessWidget {
  final BoxConstraints constraints;

  const BankingCustomerStep({super.key, required this.constraints});

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

  @override
  Widget build(BuildContext context) {
    final CreateCustomerController ctrl =
        context.watch<CreateCustomerController>();

    final double gap = AppResponsive.clamp(
      AppResponsive.scaledByHeight(constraints, 14),
      10,
      16,
    );

    Future<void> pickFromList({
      required BuildContext sheetContext,
      required String title,
      required List<String> options,
      required ValueChanged<String> onPick,
    }) async {
      await showModalBottomSheet<void>(
        context: sheetContext,
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
                          onPick(options[i]);
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

    Future<void> openAddBankAccount() async {
      final TextEditingController bankNameCtrl = TextEditingController();
      final TextEditingController accountCtrl = TextEditingController();
      final TextEditingController accountTypeCtrl = TextEditingController(
        text: 'Checking Account',
      );
      final TextEditingController ibanCtrl = TextEditingController();
      final TextEditingController swiftCtrl = TextEditingController();
      final TextEditingController currencyCtrl = TextEditingController(
        text: 'Saudi Riyal (SAR)',
      );
      bool isPrimary = ctrl.bankAccounts.isEmpty;

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
                    'Add Bank Account',
                    style: TextStyle(
                      color: Color(0xFF0B1B4B),
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: bankNameCtrl,
                    readOnly: true,
                    decoration: _dec(
                      label: 'Bank Name *',
                      hint: 'Select Bank',
                      prefixIcon: const Icon(Icons.account_balance_outlined),
                    ).copyWith(
                      suffixIcon:
                          const Icon(Icons.keyboard_arrow_down_rounded),
                    ),
                    onTap: () {
                      FocusScope.of(context).unfocus();
                      pickFromList(
                        sheetContext: context,
                        title: 'Select Bank',
                        options: const <String>[
                          'Al Rajhi Bank',
                          'SNB (National Bank)',
                          'Riyad Bank',
                          'SABB',
                          'SAIB',
                          'Other',
                        ],
                        onPick: (String v) => bankNameCtrl.text = v,
                      );
                    },
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: accountCtrl,
                    decoration: _dec(
                      label: 'Account Number *',
                      hint: 'Enter account number',
                      prefixIcon: const Icon(Icons.numbers_rounded),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: accountTypeCtrl,
                    readOnly: true,
                    decoration: _dec(
                      label: 'Account Type',
                      hint: 'Checking Account',
                      prefixIcon: const Icon(Icons.account_tree_outlined),
                    ).copyWith(
                      suffixIcon:
                          const Icon(Icons.keyboard_arrow_down_rounded),
                    ),
                    onTap: () {
                      FocusScope.of(context).unfocus();
                      pickFromList(
                        sheetContext: context,
                        title: 'Account Type',
                        options: const <String>[
                          'Checking Account',
                          'Savings Account',
                          'Business Account',
                        ],
                        onPick: (String v) => accountTypeCtrl.text = v,
                      );
                    },
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: ibanCtrl,
                    decoration: _dec(
                      label: 'IBAN *',
                      hint: 'SA00 0000 0000 0000 0000 0000',
                      prefixIcon: const Icon(Icons.credit_card_outlined),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: swiftCtrl,
                    decoration: _dec(
                      label: 'SWIFT/BIC Code',
                      hint: 'Enter SWIFT code',
                      prefixIcon: const Icon(Icons.code_rounded),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: currencyCtrl,
                    readOnly: true,
                    decoration: _dec(
                      label: 'Currency',
                      hint: 'Saudi Riyal (SAR)',
                      prefixIcon: const Icon(Icons.currency_exchange_outlined),
                    ).copyWith(
                      suffixIcon:
                          const Icon(Icons.keyboard_arrow_down_rounded),
                    ),
                    onTap: () {
                      FocusScope.of(context).unfocus();
                      pickFromList(
                        sheetContext: context,
                        title: 'Currency',
                        options: const <String>[
                          'Saudi Riyal (SAR)',
                          'US Dollar (USD)',
                          'Euro (EUR)',
                        ],
                        onPick: (String v) => currencyCtrl.text = v,
                      );
                    },
                  ),
                  const SizedBox(height: 6),
                  StatefulBuilder(
                    builder: (BuildContext context,
                        void Function(void Function()) setState) {
                      return SwitchListTile.adaptive(
                        contentPadding: EdgeInsets.zero,
                        value: isPrimary,
                        onChanged: (bool v) {
                          setState(() {
                            isPrimary = v;
                          });
                        },
                        title: const Text(
                          'Set as Primary Account',
                          style: TextStyle(
                            color: Color(0xFF0B1B4B),
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 14),
                  ElevatedButton(
                    onPressed: () {
                      final String bank = bankNameCtrl.text.trim();
                      final String iban = ibanCtrl.text.trim();
                      final String acc = accountCtrl.text.trim();
                      final String accType = accountTypeCtrl.text.trim();
                      final String swift = swiftCtrl.text.trim();
                      final String currency = currencyCtrl.text.trim();
                      if (bank.isEmpty && iban.isEmpty && acc.isEmpty) {
                        Navigator.of(ctx).pop();
                        return;
                      }
                      context.read<CreateCustomerController>().addBankAccount(
                            CustomerBankAccount(
                              bankName: bank,
                              iban: iban,
                              accountNumber: acc,
                              accountType: accType.isEmpty
                                  ? 'Checking Account'
                                  : accType,
                              swiftBic: swift,
                              currency: currency.isEmpty
                                  ? 'Saudi Riyal (SAR)'
                                  : currency,
                              isPrimary: isPrimary,
                            ),
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

      bankNameCtrl.dispose();
      accountCtrl.dispose();
      accountTypeCtrl.dispose();
      ibanCtrl.dispose();
      swiftCtrl.dispose();
      currencyCtrl.dispose();
    }

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
                if (action == 'Add Bank Account') {
                  openAddBankAccount();
                }
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

    Widget bankAccountList() {
      if (ctrl.bankAccounts.isEmpty) {
        return emptyBox(
          title: 'No bank accounts added yet.',
          subtitle: 'Click "Add Bank Account" to get started.',
          action: 'Add Bank Account',
        );
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          ElevatedButton(
            onPressed: () {
              FocusScope.of(context).unfocus();
              openAddBankAccount();
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
            child: const Text('Add Bank Account'),
          ),
          const SizedBox(height: 12),
          ...List<Widget>.generate(ctrl.bankAccounts.length, (int i) {
            final CustomerBankAccount a = ctrl.bankAccounts[i];
            final String t = a.bankName.trim().isNotEmpty
                ? a.bankName.trim()
                : 'Bank Account ${i + 1}';
            final String title = a.isPrimary ? '$t  Primary' : t;
            final String line2 = <String>[a.iban.trim(), a.accountNumber.trim()]
                .where((String s) => s.isNotEmpty)
                .join(' • ');

            return Container(
              margin: EdgeInsets.only(
                bottom: i == ctrl.bankAccounts.length - 1 ? 0 : 10,
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
                          title,
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
                        .removeBankAccountAt(i),
                    icon: const Icon(Icons.delete_outline_rounded),
                    color: const Color(0xFF9AA5B6),
                    tooltip: 'Remove',
                  ),
                ],
              ),
            );
          }),
        ],
      );
    }

    Widget moneyField({
      required String label,
      required TextEditingController controller,
      required String helper,
    }) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          TextField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: _dec(
              label: label,
              hint: '0.00',
              prefixIcon: const Icon(Icons.payments_outlined),
            ).copyWith(
              prefixIcon: const Padding(
                padding: EdgeInsets.only(left: 14, right: 10),
                child: Text(
                  'SAR',
                  style: TextStyle(
                    color: Color(0xFF6B7895),
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              prefixIconConstraints:
                  const BoxConstraints(minWidth: 0, minHeight: 0),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            helper,
            style: const TextStyle(
              color: Color(0xFF9AA5B6),
              fontWeight: FontWeight.w700,
              fontSize: 11,
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _section(
          title: 'Banking Information',
          children: <Widget>[bankAccountList()],
        ),
        SizedBox(height: gap),
        _section(
          title: 'Payment Limits',
          children: <Widget>[
            moneyField(
              label: 'Daily Limit',
              controller: ctrl.dailyLimitController,
              helper: 'Maximum daily transaction amount',
            ),
            SizedBox(height: gap),
            moneyField(
              label: 'Monthly Limit',
              controller: ctrl.monthlyLimitController,
              helper: 'Maximum monthly transaction amount',
            ),
            SizedBox(height: gap),
            moneyField(
              label: 'Per Transaction Limit',
              controller: ctrl.perTransactionLimitController,
              helper: 'Maximum single transaction amount',
            ),
            const SizedBox(height: 10),
            const Text(
              'These limits help control risk and prevent unauthorized large transactions. Leave empty for no limits.',
              style: TextStyle(
                color: Color(0xFF9AA5B6),
                fontWeight: FontWeight.w700,
                fontSize: 11,
              ),
            ),
          ],
        ),
        SizedBox(height: gap),
        _section(
          title: 'Compliance Information',
          children: <Widget>[
            TextField(
              readOnly: true,
              decoration: _dec(
                label: 'Risk Rating *',
                hint: ctrl.riskRating,
              ).copyWith(
                suffixIcon: const Icon(Icons.keyboard_arrow_down_rounded),
              ),
              onTap: () {
                FocusScope.of(context).unfocus();
                pickFromList(
                  sheetContext: context,
                  title: 'Risk Rating',
                  options: const <String>[
                    'Low Risk',
                    'Medium Risk',
                    'High Risk',
                  ],
                  onPick: context.read<CreateCustomerController>().setRiskRating,
                );
              },
            ),
            SizedBox(height: gap),
            TextField(
              readOnly: true,
              decoration: _dec(
                label: 'Status *',
                hint: ctrl.status,
              ).copyWith(
                suffixIcon: const Icon(Icons.keyboard_arrow_down_rounded),
              ),
              onTap: () {
                FocusScope.of(context).unfocus();
                pickFromList(
                  sheetContext: context,
                  title: 'Status',
                  options: const <String>[
                    'Active',
                    'Inactive',
                    'Suspended',
                  ],
                  onPick: context.read<CreateCustomerController>().setStatus,
                );
              },
            ),
            SizedBox(height: gap),
            TextField(
              readOnly: true,
              decoration: _dec(
                label: 'Verification Status',
                hint: ctrl.verificationStatus,
              ).copyWith(
                suffixIcon: const Icon(Icons.keyboard_arrow_down_rounded),
              ),
              onTap: () {
                FocusScope.of(context).unfocus();
                pickFromList(
                  sheetContext: context,
                  title: 'Verification Status',
                  options: const <String>[
                    'Pending',
                    'Verified',
                    'Rejected',
                  ],
                  onPick:
                      context.read<CreateCustomerController>().setVerificationStatus,
                );
              },
            ),
            SizedBox(height: gap),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              value: ctrl.sanctionScreened,
              onChanged: (bool v) => context
                  .read<CreateCustomerController>()
                  .setSanctionScreened(v),
              title: const Text(
                'Sanction Screened',
                style: TextStyle(
                  color: Color(0xFF0B1B4B),
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Compliance information is used for risk assessment and regulatory reporting.',
              style: TextStyle(
                color: Color(0xFF9AA5B6),
                fontWeight: FontWeight.w700,
                fontSize: 11,
              ),
            ),
          ],
        ),
        SizedBox(height: gap),
        _section(
          title: 'Customer Settings',
          children: <Widget>[
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              value: ctrl.accountActive,
              onChanged: (bool v) =>
                  context.read<CreateCustomerController>().setAccountActive(v),
              title: const Text(
                'Active Customer Account',
                style: TextStyle(
                  color: Color(0xFF0B1B4B),
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              ),
              subtitle: const Text(
                'Customer account is active and can receive invoices',
                style: TextStyle(
                  color: Color(0xFF9AA5B6),
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: gap),
        _section(
          title: 'Privacy & Consent',
          children: <Widget>[
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              value: ctrl.consentToProcessing,
              onChanged: (bool v) => context
                  .read<CreateCustomerController>()
                  .setConsentToProcessing(v),
              title: const Text(
                'Consent to data processing for business purposes',
                style: TextStyle(
                  color: Color(0xFF0B1B4B),
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              ),
            ),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: ctrl.acceptTermsOfService,
              onChanged: (bool? v) => context
                  .read<CreateCustomerController>()
                  .setAcceptTermsOfService(v ?? false),
              title: const Text(
                'Accept Terms of Service *',
                style: TextStyle(
                  color: Color(0xFF0B1B4B),
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              ),
              controlAffinity: ListTileControlAffinity.leading,
            ),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: ctrl.acceptPrivacyPolicy,
              onChanged: (bool? v) => context
                  .read<CreateCustomerController>()
                  .setAcceptPrivacyPolicy(v ?? false),
              title: const Text(
                'Accept Privacy Policy *',
                style: TextStyle(
                  color: Color(0xFF0B1B4B),
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              ),
              controlAffinity: ListTileControlAffinity.leading,
            ),
          ],
        ),
        SizedBox(height: gap),
        _section(
          title: 'Documents Upload',
          children: <Widget>[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF7FAFF),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE9EEF5)),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Text(
                    'Drop files here or click to browse',
                    style: TextStyle(
                      color: Color(0xFF0B1B4B),
                      fontWeight: FontWeight.w900,
                      fontSize: 13,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Supported formats: PDF, JPG, PNG, DOC, DOCX (Max 10MB each)',
                    style: TextStyle(
                      color: Color(0xFF9AA5B6),
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'No file chosen',
                    style: TextStyle(
                      color: Color(0xFF9AA5B6),
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Required Documents\n• Commercial Registration\n• VAT Certificate\n• Tax Registration\n\nBanking Documents\n• Bank Account Statement\n• IBAN Certificate\n\nOptional Documents\n• Company Profile\n• Authorization Letter\n• Other Certificates',
              style: TextStyle(
                color: Color(0xFF6B7895),
                fontWeight: FontWeight.w700,
                fontSize: 11,
                height: 1.4,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
