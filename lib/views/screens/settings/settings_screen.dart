import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/app_routes.dart';
import '../../../controllers/auth_controller.dart';
import '../../../controllers/settings_controller.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_responsive.dart';
import '../../widgets/common/app_splash_logo.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _RecentActivityItem {
  final String title;
  final String time;
  final IconData icon;

  const _RecentActivityItem(this.title, this.time, this.icon);
}

class _RecentActivityTile extends StatelessWidget {
  final _RecentActivityItem item;
  final bool showDivider;

  const _RecentActivityTile({required this.item, required this.showDivider});

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
            child: Icon(item.icon, color: const Color(0xFF0B1B4B), size: 20),
          ),
          title: Text(
            item.title,
            style: const TextStyle(
              color: Color(0xFF0B1B4B),
              fontWeight: FontWeight.w800,
              fontSize: 14,
            ),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              item.time,
              style: const TextStyle(
                color: Color(0xFF6B7895),
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
        ),
        if (showDivider)
          const Divider(height: 1, thickness: 1, color: Color(0xFFE9EEF5)),
      ],
    );
  }
}

class _SettingsScreenState extends State<SettingsScreen> {
  void _openProfile(BuildContext context) {
    Navigator.of(context).pushNamed(AppRoutes.profileSettings);
  }

  void _openSubscription(BuildContext context) {
    Navigator.of(context).pushNamed(AppRoutes.subscription);
  }

  void _openCompanyInfo(BuildContext context) {
    Navigator.of(context).pushNamed(AppRoutes.companyInfo);
  }

  final List<_RecentActivityItem> _recentActivity = const <_RecentActivityItem>[
    _RecentActivityItem(
      'Logged in from new device',
      '30 minutes ago',
      Icons.login,
    ),
    _RecentActivityItem(
      'Created invoice INV-2024-001234',
      '1 hour ago',
      Icons.receipt_long_outlined,
    ),
    _RecentActivityItem(
      'Updated user permissions for John Doe',
      '2 hours ago',
      Icons.admin_panel_settings_outlined,
    ),
    _RecentActivityItem(
      'Added new customer: ABC Trading Co.',
      '4 hours ago',
      Icons.person_add_alt_1_outlined,
    ),
    _RecentActivityItem(
      'Generated monthly sales report',
      '6 hours ago',
      Icons.bar_chart_outlined,
    ),
    _RecentActivityItem(
      'Updated payment method settings',
      '8 hours ago',
      Icons.payment_outlined,
    ),
    _RecentActivityItem(
      'Created new role: Accountant',
      '12 hours ago',
      Icons.badge_outlined,
    ),
    _RecentActivityItem(
      'Approved invoice INV-2024-001233',
      '1 day ago',
      Icons.verified_outlined,
    ),
    _RecentActivityItem(
      'Exported customer list',
      '1 day ago',
      Icons.download_outlined,
    ),
    _RecentActivityItem(
      'Updated company profile information',
      '2 days ago',
      Icons.apartment_outlined,
    ),
    _RecentActivityItem(
      'Deleted product: Old Service Package',
      '2 days ago',
      Icons.delete_outline,
    ),
    _RecentActivityItem(
      'Created backup of customer data',
      '3 days ago',
      Icons.backup_outlined,
    ),
    _RecentActivityItem(
      'Updated tax settings',
      '3 days ago',
      Icons.receipt_outlined,
    ),
    _RecentActivityItem(
      'Logged in from mobile app',
      '4 days ago',
      Icons.phone_android_outlined,
    ),
    _RecentActivityItem(
      'Generated quarterly report',
      '5 days ago',
      Icons.insert_chart_outlined,
    ),
  ];

  int _recentVisibleCount = 5;

