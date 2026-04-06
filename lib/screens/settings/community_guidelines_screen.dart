import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/content_spacing.dart';

/// Community standards for Brush&Coin (user-facing; linked from Settings).
class CommunityGuidelinesScreen extends StatelessWidget {
  const CommunityGuidelinesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BcColors.pageBackground,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        elevation: 0,
        leading: const BackButton(color: BcColors.ink),
        title: Text('Community guidelines', style: bcPushedScreenTitleStyle(context)),
        bottom: const BcAppBarBottomLine(),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            kScreenHorizontalPadding,
            16,
            kScreenHorizontalPadding,
            32,
          ),
          children: const [
            _GuidelineSection(
              heading: 'Our purpose',
              body:
                  'Brush&Coin is a space for artists and supporters to share work, request commissions, and connect respectfully. These guidelines help keep the community safe and constructive.',
            ),
            _GuidelineSection(
              heading: 'Be respectful',
              body:
                  'Treat others with courtesy. Do not harass, threaten, doxx, discriminate, or target individuals or groups. Disagreements are fine; abuse is not.',
            ),
            _GuidelineSection(
              heading: 'Content and safety',
              body:
                  'Do not post content that is illegal, sexually exploitative of minors, or gratuitously violent. Respect intellectual property: share only work you have rights to post or that falls under fair use where applicable.',
            ),
            _GuidelineSection(
              heading: 'Commissions and payments',
              body:
                  'Communicate clearly about scope, pricing, and timelines. Honor agreements in good faith. Disputes should be handled calmly; escalation paths may depend on how payments are processed in your region.',
            ),
            _GuidelineSection(
              heading: 'Spam and manipulation',
              body:
                  'Do not spam, phish, or manipulate ratings, follows, or discovery. Automated or inauthentic engagement is not allowed.',
            ),
            _GuidelineSection(
              heading: 'Reporting',
              body:
                  'Use the in-app Report options on posts or profiles when you see something that breaks these rules or feels unsafe. Reports are reviewed by the team; we may remove content, warn accounts, or suspend access in serious or repeated cases.',
            ),
            _GuidelineSection(
              heading: 'Enforcement',
              body:
                  'We may take action at our discretion, including removing content or restricting accounts, especially for violations of law or these guidelines. Nothing here limits other terms you agree to when using Brush&Coin.',
            ),
            _GuidelineSection(
              heading: 'Updates',
              body:
                  'We may update these guidelines from time to time. Continued use of the app after changes means you accept the updated version.',
            ),
          ],
        ),
      ),
    );
  }
}

class _GuidelineSection extends StatelessWidget {
  final String heading;
  final String body;

  const _GuidelineSection({
    required this.heading,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            heading,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF1A1A1E),
                ),
          ),
          const SizedBox(height: 6),
          Text(
            body,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  height: 1.45,
                  color: const Color(0xFF3F3F45),
                ),
          ),
        ],
      ),
    );
  }
}
