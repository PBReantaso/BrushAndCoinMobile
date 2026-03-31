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
                        const Text(
                          'Delete Account',
                          style: TextStyle(
                            fontSize: 18,
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
                  const Text(
                    'Terms of Service',
                    style: TextStyle(
                      fontSize: 18,
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
                  const Text(
                    'Privacy Policy',
                    style: TextStyle(
                      fontSize: 18,
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        Text(
          'TERMS OF SERVICE',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
          ),
        ),
        SizedBox(height: 8),
        Text(
          'Brush&Coin: A Mobile Commission Platform for Independent Artists in Secure and Community-Based Art Commerce',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 16),
        _TosSection(
          heading: '1. Acceptance of Terms',
          body:
              'By accessing, downloading, installing, or using the Brush&Coin mobile application (“the Service”), you acknowledge that you have read, understood, and agreed to be bound by these Terms of Service. These terms constitute a legally binding agreement between you (“the User”) and the developers of Brush&Coin. If you do not agree with any part of these terms, you must discontinue use of the Service immediately. Continued use of the Service after any updates or modifications shall constitute your acceptance of the revised Terms of Service.',
        ),
        _TosSection(
          heading: '2. Description of the Service',
          body:
              'Brush&Coin is a mobile-first digital platform designed to connect independent artists and clients by providing tools for portfolio presentation, commission-based transactions, messaging, tipping, and local artist discovery. The Service acts solely as an intermediary platform that facilitates interactions and transactions between users. Brush&Coin does not create, sell, or deliver artworks and does not act as a party to any agreement formed between users. All transactions, agreements, and interactions are conducted at the discretion and responsibility of the users involved.',
        ),
        _TosSection(
          heading: '3. Eligibility and User Accounts',
          body:
              'To use the Service, users must register for an account and provide accurate, complete, and up-to-date information. By creating an account, you represent that you are legally capable of entering into a binding agreement under applicable laws. Users are responsible for maintaining the confidentiality of their login credentials and for all activities conducted under their accounts. Brush&Coin shall not be liable for any loss or damage resulting from unauthorized access to user accounts. The platform reserves the right to suspend or terminate accounts that contain false information or violate these Terms of Service.',
        ),
        _TosSection(
          heading: '4. Use of the Service',
          body:
              'Users agree to use the Service only for lawful purposes and in accordance with these Terms. The platform provides features such as commission requests, payment facilitation, messaging, event listings, and content sharing. Users must not misuse these features or attempt to exploit the platform in ways that could harm other users or the integrity of the Service. Brush&Coin reserves the right to monitor usage patterns and restrict access to features when misuse or abuse is detected.',
        ),
        _TosSection(
          heading: '5. Artist and Client Responsibilities',
          body:
              'Users may participate as artists, clients, or both, and are expected to uphold professionalism and integrity in all interactions. Artists are responsible for accurately presenting their work, pricing, and commission terms, as well as delivering agreed outputs within the specified timeframe. Clients are responsible for providing clear commission requirements, honoring agreed payments, and maintaining respectful communication. Both parties acknowledge that commission agreements are formed independently between users and that Brush&Coin does not enforce or guarantee fulfillment of such agreements.',
        ),
        _TosSection(
          heading: '6. Payments and Financial Transactions',
          body:
              'The Service may integrate or simulate payment systems using third-party providers such as GCash, PayMaya, PayPal, or Stripe. By using these features, users agree to comply with the terms and policies of the respective payment providers. Brush&Coin may implement an escrow-style mechanism to temporarily hold funds until agreed conditions are met; however, this system may be simulated and does not constitute a formally regulated financial service. The platform is not responsible for transaction failures, delays, or disputes arising from third-party payment systems.',
        ),
        _TosSection(
          heading: '7. Commissions, Escrow, and Disputes',
          body:
              'Commission transactions conducted through the Service may involve milestone-based agreements where funds are released upon approval of completed work. Users are responsible for clearly defining terms such as deliverables, timelines, revisions, and payment structure before entering into a commission. In the event of disputes, Brush&Coin may provide mediation support; however, the platform does not guarantee resolution outcomes and is not legally liable for conflicts between users. All parties agree to attempt to resolve disputes in good faith.',
        ),
        _TosSection(
          heading: '8. Refunds and Cancellations',
          body:
              'Refunds and cancellations are subject to the agreement established between the artist and the client prior to the transaction. The platform does not impose a universal refund policy and does not guarantee reimbursement. Users are encouraged to clearly define refund terms within their commission agreements. Brush&Coin may assist in facilitating communication during disputes but is not obligated to enforce refund decisions.',
        ),
        _TosSection(
          heading: '9. Intellectual Property',
          body:
              'All intellectual property rights remain with the original creator unless explicitly transferred through a written agreement. Clients are granted only the rights specified in the commission agreement and may not reproduce or distribute the work beyond those terms. Users must ensure that all content uploaded to the Service is original or properly authorized. Brush&Coin reserves the right to remove content that violates intellectual property laws or infringes upon the rights of others.',
        ),
        _TosSection(
          heading: '10. User Content and Conduct',
          body:
              'Users may upload and share content within the Service, including artwork, descriptions, and messages. By submitting content, users grant Brush&Coin a limited, non-exclusive license to display and use such content for platform operations. Users agree not to upload content that is illegal, offensive, misleading, or harmful. The platform reserves the right to remove content and take action against users who violate these standards without prior notice.',
        ),
        _TosSection(
          heading: '11. Privacy and Data Usage',
          body:
              'The Service collects and processes user data necessary for functionality, including account management, communication, and transaction facilitation. By using the Service, users consent to the collection and use of their data in accordance with applicable data protection laws. While Brush&Coin implements reasonable security measures, it does not guarantee absolute protection against unauthorized access or breaches.',
        ),
        _TosSection(
          heading: '12. Prohibited Activities',
          body:
              'Users agree not to engage in activities that compromise the integrity of the Service, including fraud, impersonation, harassment, unauthorized transactions, or attempts to bypass system safeguards. Any violation may result in suspension or permanent termination of the user’s account. Brush&Coin reserves the right to take appropriate legal action where necessary.',
        ),
        _TosSection(
          heading: '13. Service Availability and Modifications',
          body:
              'Brush&Coin reserves the right to modify, suspend, or discontinue any aspect of the Service at any time without prior notice. The platform does not guarantee uninterrupted or error-free operation. Users acknowledge that features may change as part of ongoing development and improvement.',
        ),
        _TosSection(
          heading: '14. Limitation of Liability',
          body:
              'To the fullest extent permitted by law, Brush&Coin shall not be held liable for any damages arising from the use or inability to use the Service, including but not limited to financial loss, data loss, or disputes between users. The Service is provided on an “as is” and “as available” basis without warranties of any kind.',
        ),
        _TosSection(
          heading: '15. Termination',
          body:
              'Brush&Coin reserves the right to suspend or terminate user access to the Service at its discretion, particularly in cases of violations of these Terms of Service or actions deemed harmful to the platform or its users. Upon termination, users must cease all use of the Service.',
        ),
        _TosSection(
          heading: '16. Governing Law',
          body:
              'These Terms of Service shall be governed by and interpreted in accordance with the laws of the Republic of the Philippines. Any disputes arising from these terms shall be subject to the jurisdiction of the appropriate courts within the Philippines.',
        ),
        _TosSection(
          heading: '17. Contact Information',
          body:
              'For questions, concerns, or clarifications regarding these Terms of Service, users may contact the Brush&Coin development team through the official communication channels provided within the application.',
        ),
        SizedBox(height: 16),
      ],
    );
  }
}

class _PrivacyPolicyContent extends StatelessWidget {
  const _PrivacyPolicyContent();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        Text(
          'PRIVACY POLICY',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
          ),
        ),
        SizedBox(height: 8),
        Text(
          'Brush&Coin: A Mobile Commission Platform for Independent Artists in Secure and Community-Based Art Commerce',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 16),
        _TosSection(
          heading: '1. Introduction',
          body:
              'Brush&Coin (“the Application”) is committed to protecting the privacy and personal data of its users. This Privacy Policy explains how user information is collected, used, stored, and protected when accessing or using the Application. By using Brush&Coin, you consent to the practices described in this policy. This policy is designed in accordance with applicable data protection laws, including the Data Privacy Act of 2012 (Republic Act No. 10173) of the Philippines.',
        ),
        _TosSection(
          heading: '2. Information We Collect',
          body:
              'The Application collects personal and non-personal information necessary to provide its services effectively. Personal information may include, but is not limited to, your name, email address, username, profile details, and any other information voluntarily provided during account registration or profile creation. In addition, transactional data such as commission details, payment references, and communication records between users may be collected to facilitate platform functionality. The Application may also collect device-related information such as IP address, device type, operating system, and usage data to improve system performance and user experience.',
        ),
        _TosSection(
          heading: '3. How We Use Information',
          body:
              'The information collected is used to operate, maintain, and improve the Application’s services. This includes facilitating user authentication, enabling communication between artists and clients, processing transactions, managing commissions, and providing customer support. Data may also be used for analytics purposes to understand user behavior, enhance features, and improve overall system performance. Brush&Coin may use certain information to send notifications, updates, or important service-related announcements.',
        ),
        _TosSection(
          heading: '4. Sharing and Disclosure of Information',
          body:
              'Brush&Coin does not sell or rent user personal data to third parties. However, user information may be shared with trusted third-party service providers, such as payment processors, solely for the purpose of facilitating transactions and delivering core functionalities of the Application. These third parties are required to maintain the confidentiality and security of user data. Information may also be disclosed if required by law, regulation, or legal process, or if necessary to protect the rights, safety, and integrity of the platform and its users.',
        ),
        _TosSection(
          heading: '5. Data Storage and Security',
          body:
              'The Application implements reasonable administrative, technical, and physical security measures to protect user data against unauthorized access, alteration, disclosure, or destruction. Data may be stored on secure servers and protected using encryption and authentication protocols. While Brush&Coin strives to safeguard user information, no system can guarantee absolute security, and users acknowledge that they provide information at their own risk.',
        ),
        _TosSection(
          heading: '6. User Rights',
          body:
              'Users have the right to access, update, correct, or request deletion of their personal data, subject to applicable legal and contractual obligations. Users may also withdraw consent for data processing where applicable, although doing so may affect their ability to use certain features of the Application. Requests related to personal data may be submitted through the platform’s official communication channels.',
        ),
        _TosSection(
          heading: '7. Cookies and Tracking Technologies',
          body:
              'The Application may use cookies or similar tracking technologies to enhance user experience, remember preferences, and analyze usage patterns. These technologies help improve system functionality and provide personalized features. Users may manage or disable such technologies through their device settings, although this may limit certain functionalities of the Application.',
        ),
        _TosSection(
          heading: '8. Data Retention',
          body:
              'Brush&Coin retains user information only for as long as necessary to fulfill the purposes outlined in this Privacy Policy, comply with legal obligations, resolve disputes, and enforce agreements. When data is no longer required, reasonable steps will be taken to securely delete or anonymize it.',
        ),
        _TosSection(
          heading: '9. Third-Party Links and Services',
          body:
              'The Application may contain links to third-party services or integrate external platforms such as payment gateways. Brush&Coin is not responsible for the privacy practices or content of these third-party services. Users are encouraged to review the privacy policies of any external platforms they interact with.',
        ),
        _TosSection(
          heading: '10. Children’s Privacy',
          body:
              'The Application is not intended for use by individuals who are not legally capable of entering into a binding agreement under applicable laws. Brush&Coin does not knowingly collect personal information from minors without appropriate consent. If such data is identified, it will be promptly removed.',
        ),
        _TosSection(
          heading: '11. Changes to the Privacy Policy',
          body:
              'Brush&Coin reserves the right to update or modify this Privacy Policy at any time. Any changes will be reflected within the Application, and continued use of the Service after such updates constitutes acceptance of the revised policy. Users are encouraged to review this Privacy Policy periodically.',
        ),
        _TosSection(
          heading: '12. Contact Information',
          body:
              'For questions, concerns, or requests regarding this Privacy Policy or the handling of personal data, users may contact the Brush&Coin development team through the official communication channels provided within the Application.',
        ),
        SizedBox(height: 16),
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
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            body,
            style: const TextStyle(
              fontSize: 13,
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