  void _loadMoreRecent() {
    setState(() {
      _recentVisibleCount = (_recentVisibleCount + 5).clamp(0, _recentActivity.length);
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final SettingsController settingsCtrl = context
            .watch<SettingsController>();
        final Map<String, dynamic>? company = context.watch<AuthController>().myCompany;
        final Object? creds = company?['zatcaCredentials'];
        final String zatcaStatus = (creds is Map<String, dynamic>
                ? creds['status']?.toString()
                : null)
            ?.trim() ??
            '';
        final String companyName =
            (company?['companyName'] ?? company?['name'])?.toString().trim() ?? '';
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
            title: const Text('Settings'),
            leading: const BackButton(),
          ),
          body: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              hPad,
              sectionGap,
              hPad,
              AppResponsive.clamp(
                AppResponsive.scaledByHeight(constraints, 22),
                16,
                28,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                _ProfileCard(constraints: constraints, radius: cardRadius),
                SizedBox(height: sectionGap),
                const _SectionHeader('ACCOUNT'),
                _SectionCard(
                  radius: cardRadius,
                  children: <Widget>[
                    _SettingsTile(
                      icon: Icons.person_outline,
                      title: 'Profile Settings',
                      onTap: () => _openProfile(context),
                    ),
                    _SettingsTile(
                      icon: Icons.workspace_premium_outlined,
                      title: 'Subscription',
                      onTap: () => _openSubscription(context),
                    ),
                    _SettingsTile(
                      icon: Icons.settings_outlined,
                      title: 'System Settings',
                      onTap: () => Navigator.of(context).pushNamed(
                        AppRoutes.systemSettings,
                      ),
                    ),
                    _SettingsTile(
                      icon: Icons.lock_outline,
                      title: 'Change Password',
                      onTap: () {},
                    ),
                    _SettingsTile(
                      icon: Icons.shield_outlined,
                      title: 'Security',
                      onTap: () {},
                    ),
                  ],
                ),
                SizedBox(height: sectionGap),
                const _SectionHeader('BUSINESS'),
                _SectionCard(
                  radius: cardRadius,
                  children: <Widget>[
                    _SettingsTile(
                      icon: Icons.apartment_outlined,
                      title: 'Company',
                      trailingText: companyName.isEmpty ? 'Not set' : companyName,
                      showChevron: false,
                      onTap: () {},
                    ),
                    _SettingsTile(
                      icon: Icons.storefront_outlined,
                      title: 'Company Info',
                      onTap: () => _openCompanyInfo(context),
                    ),
                    _SettingsTile(
                      icon: Icons.verified_outlined,
                      title: 'ZATCA Setup',
                      trailingText: zatcaStatus.isEmpty ? 'Not started' : zatcaStatus,
                      onTap: () => Navigator.of(context).pushNamed(
                        AppRoutes.zatcaSetup,
                      ),
                    ),
                    _SettingsTile(
                      icon: Icons.receipt_long_outlined,
                      title: 'Tax Settings',
                      onTap: () {},
                    ),
                    _SettingsTile(
                      icon: Icons.currency_exchange,
                      title: 'Currency',
                      trailingText: 'SAR',
                      onTap: () {},
                    ),
                  ],
                ),
                SizedBox(height: sectionGap),
                const _SectionHeader('NOTIFICATIONS'),
                _SectionCard(
                  radius: cardRadius,
                  children: <Widget>[
                    _SettingsSwitchTile(
                      icon: Icons.notifications_outlined,
                      title: 'Push Notifications',
                      value: settingsCtrl.pushNotifications,
                      onChanged: (bool v) => context
                          .read<SettingsController>()
                          .setPushNotifications(v),
                    ),
                  ],
                ),
                SizedBox(height: sectionGap),
                const _SectionHeader('APP PREFERENCES'),
                _SectionCard(
                  radius: cardRadius,
                  children: <Widget>[
                    _SettingsTile(
                      icon: Icons.language_outlined,
                      title: 'Language',
                      trailingText: 'English',
                      onTap: () {},
                    ),
                    _SettingsTile(
                      icon: Icons.dark_mode_outlined,
                      title: 'Theme',
                      trailingText: 'Light',
                      onTap: () {},
                    ),
                  ],
                ),
                SizedBox(height: sectionGap),
                const _SectionHeader('Recent Activity'),
                _SectionCard(
                  radius: cardRadius,
                  children: <Widget>[
                    for (int i = 0; i < _recentVisibleCount; i++)
                      _RecentActivityTile(
                        item: _recentActivity[i],
                        showDivider: i != _recentVisibleCount - 1,
                      ),
                  ],
                ),
                if (_recentVisibleCount < _recentActivity.length) ...<Widget>[
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: _loadMoreRecent,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF0B1B4B),
                      side: const BorderSide(color: Color(0xFFE9EEF5)),
                      backgroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      textStyle: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                    child: const Text('Load More Activity'),
                  ),
                ],
                SizedBox(height: sectionGap),
                const _SectionHeader('SUPPORT'),
                _SectionCard(
                  radius: cardRadius,
                  children: <Widget>[
                    _SettingsTile(
                      icon: Icons.help_outline,
                      title: 'Help Center',
                      onTap: () {},
                    ),
                    _SettingsTile(
                      icon: Icons.description_outlined,
                      title: 'Terms & Privacy',
                      onTap: () {},
                    ),
                  ],
                ),
                SizedBox(height: sectionGap),
                _SectionCard(
                  radius: cardRadius,
                  children: <Widget>[
                    _SettingsTile(
                      icon: Icons.logout,
                      title: 'Log Out',
                      color: const Color(0xFFD93025),
                      showChevron: false,
                      onTap: () async {
                        await context.read<AuthController>().signOut();
                        if (!context.mounted) return;
                        Navigator.of(
                          context,
                        ).pushReplacementNamed(AppRoutes.login);
                      },
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

class _ProfileCard extends StatelessWidget {
  final BoxConstraints constraints;
  final double radius;

  const _ProfileCard({required this.constraints, required this.radius});

  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic>? profile = context.watch<AuthController>().profile;
    final String firstName = (profile?['firstName'] ?? profile?['first_name'])
            ?.toString()
            .trim() ??
        '';
    final String lastName = (profile?['lastName'] ?? profile?['last_name'])
            ?.toString()
            .trim() ??
        '';
    final String email = (profile?['email'] ?? profile?['username'])
            ?.toString()
            .trim() ??
        '';
    final String displayName = (
      <String>[firstName, lastName].where((String s) => s.trim().isNotEmpty).join(' ')
    ).trim();

    final double logoSize = AppResponsive.clamp(
      AppResponsive.scaledByHeight(constraints, 64),
      54,
      70,
    );

    final double padAll = AppResponsive.clamp(
      AppResponsive.scaledByHeight(constraints, 18),
      14,
      20,
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: DecoratedBox(
        decoration: const BoxDecoration(color: AppColors.splashBottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Padding(
              padding: EdgeInsets.all(padAll),
              child: Column(
                children: <Widget>[
                  Container(
                    width: logoSize + 18,
                    height: logoSize + 18,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFE9EEF5)),
                    ),
                    child: Center(
                      child: AppSplashLogo(
                        size: logoSize,
                        accent: AppColors.splashAccent,
                      ),
                    ),
                  ),
                  SizedBox(
                    height: AppResponsive.clamp(
                      AppResponsive.scaledByHeight(constraints, 14),
                      10,
                      18,
                    ),
                  ),
                  Text(
                    displayName.isEmpty ? 'Profile' : displayName,
                    style: TextStyle(
                      fontSize: AppResponsive.clamp(
                        AppResponsive.sp(constraints, 18),
                        16,
                        20,
                      ),
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(
                    height: AppResponsive.clamp(
                      AppResponsive.scaledByHeight(constraints, 6),
                      4,
                      10,
                    ),
                  ),
                  Text(
                    email.isEmpty ? 'Not set' : email,
                    style: TextStyle(
                      fontSize: AppResponsive.clamp(
                        AppResponsive.sp(constraints, 12),
                        11,
                        13,
                      ),
                      color: Colors.white.withValues(alpha: 0.80),
                    ),
                  ),
                  SizedBox(
                    height: AppResponsive.clamp(
                      AppResponsive.scaledByHeight(constraints, 14),
                      10,
                      18,
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pushNamed(
                      AppRoutes.profileSettings,
                    ),
                    child: const Text(
                      'Edit Profile',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String text;

  const _SectionHeader(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          color: Color(0xFF9AA5B6),
          fontSize: 12,
          letterSpacing: 1.2,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final List<Widget> children;
  final double radius;

  const _SectionCard({required this.children, required this.radius});

  @override
  Widget build(BuildContext context) {
    final List<Widget> items = <Widget>[];
    for (int i = 0; i < children.length; i++) {
      items.add(children[i]);
      if (i != children.length - 1) {
        items.add(
          const Divider(height: 1, thickness: 1, color: Color(0xFFE9EEF5)),
        );
      }
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(radius),
      ),
      child: Column(children: items),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? trailingText;
  final Color? color;
  final bool showChevron;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.onTap,
    this.trailingText,
    this.color,
    this.showChevron = true,
  });

  @override
  Widget build(BuildContext context) {
    final Color baseColor = color ?? const Color(0xFF0B1B4B);

    return ListTile(
      onTap: onTap,
      leading: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: const Color(0xFFF3F6FB),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: baseColor, size: 20),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: baseColor,
          fontWeight: FontWeight.w700,
          fontSize: 14,
        ),
      ),
      trailing: trailingText == null
          ? (showChevron
                ? const Icon(Icons.chevron_right, color: Color(0xFF9AA5B6))
                : null)
          : ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 160),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Flexible(
                    child: Text(
                      trailingText!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF6B7895),
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Icon(Icons.chevron_right, color: Color(0xFF9AA5B6)),
                ],
              ),
            ),
    );
  }
}

class _SettingsSwitchTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SettingsSwitchTile({
    required this.icon,
    required this.title,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
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
          fontWeight: FontWeight.w700,
          fontSize: 14,
        ),
      ),
      trailing: Switch.adaptive(
        value: value,
        onChanged: onChanged,
        activeTrackColor: AppColors.primary,
        activeThumbColor: Colors.white,
      ),
    );
  }
}
