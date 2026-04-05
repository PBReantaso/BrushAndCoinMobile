import 'package:flutter/material.dart';

import '../../../navigation/user_profile_navigation.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/content_spacing.dart';

class CommissionPaymentSuccessScreen extends StatelessWidget {
  final int artistUserId;
  final String artistUsername;

  const CommissionPaymentSuccessScreen({
    super.key,
    this.artistUserId = 0,
    this.artistUsername = '',
  });

  void _exitToArtistProfile(BuildContext context) {
    final nav = Navigator.of(context);
    if (nav.canPop()) {
      nav.pop();
      return;
    }
    if (artistUserId > 0) {
      pushUserProfile(
        context,
        userId: artistUserId,
        username: artistUsername.isNotEmpty ? artistUsername : 'Artist',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Scaffold(
      backgroundColor: BcColors.pageBackground,
      appBar: AppBar(
        leading: BackButton(
          color: BcColors.ink,
          onPressed: () => _exitToArtistProfile(context),
        ),
        title: Text('Payment', style: bcPushedScreenTitleStyle(context)),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        elevation: 0,
        bottom: const BcAppBarBottomLine(),
      ),
      body: Center(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.88,
          padding: const EdgeInsets.symmetric(
            vertical: 32,
            horizontal: kScreenHorizontalPadding,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                offset: const Offset(0, 8),
                blurRadius: 20,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 94,
                height: 94,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFFFF4A4A),
                ),
                child: const Center(
                  child: Icon(Icons.check, color: Colors.white, size: 52),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Success!',
                style: t.headlineMedium?.copyWith(
                  color: BcColors.brandRed,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Your payment is recorded as held in simulated escrow until the commission is completed. '
                'Then it is marked as released to the artist (no real funds move until you connect a payment provider).\n\n'
                'Email receipts appear when your account is set up for notifications.',
                textAlign: TextAlign.center,
                style: t.bodyLarge?.copyWith(
                  height: 1.4,
                  color: const Color(0xFF5A5A5A),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: BcColors.brandRed,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () => _exitToArtistProfile(context),
                  child: Text(
                    'Go back',
                    style: t.titleMedium?.copyWith(fontWeight: FontWeight.bold),
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
