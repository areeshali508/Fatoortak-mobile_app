import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../controllers/system_settings_controller.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_responsive.dart';

class SystemSettingsScreen extends StatefulWidget {
  const SystemSettingsScreen({super.key});

  @override
  State<SystemSettingsScreen> createState() => _SystemSettingsScreenState();
}

class _SystemSettingsScreenState extends State<SystemSettingsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SystemSettingsController>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final SystemSettingsController ctrl = context.watch<SystemSettingsController>();

        final double hPad = AppResponsive.clamp(
          AppResponsive.vw(constraints, 6),
          16,
          22,
        );

        final double sectionGap = AppResponsive.clamp(
          AppResponsive.scaledByHeight(constraints, 16),
          12,
          20,
        );

        final double cardRadius = AppResponsive.clamp(
          AppResponsive.scaledByHeight(constraints, 18),
          14,
          20,
        );

        return Scaffold(
          backgroundColor: const Color(0xFFF7FAFF),
          appBar: AppBar(
            title: const Text('System Settings'),
            leading: const BackButton(),
          ),
          body: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(hPad, sectionGap, hPad, sectionGap),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                ClipRRect(
                  borderRadius: BorderRadius.circular(cardRadius),
                  child: DecoratedBox(
                    decoration: const BoxDecoration(color: Colors.white),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          const Text(
                            'Configure your e-invoicing system settings',
                            style: TextStyle(
                              color: Color(0xFF0B1B4B),
                              fontWeight: FontWeight.w900,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton(
                            onPressed: (!ctrl.isDirty || ctrl.isSaving)
                                ? null
                                : () async {
                                    final bool ok = await context
                                        .read<SystemSettingsController>()
                                        .saveAll();
                                    if (!context.mounted) return;
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          ok
                                              ? 'Saved successfully'
                                              : (ctrl.errorMessage ?? 'Save failed'),
                                        ),
                                      ),
                                    );
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              textStyle: const TextStyle(fontWeight: FontWeight.w900),
                            ),
                            child: Text(ctrl.isSaving ? 'Saving...' : 'Save All Changes'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                SizedBox(height: sectionGap),
                const _SectionHeader('Notifications'),
                _SectionCard(
                  radius: cardRadius,
                  children: <Widget>[
                    _SwitchTile(
                      icon: Icons.email_outlined,
                      title: 'Email Notifications',
                      subtitle: 'Receive email notifications for important events',
                      value: ctrl.emailNotifications,
                      onChanged: ctrl.isLoading
                          ? null
                          : (bool v) => context
                              .read<SystemSettingsController>()
                              .setEmailNotifications(v),
                    ),
                    _SwitchTile(
                      icon: Icons.sms_outlined,
                      title: 'Sms Notifications',
                      subtitle: 'Receive SMS notifications for urgent matters',
                      value: ctrl.smsNotifications,
                      onChanged: ctrl.isLoading
                          ? null
                          : (bool v) => context
                              .read<SystemSettingsController>()
                              .setSmsNotifications(v),
                    ),
                    _SwitchTile(
                      icon: Icons.notifications_outlined,
                      title: 'Push Notifications',
                      subtitle: 'Receive browser push notifications',
                      value: ctrl.pushNotifications,
                      onChanged: ctrl.isLoading
                          ? null
                          : (bool v) => context
                              .read<SystemSettingsController>()
                              .setPushNotifications(v),
                    ),
                    _SwitchTile(
                      icon: Icons.warning_amber_outlined,
                      title: 'System Alerts',
                      subtitle: 'Get notified about system updates and maintenance',
                      value: ctrl.systemAlerts,
                      onChanged: ctrl.isLoading
                          ? null
                          : (bool v) => context
                              .read<SystemSettingsController>()
                              .setSystemAlerts(v),
                    ),
                    _SwitchTile(
                      icon: Icons.security_outlined,
                      title: 'Security Alerts',
                      subtitle: 'Critical security notifications (always enabled)',
                      value: true,
                      onChanged: null,
                      locked: true,
                    ),
                    _SwitchTile(
                      icon: Icons.build_outlined,
                      title: 'Maintenance Alerts',
                      subtitle: 'Scheduled maintenance and downtime notices',
                      value: ctrl.maintenanceAlerts,
                      onChanged: ctrl.isLoading
                          ? null
                          : (bool v) => context
                              .read<SystemSettingsController>()
                              .setMaintenanceAlerts(v),
                      showDivider: false,
                    ),
                  ],
                ),
                SizedBox(height: sectionGap),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 0, 2, 10),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          color: Color(0xFF6B7895),
          fontWeight: FontWeight.w900,
          letterSpacing: 1.2,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final double radius;
  final List<Widget> children;

  const _SectionCard({required this.radius, required this.children});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: DecoratedBox(
        decoration: const BoxDecoration(color: Colors.white),
        child: Column(mainAxisSize: MainAxisSize.min, children: children),
      ),
    );
  }
}

class _SwitchTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;
  final bool showDivider;
  final bool locked;

  const _SwitchTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    this.showDivider = true,
    this.locked = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        ListTile(
          leading: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: const Color(0xFFF3F6FB),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: const Color(0xFF0B1B4B), size: 20),
          ),
          title: Text(
            title,
            style: const TextStyle(
              color: Color(0xFF0B1B4B),
              fontWeight: FontWeight.w800,
              fontSize: 14,
            ),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              subtitle,
              style: const TextStyle(
                color: Color(0xFF6B7895),
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
          trailing: Switch.adaptive(
            value: value,
            onChanged: locked ? null : onChanged,
            activeTrackColor: AppColors.primary,
            activeThumbColor: Colors.white,
          ),
        ),
        if (showDivider)
          const Divider(height: 1, thickness: 1, color: Color(0xFFE9EEF5)),
      ],
    );
  }
}
