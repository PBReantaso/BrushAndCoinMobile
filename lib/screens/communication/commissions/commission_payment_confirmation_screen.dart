import 'package:flutter/material.dart';

import '../../../models/app_models.dart';
import '../../../services/api_client.dart';
import 'commission_payment_success_screen.dart';

class CommissionPaymentConfirmationScreen extends StatefulWidget {
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

  Future<void> _processPayment(BuildContext context) async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);

    try {
      await _apiClient.updateCommissionStatus(
          widget.commissionId, 'inProgress');
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => const CommissionPaymentSuccessScreen(),
        ),
      );
    } catch (e) {
      final message = e is ApiException
          ? e.message
          : 'Could not process payment. Please try again.';
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(color: Colors.black),
        title: const Text('Payment', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 1,
      ),
      backgroundColor: const Color(0xFFF2F2F4),
      body: Padding(
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
            const SizedBox(height: 18),
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
            Text(_paymentMethodLabel, style: const TextStyle(fontSize: 16)),
            const Spacer(),
            ElevatedButton(
              onPressed: _isProcessing ? null : () => _processPayment(context),
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
                  : const Text('Pay now',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _priceRow(String label, double value,
      {bool bold = false, bool highlighted = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  fontWeight: bold ? FontWeight.w700 : FontWeight.w500)),
          Text(
            '₱${value.toStringAsFixed(2)}',
            style: TextStyle(
              fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
              color: highlighted ? const Color(0xFFD32F2F) : Colors.black87,
              fontSize: highlighted ? 16 : 14,
            ),
          ),
        ],
      ),
    );
  }
}
