import 'package:flutter/material.dart';

import '../../services/api_client.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _emailNotifications = true;
  bool _showEmail = false;
  bool _autoPlayVideos = true;
  bool _privateAccount = false;

  bool _likes = true;
  bool _comments = true;
  bool _newFollowers = false;

  bool _isLoggingOut = false;
  bool _isDeletingAccount = false;

  final ApiClient _apiClient = ApiClient();

  @override
  Widget build(BuildContext context) {
    final accent = const Color(0xFFFF4A4A);
    return Scaffold(
      backgroundColor: const Color(0xFFF3F3F6),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF3F3F6),
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: IconButton(
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.arrow_back),
          color: Colors.black,
        ),
        title: const Text(
          'Settings',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.2,
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            _Section(
              title: 'General',
              icon: Icons.tune_rounded,
              accentColor: accent,
              children: [
                _ToggleRow(
                  icon: Icons.mail_outline,
                  iconColor: accent,
                  title: 'Email Notifications',
                  subtitle: 'Receive emails about your account activity',
                  value: _emailNotifications,
                  onChanged: (v) => setState(() => _emailNotifications = v),
                ),
                _ToggleRow(
                  icon: Icons.lock_outline,
                  iconColor: accent,
                  title: 'Show Email',
                  subtitle: 'Receive email updates about your account activity',
                  value: _showEmail,
                  onChanged: (v) => setState(() => _showEmail = v),
                ),
                _ToggleRow(
                  icon: Icons.play_circle_outline,
                  iconColor: accent,
                  title: 'Auto-play Videos',
                  subtitle: 'Receive emails about your account activity',
                  value: _autoPlayVideos,
                  onChanged: (v) => setState(() => _autoPlayVideos = v),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _Section(
              title: 'Account',
              icon: Icons.person_outline_rounded,
              accentColor: accent,
              children: [
                _ChevronRow(
                  icon: Icons.edit_outlined,
                  iconColor: accent,
                  title: 'Edit Profile',
                  subtitle: 'Receive email updates about your account activity',
                  onTap: () {},
                ),
                _ToggleRow(
                  icon: Icons.privacy_tip_outlined,
                  iconColor: accent,
                  title: 'Private Account',
                  subtitle: 'Receive email updates about your account activity',
                  value: _privateAccount,
                  onChanged: (v) => setState(() => _privateAccount = v),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _Section(
              title: 'Notifications',
              icon: Icons.notifications_none_outlined,
              accentColor: accent,
              children: [
                _ToggleRow(
                  icon: Icons.favorite_border_outlined,
                  iconColor: accent,
                  title: 'Likes',
                  subtitle: 'Receive email updates about your account activity',
                  value: _likes,
                  onChanged: (v) => setState(() => _likes = v),
                ),
                _ToggleRow(
                  icon: Icons.chat_bubble_outline,
                  iconColor: accent,
                  title: 'Comments',
                  subtitle: 'Receive email updates about your account activity',
                  value: _comments,
                  onChanged: (v) => setState(() => _comments = v),
                ),
                _ToggleRow(
                  icon: Icons.person_add_alt_outlined,
                  iconColor: accent,
                  title: 'New Followers',
                  subtitle: 'Receive email updates about your account activity',
                  value: _newFollowers,
                  onChanged: (v) => setState(() => _newFollowers = v),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _Section(
              title: 'Security',
              icon: Icons.security_outlined,
              accentColor: accent,
              children: [
                _ChevronRow(
                  icon: Icons.password_outlined,
                  iconColor: accent,
                  title: 'Change Password',
                  subtitle: '',
                  onTap: () {},
                ),
                _ChevronRow(
                  icon: Icons.history_rounded,
                  iconColor: accent,
                  title: 'Login Activity',
                  subtitle: '',
                  onTap: () {},
                ),
              ],
            ),
            const SizedBox(height: 16),
            _Section(
              title: 'Support',
              icon: Icons.support_agent_outlined,
              accentColor: accent,
              children: [
                _ChevronRow(
                  icon: Icons.help_outline,
                  iconColor: accent,
                  title: 'Help Center',
                  subtitle: '',
                  onTap: () {},
                ),
                _ChevronRow(
                  icon: Icons.privacy_tip_outlined,
                  iconColor: accent,
                  title: 'Privacy Policy',
                  subtitle: '',
                  onTap: () {},
                ),
                _ChevronRow(
                  icon: Icons.article_outlined,
                  iconColor: accent,
                  title: 'Terms of Service',
                  subtitle: '',
                  onTap: () {},
                ),
              ],
            ),
            const SizedBox(height: 18),
            _DangerButton(
              color: accent,
              textColor: Colors.white,
              icon: Icons.logout,
              label: 'Logout',
              isLoading: _isLoggingOut,
              onPressed: _handleLogout,
            ),
            const SizedBox(height: 12),
            _DangerButton(
              color: const Color(0xFFFFD7D7),
              textColor: accent,
              icon: Icons.delete_outline,
              label: 'Delete Account',
              isLoading: _isDeletingAccount,
              onPressed: _handleDeleteAccount,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleLogout() async {
    if (_isLoggingOut) return;
    setState(() => _isLoggingOut = true);
    try {
      await _apiClient.logout();
    } finally {
      if (!mounted) return;
      setState(() => _isLoggingOut = false);
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (r) => false);
    }
  }

  Future<void> _handleDeleteAccount() async {
    if (_isDeletingAccount) return;
    setState(() => _isDeletingAccount = true);
    // TODO: connect to backend delete-account endpoint.
    await Future<void>.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;
    setState(() => _isDeletingAccount = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Delete account is not implemented yet.')),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color accentColor;
  final List<Widget> children;

  const _Section({
    required this.title,
    required this.icon,
    required this.accentColor,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 10),
          child: Row(
            children: [
              Icon(icon, size: 18, color: accentColor),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  color: accentColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
        ...children,
      ],
    );
  }
}

class _ToggleRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ToggleRow({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    const subtitleColor = Color(0xFF9B9B9F);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: SwitchListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 0),
        dense: true,
        value: value,
        onChanged: onChanged,
        secondary: Icon(icon, color: iconColor),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
        subtitle: subtitle.isEmpty
            ? null
            : Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 12,
                  color: subtitleColor,
                ),
              ),
      ),
    );
  }
}

class _ChevronRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ChevronRow({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const subtitleColor = Color(0xFF9B9B9F);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(icon, color: iconColor),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
        subtitle: subtitle.isEmpty
            ? null
            : Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 12,
                  color: subtitleColor,
                ),
              ),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}

class _DangerButton extends StatelessWidget {
  final Color color;
  final Color textColor;
  final IconData icon;
  final String label;
  final bool isLoading;
  final VoidCallback onPressed;

  const _DangerButton({
    required this.color,
    required this.textColor,
    required this.icon,
    required this.label,
    required this.isLoading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      style: FilledButton.styleFrom(
        backgroundColor: color,
        foregroundColor: textColor,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      icon: isLoading ? const SizedBox.shrink() : Icon(icon, size: 18),
      label: isLoading
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
      onPressed: isLoading ? null : onPressed,
    );
  }
}

