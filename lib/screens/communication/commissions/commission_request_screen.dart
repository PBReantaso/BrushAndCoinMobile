import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../models/app_models.dart';
import '../../../services/api_client.dart';
import 'commission_payment_confirmation_screen.dart';

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
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => CommissionPaymentConfirmationScreen(
            artistUserId: widget.artistId,
            artistUsername: widget.artistName,
            commissionId: commissionId,
            commissionTitle: title,
            baseBudget: budget,
            isUrgent: _isUrgent,
            paymentMethod: _selectedPaymentMethod,
            urgencyFee: _urgencyFee,
            platformFee: _platformFee,
            totalAmount: _totalAmount,
          ),
        ),
      );
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
        leading: BackButton(color: Colors.black),
        title: const Text('Request Commission',
            style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 1,
      ),
      backgroundColor: const Color(0xFFF2F2F4),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: const Color(0xFFFFE6E6),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Provided by Artist',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(
                    'Description from ${widget.artistName}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 8),
                  const Text('Starting Price: ₱300.00',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFB00020))),
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
                    hint: 'dd/mm/yyyy'),
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
            Text('Reference Images (Optional, max 5)',
                style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            _buildReferenceImagePicker(),
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
                  color: Colors.white, borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Pricing Summary',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  _buildPricingRow('Base budget', _budgetValue),
                  _buildPricingRow('Urgency Fee (20%)', _urgencyFee),
                  _buildPricingRow('Platform Fee (5%)', _platformFee),
                  const Divider(),
                  _buildPricingRow('Total Amount', _totalAmount,
                      bold: true, colored: true),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text('Payment Method',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            _buildPaymentOption(PaymentMethodType.gcash, 'Gcash'),
            const SizedBox(height: 8),
            _buildPaymentOption(PaymentMethodType.paymaya, 'PayMaya'),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                    ),
                    onPressed: _isSubmitting
                        ? null
                        : () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD32F2F),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: _isSubmitting ? null : _submit,
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : const Text('Send Request',
                            style: TextStyle(fontWeight: FontWeight.bold)),
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
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
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
              ? const Color(0xFFFFE6E6)
              : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: _selectedPaymentMethod == type
                ? const Color(0xFFD32F2F)
                : const Color(0xFFC7C7CC),
          ),
        ),
        child: Row(
          children: [
            Icon(
              _selectedPaymentMethod == type
                  ? Icons.radio_button_checked
                  : Icons.radio_button_off,
              color: _selectedPaymentMethod == type
                  ? const Color(0xFFD32F2F)
                  : Colors.grey,
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
          Text(label,
              style: TextStyle(
                  fontWeight: bold ? FontWeight.w700 : FontWeight.w500)),
          Text(
            '₱${amount.toStringAsFixed(2)}',
            style: TextStyle(
              fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
              color: colored ? const Color(0xFFD32F2F) : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
