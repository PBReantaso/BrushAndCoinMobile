import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../models/app_models.dart';
import '../../../navigation/user_profile_navigation.dart';
import '../../../services/api_client.dart';
import 'commission_payment_success_screen.dart';

/// Opens the provider's public site in the system browser.
/// Production: replace with a checkout URL returned by your API (Stripe Checkout, PayMongo, etc.).
Uri _paymentProviderEntryUri(PaymentMethodType method) {
  switch (method) {
    case PaymentMethodType.gcash:
      return Uri.parse('https://www.gcash.com/');
    case PaymentMethodType.paymaya:
      return Uri.parse('https://www.paymaya.com/');
    case PaymentMethodType.paypal:
      return Uri.parse('https://www.paypal.com/');
    case PaymentMethodType.stripe:
      return Uri.parse('https://stripe.com/docs/payments');
  }
}

class CommissionPaymentConfirmationScreen extends StatefulWidget {
  /// Artist being commissioned (for returning to their profile after pay / failure).
  final int artistUserId;
  final String artistUsername;

  final int commissionId;
  final String commissionTitle;
  final double baseBudget;
  final bool isUrgent;
  final PaymentMethodType paymentMethod;
  final double urgencyFee;
  final double platformFee;
  final double totalAmount;

  const CommissionPaymentConfirmationScreen({
    super.key,
    required this.artistUserId,
    required this.artistUsername,
    required this.commissionId,
    required this.commissionTitle,
    required this.baseBudget,
    required this.isUrgent,
    required this.paymentMethod,
    required this.urgencyFee,
    required this.platformFee,
    required this.totalAmount,
  });

  @override
  State<CommissionPaymentConfirmationScreen> createState() =>
      _CommissionPaymentConfirmationScreenState();
}

class _CommissionPaymentConfirmationScreenState
    extends State<CommissionPaymentConfirmationScreen> {
  final _apiClient = ApiClient();
  bool _isProcessing = false;
  bool _openingBrowser = false;
  /// After user taps "Pay now", we open the provider; they must confirm in-app before API.
  bool _checkoutPageOpened = false;

  String get _paymentMethodLabel {
    switch (widget.paymentMethod) {
      case PaymentMethodType.gcash:
        return 'GCash';
      case PaymentMethodType.paymaya:
        return 'PayMaya';
      case PaymentMethodType.paypal:
        return 'PayPal';
      case PaymentMethodType.stripe:
        return 'Stripe';
    }
  }

  void _returnToArtistProfile(BuildContext context) {
    final nav = Navigator.of(context);
    if (nav.canPop()) {
      nav.pop();
      return;
    }
    if (widget.artistUserId > 0) {
      pushUserProfile(
        context,
        userId: widget.artistUserId,
        username: widget.artistUsername.isNotEmpty
            ? widget.artistUsername
            : 'Artist',
      );
    }
  }

  void _showPaymentFailedThenReturn(String message) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Payment could not be confirmed'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              if (mounted) _returnToArtistProfile(context);
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _openPaymentProviderInBrowser() async {
    if (_openingBrowser) return;
    setState(() => _openingBrowser = true);
    final uri = _paymentProviderEntryUri(widget.paymentMethod);
    try {
      var ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok) {
        ok = await launchUrl(uri, mode: LaunchMode.platformDefault);
      }
      if (!mounted) return;
      if (!ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not open the browser. Try again or use another device.'),
          ),
        );
        return;
      }
      setState(() => _checkoutPageOpened = true);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not open the payment page. Check your connection and try again.'),
        ),
      );
    } finally {
      if (mounted) setState(() => _openingBrowser = false);
    }
  }

  Future<void> _processPayment() async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);

    try {
      await _apiClient.updateCommissionStatus(
        widget.commissionId,
        'inProgress',
        paymentMethod: widget.paymentMethod.name,
      );
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => CommissionPaymentSuccessScreen(
            artistUserId: widget.artistUserId,
            artistUsername: widget.artistUsername,
          ),
        ),
      );
    } catch (e) {
      final message = e is ApiException
          ? e.message
          : 'Could not process payment. Please try again.';
      if (!mounted) return;
      _showPaymentFailedThenReturn(message);
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(color: Colors.black),
        title: const Text('Payment', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 1,
      ),
      backgroundColor: const Color(0xFFF2F2F4),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (widget.isUrgent)
                Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF2F2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'This is an urgent commission (+20% fee)',
                    style: TextStyle(
                        color: Color(0xFFD32F2F), fontWeight: FontWeight.bold),
                  ),
                ),
              if (widget.isUrgent) const SizedBox(height: 18),
              const Text('Pricing Summary',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              _priceRow('Base budget', widget.baseBudget),
              _priceRow('Urgency Fee (20%)', widget.urgencyFee),
              _priceRow('Platform Fee (5%)', widget.platformFee),
              const Divider(thickness: 1.2),
              _priceRow('Total Amount', widget.totalAmount,
                  bold: true, highlighted: true),
              const SizedBox(height: 20),
              const Text('Payment Method',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(_paymentMethodLabel, style: t.titleMedium),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F4FF),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFC5CAE9)),
                ),
                child: Text(
                  'Simulated escrow: after you confirm, Brush&Coin shows your total as held until the work is completed, '
                  'then released to the artist. Real money movement requires a payment provider integration.',
                  style: t.bodySmall?.copyWith(
                    color: const Color(0xFF3949AB),
                    height: 1.35,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        _checkoutPageOpened
                            ? 'We opened your ${_paymentMethodLabel} page in the browser. '
                                'Complete payment there, then return here and tap the button below to record escrow in Brush&Coin.'
                            : 'Tap Pay now to open ${_paymentMethodLabel} in your browser. '
                                'After you pay, come back and confirm so we can update your commission.',
                        style: t.bodySmall?.copyWith(
                          color: const Color(0xFF5C5C66),
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Note: a real app uses a checkout link from your server (e.g. Stripe Checkout, PayMongo). '
                        'This build opens the provider’s public site as a stand-in.',
                        style: t.bodySmall?.copyWith(
                          color: const Color(0xFF8E8E99),
                          height: 1.3,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              if (!_checkoutPageOpened)
                ElevatedButton(
                  onPressed: (_isProcessing || _openingBrowser)
                      ? null
                      : _openPaymentProviderInBrowser,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD32F2F),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: _openingBrowser
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          'Pay now',
                          style: t.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                )
              else ...[
                OutlinedButton(
                  onPressed: _openingBrowser ? null : _openPaymentProviderInBrowser,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    foregroundColor: const Color(0xFFD32F2F),
                    side: const BorderSide(color: Color(0xFFD32F2F)),
                  ),
                  child: const Text('Open payment page again'),
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: _isProcessing ? null : _processPayment,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD32F2F),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: _isProcessing
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          'I’ve paid — confirm in Brush&Coin',
                          textAlign: TextAlign.center,
                          style: t.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _priceRow(String label, double value,
      {bool bold = false, bool highlighted = false}) {
    final t = Theme.of(context).textTheme;
    final amountStyle = (highlighted ? t.titleMedium : t.bodyMedium)?.copyWith(
      fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
      color: highlighted ? const Color(0xFFD32F2F) : Colors.black87,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: t.bodyMedium?.copyWith(
              fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
          Text(
            '₱${value.toStringAsFixed(2)}',
            style: amountStyle,
          ),
        ],
      ),
    );
  }
}
