import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../controllers/create_customer_controller.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_responsive.dart';
import '../../../models/customer.dart';
import 'add_customer_steps/address_customer_step.dart';
import 'add_customer_steps/banking_customer_step.dart';
import 'add_customer_steps/basic_customer_step.dart';

class AddCustomerScreen extends StatefulWidget {
  const AddCustomerScreen({super.key});

  @override
  State<AddCustomerScreen> createState() => _AddCustomerScreenState();
}

class _AddCustomerScreenState extends State<AddCustomerScreen> {
  void _onBackPressed() {
    final CreateCustomerController ctrl = context.read<CreateCustomerController>();
    if (ctrl.currentStep == 0) {
      Navigator.of(context).pop();
      return;
    }
    ctrl.prevStep();
  }

  Future<void> _save() async {
    final CreateCustomerController ctrl = context.read<CreateCustomerController>();
    final Customer? created = await ctrl.submit();
    if (!mounted) return;
    if (created != null) {
      Navigator.of(context).pop(true);
      return;
    }
    final String msg = (ctrl.errorMessage ?? '').trim();
    if (msg.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  Widget _stepTab({
    required BoxConstraints constraints,
    required int index,
    required IconData icon,
    required String label,
    required bool selected,
    required bool enabled,
    required VoidCallback onTap,
  }) {
    final double iconSize = AppResponsive.clamp(
      AppResponsive.sp(constraints, 18),
      16,
      20,
    );

    final Color fg = selected ? AppColors.primary : const Color(0xFF9AA5B6);

    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: 86,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(icon, size: iconSize, color: fg),
            const SizedBox(height: 6),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: fg,
                fontWeight: FontWeight.w800,
                fontSize: 11,
              ),
            ),
            const SizedBox(height: 8),
            AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              height: 2.5,
              width: selected ? 46 : 0,
              decoration: BoxDecoration(
                color: selected ? AppColors.primary : Colors.transparent,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _next() {
    final CreateCustomerController ctrl = context.read<CreateCustomerController>();
    final bool ok = ctrl.nextStep();
    if (!ok) {
      final String msg = (ctrl.errorMessage ?? '').trim();
      if (msg.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please complete required fields')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final CreateCustomerController ctrl =
            context.watch<CreateCustomerController>();

        final double hPad = AppResponsive.clamp(
          AppResponsive.vw(constraints, 5.5),
          16,
          22,
        );

        final double gap = AppResponsive.clamp(
          AppResponsive.scaledByHeight(constraints, 14),
          12,
          18,
        );

        final int step = ctrl.currentStep + 1;
        final int totalSteps = 3;
        final double progress = step / totalSteps;
        final int percent = (progress * 100).round();

        Widget content() {
          switch (ctrl.currentStep) {
            case 0:
              return BasicCustomerStep(constraints: constraints);
            case 1:
              return AddressCustomerStep(constraints: constraints);
            case 2:
              return BankingCustomerStep(constraints: constraints);
            default:
              return const SizedBox.shrink();
          }
        }

        return Scaffold(
          backgroundColor: const Color(0xFFF7FAFF),
          appBar: AppBar(
            title: const Text('Add Customer'),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: _onBackPressed,
            ),
          ),
          body: SafeArea(
            child: Padding(
              padding: EdgeInsets.fromLTRB(hPad, gap, hPad, 0),
              child: Column(
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          'Step $step of $totalSteps',
                          style: const TextStyle(
                            color: Color(0xFF0B1B4B),
                            fontWeight: FontWeight.w900,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      Text(
                        '$percent%',
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w900,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 6,
                      backgroundColor: const Color(0xFFE9EEF5),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: <Widget>[
                        _stepTab(
                          constraints: constraints,
                          index: 0,
                          icon: Icons.info_outline,
                          label: 'Basic',
                          selected: ctrl.currentStep == 0,
                          enabled: 0 <= ctrl.maxStepReached,
                          onTap: () => ctrl.goToStep(0),
                        ),
                        _stepTab(
                          constraints: constraints,
                          index: 1,
                          icon: Icons.location_on_outlined,
                          label: 'Address',
                          selected: ctrl.currentStep == 1,
                          enabled: 1 <= ctrl.maxStepReached,
                          onTap: () => ctrl.goToStep(1),
                        ),
                        _stepTab(
                          constraints: constraints,
                          index: 2,
                          icon: Icons.account_balance_outlined,
                          label: 'Banking',
                          selected: ctrl.currentStep == 2,
                          enabled: 2 <= ctrl.maxStepReached,
                          onTap: () => ctrl.goToStep(2),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: gap),
                  Expanded(
                    child: ListView(
                      padding: EdgeInsets.only(bottom: gap),
                      children: <Widget>[content()],
                    ),
                  ),
                ],
              ),
            ),
          ),
          bottomNavigationBar: SafeArea(
            top: false,
            child: Padding(
              padding: EdgeInsets.fromLTRB(hPad, 10, hPad, 10),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: OutlinedButton(
                      onPressed: ctrl.isSubmitting ? null : _save,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF0B1B4B),
                        side: const BorderSide(color: Color(0xFFE9EEF5)),
                        backgroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        textStyle: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                      child: const Text('Save'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed:
                          ctrl.isSubmitting ? null : (ctrl.currentStep == 2 ? _save : _next),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        textStyle: const TextStyle(fontWeight: FontWeight.w900),
                        elevation: 0,
                      ),
                      child: ctrl.isSubmitting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.2,
                                color: Colors.white,
                              ),
                            )
                          : Text(ctrl.currentStep == 2 ? 'Save Customer' : 'Next'),
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
