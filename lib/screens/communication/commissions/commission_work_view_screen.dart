import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../models/app_models.dart';
import '../../../services/api_client.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/content_spacing.dart';

class CommissionWorkViewScreen extends StatefulWidget {
  final Project commission;
  final String? workStageKey;
  final bool patronReviewMode;

  const CommissionWorkViewScreen({
    super.key,
    required this.commission,
    this.workStageKey,
    this.patronReviewMode = false,
  });

  @override
  State<CommissionWorkViewScreen> createState() => _CommissionWorkViewScreenState();
}

class _CommissionWorkViewScreenState extends State<CommissionWorkViewScreen> {
  static const _acceptReleaseGreen = Color(0xFF2E7D32);

  final _apiClient = ApiClient();
  int _selectedImageIndex = 0;
  bool _busy = false;
  int? _myUserId;
  Project? _commissionRefresh;

  Project get _c => _commissionRefresh ?? widget.commission;

  List<String> get _imageGallery {
    final sub = _c.submissionImages;
    if (sub.isNotEmpty) {
      return sub.map(ApiClient.resolveMediaUrl).toList();
    }
    return _c.referenceImages;
  }

  double get _urgencyFee => _c.isUrgent ? _c.budget * 0.20 : 0;
  double get _platformFee => _c.budget * 0.05;
  double get _totalAmount => _c.budget + _urgencyFee + _platformFee;

  @override
  void initState() {
    super.initState();
    _loadUserId();
    _reloadCommission();
  }

  Future<void> _reloadCommission() async {
    final id = widget.commission.id;
    if (id == null) return;
    try {
      final json = await _apiClient.fetchCommission(id);
      if (!mounted) return;
      setState(() => _commissionRefresh = Project.fromJson(json));
    } catch (_) {
      // Keep widget.commission.
    }
  }

  Future<void> _loadUserId() async {
    final id = await _apiClient.getCurrentUserId();
    if (mounted) setState(() => _myUserId = id);
  }

  String _stageTitle() {
    switch (widget.workStageKey) {
      case 'second':
        return 'Second work';
      case 'last':
        return 'Last work';
      default:
        return 'First work';
    }
  }

  String? _formatDeadline() {
    final d = _c.deadline;
    if (d == null || d.isEmpty) return null;
    final parsed = DateTime.tryParse(d);
    if (parsed != null) {
      return DateFormat('dd/MM/yyyy').format(parsed.toLocal());
    }
    return d;
  }

