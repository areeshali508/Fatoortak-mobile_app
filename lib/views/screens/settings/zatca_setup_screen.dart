import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../controllers/auth_controller.dart';
import '../../../controllers/zatca_controller.dart';
import '../../../core/constants/app_colors.dart';

class ZatcaSetupScreen extends StatefulWidget {
  const ZatcaSetupScreen({super.key});

  @override
  State<ZatcaSetupScreen> createState() => _ZatcaSetupScreenState();
}

class _ZatcaSetupScreenState extends State<ZatcaSetupScreen> {
  bool _requestedInitial = false;

  final TextEditingController _commonNameCtrl = TextEditingController();
  final TextEditingController _orgIdCtrl = TextEditingController();

  String? _companyId() {
    final Map<String, dynamic>? company = context.read<AuthController>().myCompany;
    final String? id = (company?['_id'] ?? company?['id'])?.toString().trim();
    if (id == null || id.isEmpty) return null;
    return id;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_requestedInitial) return;
    _requestedInitial = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final String? companyId = _companyId();
      if (companyId == null) return;
      await context.read<ZatcaController>().loadStatus(companyId: companyId);
    });
  }

  Future<void> _run(Future<void> Function() action) async {
    final NavigatorState nav = Navigator.of(context);
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    final ZatcaController ctrl = context.read<ZatcaController>();
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
    try {
      await action();
    } finally {
      if (nav.mounted) {
        nav.pop();
      }
    }

    if (!mounted) return;
    final String? err = ctrl.errorMessage;
    if (err != null && err.trim().isNotEmpty) {
      messenger.showSnackBar(SnackBar(content: Text(err)));
      return;
    }

    final Map<String, dynamic>? last = ctrl.lastResult;
    if (last != null) {
      messenger.showSnackBar(
        const SnackBar(content: Text('ZATCA step completed successfully')),
      );
    }
  }

  String _pretty(Object? obj) {
    if (obj == null) return '';
    try {
      return const JsonEncoder.withIndent('  ').convert(obj);
    } catch (_) {
      return obj.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    final ZatcaController ctrl = context.watch<ZatcaController>();
    final String? companyId = _companyId();

    return Scaffold(
      backgroundColor: const Color(0xFFF7FAFF),
      appBar: AppBar(title: const Text('ZATCA Setup')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE9EEF5)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                const Text(
                  'Onboarding Status',
                  style: TextStyle(
                    color: Color(0xFF0B1B4B),
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  companyId == null
                      ? 'Company not loaded'
                      : (_pretty(ctrl.status).trim().isEmpty
                            ? '-'
                            : _pretty(ctrl.status)),
                  style: const TextStyle(
                    color: Color(0xFF6B7895),
                    fontWeight: FontWeight.w700,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 10),
                OutlinedButton(
                  onPressed: companyId == null
                      ? null
                      : () => _run(() => ctrl.loadStatus(companyId: companyId)),
                  child: const Text('Refresh Status'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE9EEF5)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                const Text(
                  'CSR Details',
                  style: TextStyle(
                    color: Color(0xFF0B1B4B),
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _commonNameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'CommonName',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _orgIdCtrl,
                  decoration: const InputDecoration(
                    labelText: 'OrganizationIdentifier',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: companyId == null
                ? null
                : () => _run(
                      () => ctrl.generateCsr(
                        companyId: companyId,
                        commonName: _commonNameCtrl.text,
                        organizationIdentifier: _orgIdCtrl.text,
                      ),
                    ),
            child: const Text('Generate CSR'),
          ),
          const SizedBox(height: 10),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: companyId == null
                ? null
                : () => _run(() => ctrl.getComplianceCert(companyId: companyId)),
            child: const Text('Get Compliance Certificate'),
          ),
          const SizedBox(height: 10),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: companyId == null
                ? null
                : () => _run(() => ctrl.getProductionCsid(companyId: companyId)),
            child: const Text('Get Production CSID'),
          ),
          const SizedBox(height: 14),
          if ((ctrl.lastResult ?? const <String, dynamic>{}).isNotEmpty)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE9EEF5)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  const Text(
                    'Last Response',
                    style: TextStyle(
                      color: Color(0xFF0B1B4B),
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _pretty(ctrl.lastResult),
                    style: const TextStyle(
                      color: Color(0xFF0B1B4B),
                      fontWeight: FontWeight.w700,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _commonNameCtrl.dispose();
    _orgIdCtrl.dispose();
    super.dispose();
  }
}
