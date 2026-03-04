import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../../../controllers/add_new_user_controller.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_responsive.dart';

class AddNewUserScreen extends StatefulWidget {
  const AddNewUserScreen({super.key});

  @override
  State<AddNewUserScreen> createState() => _AddNewUserScreenState();
}

class _AddNewUserScreenState extends State<AddNewUserScreen> {
  int _step = 0;

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _firstName = TextEditingController();
  final TextEditingController _lastName = TextEditingController();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _phone = TextEditingController();

  final TextEditingController _password = TextEditingController();
  final TextEditingController _confirmPassword = TextEditingController();
  bool _passwordVisible = false;

  bool _statusActive = true;
  String _language = 'English (US)';

  bool _sendWelcomeEmail = true;
  bool _forcePasswordChange = true;
  bool _enable2fa = false;
  bool _emailNotifications = true;

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _email.dispose();
    _phone.dispose();
    _password.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }

  InputDecoration _dec({required String label, String? hint, Widget? suffix}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      suffixIcon: suffix,
      hintStyle: const TextStyle(color: Color(0xFF9AA5B6)),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE9EEF5)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.4),
      ),
    );
  }

  Widget _section({required String title, required Widget child, IconData? icon}) {
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
          Row(
            children: <Widget>[
              if (icon != null) ...<Widget>[
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF4FF),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: AppColors.primary, size: 18),
                ),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF0B1B4B),
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _stepDots() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        _Dot(active: _step == 0),
        const SizedBox(width: 8),
        _Dot(active: _step == 1),
      ],
    );
  }

  bool _validateStep0() {
    final FormState? form = _formKey.currentState;
    if (form == null) return false;
    if (!form.validate()) return false;
    final String pass = _password.text;
    final String conf = _confirmPassword.text;
    if (pass != conf) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passwords do not match')),
      );
      return false;
    }
    return true;
  }

  Future<void> _next() async {
    if (_step == 0) {
      if (!_validateStep0()) return;
      setState(() => _step = 1);
      return;
    }

    final AddNewUserController ctrl = context.read<AddNewUserController>();
    if (ctrl.loading) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please wait... loading data')),
      );
      return;
    }
    if (ctrl.submitting) return;

    try {
      await ctrl.createUser(
        firstName: _firstName.text,
        lastName: _lastName.text,
        email: _email.text,
        phone: _phone.text,
        password: _password.text,
        confirmPassword: _confirmPassword.text,
        isActive: _statusActive,
      );

      if (!mounted) return;
      if (ctrl.error != null && ctrl.error!.trim().isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ctrl.error!.trim())),
        );
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User registered successfully')),
      );
      Navigator.of(context).pop(true);
    } catch (_) {
      if (!mounted) return;
      final String msg = (ctrl.error ?? 'Failed to create user').trim();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg.isEmpty ? 'Failed to create user' : msg)),
      );
    }
  }

  void _back() {
    if (_step == 0) {
      Navigator.of(context).pop();
      return;
    }
    setState(() => _step = 0);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final AddNewUserController ctrl = context.watch<AddNewUserController>();

        final bool showSkeleton = ctrl.loading &&
            ctrl.roles.isEmpty &&
            ctrl.permissions.isEmpty &&
            ctrl.companies.isEmpty;
        final bool showRefreshingBar = ctrl.loading && !showSkeleton;

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
            title: const Text('Add New User'),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: _back,
            ),
          ),
          body: SafeArea(
            child: Skeletonizer(
              enabled: showSkeleton,
              child: ListView(
                padding: EdgeInsets.fromLTRB(hPad, gap, hPad, gap + 98),
                children: <Widget>[
                  _stepDots(),
                  SizedBox(height: gap),
                  if (showRefreshingBar)
                    const Padding(
                      padding: EdgeInsets.only(bottom: 10),
                      child: ClipRRect(
                        borderRadius: BorderRadius.all(Radius.circular(999)),
                        child: LinearProgressIndicator(minHeight: 3),
                      ),
                    ),
                  if (ctrl.error != null && ctrl.error!.trim().isNotEmpty)
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFE7E7),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: const Color(0xFFFFC9C9)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          const Icon(
                            Icons.error_outline,
                            color: Color(0xFFFF3B30),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              ctrl.error!.trim(),
                              style: const TextStyle(
                                color: Color(0xFF0B1B4B),
                                fontWeight: FontWeight.w700,
                                height: 1.35,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          InkWell(
                            onTap: () =>
                                context.read<AddNewUserController>().loadInitial(),
                            borderRadius: BorderRadius.circular(10),
                            child: const Padding(
                              padding: EdgeInsets.all(6),
                              child: Icon(
                                Icons.refresh,
                                color: Color(0xFF0B1B4B),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (ctrl.error != null && ctrl.error!.trim().isNotEmpty)
                    SizedBox(height: gap),
                  if (_step == 0)
                    Form(
                      key: _formKey,
                      child: Column(
                        children: <Widget>[
                          _section(
                            title: 'Personal Info',
                            icon: Icons.person_outline,
                            child: Column(
                              children: <Widget>[
                                Row(
                                  children: <Widget>[
                                    Expanded(
                                      child: TextFormField(
                                        controller: _firstName,
                                        decoration: _dec(label: 'First Name*'),
                                        validator: (String? v) {
                                          if ((v ?? '').trim().isEmpty) {
                                            return 'Required';
                                          }
                                          return null;
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: TextFormField(
                                        controller: _lastName,
                                        decoration: _dec(label: 'Last Name*'),
                                        validator: (String? v) {
                                          if ((v ?? '').trim().isEmpty) {
                                            return 'Required';
                                          }
                                          return null;
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                TextFormField(
                                  controller: _email,
                                  keyboardType: TextInputType.emailAddress,
                                  decoration: _dec(label: 'Email Address*'),
                                  validator: (String? v) {
                                    final String s = (v ?? '').trim();
                                    if (s.isEmpty) return 'Required';
                                    if (!s.contains('@')) return 'Invalid email';
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 12),
                                TextFormField(
                                  controller: _phone,
                                  keyboardType: TextInputType.phone,
                                  decoration: _dec(label: 'Phone Number'),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: gap),
                          _section(
                            title: 'Account Settings',
                            icon: Icons.lock_outline,
                            child: Column(
                              children: <Widget>[
                                TextFormField(
                                  controller: _password,
                                  obscureText: !_passwordVisible,
                                  decoration: _dec(
                                    label: 'Password*',
                                    suffix: IconButton(
                                      onPressed: () => setState(
                                        () =>
                                            _passwordVisible = !_passwordVisible,
                                      ),
                                      icon: Icon(
                                        _passwordVisible
                                            ? Icons.visibility_off_outlined
                                            : Icons.visibility_outlined,
                                      ),
                                    ),
                                  ),
                                  validator: (String? v) {
                                    if ((v ?? '').trim().length < 6) {
                                      return 'Min 6 characters';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 12),
                                TextFormField(
                                  controller: _confirmPassword,
                                  obscureText: true,
                                  decoration: _dec(label: 'Confirm Password*'),
                                  validator: (String? v) {
                                    if ((v ?? '').trim().length < 6) {
                                      return 'Min 6 characters';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: <Widget>[
                                    Expanded(
                                      child: _DropdownCard(
                                        label: 'Status',
                                        value: _statusActive
                                            ? 'Active'
                                            : 'Inactive',
                                        onTap: () async {
                                          final bool? picked =
                                              await showModalBottomSheet<bool>(
                                            context: context,
                                            showDragHandle: true,
                                            backgroundColor: Colors.white,
                                            shape: const RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.vertical(
                                                top: Radius.circular(18),
                                              ),
                                            ),
                                            builder: (BuildContext ctx) {
                                              return SafeArea(
                                                child: Column(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: <Widget>[
                                                    _SheetPickTile(
                                                      title: 'Active',
                                                      onTap: () =>
                                                          Navigator.of(ctx)
                                                              .pop(true),
                                                    ),
                                                    _SheetPickTile(
                                                      title: 'Inactive',
                                                      onTap: () =>
                                                          Navigator.of(ctx)
                                                              .pop(false),
                                                    ),
                                                    const SizedBox(height: 8),
                                                  ],
                                                ),
                                              );
                                            },
                                          );
                                          if (picked == null) return;
                                          setState(() => _statusActive = picked);
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: _DropdownCard(
                                        label: 'Language',
                                        value: _language,
                                        onTap: () async {
                                          final String? picked = await
                                              showModalBottomSheet<String>(
                                            context: context,
                                            showDragHandle: true,
                                            backgroundColor: Colors.white,
                                            shape: const RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.vertical(
                                                top: Radius.circular(18),
                                              ),
                                            ),
                                            builder: (BuildContext ctx) {
                                              return SafeArea(
                                                child: Column(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: <Widget>[
                                                    _SheetPickTile(
                                                      title: 'English (US)',
                                                      onTap: () =>
                                                          Navigator.of(ctx)
                                                              .pop('English (US)'),
                                                    ),
                                                    _SheetPickTile(
                                                      title: 'Arabic (SA)',
                                                      onTap: () =>
                                                          Navigator.of(ctx)
                                                              .pop('Arabic (SA)'),
                                                    ),
                                                    const SizedBox(height: 8),
                                                  ],
                                                ),
                                              );
                                            },
                                          );
                                          if (picked == null) return;
                                          setState(() => _language = picked);
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Column(
                      children: <Widget>[
                        _section(
                          title: 'Role & Company',
                          icon: Icons.badge_outlined,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: <Widget>[
                              _DropdownCard(
                                label: 'Role',
                                value: (ctrl.selectedRole?.name ?? '').trim().isEmpty
                                    ? '-'
                                    : (ctrl.selectedRole?.name ?? '').trim(),
                                onTap: () async {
                                  if (ctrl.roles.isEmpty) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('No roles available'),
                                      ),
                                    );
                                    return;
                                  }

                                  await showModalBottomSheet<void>(
                                    context: context,
                                    showDragHandle: true,
                                    backgroundColor: Colors.white,
                                    shape: const RoundedRectangleBorder(
                                      borderRadius: BorderRadius.vertical(
                                        top: Radius.circular(18),
                                      ),
                                    ),
                                    builder: (BuildContext ctx) {
                                      return SafeArea(
                                        child: ListView(
                                          shrinkWrap: true,
                                          padding: const EdgeInsets.fromLTRB(
                                            18,
                                            6,
                                            18,
                                            18,
                                          ),
                                          children: <Widget>[
                                            const Text(
                                              'Select Role',
                                              textAlign: TextAlign.center,
                                              style: TextStyle(
                                                color: Color(0xFF0B1B4B),
                                                fontWeight: FontWeight.w900,
                                                fontSize: 16,
                                              ),
                                            ),
                                            const SizedBox(height: 10),
                                            ...ctrl.roles.map((role) {
                                              final bool selected =
                                                  ctrl.selectedRole?.id == role.id;
                                              final String name =
                                                  role.name.trim().isEmpty
                                                      ? '-'
                                                      : role.name.trim();
                                              return ListTile(
                                                title: Text(
                                                  name,
                                                  style: const TextStyle(
                                                    color: Color(0xFF0B1B4B),
                                                    fontWeight: FontWeight.w800,
                                                  ),
                                                ),
                                                subtitle: (role.description
                                                        .trim()
                                                        .isEmpty)
                                                    ? null
                                                    : Text(
                                                        role.description.trim(),
                                                        style: const TextStyle(
                                                          color:
                                                              Color(0xFF6B7895),
                                                          fontWeight:
                                                              FontWeight.w700,
                                                          fontSize: 12,
                                                        ),
                                                      ),
                                                trailing: Icon(
                                                  selected
                                                      ? Icons.check_circle
                                                      : Icons.circle_outlined,
                                                  color: selected
                                                      ? AppColors.primary
                                                      : const Color(0xFF9AA5B6),
                                                ),
                                                onTap: () {
                                                  Navigator.of(ctx).pop();
                                                  context
                                                      .read<AddNewUserController>()
                                                      .setRole(role);
                                                },
                                              );
                                            }),
                                          ],
                                        ),
                                      );
                                    },
                                  );
                                },
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                'Assign Company',
                                style: TextStyle(
                                  color: Color(0xFF9AA5B6),
                                  fontWeight: FontWeight.w800,
                                  fontSize: 11,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 10,
                                runSpacing: 10,
                                children: ctrl.companies.map((c) {
                                  final bool selected =
                                      ctrl.selectedCompanyIds.contains(c.id);
                                  final String name = c.name.trim().isEmpty
                                      ? '-'
                                      : c.name.trim();
                                  return InkWell(
                                    borderRadius: BorderRadius.circular(999),
                                    onTap: () => context
                                        .read<AddNewUserController>()
                                        .toggleCompany(c.id),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 10,
                                      ),
                                      decoration: BoxDecoration(
                                        color: selected
                                            ? const Color(0xFFEFF4FF)
                                            : const Color(0xFFF7FAFF),
                                        borderRadius: BorderRadius.circular(999),
                                        border: Border.all(
                                          color: selected
                                              ? AppColors.primary
                                              : const Color(0xFFE9EEF5),
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: <Widget>[
                                          Icon(
                                            selected
                                                ? Icons.check_circle
                                                : Icons.circle_outlined,
                                            size: 18,
                                            color: selected
                                                ? AppColors.primary
                                                : const Color(0xFF9AA5B6),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            name,
                                            style: TextStyle(
                                              color: selected
                                                  ? const Color(0xFF0B1B4B)
                                                  : const Color(0xFF6B7895),
                                              fontWeight: FontWeight.w800,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: gap),
                        _section(
                          title: 'Profile Picture',
                          icon: Icons.photo_camera_outlined,
                          child: Container(
                            height: 160,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF7FAFF),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: const Color(0xFFE9EEF5),
                              ),
                            ),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(18),
                              onTap: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Coming soon')),
                                );
                              },
                              child: const Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: <Widget>[
                                    Icon(Icons.add_a_photo_outlined, size: 22),
                                    SizedBox(height: 8),
                                    Text(
                                      'Tap to upload',
                                      style: TextStyle(
                                        color: Color(0xFF6B7895),
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      'PNG, JPG up to 5MB',
                                      style: TextStyle(
                                        color: Color(0xFF9AA5B6),
                                        fontWeight: FontWeight.w700,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: gap),
                        _section(
                          title: 'Quick Settings',
                          icon: Icons.tune,
                          child: Column(
                            children: <Widget>[
                              _SwitchTile(
                                title: 'Send welcome email',
                                subtitle: 'Notify user about account creation',
                                value: _sendWelcomeEmail,
                                onChanged: (bool v) =>
                                    setState(() => _sendWelcomeEmail = v),
                              ),
                              const SizedBox(height: 10),
                              _SwitchTile(
                                title: 'Force password change',
                                subtitle: 'Prompt user to set a new password',
                                value: _forcePasswordChange,
                                onChanged: (bool v) =>
                                    setState(() => _forcePasswordChange = v),
                              ),
                              const SizedBox(height: 10),
                              _SwitchTile(
                                title: 'Enable 2FA',
                                subtitle: 'Require two-factor authentication',
                                value: _enable2fa,
                                onChanged: (bool v) =>
                                    setState(() => _enable2fa = v),
                              ),
                              const SizedBox(height: 10),
                              _SwitchTile(
                                title: 'Email notifications',
                                subtitle: 'Daily digest and alerts',
                                value: _emailNotifications,
                                onChanged: (bool v) =>
                                    setState(() => _emailNotifications = v),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: gap),
                        _section(
                          title: 'Permissions',
                          icon: Icons.admin_panel_settings_outlined,
                          child: Column(
                            children: <Widget>[
                              if (ctrl.permissions.isEmpty)
                                const Text(
                                  'No permissions available',
                                  style: TextStyle(
                                    color: Color(0xFF6B7895),
                                    fontWeight: FontWeight.w800,
                                  ),
                                )
                              else
                                ...ctrl.permissions.map((p) {
                                  final bool selected =
                                      ctrl.selectedPermissionIds.contains(p.id);
                                  final String title = p.name.trim().isEmpty
                                      ? p.id
                                      : p.name.trim();
                                  final String subtitle = p.category.trim().isEmpty
                                      ? (p.identifier.trim().isEmpty
                                          ? '-'
                                          : p.identifier.trim())
                                      : p.category.trim();

                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 10),
                                    child: _PermissionToggleTile(
                                      title: title,
                                      subtitle: subtitle,
                                      value: selected,
                                      onTap: () => context
                                          .read<AddNewUserController>()
                                          .togglePermission(p.id),
                                    ),
                                  );
                                }),
                            ],
                          ),
                        ),
                        SizedBox(height: gap),
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF3E6),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: const Color(0xFFFFE1C4)),
                          ),
                          child: const Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Icon(
                                Icons.warning_amber_rounded,
                                color: Color(0xFFFF9500),
                              ),
                              SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Security notice: Follow the principle of least privilege. Only assign permissions necessary for the user\'s role to minimize security risks.',
                                  style: TextStyle(
                                    color: Color(0xFF0B1B4B),
                                    fontWeight: FontWeight.w700,
                                    height: 1.35,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
          bottomNavigationBar: SafeArea(
            child: Padding(
              padding: EdgeInsets.fromLTRB(hPad, 10, hPad, 12),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: OutlinedButton(
                      onPressed: ctrl.submitting ? null : _back,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: const BorderSide(color: Color(0xFFE9EEF5)),
                        foregroundColor: const Color(0xFF0B1B4B),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(_step == 0 ? 'Cancel' : 'Back'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: ctrl.submitting ? null : _next,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        _step == 0
                            ? 'Continue'
                            : (ctrl.submitting ? 'Creating...' : 'Create'),
                      ),
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

class _PermissionToggleTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final VoidCallback onTap;

  const _PermissionToggleTile({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: value ? const Color(0xFFEFF4FF) : const Color(0xFFF7FAFF),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: value ? AppColors.primary : const Color(0xFFE9EEF5),
          ),
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
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Color(0xFF6B7895),
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Icon(
              value ? Icons.check_circle : Icons.circle_outlined,
              color: value ? AppColors.primary : const Color(0xFF9AA5B6),
            ),
          ],
        ),
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  final bool active;

  const _Dot({required this.active});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      width: active ? 26 : 10,
      height: 10,
      decoration: BoxDecoration(
        color: active ? AppColors.primary : const Color(0xFFE2E8F0),
        borderRadius: BorderRadius.circular(999),
      ),
    );
  }
}

class _SheetPickTile extends StatelessWidget {
  final String title;
  final VoidCallback onTap;

  const _SheetPickTile({required this.title, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(
        title,
        style: const TextStyle(
          color: Color(0xFF0B1B4B),
          fontWeight: FontWeight.w800,
        ),
      ),
      onTap: onTap,
    );
  }
}

class _DropdownCard extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onTap;

  const _DropdownCard({
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
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
            const Icon(
              Icons.keyboard_arrow_down_rounded,
              color: Color(0xFF6B7895),
            ),
          ],
        ),
      ),
    );
  }
}

class _SwitchTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SwitchTile({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
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
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Color(0xFF6B7895),
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: AppColors.primary,
          ),
        ],
      ),
    );
  }
}

