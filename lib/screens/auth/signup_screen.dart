import 'package:flutter/material.dart';

import '../../services/api_client.dart';
import '../../widgets/auth/auth_styles.dart';
import '../../widgets/auth/google_button.dart';
import '../../widgets/auth/or_divider.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _apiClient = ApiClient();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _retypeController = TextEditingController();

  bool _agree = false;
  bool _obscurePassword = true;
  bool _obscureRetype = true;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _retypeController.dispose();
    super.dispose();
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _signUp() async {
    if (_passwordController.text != _retypeController.text) {
      _showSnack('Passwords do not match.');
      return;
    }
    if (!_agree) {
      _showSnack('Please agree to the terms first.');
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      await _apiClient.signup(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        rememberMe: true,
      );
      if (!mounted) {
        return;
      }
      Navigator.pushReplacementNamed(context, '/onboarding');
    } on ApiException catch (e) {
      if (!mounted) {
        return;
      }
      _showSnack(e.message);
    } catch (e) {
      if (!mounted) {
        return;
      }
      _showSnack(
        'Cannot reach API (${e.runtimeType}). '
        'On a real phone use: '
        'flutter run --dart-define=API_BASE_URL=http://YOUR_PC_IP:4000',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 6),
              const Text('Hello', style: AuthTextStyles.headlineRed),
              const Text('Art Lover!', style: AuthTextStyles.headlineBlack),
              const SizedBox(height: 26),
              const Text('Email', style: AuthTextStyles.fieldLabel),
              const SizedBox(height: 6),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: authInputDecoration(
                  hintText: 'Enter your mail/phone number',
                ),
              ),
              const SizedBox(height: 14),
              const Text('Password', style: AuthTextStyles.fieldLabel),
              const SizedBox(height: 6),
              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: authInputDecoration(
                  hintText: 'Create password',
                  suffixIcon: IconButton(
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: Colors.black54,
                      size: 20,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              const Text('Re-type Password', style: AuthTextStyles.fieldLabel),
              const SizedBox(height: 6),
              TextField(
                controller: _retypeController,
                obscureText: _obscureRetype,
                decoration: authInputDecoration(
                  hintText: 'Re-type your password',
                  suffixIcon: IconButton(
                    onPressed: () {
                      setState(() {
                        _obscureRetype = !_obscureRetype;
                      });
                    },
                    icon: Icon(
                      _obscureRetype
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: Colors.black54,
                      size: 20,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: Checkbox(
                      value: _agree,
                      activeColor: AuthColors.primaryRed,
                      side: const BorderSide(color: AuthColors.borderGray),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                      onChanged: (value) {
                        setState(() {
                          _agree = value ?? false;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Wrap(
                      children: [
                        const Text(
                          'By signing up, you agree to our ',
                          style:
                              TextStyle(fontSize: 12, color: Colors.black54),
                        ),
                        GestureDetector(
                          onTap: () => _showLegalSheet(context),
                          child: const Text(
                            'Terms of Service & Privacy Policy',
                            style: TextStyle(
                              fontSize: 12,
                              color: AuthColors.primaryRed,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ElevatedButton(
                style: primaryPillButtonStyle(),
                onPressed: _isSubmitting ? null : _signUp,
                child: Text(_isSubmitting ? 'Creating account...' : 'Sign-Up'),
              ),
              const SizedBox(height: 18),
              const OrDivider(),
              const SizedBox(height: 18),
              GoogleAuthButton(
                label: 'Sign-Up using Google',
                onPressed: () => Navigator.pushReplacementNamed(
                  context,
                  '/onboarding',
                ),
              ),
              const SizedBox(height: 18),
              Center(
                child: Text.rich(
                  TextSpan(
                    text: 'Already have an account? ',
                    style: const TextStyle(fontSize: 12, color: Colors.black54),
                    children: [
                      WidgetSpan(
                        alignment: PlaceholderAlignment.baseline,
                        baseline: TextBaseline.alphabetic,
                        child: GestureDetector(
                          onTap: () => Navigator.pushReplacementNamed(
                            context,
                            '/login',
                          ),
                          child: const Text(
                            'Sign In',
                            style: TextStyle(
                              fontSize: 12,
                              color: AuthColors.primaryRed,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum LegalTab { terms, privacy }

class _LegalSection extends StatelessWidget {
  final String heading;
  final String body;

  const _LegalSection({required this.heading, required this.body});

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

void _showLegalSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) {
      final height = MediaQuery.of(ctx).size.height * 0.9;
      return _LegalSheetContainer(height: height);
    },
  );
}

class _LegalSheetContainer extends StatefulWidget {
  final double height;

  const _LegalSheetContainer({required this.height});

  @override
  State<_LegalSheetContainer> createState() => _LegalSheetContainerState();
}

class _LegalSheetContainerState extends State<_LegalSheetContainer> {
  LegalTab _tab = LegalTab.terms;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: widget.height,
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
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.arrow_back),
                ),
                const SizedBox(width: 4),
                const Text(
                  'Legal',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              children: [
                Expanded(
                  child: _LegalTabChip(
                    label: 'Terms of Service',
                    selected: _tab == LegalTab.terms,
                    onTap: () => setState(() => _tab = LegalTab.terms),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _LegalTabChip(
                    label: 'Privacy Policy',
                    selected: _tab == LegalTab.privacy,
                    onTap: () => setState(() => _tab = LegalTab.privacy),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: SingleChildScrollView(
                child: _tab == LegalTab.terms
                    ? const _SignUpTermsContent()
                    : const _SignUpPrivacyContent(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LegalTabChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _LegalTabChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bg = selected ? AuthColors.primaryRed : const Color(0xFFF3F3F6);
    final fg = selected ? Colors.white : Colors.black87;

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        height: 48,
        width: double.infinity,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: fg,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}

class _SignUpTermsContent extends StatelessWidget {
  const _SignUpTermsContent();

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
        _LegalSection(
          heading: '1. Acceptance of Terms',
          body:
              'By accessing, downloading, installing, or using the Brush&Coin mobile application (“the Service”), you acknowledge that you have read, understood, and agreed to be bound by these Terms of Service. These terms constitute a legally binding agreement between you (“the User”) and the developers of Brush&Coin. If you do not agree with any part of these terms, you must discontinue use of the Service immediately. Continued use of the Service after any updates or modifications shall constitute your acceptance of the revised Terms of Service.',
        ),
        _LegalSection(
          heading: '2. Description of the Service',
          body:
              'Brush&Coin is a mobile-first digital platform designed to connect independent artists and clients by providing tools for portfolio presentation, commission-based transactions, messaging, tipping, and local artist discovery. The Service acts solely as an intermediary platform that facilitates interactions and transactions between users. Brush&Coin does not create, sell, or deliver artworks and does not act as a party to any agreement formed between users. All transactions, agreements, and interactions are conducted at the discretion and responsibility of the users involved.',
        ),
        _LegalSection(
          heading: '3. Eligibility and User Accounts',
          body:
              'To use the Service, users must register for an account and provide accurate, complete, and up-to-date information. By creating an account, you represent that you are legally capable of entering into a binding agreement under applicable laws. Users are responsible for maintaining the confidentiality of their login credentials and for all activities conducted under their accounts. Brush&Coin shall not be liable for any loss or damage resulting from unauthorized access to user accounts. The platform reserves the right to suspend or terminate accounts that contain false information or violate these Terms of Service.',
        ),
        _LegalSection(
          heading: '4. Use of the Service',
          body:
              'Users agree to use the Service only for lawful purposes and in accordance with these Terms. The platform provides features such as commission requests, payment facilitation, messaging, event listings, and content sharing. Users must not misuse these features or attempt to exploit the platform in ways that could harm other users or the integrity of the Service. Brush&Coin reserves the right to monitor usage patterns and restrict access to features when misuse or abuse is detected.',
        ),
        _LegalSection(
          heading: '5. Artist and Client Responsibilities',
          body:
              'Users may participate as artists, clients, or both, and are expected to uphold professionalism and integrity in all interactions. Artists are responsible for accurately presenting their work, pricing, and commission terms, as well as delivering agreed outputs within the specified timeframe. Clients are responsible for providing clear commission requirements, honoring agreed payments, and maintaining respectful communication. Both parties acknowledge that commission agreements are formed independently between users and that Brush&Coin does not enforce or guarantee fulfillment of such agreements.',
        ),
        _LegalSection(
          heading: '6. Payments and Financial Transactions',
          body:
              'The Service may integrate or simulate payment systems using third-party providers such as GCash, PayMaya, PayPal, or Stripe. By using these features, users agree to comply with the terms and policies of the respective payment providers. Brush&Coin may implement an escrow-style mechanism to temporarily hold funds until agreed conditions are met; however, this system may be simulated and does not constitute a formally regulated financial service. The platform is not responsible for transaction failures, delays, or disputes arising from third-party payment systems.',
        ),
        _LegalSection(
          heading: '7. Commissions, Escrow, and Disputes',
          body:
              'Commission transactions conducted through the Service may involve milestone-based agreements where funds are released upon approval of completed work. Users are responsible for clearly defining terms such as deliverables, timelines, revisions, and payment structure before entering into a commission. In the event of disputes, Brush&Coin may provide mediation support; however, the platform does not guarantee resolution outcomes and is not legally liable for conflicts between users. All parties agree to attempt to resolve disputes in good faith.',
        ),
        _LegalSection(
          heading: '8. Refunds and Cancellations',
          body:
              'Refunds and cancellations are subject to the agreement established between the artist and the client prior to the transaction. The platform does not impose a universal refund policy and does not guarantee reimbursement. Users are encouraged to clearly define refund terms within their commission agreements. Brush&Coin may assist in facilitating communication during disputes but is not obligated to enforce refund decisions.',
        ),
        _LegalSection(
          heading: '9. Intellectual Property',
          body:
              'All intellectual property rights remain with the original creator unless explicitly transferred through a written agreement. Clients are granted only the rights specified in the commission agreement and may not reproduce or distribute the work beyond those terms. Users must ensure that all content uploaded to the Service is original or properly authorized. Brush&Coin reserves the right to remove content that violates intellectual property laws or infringes upon the rights of others.',
        ),
        _LegalSection(
          heading: '10. User Content and Conduct',
          body:
              'Users may upload and share content within the Service, including artwork, descriptions, and messages. By submitting content, users grant Brush&Coin a limited, non-exclusive license to display and use such content for platform operations. Users agree not to upload content that is illegal, offensive, misleading, or harmful. The platform reserves the right to remove content and take action against users who violate these standards without prior notice.',
        ),
        _LegalSection(
          heading: '11. Privacy and Data Usage',
          body:
              'The Service collects and processes user data necessary for functionality, including account management, communication, and transaction facilitation. By using the Service, users consent to the collection and use of their data in accordance with applicable data protection laws. While Brush&Coin implements reasonable security measures, it does not guarantee absolute protection against unauthorized access or breaches.',
        ),
        _LegalSection(
          heading: '12. Prohibited Activities',
          body:
              'Users agree not to engage in activities that compromise the integrity of the Service, including fraud, impersonation, harassment, unauthorized transactions, or attempts to bypass system safeguards. Any violation may result in suspension or permanent termination of the user’s account. Brush&Coin reserves the right to take appropriate legal action where necessary.',
        ),
        _LegalSection(
          heading: '13. Service Availability and Modifications',
          body:
              'Brush&Coin reserves the right to modify, suspend, or discontinue any aspect of the Service at any time without prior notice. The platform does not guarantee uninterrupted or error-free operation. Users acknowledge that features may change as part of ongoing development and improvement.',
        ),
        _LegalSection(
          heading: '14. Limitation of Liability',
          body:
              'To the fullest extent permitted by law, Brush&Coin shall not be held liable for any damages arising from the use or inability to use the Service, including but not limited to financial loss, data loss, or disputes between users. The Service is provided on an “as is” and “as available” basis without warranties of any kind.',
        ),
        _LegalSection(
          heading: '15. Termination',
          body:
              'Brush&Coin reserves the right to suspend or terminate user access to the Service at its discretion, particularly in cases of violations of these Terms of Service or actions deemed harmful to the platform or its users. Upon termination, users must cease all use of the Service.',
        ),
        _LegalSection(
          heading: '16. Governing Law',
          body:
              'These Terms of Service shall be governed by and interpreted in accordance with the laws of the Republic of the Philippines. Any disputes arising from these terms shall be subject to the jurisdiction of the appropriate courts within the Philippines.',
        ),
        _LegalSection(
          heading: '17. Contact Information',
          body:
              'For questions, concerns, or clarifications regarding these Terms of Service, users may contact the Brush&Coin development team through the official communication channels provided within the application.',
        ),
        SizedBox(height: 16),
      ],
    );
  }
}

class _SignUpPrivacyContent extends StatelessWidget {
  const _SignUpPrivacyContent();

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
        _LegalSection(
          heading: '1. Introduction',
          body:
              'Brush&Coin (“the Application”) is committed to protecting the privacy and personal data of its users. This Privacy Policy explains how user information is collected, used, stored, and protected when accessing or using the Application. By using Brush&Coin, you consent to the practices described in this policy. This policy is designed in accordance with applicable data protection laws, including the Data Privacy Act of 2012 (Republic Act No. 10173) of the Philippines.',
        ),
        _LegalSection(
          heading: '2. Information We Collect',
          body:
              'The Application collects personal and non-personal information necessary to provide its services effectively. Personal information may include, but is not limited to, your name, email address, username, profile details, and any other information voluntarily provided during account registration or profile creation. In addition, transactional data such as commission details, payment references, and communication records between users may be collected to facilitate platform functionality. The Application may also collect device-related information such as IP address, device type, operating system, and usage data to improve system performance and user experience.',
        ),
        _LegalSection(
          heading: '3. How We Use Information',
          body:
              'The information collected is used to operate, maintain, and improve the Application’s services. This includes facilitating user authentication, enabling communication between artists and clients, processing transactions, managing commissions, and providing customer support. Data may also be used for analytics purposes to understand user behavior, enhance features, and improve overall system performance. Brush&Coin may use certain information to send notifications, updates, or important service-related announcements.',
        ),
        _LegalSection(
          heading: '4. Sharing and Disclosure of Information',
          body:
              'Brush&Coin does not sell or rent user personal data to third parties. However, user information may be shared with trusted third-party service providers, such as payment processors, solely for the purpose of facilitating transactions and delivering core functionalities of the Application. These third parties are required to maintain the confidentiality and security of user data. Information may also be disclosed if required by law, regulation, or legal process, or if necessary to protect the rights, safety, and integrity of the platform and its users.',
        ),
        _LegalSection(
          heading: '5. Data Storage and Security',
          body:
              'The Application implements reasonable administrative, technical, and physical security measures to protect user data against unauthorized access, alteration, disclosure, or destruction. Data may be stored on secure servers and protected using encryption and authentication protocols. While Brush&Coin strives to safeguard user information, no system can guarantee absolute security, and users acknowledge that they provide information at their own risk.',
        ),
        _LegalSection(
          heading: '6. User Rights',
          body:
              'Users have the right to access, update, correct, or request deletion of their personal data, subject to applicable legal and contractual obligations. Users may also withdraw consent for data processing where applicable, although doing so may affect their ability to use certain features of the Application. Requests related to personal data may be submitted through the platform’s official communication channels.',
        ),
        _LegalSection(
          heading: '7. Cookies and Tracking Technologies',
          body:
              'The Application may use cookies or similar tracking technologies to enhance user experience, remember preferences, and analyze usage patterns. These technologies help improve system functionality and provide personalized features. Users may manage or disable such technologies through their device settings, although this may limit certain functionalities of the Application.',
        ),
        _LegalSection(
          heading: '8. Data Retention',
          body:
              'Brush&Coin retains user information only for as long as necessary to fulfill the purposes outlined in this Privacy Policy, comply with legal obligations, resolve disputes, and enforce agreements. When data is no longer required, reasonable steps will be taken to securely delete or anonymize it.',
        ),
        _LegalSection(
          heading: '9. Third-Party Links and Services',
          body:
              'The Application may contain links to third-party services or integrate external platforms such as payment gateways. Brush&Coin is not responsible for the privacy practices or content of these third-party services. Users are encouraged to review the privacy policies of any external platforms they interact with.',
        ),
        _LegalSection(
          heading: '10. Children’s Privacy',
          body:
              'The Application is not intended for use by individuals who are not legally capable of entering into a binding agreement under applicable laws. Brush&Coin does not knowingly collect personal information from minors without appropriate consent. If such data is identified, it will be promptly removed.',
        ),
        _LegalSection(
          heading: '11. Changes to the Privacy Policy',
          body:
              'Brush&Coin reserves the right to update or modify this Privacy Policy at any time. Any changes will be reflected within the Application, and continued use of the Service after such updates constitutes acceptance of the revised policy. Users are encouraged to review this Privacy Policy periodically.',
        ),
        _LegalSection(
          heading: '12. Contact Information',
          body:
              'For questions, concerns, or requests regarding this Privacy Policy or the handling of personal data, users may contact the Brush&Coin development team through the official communication channels provided within the Application.',
        ),
        SizedBox(height: 16),
      ],
    );
  }
}
