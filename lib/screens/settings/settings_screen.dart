import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../services/api_client.dart';
import '../../state/notification_preferences.dart';
import '../notifications/notifications_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  static const _accent = Color(0xFFFF4A4A);

  bool _notifPrefsLoading = true;
  bool _notifMaster = true;
  bool _notifMessages = true;
  bool _notifMentions = true;
  bool _notifCommissions = true;
  bool _notifEvents = true;
  bool _notifSocial = true;
  bool _notifSystem = true;

  bool _privateAccount = false;
  bool _privateSaving = false;

  bool _isLoggingOut = false;
  bool _isDeletingAccount = false;

  final ApiClient _apiClient = ApiClient();

  @override
  void initState() {
    super.initState();
    _hydrateNotificationPrefs();
    _loadAccountPrivacy();
  }

  Future<void> _loadAccountPrivacy() async {
    try {
      final me = await _apiClient.fetchMe();
      final u = me['user'];
      if (!mounted || u is! Map) return;
      final p = u['isPrivate'];
      if (p is bool) {
        setState(() => _privateAccount = p);
      }
    } catch (_) {}
  }

  Future<void> _hydrateNotificationPrefs() async {
    final m = await loadNotificationPrefs();
    if (!mounted) return;
    setState(() {
      _notifMaster = m[NotificationPrefKeys.master] ?? true;
      _notifMessages = m[NotificationPrefKeys.messages] ?? true;
      _notifMentions = m[NotificationPrefKeys.mentions] ?? true;
      _notifCommissions = m[NotificationPrefKeys.commissions] ?? true;
      _notifEvents = m[NotificationPrefKeys.events] ?? true;
      _notifSocial = m[NotificationPrefKeys.social] ?? true;
      _notifSystem = m[NotificationPrefKeys.system] ?? true;
      _notifPrefsLoading = false;
    });
  }

  Future<void> _setNotif(String key, bool value, VoidCallback applyState) async {
    applyState();
    await saveNotificationPref(key, value);
  }

  bool get _notifEnabled => _notifMaster;

  @override
  Widget build(BuildContext context) {
    final accent = _accent;
    final t = Theme.of(context).textTheme;
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
        title: Text(
          'Settings',
          style: t.titleLarge?.copyWith(
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
              title: 'Account',
              icon: Icons.person_outline_rounded,
              accentColor: accent,
              children: [
                _ChevronRow(
                  icon: Icons.badge_outlined,
                  iconColor: accent,
                  title: 'Edit profile',
                  subtitle: 'Username shown on posts and messages',
                  onTap: _openEditProfile,
                ),
                _ChevronRow(
                  icon: Icons.email_outlined,
                  iconColor: accent,
                  title: 'Email',
                  subtitle: 'Used for sign-in and account recovery',
                  onTap: _showEmailInfo,
                ),
                _ToggleRow(
                  icon: Icons.lock_person_outlined,
                  iconColor: accent,
                  title: 'Private account',
                  subtitle:
                      'Only followers can see your posts, DM you, or request commissions',
                  value: _privateAccount,
                  onChanged: _privateSaving
                      ? null
                      : (v) async {
                          setState(() {
                            _privateSaving = true;
                            _privateAccount = v;
                          });
                          try {
                            await _apiClient.updateProfile(isPrivate: v);
                          } catch (e) {
                            if (mounted) {
                              setState(() => _privateAccount = !v);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    e is ApiException
                                        ? e.message
                                        : 'Could not update privacy.',
                                  ),
                                ),
                              );
                            }
                          } finally {
                            if (mounted) {
                              setState(() => _privateSaving = false);
                            }
                          }
                        },
                ),
              ],
            ),
            const SizedBox(height: 16),
            _Section(
              title: 'Notifications',
              icon: Icons.notifications_none_outlined,
              accentColor: accent,
              children: [
                if (_notifPrefsLoading)
                  const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else ...[
                  _ChevronRow(
                    icon: Icons.inbox_outlined,
                    iconColor: accent,
                    title: 'Notification inbox',
                    subtitle: 'Everything that has arrived for you',
                    onTap: () {
                      Navigator.of(context).push<void>(
                        MaterialPageRoute<void>(
                          builder: (_) => const NotificationsScreen(),
                        ),
                      );
                    },
                  ),
                  _ToggleRow(
                    icon: Icons.notifications_active_outlined,
                    iconColor: accent,
                    title: 'In-app notification categories',
                    subtitle:
                        'Saved on this device; push delivery will respect these when enabled',
                    value: _notifMaster,
                    onChanged: (v) async {
                      await _setNotif(NotificationPrefKeys.master, v, () {
                        setState(() => _notifMaster = v);
                      });
                    },
                  ),
                  _ToggleRow(
                    icon: Icons.forum_outlined,
                    iconColor: accent,
                    title: 'Messages & chats',
                    subtitle: 'New direct messages and mentions in chat',
                    value: _notifMessages,
                    onChanged: !_notifEnabled
                        ? null
                        : (v) async {
                            await _setNotif(NotificationPrefKeys.messages, v, () {
                              setState(() => _notifMessages = v);
                            });
                          },
                  ),
                  _ToggleRow(
                    icon: Icons.alternate_email,
                    iconColor: accent,
                    title: 'Mentions',
                    subtitle: 'When someone @tags you in a post or comment',
                    value: _notifMentions,
                    onChanged: !_notifEnabled
                        ? null
                        : (v) async {
                            await _setNotif(NotificationPrefKeys.mentions, v, () {
                              setState(() => _notifMentions = v);
                            });
                          },
                  ),
                  _ToggleRow(
                    icon: Icons.palette_outlined,
                    iconColor: accent,
                    title: 'Commissions',
                    subtitle: 'Requests, acceptances, and status changes',
                    value: _notifCommissions,
                    onChanged: !_notifEnabled
                        ? null
                        : (v) async {
                            await _setNotif(NotificationPrefKeys.commissions, v, () {
                              setState(() => _notifCommissions = v);
                            });
                          },
                  ),
                  _ToggleRow(
                    icon: Icons.event_outlined,
                    iconColor: accent,
                    title: 'Events from people you follow',
                    subtitle: 'New or updated events by artists you follow',
                    value: _notifEvents,
                    onChanged: !_notifEnabled
                        ? null
                        : (v) async {
                            await _setNotif(NotificationPrefKeys.events, v, () {
                              setState(() => _notifEvents = v);
                            });
                          },
                  ),
                  _ToggleRow(
                    icon: Icons.favorite_border,
                    iconColor: accent,
                    title: 'Social',
                    subtitle: 'Likes, comments, and new followers',
                    value: _notifSocial,
                    onChanged: !_notifEnabled
                        ? null
                        : (v) async {
                            await _setNotif(NotificationPrefKeys.social, v, () {
                              setState(() => _notifSocial = v);
                            });
                          },
                  ),
                  _ToggleRow(
                    icon: Icons.campaign_outlined,
                    iconColor: accent,
                    title: 'System & announcements',
                    subtitle: 'Important updates from Brush&Coin',
                    value: _notifSystem,
                    onChanged: !_notifEnabled
                        ? null
                        : (v) async {
                            await _setNotif(NotificationPrefKeys.system, v, () {
                              setState(() => _notifSystem = v);
                            });
                          },
                  ),
                ],
              ],
            ),
            const SizedBox(height: 16),
            _Section(
              title: 'Appearance',
              icon: Icons.palette_outlined,
              accentColor: accent,
              children: [
                _ChevronRow(
                  icon: Icons.light_mode_outlined,
                  iconColor: accent,
                  title: 'Theme',
                  subtitle: 'Light (system dark mode coming later)',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Only Light theme is available for now.'),
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            _Section(
              title: 'About',
              icon: Icons.info_outline_rounded,
              accentColor: accent,
              children: [
                _ChevronRow(
                  icon: Icons.tag_outlined,
                  iconColor: accent,
                  title: 'Version',
                  subtitle: 'Brush&Coin mobile · 1.0.0',
                  onTap: () {
                    showAboutDialog(
                      context: context,
                      applicationName: 'Brush&Coin',
                      applicationVersion: '1.0.0',
                      applicationIcon: const Icon(Icons.brush, color: _accent, size: 32),
                      children: const [
                        SizedBox(height: 8),
                        Text(
                          'Commission and community tools for independent artists.',
                        ),
                      ],
                    );
                  },
                ),
                _ChevronRow(
                  icon: Icons.gavel_outlined,
                  iconColor: accent,
                  title: 'Open-source licenses',
                  subtitle: 'Third-party packages used in this app',
                  onTap: () {
                    Navigator.of(context).push<void>(
                      MaterialPageRoute<void>(
                        builder: (ctx) => LicensePage(
                          applicationName: 'Brush&Coin',
                          applicationVersion: '1.0.0',
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            _Section(
              title: 'Security',
              icon: Icons.shield_outlined,
              accentColor: accent,
              children: [
                _ChevronRow(
                  icon: Icons.password_rounded,
                  iconColor: accent,
                  title: 'Change Password',
                  subtitle: '',
                  onTap: _openChangePasswordInfo,
                ),
                _ChevronRow(
                  icon: Icons.manage_history_outlined,
                  iconColor: accent,
                  title: 'Login Activity',
                  subtitle: '',
                  onTap: _openLoginActivity,
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
                  icon: Icons.help_outline_rounded,
                  iconColor: accent,
                  title: 'Help Center',
                  subtitle: '',
                  onTap: _openHelpCenter,
                ),
                _ChevronRow(
                  icon: Icons.privacy_tip_outlined,
                  iconColor: accent,
                  title: 'Privacy Policy',
                  subtitle: '',
                  onTap: () => _showPrivacyPolicy(context),
                ),
                _ChevronRow(
                  icon: Icons.article_outlined,
                  iconColor: accent,
                  title: 'Terms of Service',
                  subtitle: '',
                  onTap: () => _showTermsOfService(context),
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

  Future<void> _openEditProfile() async {
    String? error;
    final controller = TextEditingController(
      text: await _apiClient.getCurrentUsername() ?? '',
    );
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: StatefulBuilder(
            builder: (ctx, setSheet) {
              return Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Edit profile',
                          style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(ctx),
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                    TextField(
                      controller: controller,
                      textInputAction: TextInputAction.done,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9_]')),
                      ],
                      decoration: InputDecoration(
                        labelText: 'Username',
                        errorText: error,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: () async {
                        final u = controller.text.trim();
                        if (u.length < 2) {
                          setSheet(() => error = 'Username must be at least 2 characters.');
                          return;
                        }
                        setSheet(() => error = null);
                        try {
                          await _apiClient.updateProfile(username: u);
                          if (ctx.mounted) Navigator.pop(ctx);
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Profile updated.')),
                            );
                          }
                        } on ApiException catch (e) {
                          setSheet(() => error = e.message);
                        } catch (_) {
                          setSheet(() => error = 'Could not save username.');
                        }
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: _accent,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Save'),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
    controller.dispose();
  }

  Future<void> _showEmailInfo() async {
    try {
      final me = await _apiClient.fetchMe();
      final email = (me['user'] as Map?)?['email']?.toString() ?? '—';
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Email'),
          content: Text(
            'Signed in as:\n$email\n\nEmail is set when you create your account. '
            'Contact support to change it in a future release.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not load account details.')),
      );
    }
  }

  void _openChangePasswordInfo() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.password_rounded, color: _accent),
                const SizedBox(width: 10),
                Text(
                  'Change password',
                  style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'In-app password changes are not available yet. Log out and use your recovery flow, '
              'or reach out through Help Center so we can point you to the right steps.',
              style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(height: 1.4),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.pop(ctx),
                style: FilledButton.styleFrom(
                  backgroundColor: _accent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Got it'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openLoginActivity() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.manage_history_outlined, color: _accent),
                const SizedBox(width: 10),
                Text(
                  'Login activity',
                  style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'We will list signed-in devices and recent sessions here. '
              'For now, logging out on this device ends your local session.',
              style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(height: 1.4),
            ),
            const SizedBox(height: 8),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.smartphone_outlined),
              title: const Text('This device'),
              subtitle: const Text('Active · Brush&Coin app'),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.pop(ctx),
                style: FilledButton.styleFrom(
                  backgroundColor: _accent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Close'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openHelpCenter() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final h = MediaQuery.of(ctx).size.height * 0.72;
        return Container(
          height: h,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 8, 0),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(ctx),
                      icon: const Icon(Icons.close),
                    ),
                    Text(
                      'Help Center',
                      style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                  children: [
                    Text(
                      'Getting started',
                      style: Theme.of(ctx).textTheme.titleSmall?.copyWith(
                            color: _accent,
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '• Complete your profile username so people can find and mention you.\n'
                      '• Post work with clear commission availability if you take client jobs.\n'
                      '• Use Messages for ongoing chats and Commissions for formal requests.',
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Commissions & payments',
                      style: Theme.of(ctx).textTheme.titleSmall?.copyWith(
                            color: _accent,
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '• Start a request from an artist profile; you can track status under Commissions.\n'
                      '• Always confirm scope, deadline, and payment method in writing before paying.',
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Events & feed',
                      style: Theme.of(ctx).textTheme.titleSmall?.copyWith(
                            color: _accent,
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '• Artists you follow can surface new events in your notifications.\n'
                      '• @mention someone in a post or comment to send them an in-app heads-up.',
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Still stuck?',
                      style: Theme.of(ctx).textTheme.titleSmall?.copyWith(
                            color: _accent,
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Use Privacy Policy / Terms below for legal questions. For product issues, note your account email and what you were trying to do — your team can wire a support address here later.',
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
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
    final theme = Theme.of(context);
    final passwordController = TextEditingController();
    String? errorText;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final viewInsets = MediaQuery.of(ctx).viewInsets.bottom;
        return Padding(
          padding: EdgeInsets.only(bottom: viewInsets),
          child: StatefulBuilder(
            builder: (context, setLocalState) {
              final sheetT = Theme.of(context).textTheme;
              return Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Delete Account',
                          style: sheetT.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.of(ctx).pop(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'This action is permanent. Please enter your password to confirm account deletion.',
                      style: theme.textTheme.bodySmall,
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: passwordController,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        errorText: errorText,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.of(ctx).pop(),
                            style: OutlinedButton.styleFrom(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text('Cancel'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton(
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFFFF4A4A),
                              padding:
                                  const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: _isDeletingAccount
                                ? null
                                : () async {
                                    final password =
                                        passwordController.text.trim();
                                    if (password.isEmpty) {
                                      setLocalState(() {
                                        errorText =
                                            'Please enter your password.';
                                      });
                                      return;
                                    }
                                    setLocalState(() {
                                      errorText = null;
                                    });
                                    setState(() => _isDeletingAccount = true);
                                    try {
                                      await _apiClient.deleteAccount(
                                        password: password,
                                      );
                                      if (!mounted) return;
                                      Navigator.of(ctx).pop();
                                      Navigator.of(context)
                                          .pushNamedAndRemoveUntil(
                                        '/login',
                                        (r) => false,
                                      );
                                    } on ApiException catch (e) {
                                      setLocalState(() {
                                        errorText = e.message;
                                      });
                                    } catch (_) {
                                      setLocalState(() {
                                        errorText =
                                            'Failed to delete account. Please try again.';
                                      });
                                    } finally {
                                      if (mounted) {
                                        setState(
                                            () => _isDeletingAccount = false);
                                      }
                                    }
                                  },
                            child: _isDeletingAccount
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text('Delete'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}

void _showTermsOfService(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) {
      final height = MediaQuery.of(ctx).size.height * 0.9;
      return Container(
        height: height,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    icon: const Icon(Icons.arrow_back),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Terms of Service',
                    style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: const SingleChildScrollView(
                  child: _TermsOfServiceContent(),
                ),
              ),
            ),
          ],
        ),
      );
    },
  );
}

void _showPrivacyPolicy(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) {
      final height = MediaQuery.of(ctx).size.height * 0.9;
      return Container(
        height: height,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    icon: const Icon(Icons.arrow_back),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Privacy Policy',
                    style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: const SingleChildScrollView(
                  child: _PrivacyPolicyContent(),
                ),
              ),
            ),
          ],
        ),
      );
    },
  );
}

class _TermsOfServiceContent extends StatelessWidget {
  const _TermsOfServiceContent();

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'TERMS OF SERVICE',
          style: t.titleMedium?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 8),
        Text(
          'Brush&Coin: A Mobile Commission Platform for Independent Artists in Secure and Community-Based Art Commerce',
          style: t.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 16),
        const _TosSection(
          heading: '1. Acceptance of Terms',
          body:
              'By accessing, downloading, installing, or using the Brush&Coin mobile application (“the Service”), you acknowledge that you have read, understood, and agreed to be bound by these Terms of Service. These terms constitute a legally binding agreement between you (“the User”) and the developers of Brush&Coin. If you do not agree with any part of these terms, you must discontinue use of the Service immediately. Continued use of the Service after any updates or modifications shall constitute your acceptance of the revised Terms of Service.',
        ),
        const _TosSection(
          heading: '2. Description of the Service',
          body:
              'Brush&Coin is a mobile-first digital platform designed to connect independent artists and clients by providing tools for portfolio presentation, commission-based transactions, messaging, tipping, and local artist discovery. The Service acts solely as an intermediary platform that facilitates interactions and transactions between users. Brush&Coin does not create, sell, or deliver artworks and does not act as a party to any agreement formed between users. All transactions, agreements, and interactions are conducted at the discretion and responsibility of the users involved.',
        ),
        const _TosSection(
          heading: '3. Eligibility and User Accounts',
          body:
              'To use the Service, users must register for an account and provide accurate, complete, and up-to-date information. By creating an account, you represent that you are legally capable of entering into a binding agreement under applicable laws. Users are responsible for maintaining the confidentiality of their login credentials and for all activities conducted under their accounts. Brush&Coin shall not be liable for any loss or damage resulting from unauthorized access to user accounts. The platform reserves the right to suspend or terminate accounts that contain false information or violate these Terms of Service.',
        ),
        const _TosSection(
          heading: '4. Use of the Service',
          body:
              'Users agree to use the Service only for lawful purposes and in accordance with these Terms. The platform provides features such as commission requests, payment facilitation, messaging, event listings, and content sharing. Users must not misuse these features or attempt to exploit the platform in ways that could harm other users or the integrity of the Service. Brush&Coin reserves the right to monitor usage patterns and restrict access to features when misuse or abuse is detected.',
        ),
        const _TosSection(
          heading: '5. Artist and Client Responsibilities',
          body:
              'Users may participate as artists, clients, or both, and are expected to uphold professionalism and integrity in all interactions. Artists are responsible for accurately presenting their work, pricing, and commission terms, as well as delivering agreed outputs within the specified timeframe. Clients are responsible for providing clear commission requirements, honoring agreed payments, and maintaining respectful communication. Both parties acknowledge that commission agreements are formed independently between users and that Brush&Coin does not enforce or guarantee fulfillment of such agreements.',
        ),
        const _TosSection(
          heading: '6. Payments and Financial Transactions',
          body:
              'The Service may integrate or simulate payment systems using third-party providers such as GCash, PayMaya, PayPal, or Stripe. By using these features, users agree to comply with the terms and policies of the respective payment providers. Brush&Coin may implement an escrow-style mechanism to temporarily hold funds until agreed conditions are met; however, this system may be simulated and does not constitute a formally regulated financial service. The platform is not responsible for transaction failures, delays, or disputes arising from third-party payment systems.',
        ),
        const _TosSection(
          heading: '7. Commissions, Escrow, and Disputes',
          body:
              'Commission transactions conducted through the Service may involve milestone-based agreements where funds are released upon approval of completed work. Users are responsible for clearly defining terms such as deliverables, timelines, revisions, and payment structure before entering into a commission. In the event of disputes, Brush&Coin may provide mediation support; however, the platform does not guarantee resolution outcomes and is not legally liable for conflicts between users. All parties agree to attempt to resolve disputes in good faith.',
        ),
        const _TosSection(
          heading: '8. Refunds and Cancellations',
          body:
              'Refunds and cancellations are subject to the agreement established between the artist and the client prior to the transaction. The platform does not impose a universal refund policy and does not guarantee reimbursement. Users are encouraged to clearly define refund terms within their commission agreements. Brush&Coin may assist in facilitating communication during disputes but is not obligated to enforce refund decisions.',
        ),
        const _TosSection(
          heading: '9. Intellectual Property',
          body:
              'All intellectual property rights remain with the original creator unless explicitly transferred through a written agreement. Clients are granted only the rights specified in the commission agreement and may not reproduce or distribute the work beyond those terms. Users must ensure that all content uploaded to the Service is original or properly authorized. Brush&Coin reserves the right to remove content that violates intellectual property laws or infringes upon the rights of others.',
        ),
        const _TosSection(
          heading: '10. User Content and Conduct',
          body:
              'Users may upload and share content within the Service, including artwork, descriptions, and messages. By submitting content, users grant Brush&Coin a limited, non-exclusive license to display and use such content for platform operations. Users agree not to upload content that is illegal, offensive, misleading, or harmful. The platform reserves the right to remove content and take action against users who violate these standards without prior notice.',
        ),
        const _TosSection(
          heading: '11. Privacy and Data Usage',
          body:
              'The Service collects and processes user data necessary for functionality, including account management, communication, and transaction facilitation. By using the Service, users consent to the collection and use of their data in accordance with applicable data protection laws. While Brush&Coin implements reasonable security measures, it does not guarantee absolute protection against unauthorized access or breaches.',
        ),
        const _TosSection(
          heading: '12. Prohibited Activities',
          body:
              'Users agree not to engage in activities that compromise the integrity of the Service, including fraud, impersonation, harassment, unauthorized transactions, or attempts to bypass system safeguards. Any violation may result in suspension or permanent termination of the user’s account. Brush&Coin reserves the right to take appropriate legal action where necessary.',
        ),
        const _TosSection(
          heading: '13. Service Availability and Modifications',
          body:
              'Brush&Coin reserves the right to modify, suspend, or discontinue any aspect of the Service at any time without prior notice. The platform does not guarantee uninterrupted or error-free operation. Users acknowledge that features may change as part of ongoing development and improvement.',
        ),
        const _TosSection(
          heading: '14. Limitation of Liability',
          body:
              'To the fullest extent permitted by law, Brush&Coin shall not be held liable for any damages arising from the use or inability to use the Service, including but not limited to financial loss, data loss, or disputes between users. The Service is provided on an “as is” and “as available” basis without warranties of any kind.',
        ),
        const _TosSection(
          heading: '15. Termination',
          body:
              'Brush&Coin reserves the right to suspend or terminate user access to the Service at its discretion, particularly in cases of violations of these Terms of Service or actions deemed harmful to the platform or its users. Upon termination, users must cease all use of the Service.',
        ),
        const _TosSection(
          heading: '16. Governing Law',
          body:
              'These Terms of Service shall be governed by and interpreted in accordance with the laws of the Republic of the Philippines. Any disputes arising from these terms shall be subject to the jurisdiction of the appropriate courts within the Philippines.',
        ),
        const _TosSection(
          heading: '17. Contact Information',
          body:
              'For questions, concerns, or clarifications regarding these Terms of Service, users may contact the Brush&Coin development team through the official communication channels provided within the application.',
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

class _PrivacyPolicyContent extends StatelessWidget {
  const _PrivacyPolicyContent();

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'PRIVACY POLICY',
          style: t.titleMedium?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 8),
        Text(
          'Brush&Coin: A Mobile Commission Platform for Independent Artists in Secure and Community-Based Art Commerce',
          style: t.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 16),
        const _TosSection(
          heading: '1. Introduction',
          body:
              'Brush&Coin (“the Application”) is committed to protecting the privacy and personal data of its users. This Privacy Policy explains how user information is collected, used, stored, and protected when accessing or using the Application. By using Brush&Coin, you consent to the practices described in this policy. This policy is designed in accordance with applicable data protection laws, including the Data Privacy Act of 2012 (Republic Act No. 10173) of the Philippines.',
        ),
        const _TosSection(
          heading: '2. Information We Collect',
          body:
              'The Application collects personal and non-personal information necessary to provide its services effectively. Personal information may include, but is not limited to, your name, email address, username, profile details, and any other information voluntarily provided during account registration or profile creation. In addition, transactional data such as commission details, payment references, and communication records between users may be collected to facilitate platform functionality. The Application may also collect device-related information such as IP address, device type, operating system, and usage data to improve system performance and user experience.',
        ),
        const _TosSection(
          heading: '3. How We Use Information',
          body:
              'The information collected is used to operate, maintain, and improve the Application’s services. This includes facilitating user authentication, enabling communication between artists and clients, processing transactions, managing commissions, and providing customer support. Data may also be used for analytics purposes to understand user behavior, enhance features, and improve overall system performance. Brush&Coin may use certain information to send notifications, updates, or important service-related announcements.',
        ),
        const _TosSection(
          heading: '4. Sharing and Disclosure of Information',
          body:
              'Brush&Coin does not sell or rent user personal data to third parties. However, user information may be shared with trusted third-party service providers, such as payment processors, solely for the purpose of facilitating transactions and delivering core functionalities of the Application. These third parties are required to maintain the confidentiality and security of user data. Information may also be disclosed if required by law, regulation, or legal process, or if necessary to protect the rights, safety, and integrity of the platform and its users.',
        ),
        const _TosSection(
          heading: '5. Data Storage and Security',
          body:
              'The Application implements reasonable administrative, technical, and physical security measures to protect user data against unauthorized access, alteration, disclosure, or destruction. Data may be stored on secure servers and protected using encryption and authentication protocols. While Brush&Coin strives to safeguard user information, no system can guarantee absolute security, and users acknowledge that they provide information at their own risk.',
        ),
        const _TosSection(
          heading: '6. User Rights',
          body:
              'Users have the right to access, update, correct, or request deletion of their personal data, subject to applicable legal and contractual obligations. Users may also withdraw consent for data processing where applicable, although doing so may affect their ability to use certain features of the Application. Requests related to personal data may be submitted through the platform’s official communication channels.',
        ),
        const _TosSection(
          heading: '7. Cookies and Tracking Technologies',
          body:
              'The Application may use cookies or similar tracking technologies to enhance user experience, remember preferences, and analyze usage patterns. These technologies help improve system functionality and provide personalized features. Users may manage or disable such technologies through their device settings, although this may limit certain functionalities of the Application.',
        ),
        const _TosSection(
          heading: '8. Data Retention',
          body:
              'Brush&Coin retains user information only for as long as necessary to fulfill the purposes outlined in this Privacy Policy, comply with legal obligations, resolve disputes, and enforce agreements. When data is no longer required, reasonable steps will be taken to securely delete or anonymize it.',
        ),
        const _TosSection(
          heading: '9. Third-Party Links and Services',
          body:
              'The Application may contain links to third-party services or integrate external platforms such as payment gateways. Brush&Coin is not responsible for the privacy practices or content of these third-party services. Users are encouraged to review the privacy policies of any external platforms they interact with.',
        ),
        const _TosSection(
          heading: '10. Children’s Privacy',
          body:
              'The Application is not intended for use by individuals who are not legally capable of entering into a binding agreement under applicable laws. Brush&Coin does not knowingly collect personal information from minors without appropriate consent. If such data is identified, it will be promptly removed.',
        ),
        const _TosSection(
          heading: '11. Changes to the Privacy Policy',
          body:
              'Brush&Coin reserves the right to update or modify this Privacy Policy at any time. Any changes will be reflected within the Application, and continued use of the Service after such updates constitutes acceptance of the revised policy. Users are encouraged to review this Privacy Policy periodically.',
        ),
        const _TosSection(
          heading: '12. Contact Information',
          body:
              'For questions, concerns, or requests regarding this Privacy Policy or the handling of personal data, users may contact the Brush&Coin development team through the official communication channels provided within the Application.',
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

class _TosSection extends StatelessWidget {
  final String heading;
  final String body;

  const _TosSection({
    required this.heading,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            heading,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            body,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  height: 1.4,
                ),
          ),
        ],
      ),
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
    final t = Theme.of(context).textTheme;
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
                style: t.titleSmall?.copyWith(
                  color: accentColor,
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
  final ValueChanged<bool>? onChanged;

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
    final t = Theme.of(context).textTheme;
    final muted = onChanged == null;
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
        activeTrackColor: iconColor,
        activeThumbColor: Colors.white,
        inactiveTrackColor: const Color(0xFFE8E8EC),
        inactiveThumbColor: const Color(0xFF9E9EA3),
        secondary: Icon(icon, color: iconColor),
        title: Text(
          title,
          style: t.titleSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        subtitle: subtitle.isEmpty
            ? null
            : Text(
                subtitle,
                style: t.bodySmall?.copyWith(
                  color: muted
                      ? subtitleColor.withValues(alpha: 0.72)
                      : subtitleColor,
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
    final t = Theme.of(context).textTheme;
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
          style: t.titleSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        subtitle: subtitle.isEmpty
            ? null
            : Text(
                subtitle,
                style: t.bodySmall?.copyWith(color: subtitleColor),
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
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
      onPressed: isLoading ? null : onPressed,
    );
  }
}

