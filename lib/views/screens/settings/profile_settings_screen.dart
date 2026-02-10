import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../controllers/auth_controller.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_responsive.dart';
import '../../widgets/common/app_splash_logo.dart';

class ProfileSettingsScreen extends StatelessWidget {
  const ProfileSettingsScreen({super.key});

  String _pickString(Map<String, dynamic>? m, List<String> keys) {
    if (m == null) return '';
    for (final String k in keys) {
      final Object? v = m[k];
      if (v == null) continue;
      final String s = v.toString().trim();
      if (s.isNotEmpty) return s;
    }
    return '';
  }

  String _pickGender(Map<String, dynamic>? m) {
    final String g = _pickString(m, <String>['gender', 'Gender']);
    if (g.isEmpty) return 'Prefer not to say';
    final String n = g.toLowerCase();
    if (n == 'male') return 'Male';
    if (n == 'female') return 'Female';
    if (n == 'prefer_not_to_say' || n == 'prefer not to say') {
      return 'Prefer not to say';
    }
    return g;
  }

  String _pickDob(Map<String, dynamic>? m) {
    final String raw = _pickString(m, <String>[
      'dateOfBirth',
      'dob',
      'birthDate',
      'birth_date',
    ]);
    if (raw.isEmpty) return 'Not specified';
    final DateTime? dt = DateTime.tryParse(raw);
    if (dt == null) return raw;
    String two(int v) => v.toString().padLeft(2, '0');
    return '${dt.year}-${two(dt.month)}-${two(dt.day)}';
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final Map<String, dynamic>? profile = context.watch<AuthController>().profile;

        final String firstName = _pickString(profile, <String>['firstName', 'first_name', 'firstname']);
        final String lastName = _pickString(profile, <String>['lastName', 'last_name', 'lastname']);
        final String email = _pickString(profile, <String>['email', 'Email', 'username']);
        final String phone = _pickString(profile, <String>['phone', 'phoneNumber', 'mobile', 'mobileNumber']);
        final String dob = _pickDob(profile);
        final String gender = _pickGender(profile);

        final String displayName = (
          <String>[firstName, lastName].where((String s) => s.trim().isNotEmpty).join(' ')
        ).trim();

        final double hPad = AppResponsive.clamp(
          AppResponsive.vw(constraints, 6),
          16,
          22,
        );

        final double gap = AppResponsive.clamp(
          AppResponsive.scaledByHeight(constraints, 16),
          12,
          18,
        );

        final double cardRadius = AppResponsive.clamp(
          AppResponsive.scaledByHeight(constraints, 18),
          14,
          20,
        );

        final double logoSize = AppResponsive.clamp(
          AppResponsive.scaledByHeight(constraints, 54),
          46,
          62,
        );

        Widget infoTile({
          required IconData icon,
          required String label,
          required String value,
          bool selectable = false,
          bool showDivider = true,
        }) {
          final String v = value.trim().isEmpty ? 'Not specified' : value.trim();

          final TextStyle labelStyle = const TextStyle(
            color: Color(0xFF6B7895),
            fontWeight: FontWeight.w800,
            fontSize: 12,
          );

          final TextStyle valueStyle = const TextStyle(
            color: Color(0xFF0B1B4B),
            fontWeight: FontWeight.w900,
            fontSize: 14,
          );

          final Widget valueWidget = selectable
              ? SelectableText(v, style: valueStyle)
              : Text(
                  v,
                  style: valueStyle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                );

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                child: Row(
                  children: <Widget>[
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F6FB),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(icon, color: const Color(0xFF0B1B4B), size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(label, style: labelStyle),
                          const SizedBox(height: 3),
                          valueWidget,
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (showDivider)
                const Divider(height: 1, thickness: 1, color: Color(0xFFE9EEF5)),
            ],
          );
        }

        return Scaffold(
          backgroundColor: const Color(0xFFF7FAFF),
          appBar: AppBar(
            title: const Text('Profile Information'),
            leading: const BackButton(),
            actions: <Widget>[
              TextButton(
                onPressed: profile == null
                    ? null
                    : () {
                        final TextEditingController firstCtrl =
                            TextEditingController(text: firstName);
                        final TextEditingController lastCtrl =
                            TextEditingController(text: lastName);
                        final TextEditingController emailCtrl =
                            TextEditingController(text: email);
                        final TextEditingController phoneCtrl =
                            TextEditingController(text: phone);
                        final TextEditingController dobCtrl =
                            TextEditingController(
                              text: dob == 'Not specified' ? '' : dob,
                            );
                        String genderValue = gender;

                        showModalBottomSheet<void>(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (BuildContext ctx) {
                            final EdgeInsets viewInsets =
                                MediaQuery.viewInsetsOf(ctx);

                            Widget field({
                              required String label,
                              required TextEditingController controller,
                              bool enabled = true,
                              TextInputType keyboardType = TextInputType.text,
                            }) {
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Text(
                                    label,
                                    style: const TextStyle(
                                      color: Color(0xFF6B7895),
                                      fontWeight: FontWeight.w800,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  TextField(
                                    controller: controller,
                                    enabled: enabled,
                                    keyboardType: keyboardType,
                                    decoration: InputDecoration(
                                      isDense: true,
                                      filled: true,
                                      fillColor: const Color(0xFFF7FAFF),
                                      contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 14,
                                        vertical: 12,
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(14),
                                        borderSide: const BorderSide(
                                          color: Color(0xFFE9EEF5),
                                        ),
                                      ),
                                      disabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(14),
                                        borderSide: const BorderSide(
                                          color: Color(0xFFE9EEF5),
                                        ),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(14),
                                        borderSide: const BorderSide(
                                          color: AppColors.primary,
                                          width: 1.2,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            }

                            return Padding(
                              padding: EdgeInsets.only(
                                left: 16,
                                right: 16,
                                bottom: 16 + viewInsets.bottom,
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(18),
                                child: DecoratedBox(
                                  decoration:
                                      const BoxDecoration(color: Colors.white),
                                  child: Padding(
                                    padding: const EdgeInsets.fromLTRB(
                                      16,
                                      14,
                                      16,
                                      16,
                                    ),
                                    child: StatefulBuilder(
                                      builder: (
                                        BuildContext ctx,
                                        void Function(void Function()) setState,
                                      ) {
                                        return Column(
                                          mainAxisSize: MainAxisSize.min,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.stretch,
                                          children: <Widget>[
                                            Row(
                                              children: <Widget>[
                                                const Expanded(
                                                  child: Text(
                                                    'Edit Profile',
                                                    style: TextStyle(
                                                      color: Color(0xFF0B1B4B),
                                                      fontWeight: FontWeight.w900,
                                                      fontSize: 16,
                                                    ),
                                                  ),
                                                ),
                                                IconButton(
                                                  onPressed: () =>
                                                      Navigator.of(ctx).pop(),
                                                  icon: const Icon(Icons.close),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 6),
                                            field(
                                              label: 'First Name',
                                              controller: firstCtrl,
                                            ),
                                            const SizedBox(height: 12),
                                            field(
                                              label: 'Last Name',
                                              controller: lastCtrl,
                                            ),
                                            const SizedBox(height: 12),
                                            field(
                                              label: 'Email Address',
                                              controller: emailCtrl,
                                              enabled: false,
                                              keyboardType:
                                                  TextInputType.emailAddress,
                                            ),
                                            const SizedBox(height: 6),
                                            Text(
                                              'Email cannot be changed',
                                              style: TextStyle(
                                                color: const Color(0xFF6B7895)
                                                    .withValues(alpha: 0.85),
                                                fontWeight: FontWeight.w700,
                                                fontSize: 12,
                                              ),
                                            ),
                                            const SizedBox(height: 12),
                                            field(
                                              label: 'Phone Number',
                                              controller: phoneCtrl,
                                              keyboardType: TextInputType.phone,
                                            ),
                                            const SizedBox(height: 12),
                                            field(
                                              label: 'Date of Birth (YYYY-MM-DD)',
                                              controller: dobCtrl,
                                              keyboardType:
                                                  TextInputType.datetime,
                                            ),
                                            const SizedBox(height: 12),
                                            const Text(
                                              'Gender',
                                              style: TextStyle(
                                                color: Color(0xFF6B7895),
                                                fontWeight: FontWeight.w800,
                                                fontSize: 12,
                                              ),
                                            ),
                                            const SizedBox(height: 6),
                                            DropdownButtonFormField<String>(
                                              initialValue: genderValue,
                                              items: const <DropdownMenuItem<String>>[
                                                DropdownMenuItem<String>(
                                                  value: 'Prefer not to say',
                                                  child: Text('Prefer not to say'),
                                                ),
                                                DropdownMenuItem<String>(
                                                  value: 'Male',
                                                  child: Text('Male'),
                                                ),
                                                DropdownMenuItem<String>(
                                                  value: 'Female',
                                                  child: Text('Female'),
                                                ),
                                              ],
                                              onChanged: (String? v) {
                                                if (v == null) return;
                                                setState(() => genderValue = v);
                                              },
                                              decoration: InputDecoration(
                                                isDense: true,
                                                filled: true,
                                                fillColor: const Color(0xFFF7FAFF),
                                                contentPadding:
                                                    const EdgeInsets.symmetric(
                                                  horizontal: 14,
                                                  vertical: 12,
                                                ),
                                                enabledBorder: OutlineInputBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(14),
                                                  borderSide: const BorderSide(
                                                    color: Color(0xFFE9EEF5),
                                                  ),
                                                ),
                                                focusedBorder: OutlineInputBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(14),
                                                  borderSide: const BorderSide(
                                                    color: AppColors.primary,
                                                    width: 1.2,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(height: 14),
                                            ElevatedButton(
                                              onPressed: () {
                                                final Map<String, dynamic> next =
                                                    Map<String, dynamic>.from(
                                                        profile);

                                                next['firstName'] =
                                                    firstCtrl.text.trim();
                                                next['lastName'] =
                                                    lastCtrl.text.trim();
                                                next['phone'] =
                                                    phoneCtrl.text.trim();
                                                next['dateOfBirth'] =
                                                    dobCtrl.text.trim();
                                                next['gender'] = genderValue;

                                                ctx
                                                    .read<AuthController>()
                                                    .updateLocalProfile(next);

                                                Navigator.of(ctx).pop();
                                                ScaffoldMessenger.of(context)
                                                    .showSnackBar(
                                                  const SnackBar(
                                                    content: Text(
                                                      'Profile updated (local only)',
                                                    ),
                                                  ),
                                                );
                                              },
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor:
                                                    AppColors.primary,
                                                foregroundColor: Colors.white,
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                  vertical: 14,
                                                ),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(14),
                                                ),
                                                textStyle: const TextStyle(
                                                  fontWeight: FontWeight.w900,
                                                ),
                                              ),
                                              child: const Text('Save'),
                                            ),
                                          ],
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ).whenComplete(() {
                          firstCtrl.dispose();
                          lastCtrl.dispose();
                          emailCtrl.dispose();
                          phoneCtrl.dispose();
                          dobCtrl.dispose();
                        });
                      },
                child: const Text(
                  'Edit',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(hPad, gap, hPad, gap),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                ClipRRect(
                  borderRadius: BorderRadius.circular(cardRadius),
                  child: DecoratedBox(
                    decoration: const BoxDecoration(color: AppColors.splashBottom),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                      child: Row(
                        children: <Widget>[
                          Container(
                            width: logoSize + 16,
                            height: logoSize + 16,
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
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  displayName.isEmpty ? 'Profile' : displayName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: AppResponsive.clamp(
                                      AppResponsive.sp(constraints, 18),
                                      16,
                                      20,
                                    ),
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  email.isEmpty ? 'Not set' : email,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: AppResponsive.clamp(
                                      AppResponsive.sp(constraints, 12),
                                      11,
                                      13,
                                    ),
                                    color: Colors.white.withValues(alpha: 0.82),
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                SizedBox(height: gap),
                ClipRRect(
                  borderRadius: BorderRadius.circular(cardRadius),
                  child: const DecoratedBox(
                    decoration: BoxDecoration(color: Colors.white),
                    child: SizedBox.shrink(),
                  ),
                ),
                ClipRRect(
                  borderRadius: BorderRadius.circular(cardRadius),
                  child: DecoratedBox(
                    decoration: const BoxDecoration(color: Colors.white),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        infoTile(
                          icon: Icons.badge_outlined,
                          label: 'First Name',
                          value: firstName,
                        ),
                        infoTile(
                          icon: Icons.badge_outlined,
                          label: 'Last Name',
                          value: lastName,
                        ),
                        infoTile(
                          icon: Icons.email_outlined,
                          label: 'Email Address',
                          value: email,
                          selectable: true,
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Email cannot be changed',
                              style: TextStyle(
                                color: const Color(0xFF6B7895).withValues(alpha: 0.85),
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                        infoTile(
                          icon: Icons.phone_outlined,
                          label: 'Phone Number',
                          value: phone,
                          selectable: true,
                        ),
                        infoTile(
                          icon: Icons.cake_outlined,
                          label: 'Date of Birth',
                          value: dob,
                        ),
                        infoTile(
                          icon: Icons.person_outline,
                          label: 'Gender',
                          value: gender,
                          showDivider: false,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
