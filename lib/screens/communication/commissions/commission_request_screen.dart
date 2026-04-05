import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../models/app_models.dart';
import '../../../services/api_client.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/content_spacing.dart';

class CommissionRequestScreen extends StatefulWidget {
  final int artistId;
  final String artistName;

  const CommissionRequestScreen({
    super.key,
    required this.artistId,
    required this.artistName,
  });

  @override
  State<CommissionRequestScreen> createState() =>
      _CommissionRequestScreenState();
}

class _CommissionRequestScreenState extends State<CommissionRequestScreen> {
  final _apiClient = ApiClient();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _budgetController = TextEditingController();
  final _deadlineController = TextEditingController();
  final _requirementsController = TextEditingController();

  bool _isUrgent = false;
  bool _isSubmitting = false;
  PaymentMethodType _selectedPaymentMethod = PaymentMethodType.gcash;
  List<XFile> _referenceImages = [];

  double get _budgetValue {
    final value =
        double.tryParse(_budgetController.text.replaceAll(',', '')) ?? 0;
    return value;
  }

  double get _urgencyFee => _isUrgent ? _budgetValue * 0.20 : 0;
  double get _platformFee => _budgetValue * 0.05;
  double get _totalAmount => _budgetValue + _urgencyFee + _platformFee;

  Future<void> _pickReferenceImage() async {
    if (_referenceImages.length >= 5) return;
    final picker = ImagePicker();
    final result =
        await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (result != null) {
      setState(() {
        _referenceImages.add(result);
      });
    }
  }

  Future<void> _removeReferenceImage(int index) async {
    setState(() {
      _referenceImages.removeAt(index);
    });
  }