  Future<void> _accept() async {
    final id = _c.id;
    if (id == null || _busy) return;
    setState(() => _busy = true);
    try {
      await _apiClient.updateCommissionStatus(id, 'completed');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Commission completed. Escrow is released to the artist.',
          ),
        ),
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      final msg = e is ApiException ? e.message : 'Could not accept work.';
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _reject() async {
    final id = _c.id;
    if (id == null || _busy) return;
    setState(() => _busy = true);
    try {
      await _apiClient.updateCommissionStatus(id, 'accepted');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You asked for revisions. The artist can submit again.'),
        ),
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      final msg = e is ApiException ? e.message : 'Could not reject work.';
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _tryDownload() async {
    final paths = _imageGallery;
    if (paths.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No artwork files are linked yet.')),
      );
      return;
    }
    final p = paths[_selectedImageIndex.clamp(0, paths.length - 1)];
    if (p.startsWith('http://') || p.startsWith('https://')) {
      final uri = Uri.tryParse(p);
      if (uri != null && await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open this link.')),
        );
      }
      return;
    }
    final f = File(p);
    if (f.existsSync()) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Saved locally: $p')),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This path is not available on this device.'),
        ),
      );
    }
  }

  Widget _buildGalleryImage(String imagePath, {BoxFit fit = BoxFit.cover}) {
    if (imagePath.startsWith('http://') || imagePath.startsWith('https://')) {
      return Image.network(
        imagePath,
        fit: fit,
        errorBuilder: (_, __, ___) => ColoredBox(
          color: Colors.grey.shade300,
          child: const Center(child: Icon(Icons.broken_image_outlined)),
        ),
      );
    }
    final f = File(imagePath);
    if (f.existsSync()) {
      return Image.file(
        f,
        fit: fit,
        errorBuilder: (_, __, ___) => ColoredBox(color: Colors.grey.shade300),
      );
    }
    return ColoredBox(
      color: Colors.grey.shade300,
      child: const Center(
        child: Icon(Icons.image_not_supported_outlined, color: Colors.black38),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final deadlineLabel = _formatDeadline();
    final isPatron = _myUserId != null && _myUserId == _c.patronId;
    final showDownload =
        isPatron && _c.status == ProjectStatus.completed;

    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(color: BcColors.ink),
        title: Text(
          'View Commission Work',
          style: bcPushedScreenTitleStyle(context),
        ),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        elevation: 0,
        bottom: const BcAppBarBottomLine(),
      ),
      backgroundColor: BcColors.pageBackground,
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      kScreenHorizontalPadding,
                      16,
                      kScreenHorizontalPadding,
                      8,
                    ),
                    child: Text(
                      'Artwork Submitted: ${_stageTitle()}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF111111),
                          ),
                    ),
                  ),
                  if (_imageGallery.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: kScreenHorizontalPadding),
                      child: AspectRatio(
                        aspectRatio: 1,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: _buildGalleryImage(
                            _imageGallery[_selectedImageIndex
                                .clamp(0, _imageGallery.length - 1)],
                          ),
                        ),
                      ),
                    ),
                    if (_imageGallery.length > 1) ...[
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 80,
                        child: ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: kScreenHorizontalPadding),
                          scrollDirection: Axis.horizontal,
                          itemCount: _imageGallery.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 8),
                          itemBuilder: (context, index) {
                            final sel = index == _selectedImageIndex;
                            return GestureDetector(
                              onTap: () => setState(() => _selectedImageIndex = index),
                              child: Container(
                                width: 80,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: sel
                                        ? BcColors.brandRed
                                        : Colors.grey.shade300,
                                    width: sel ? 2 : 1,
                                  ),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(6),
                                  child: _buildGalleryImage(_imageGallery[index]),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ] else ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: kScreenHorizontalPadding),
                      child: AspectRatio(
                        aspectRatio: 1.2,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Center(
                            child: Text(
                              'No preview images for this submission yet.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Color(0xFF6E6E6E)),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: kScreenHorizontalPadding),
                    child: _detailCard(
                      context,
                      children: [
                        Text(
                          'Commission No#${_c.id ?? '—'}',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                        const SizedBox(height: 10),
                        _row('Title', _c.title),
                        _row('Description', _c.description),
                        _row(
                          'Budget',
                          '₱${_c.budget.toStringAsFixed(2)}',
                          accent: true,
                        ),
                        if (deadlineLabel != null)
                          _row('Preferred Deadline', deadlineLabel),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: kScreenHorizontalPadding),
                    child: _detailCard(
                      context,
                      children: [
                        Text(
                          'Special Requirements',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _c.specialRequirements.isEmpty
                              ? '—'
                              : _c.specialRequirements,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                  if (_c.referenceImages.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: kScreenHorizontalPadding),
                      child: Text(
                        'Reference Images',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 88,
                      child: ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: kScreenHorizontalPadding),
                        scrollDirection: Axis.horizontal,
                        itemCount: _c.referenceImages.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (context, i) {
                          final path = _c.referenceImages[i];
                          return ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: SizedBox(
                              width: 88,
                              height: 88,
                              child: _buildGalleryImage(path),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: kScreenHorizontalPadding),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _c.isUrgent
                              ? BcColors.brandRed
                              : Colors.grey.shade300,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (_c.isUrgent)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: Text(
                                'This is an urgent commission',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: BcColors.brandRed,
                                      fontWeight: FontWeight.w700,
                                    ),
                              ),
                            ),
                          const Text(
                            'Pricing Summary',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          _priceRow('Base budget', _c.budget),
                          _priceRow('Urgency Fee (20%)', _urgencyFee),
                          _priceRow('Platform Fee (5%)', _platformFee),
                          const Divider(),
                          _priceRow('Total Amount', _totalAmount, bold: true, accent: true),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
          if (widget.patronReviewMode) ...[
            Container(
              padding: const EdgeInsets.fromLTRB(
              kScreenHorizontalPadding,
              8,
              kScreenHorizontalPadding,
              16,
            ),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 8,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_imageGallery.isEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Text(
                          'No artwork is linked to this submission yet. You can’t release escrow until the artist submits images.',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: const Color(0xFF6E6E6E),
                              ),
                        ),
                      ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _busy ? null : _reject,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF101010),
                              side: const BorderSide(color: Color(0xFF424242)),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 14,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(999),
                              ),
                            ),
                            child: const Text(
                              'Reject',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: (_busy || _imageGallery.isEmpty)
                                ? null
                                : _accept,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _acceptReleaseGreen,
                              foregroundColor: Colors.white,
                              disabledBackgroundColor: Colors.grey.shade300,
                              disabledForegroundColor: Colors.grey.shade600,
                              elevation: 0,
                              shadowColor: Colors.transparent,
                              surfaceTintColor: Colors.transparent,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 14,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(999),
                              ),
                            ),
                            child: _busy
                                ? const SizedBox(
                                    height: 22,
                                    width: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text(
                                    'Accept work & release payment',
                                    textAlign: TextAlign.center,
                                    maxLines: 3,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                      fontSize: 13,
                                      height: 1.25,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ] else if (showDownload) ...[
            Container(
              padding: const EdgeInsets.fromLTRB(
              kScreenHorizontalPadding,
              8,
              kScreenHorizontalPadding,
              16,
            ),
              decoration: const BoxDecoration(color: Colors.white),
              child: SafeArea(
                top: false,
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _tryDownload,
                    icon: const Icon(Icons.download_outlined),
                    label: const Text('Download artwork'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _detailCard(BuildContext context, {required List<Widget> children}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _row(String label, String value, {bool accent = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: Color(0xFF6E6E6E),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: accent ? BcColors.brandRed : const Color(0xFF111111),
            ),
          ),
        ],
      ),
    );
  }

  Widget _priceRow(String label, double amount, {bool bold = false, bool accent = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
          Text(
            '₱${amount.toStringAsFixed(2)}',
            style: TextStyle(
              fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
              color: accent ? BcColors.brandRed : const Color(0xFF111111),
            ),
          ),
        ],
      ),
    );
  }
}
