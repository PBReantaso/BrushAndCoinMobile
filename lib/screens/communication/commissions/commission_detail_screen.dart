import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../models/app_models.dart';
import '../../../services/api_client.dart';

class CommissionDetailScreen extends StatefulWidget {
  final Project commission;

  const CommissionDetailScreen({
    super.key,
    required this.commission,
  });

  @override
  State<CommissionDetailScreen> createState() => _CommissionDetailScreenState();
}

class _CommissionDetailScreenState extends State<CommissionDetailScreen> {
  final _apiClient = ApiClient();
  bool _isProcessing = false;
  bool _isSubmittingArtwork = false;
  List<XFile> _submittedArtworks = [];

  double get _urgencyFee =>
      widget.commission.isUrgent ? widget.commission.budget * 0.20 : 0;
  double get _platformFee => widget.commission.budget * 0.05;
  double get _totalAmount =>
      widget.commission.budget + _urgencyFee + _platformFee;

  Future<void> _accept() async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);
    try {
      await _apiClient.updateCommissionStatus(
        widget.commission.id ?? 0,
        'accepted',
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Commission accepted!')),
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      final msg =
          e is ApiException ? e.message : 'Failed to accept commission.';
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _reject() async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);
    try {
      await _apiClient.updateCommissionStatus(
        widget.commission.id ?? 0,
        'rejected',
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Commission rejected.')),
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      final msg =
          e is ApiException ? e.message : 'Failed to reject commission.';
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _pickSubmissionImage() async {
    if (_submittedArtworks.length >= 5) return;
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (picked != null) {
      setState(() {
        _submittedArtworks.add(picked);
      });
    }
  }

  Future<void> _removeSubmissionImage(int index) async {
    setState(() {
      _submittedArtworks.removeAt(index);
    });
  }

  Future<void> _submitArtwork() async {
    if (_isSubmittingArtwork || widget.commission.id == null) return;
    if (_submittedArtworks.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please upload at least one artwork image.')),
      );
      return;
    }

    setState(() => _isSubmittingArtwork = true);
    try {
      await _apiClient.updateCommissionStatus(
        widget.commission.id!,
        widget.commission.status == ProjectStatus.accepted
            ? 'inProgress'
            : 'completed',
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Artwork submitted successfully.')),
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      final msg = e is ApiException ? e.message : 'Failed to submit artwork.';
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } finally {
      if (mounted) setState(() => _isSubmittingArtwork = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(color: Colors.black),
        title: const Text('Commissioner Request',
            style: TextStyle(color: const Color(0xFFD32F2F))),
        backgroundColor: Colors.white,
        elevation: 1,
      ),
      backgroundColor: const Color(0xFFF2F2F4),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDetailRow('Title', widget.commission.title),
                  const SizedBox(height: 12),
                  _buildDetailRow('Description', widget.commission.description),
                  const SizedBox(height: 12),
                  _buildDetailRow('Budget',
                      '₱${widget.commission.budget.toStringAsFixed(2)}',
                      colored: true),
                  const SizedBox(height: 12),
                  if (widget.commission.deadline != null)
                    _buildDetailRow(
                        'Preferred Deadline', widget.commission.deadline ?? ''),
                  if (widget.commission.deadline != null)
                    const SizedBox(height: 12),
                  if (widget.commission.specialRequirements.isNotEmpty)
                    _buildDetailRow('Special Requirements',
                        widget.commission.specialRequirements),
                  if (widget.commission.specialRequirements.isNotEmpty)
                    const SizedBox(height: 12),
                  if (widget.commission.referenceImages.isNotEmpty) ...[
                    const Text('Reference Images',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    _buildReferenceImages(),
                    const SizedBox(height: 12),
                  ],
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline, color: Colors.orange),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'This is an ${widget.commission.isUrgent ? 'urgent' : 'normal'} commission',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Pricing Summary',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        _buildPricingRow(
                            'Base budget', widget.commission.budget),
                        _buildPricingRow('Urgency Fee (20%)', _urgencyFee),
                        _buildPricingRow('Platform Fee (5%)', _platformFee),
                        const Divider(),
                        _buildPricingRow('Total Amount', _totalAmount,
                            bold: true, colored: true),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (widget.commission.status == ProjectStatus.inquiry) ...[
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.black,
                            ),
                            onPressed: _isProcessing ? null : _reject,
                            child: const Text('Reject'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFD32F2F),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            onPressed: _isProcessing ? null : _accept,
                            child: _isProcessing
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text('Accept',
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                  ] else if (widget.commission.status ==
                          ProjectStatus.accepted ||
                      widget.commission.status == ProjectStatus.inProgress) ...[
                    Text(
                      'Artwork Submission',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 12),
                    _buildArtworkUploader(),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed:
                          _isSubmittingArtwork ? null : () => _submitArtwork(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFD32F2F),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: _isSubmittingArtwork
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              widget.commission.status == ProjectStatus.accepted
                                  ? 'Start Work'
                                  : 'Mark Complete',
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                    ),
                  ] else if (widget.commission.status ==
                      ProjectStatus.completed) ...[
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F5E9),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        'This commission is completed. Great work!',
                        style: TextStyle(
                          color: Color(0xFF2E7D32),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ] else if (widget.commission.status ==
                      ProjectStatus.rejected) ...[
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFEBEE),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        'This commission was rejected.',
                        style: TextStyle(
                          color: Color(0xFFD32F2F),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildArtworkUploader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Artwork Submission',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text('PNG, JPG, GIF up to 10MB',
                  style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: _pickSubmissionImage,
                child: Container(
                  height: 120,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey, width: 1.2),
                  ),
                  child: const Text('Click to upload',
                      style: TextStyle(color: Colors.grey)),
                ),
              ),
              const SizedBox(height: 12),
              if (_submittedArtworks.isNotEmpty)
                SizedBox(
                  height: 100,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _submittedArtworks.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final file = _submittedArtworks[index];
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
                            top: 4,
                            right: 4,
                            child: GestureDetector(
                              onTap: () => _removeSubmissionImage(index),
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: Colors.black45,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.close,
                                    size: 16, color: Colors.white),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value, {bool colored = false}) {
    final t = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: t.bodySmall?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: t.bodyMedium?.copyWith(
            color: colored ? const Color(0xFFD32F2F) : Colors.black87,
            fontWeight: colored ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildReferenceImages() {
    return SizedBox(
      height: 100,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: widget.commission.referenceImages.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final imagePath = widget.commission.referenceImages[index];
          return Container(
            width: 100,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              image: DecorationImage(
                image: _getImageProvider(imagePath),
                fit: BoxFit.cover,
              ),
            ),
          );
        },
      ),
    );
  }

  ImageProvider _getImageProvider(String imagePath) {
    if (imagePath.startsWith('http')) {
      return NetworkImage(imagePath);
    }
    return FileImage(File(imagePath));
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
                fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
              )),
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