  Future<void> _selectDeadline() async {
    final now = DateTime.now();
    final selected = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(days: 7)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (selected != null) {
      _deadlineController.text =
          '${selected.year}-${selected.month.toString().padLeft(2, '0')}-${selected.day.toString().padLeft(2, '0')}';
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _budgetController.dispose();
    _deadlineController.dispose();
    _requirementsController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;

    final title = _titleController.text.trim();
    final description = _descriptionController.text.trim();
    final budget = _budgetValue;

    if (title.isEmpty || description.isEmpty || budget <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Title, description, and budget are required.')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final clientName = await _apiClient.getCurrentUsername() ?? 'Client';

      final commissionData = await _apiClient.createCommission(
        artistId: widget.artistId,
        title: title,
        clientName: clientName,
        description: description,
        budget: budget,
        deadline:
            _deadlineController.text.isEmpty ? null : _deadlineController.text,
        specialRequirements: _requirementsController.text.trim(),
        isUrgent: _isUrgent,
        referenceImages: _referenceImages.map((e) => e.path).toList(),
        totalAmount: _totalAmount,
        preferredPaymentMethod: _selectedPaymentMethod.name,
      );

      final commissionId = (commissionData['id'] as int?) ?? 0;

      final conversation = await _apiClient.startConversation(
        widget.artistId,
        commissionId: commissionId > 0 ? commissionId : null,
      );
      final conversationId = conversation['id'] as int?;
      if (conversationId != null && description.isNotEmpty) {
        await _apiClient.sendMessage(conversationId, description);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Request sent. You’ll pay after the artist accepts — check Sent in Commissions.',
          ),
        ),
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      final message =
          e is ApiException ? e.message : 'Failed to send commission request.';
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(color: BcColors.ink),
        title: Text(
          'Request Commission',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: BcColors.brandRed,
              ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        bottom: const BcAppBarBottomLine(),
      ),
      backgroundColor: BcColors.pageBackground,
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          kScreenHorizontalPadding,
          12,
          kScreenHorizontalPadding,
          24,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: BcColors.cardBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Provided by artist',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF8C8C90),
                        ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    widget.artistName,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF1A1A1E),
                        ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'You\'re requesting a commission from this artist.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: const Color(0xFF6C6C74),
                          height: 1.35,
                        ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Starting price: ₱300.00',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: BcColors.brandRed,
                        ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _buildTextField(
                controller: _titleController,
                label: 'Title *',
                hint: 'e.g., Digital portrait of my pet'),
            const SizedBox(height: 12),
            _buildTextField(
                controller: _descriptionController,
                label: 'Description *',
                hint: 'Describe what you want commissioned in detail...',
                maxLines: 5),
            const SizedBox(height: 12),
            _buildTextField(
                controller: _budgetController,
                label: 'Budget *',
                hint: 'e.g., 2500',
                keyboardType: TextInputType.number),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: _selectDeadline,
              child: AbsorbPointer(
                child: _buildTextField(
                    controller: _deadlineController,
                    label: 'Preferred Deadline (Optional)',
                    hint: 'Tap to choose a date'),
              ),
            ),
            const SizedBox(height: 12),
            _buildTextField(
                controller: _requirementsController,
                label: 'Special Requirements (Optional)',
                hint:
                    'Any specific details, style preference, dimensions, etc.',
                maxLines: 3),
            const SizedBox(height: 12),
            Text(
              'Reference Images (Optional, max 5)',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF8C8C90),
                  ),
            ),
            const SizedBox(height: 8),
            _buildReferenceImagePicker(),
            const SizedBox(height: 20),
            Text(
              'Preferred payment method',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF1A1A1E),
                  ),
            ),
            const SizedBox(height: 6),
            Text(
              'Saved with your request so the artist knows how you plan to pay. '
              'After they accept, you’ll complete payment from the commission to fund escrow.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF5C5C66),
                    height: 1.35,
                  ),
            ),
            const SizedBox(height: 12),
            _buildPaymentOption(PaymentMethodType.gcash, 'GCash'),
            const SizedBox(height: 8),
            _buildPaymentOption(PaymentMethodType.paymaya, 'PayMaya'),
            const SizedBox(height: 8),
            _buildPaymentOption(PaymentMethodType.paypal, 'PayPal'),
            const SizedBox(height: 8),
            _buildPaymentOption(PaymentMethodType.stripe, 'Stripe'),
            const SizedBox(height: 16),
            Row(
              children: [
                Checkbox(
                    value: _isUrgent,
                    onChanged: (v) => setState(() => _isUrgent = v ?? false)),
                Expanded(
                    child: Text('This is an urgent commission (+20% fee)',
                        style: const TextStyle(fontWeight: FontWeight.w600))),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: BcColors.cardBorder),
              ),
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Pricing Summary',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF1A1A1E),
                        ),
                  ),
                  const SizedBox(height: 10),
                  _buildPricingRow('Base budget', _budgetValue),
                  _buildPricingRow('Urgency Fee (20%)', _urgencyFee),
                  _buildPricingRow('Platform Fee (5%)', _platformFee),
                  const Divider(height: 20, color: Color(0xFFE6E6EA)),
                  _buildPricingRow('Total Amount', _totalAmount,
                      bold: true, colored: true),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF1A1A1E),
                      side: const BorderSide(color: Color(0xFF424242)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    onPressed: _isSubmitting
                        ? null
                        : () => Navigator.of(context).pop(),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: BcColors.brandRed,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      surfaceTintColor: Colors.transparent,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    onPressed: _isSubmitting ? null : _submit,
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : const Text(
                            'Send Request',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: const Color(0xFF8C8C90),
            ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: BcColors.cardBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: BcColors.cardBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: BcColors.brandRed, width: 1.5),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
    );
  }

  Widget _buildReferenceImagePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 90,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _referenceImages.length + 1,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              if (index == _referenceImages.length) {
                return GestureDetector(
                  onTap:
                      _referenceImages.length < 5 ? _pickReferenceImage : null,
                  child: Container(
                    width: 100,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Center(
                        child: Icon(Icons.upload_file, color: Colors.grey)),
                  ),
                );
              }
              final file = _referenceImages[index];
              return Stack(
                children: [
                  Container(
                    width: 100,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      image: DecorationImage(
                        image: FileImage(File(file.path)),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  Positioned(
                    top: 2,
                    right: 2,
                    child: GestureDetector(
                      onTap: () => _removeReferenceImage(index),
                      child: Container(
                        decoration: const BoxDecoration(
                            color: Colors.black54, shape: BoxShape.circle),
                        child: const Icon(Icons.close,
                            size: 18, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        if (_referenceImages.isNotEmpty) const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildPaymentOption(PaymentMethodType type, String label) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPaymentMethod = type;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        decoration: BoxDecoration(
          color: _selectedPaymentMethod == type
              ? const Color(0xFFFFF0F0)
              : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _selectedPaymentMethod == type
                ? BcColors.brandRed
                : BcColors.cardBorder,
          ),
        ),
        child: Row(
          children: [
            Icon(
              _selectedPaymentMethod == type
                  ? Icons.radio_button_checked
                  : Icons.radio_button_off,
              color: _selectedPaymentMethod == type
                  ? BcColors.brandRed
                  : const Color(0xFF8C8C90),
            ),
            const SizedBox(width: 10),
            Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _buildPricingRow(String label, double amount,
      {bool bold = false, bool colored = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: bold ? FontWeight.w800 : FontWeight.w500,
              color: const Color(0xFF1A1A1E),
            ),
          ),
          Text(
            '₱${amount.toStringAsFixed(2)}',
            style: TextStyle(
              fontWeight: bold ? FontWeight.w800 : FontWeight.w500,
              color: colored ? BcColors.brandRed : const Color(0xFF1A1A1E),
            ),
          ),
        ],
      ),
    );
  }
}
