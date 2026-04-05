import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/content_spacing.dart';

import '../../services/api_client.dart';
import '../../state/app_profile.dart';
import '../../state/app_profile_scope.dart';
import '../../widgets/auth/auth_styles.dart';

class OnboardingRoleScreen extends StatefulWidget {
  const OnboardingRoleScreen({super.key});

  @override
  State<OnboardingRoleScreen> createState() => _OnboardingRoleScreenState();
}

class _OnboardingRoleScreenState extends State<OnboardingRoleScreen> {
  final _apiClient = ApiClient();
  final _usernameController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _countryCodeController = TextEditingController(text: '+63');
  final _phoneController = TextEditingController();

  DateTime? _birthday;
  GenderOption _gender = GenderOption.male;
  UserRole _role = UserRole.patron;

  @override
  void dispose() {
    _usernameController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _countryCodeController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _pickBirthday() async {
    final now = DateTime.now();
    final initial = _birthday ?? DateTime(now.year - 18, now.month, now.day);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1900),
      lastDate: now,
    );
    if (picked != null) {
      setState(() {
        _birthday = picked;
      });
    }
  }

  void _setRole(UserRole newRole) {
    setState(() {
      _role = newRole;
    });
    AppProfileScope.of(context).setRole(newRole);
  }

  Future<void> _continue() async {
    final username = _usernameController.text.trim();
    final fn = _firstNameController.text.trim();
    final ln = _lastNameController.text.trim();
    if (username.isNotEmpty || fn.isNotEmpty || ln.isNotEmpty) {
      try {
        await _apiClient.updateProfile(
          username: username.isNotEmpty ? username : null,
          firstName: fn,
          lastName: ln,
        );
      } on ApiException catch (e) {
        if (e.statusCode == 409) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.message)),
          );
          return;
        }
        // Other errors: continue onboarding with local profile only.
      } catch (_) {
        // Network / unexpected: continue onboarding.
      }
    }
    if (!mounted) return;
    AppProfileScope.of(context).updateOnboardingInfo(
      username: username,
      firstName: _firstNameController.text.trim(),
      lastName: _lastNameController.text.trim(),
      countryCode: _countryCodeController.text.trim(),
      phoneNumber: _phoneController.text.trim(),
      birthday: _birthday,
      gender: _gender,
    );
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/app');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BcColors.pageBackground,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: kScreenHorizontalPadding,
            vertical: 16,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 6),
              Text('What is your', style: AuthTextStyles.headlineRed),
              Text('role?', style: AuthTextStyles.headlineBlack),
              const SizedBox(height: 10),
              _RoleIllustration(role: _role),
              const SizedBox(height: 8),
              Row(
                children: [
                  IconButton(
                    onPressed: () => _setRole(UserRole.patron),
                    icon: const Icon(Icons.chevron_left),
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          _role == UserRole.patron ? 'Are you a...' : 'Or an...',
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: Colors.black54),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _role == UserRole.patron ? 'Patron' : 'Artist',
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                height: 1.05,
                                color: AuthColors.primaryRed,
                              ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => _setRole(UserRole.artist),
                    icon: const Icon(Icons.chevron_right),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text('Username', style: AuthTextStyles.fieldLabel),
              const SizedBox(height: 6),
              TextField(
                controller: _usernameController,
                decoration: authInputDecoration(hintText: 'e.g. Moachi'),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('First Name', style: AuthTextStyles.fieldLabel),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _firstNameController,
                          decoration: authInputDecoration(hintText: 'First name'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Last Name', style: AuthTextStyles.fieldLabel),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _lastNameController,
                          decoration: authInputDecoration(hintText: 'Last name'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Number', style: AuthTextStyles.fieldLabel),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            SizedBox(
                              width: 78,
                              child: TextField(
                                controller: _countryCodeController,
                                keyboardType: TextInputType.phone,
                                decoration: authInputDecoration(hintText: '+63'),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextField(
                                controller: _phoneController,
                                keyboardType: TextInputType.phone,
                                decoration:
                                    authInputDecoration(hintText: 'Phone number'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Birthday', style: AuthTextStyles.fieldLabel),
                        const SizedBox(height: 6),
                        InkWell(
                          borderRadius: BorderRadius.circular(10),
                          onTap: _pickBirthday,
                          child: IgnorePointer(
                            child: TextField(
                              decoration: authInputDecoration(
                                hintText: _birthday == null
                                    ? 'MM/DD/YYYY'
                                    : _fmtDate(_birthday!),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text('Gender', style: AuthTextStyles.fieldLabel),
              const SizedBox(height: 8),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _GenderChip(
                    label: 'Male',
                    selected: _gender == GenderOption.male,
                    onTap: () => setState(() => _gender = GenderOption.male),
                  ),
                  _GenderChip(
                    label: 'Female',
                    selected: _gender == GenderOption.female,
                    onTap: () => setState(() => _gender = GenderOption.female),
                  ),
                  _GenderChip(
                    label: 'Other',
                    selected: _gender == GenderOption.other,
                    onTap: () => setState(() => _gender = GenderOption.other),
                  ),
                  _GenderChip(
                    label: 'Prefer not to say',
                    selected: _gender == GenderOption.preferNotToSay,
                    onTap: () =>
                        setState(() => _gender = GenderOption.preferNotToSay),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                style: primaryPillButtonStyle(),
                onPressed: _continue,
                child: const Text('Continue'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _fmtDate(DateTime dt) {
    final mm = dt.month.toString().padLeft(2, '0');
    final dd = dt.day.toString().padLeft(2, '0');
    final yyyy = dt.year.toString();
    return '$mm/$dd/$yyyy';
  }
}

class _RoleIllustration extends StatelessWidget {
  final UserRole role;

  const _RoleIllustration({required this.role});

  @override
  Widget build(BuildContext context) {
    // Placeholder illustration area (we'll swap to real assets later).
    return Container(
      height: 170,
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFF7F7F7),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E5E5)),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              role == UserRole.patron ? Icons.favorite_border : Icons.brush_outlined,
              size: 42,
              color: Colors.black54,
            ),
            const SizedBox(height: 8),
            Text(
              role == UserRole.patron ? 'Patron illustration' : 'Artist illustration',
              style: const TextStyle(color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }
}

class _GenderChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _GenderChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bg = selected ? AuthColors.primaryRed : Colors.white;
    final fg = selected ? Colors.white : Colors.black87;

    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: AuthColors.borderGray),
        ),
        child: Text(
          label,
          style: Theme.of(context)
              .textTheme
              .bodySmall
              ?.copyWith(color: fg, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
