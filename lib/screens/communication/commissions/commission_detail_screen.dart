import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../models/app_models.dart';
import '../../../services/api_client.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/content_spacing.dart';
import '../../../state/inbox_badge_scope.dart';
import 'commission_chat_screen.dart';
import 'commission_payment_confirmation_screen.dart';
import 'commission_work_view_screen.dart';

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
  bool _patronCompleting = false;
  List<XFile> _submittedArtworks = [];
  String? _currentUsername;
  /// After payment or status updates, merged with [CommissionDetailScreen.commission].
  Project? _commissionRefresh;

  Project get _c => _commissionRefresh ?? widget.commission;

  Future<void> _reloadCommission() async {
    final id = _c.id;
    if (id == null) return;
    try {
      final json = await _apiClient.fetchCommission(id);
      if (!mounted) return;
      setState(() => _commissionRefresh = Project.fromJson(json));
    } catch (_) {
      // Keep last known commission.
    }
  }

  Future<void> _patronCompleteAndReleaseEscrow() async {
    if (!_isCommissioner || _c.id == null) return;
    if (_patronCompleting) return;
    setState(() => _patronCompleting = true);
    try {
      await _apiClient.updateCommissionStatus(_c.id!, 'completed');
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
      final msg = e is ApiException ? e.message : 'Could not complete commission.';
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } finally {
      if (mounted) setState(() => _patronCompleting = false);
    }
  }

  Future<void> _openPatronPayment() async {
    final id = _c.id;
    final aid = _c.artistId;
    if (id == null || aid == null) return;
    final uname = (_c.artistUsername ?? '').trim();
    await Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (context) => CommissionPaymentConfirmationScreen(
          artistUserId: aid,
          artistUsername: uname.isNotEmpty ? uname : 'Artist',
          commissionId: id,
          commissionTitle: _c.title,
          baseBudget: _c.budget,
          isUrgent: _c.isUrgent,
          paymentMethod:
              paymentMethodTypeFromStoredName(_c.preferredPaymentMethod),
          urgencyFee: _urgencyFee,
          platformFee: _platformFee,
          totalAmount: _totalAmount,
        ),
      ),
    );
    await _reloadCommission();
  }

  @override
  void initState() {
    super.initState();
    _loadCurrentUsername();
    final cid = widget.commission.id;
    if (cid != null && cid > 0) {
      unawaited(_markViewed(cid));
    }
  }

  Future<void> _markViewed(int commissionId) async {
    try {
      await _apiClient.markCommissionViewed(commissionId);
      if (!mounted) return;
      InboxBadgeScope.maybeOf(context)?.refresh();
    } catch (_) {
      // List still shows unread until next successful sync; avoid blocking UI.
    }
  }

  Future<void> _loadCurrentUsername() async {
    try {
      final username = await _apiClient.getCurrentUsername();
      if (mounted) {
        setState(() => _currentUsername = username);
      }
    } catch (e) {
      // Handle error silently
    }
  }

  bool get _isCommissioner {
    if (_currentUsername == null) return false;
    return _c.clientName == _currentUsername;
  }

  double get _urgencyFee =>
      _c.isUrgent ? _c.budget * 0.20 : 0;
  double get _platformFee => _c.budget * 0.05;
  double get _totalAmount =>
      _c.budget + _urgencyFee + _platformFee;

  Future<void> _accept() async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);
    try {
      await _apiClient.updateCommissionStatus(
        _c.id ?? 0,
        'accepted',
      );
      if (!mounted) return;
      final cid = _c.id;
      final patronId = _c.patronId;
        if (cid != null && patronId != null) {
          final convJson =
              await _apiClient.startConversation(patronId, commissionId: cid);
          final conv = Conversation.fromJson(convJson);
          if (!mounted) return;
          await Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => CommissionChatScreen(
                conversation: conv,
                commissionId: cid,
              ),
            ),
          );
          return;
        }
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
        _c.id ?? 0,
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
    final choice = await showModalBottomSheet<ImageSource>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from gallery'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Take a photo'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
          ],
        ),
      ),
    );
    if (!mounted || choice == null) return;
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: choice,
      imageQuality: 80,
    );
    if (picked != null && mounted) {
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
    if (_isSubmittingArtwork || _c.id == null) return;
    final revisionAfterFunded = _c.status == ProjectStatus.accepted &&
        _c.escrowStatus == EscrowStatus.funded;
    final firstWorkAfterPayment = _c.status == ProjectStatus.inProgress &&
        _c.submissionRound == 0;
    if (!revisionAfterFunded && !firstWorkAfterPayment) return;
    if (_submittedArtworks.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please upload at least one artwork image.')),
      );
      return;
    }

    setState(() => _isSubmittingArtwork = true);
    try {
      final parts = <Map<String, String>>[];
      for (final f in _submittedArtworks) {
        final bytes = await f.readAsBytes();
        parts.add({
          'mimeType': f.mimeType ?? 'image/jpeg',
          'dataBase64': base64Encode(bytes),
        });
      }
      await _apiClient.updateCommissionStatus(
        _c.id!,
        'inProgress',
        submissionImages: parts,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Work submitted. Waiting for patron approval.')),
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

  Future<void> _openCommissionChat() async {
    final cid = _c.id;
    final patronId = _c.patronId;
    final artistId = _c.artistId;
    if (cid == null || patronId == null || artistId == null) return;
    final other = _isCommissioner ? artistId : patronId;
    try {
      final convJson =
          await _apiClient.startConversation(other, commissionId: cid);
      final conv = Conversation.fromJson(convJson);
      if (!mounted) return;
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CommissionChatScreen(
            conversation: conv,
            commissionId: cid,
          ),
        ),
      );
    } catch (e) {
      final msg = e is ApiException ? e.message : 'Could not open chat.';
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  String _workStageKeyFromRound(int round) {
    if (round <= 1) return 'first';
    if (round == 2) return 'second';
    return 'last';
  }

  Future<void> _openCommissionWorkView() async {
    final key = _workStageKeyFromRound(_c.submissionRound);
    await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => CommissionWorkViewScreen(
          commission: _c,
          workStageKey: key,
          patronReviewMode: _isCommissioner &&
              _c.status == ProjectStatus.inProgress,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(color: BcColors.ink),
        title: _isCommissioner
            ? _buildCommissionerHeader()
            : Text(
                'Commissioner Request',
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                kScreenHorizontalPadding,
                12,
                kScreenHorizontalPadding,
                24,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: BcColors.cardBorder),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildDetailRow('Title', _c.title),
                        const SizedBox(height: 12),
                        _buildDetailRow('Description', _c.description),
                        const SizedBox(height: 12),
                        _buildDetailRow(
                          'Budget',
                          '₱${_c.budget.toStringAsFixed(2)}',
                          colored: true,
                        ),
                        if (_c.preferredPaymentMethod != null &&
                            _c.preferredPaymentMethod!.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          _buildDetailRow(
                            'Preferred payment',
                            _paymentMethodDisplayLabel(
                              _c.preferredPaymentMethod!,
                            ),
                          ),
                        ],
                        if (_c.deadline != null) ...[
                          const SizedBox(height: 12),
                          _buildDetailRow(
                            'Preferred Deadline',
                            _c.deadline ?? '',
                          ),
                        ],
                        if (_c.specialRequirements.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          _buildDetailRow(
                            'Special Requirements',
                            _c.specialRequirements,
                          ),
                        ],
                        if (_c.referenceImages.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Text(
                            'Reference Images',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF8C8C90),
                                ),
                          ),
                          const SizedBox(height: 8),
                          _buildReferenceImages(),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: BcColors.cardBorder),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline_rounded,
                          color: _c.isUrgent
                              ? const Color(0xFFFFA000)
                              : const Color(0xFF8C8C90),
                          size: 22,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'This is an ${_c.isUrgent ? 'urgent' : 'normal'} commission',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: const Color(0xFF3B3B3B),
                                  height: 1.35,
                                ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
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
                        _buildPricingRow('Base budget', _c.budget),
                        _buildPricingRow('Urgency Fee (20%)', _urgencyFee),
                        _buildPricingRow('Platform Fee (5%)', _platformFee),
                        const Divider(height: 20, color: Color(0xFFE6E6EA)),
                        _buildPricingRow('Total Amount', _totalAmount,
                            bold: true, colored: true),
                      ],
                    ),
                  ),
                  if (_c.escrowSimulation != null) ...[
                    const SizedBox(height: 12),
                    _buildSimulatedEscrowCard(),
                  ] else if (_c.escrowStatus !=
                      EscrowStatus.none) ...[
                    const SizedBox(height: 12),
                    _buildEscrowStatusBanner(),
                  ],
                  const SizedBox(height: 16),
                  if (_isCommissioner) ...[
                    _buildCommissionerActionSection(),
                  ] else ...[
                    if (_c.status == ProjectStatus.pending) ...[
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFF101010),
                                side: const BorderSide(color: Color(0xFF424242)),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(999),
                                ),
                              ),
                              onPressed: _isProcessing ? null : _reject,
                              child: const Text(
                                'Reject',
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF2E7D32),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                surfaceTintColor: Colors.transparent,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(999),
                                ),
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
                                  : const Text(
                                      'Accept',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ] else if (_c.status == ProjectStatus.accepted) ...[
                      if (_c.escrowStatus == EscrowStatus.none)
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF8E1),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFFFA000)),
                          ),
                          child: const Text(
                            'Waiting for the patron to complete payment. You can submit work once escrow is funded.',
                            style: TextStyle(
                              color: Color(0xFFE65100),
                              height: 1.35,
                            ),
                          ),
                        )
                      else ...[
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
                          onPressed: _isSubmittingArtwork
                              ? null
                              : () => _submitArtwork(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: BcColors.brandRed,
                            foregroundColor: Colors.white,
                            disabledForegroundColor: Colors.white70,
                            elevation: 0,
                            surfaceTintColor: Colors.transparent,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 22,
                              vertical: 14,
                            ),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(999),
                            ),
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
                              : const Text(
                                  'Submit revised work',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                      ],
                    ] else if (_c.status ==
                        ProjectStatus.inProgress) ...[
                      if (_c.submissionRound == 0) ...[
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
                          onPressed: _isSubmittingArtwork
                              ? null
                              : () => _submitArtwork(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: BcColors.brandRed,
                            foregroundColor: Colors.white,
                            disabledForegroundColor: Colors.white70,
                            elevation: 0,
                            surfaceTintColor: Colors.transparent,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 22,
                              vertical: 14,
                            ),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(999),
                            ),
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
                              : const Text(
                                  'Submit first work',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                      ] else ...[
                        Text(
                          'Work submitted',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Status stays in progress until the patron accepts the final work. Use commission chat to coordinate.',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: const Color(0xFF6E6E6E),
                              ),
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          onPressed: _openCommissionChat,
                          icon: const Icon(Icons.chat_bubble_outline),
                          label: const Text('Open commission chat'),
                        ),
                      ],
                    ] else if (_c.status ==
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
                    ] else if (_c.status ==
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
                            color: BcColors.brandRed,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatEscrowMoney(EscrowSimulation sim, double amount) {
    final sym = sim.currency == 'PHP' ? '₱' : '${sim.currency} ';
    return '$sym${amount.toStringAsFixed(2)}';
  }

  Widget _buildSimulatedEscrowCard() {
    final sim = _c.escrowSimulation!;
    late Color bg;
    late Color fg;
    late String phaseLabel;
    switch (sim.phase) {
      case 'held':
        bg = const Color(0xFFE8F5E9);
        fg = const Color(0xFF1B5E20);
        phaseLabel = 'Held for artist';
        break;
      case 'released_to_artist':
        bg = const Color(0xFFE3F2FD);
        fg = const Color(0xFF0D47A1);
        phaseLabel = 'Released to artist';
        break;
      case 'refunded_to_patron':
        bg = const Color(0xFFFFF3E0);
        fg = const Color(0xFFE65100);
        phaseLabel = 'Refunded to patron';
        break;
      case 'awaiting_funding':
      default:
        bg = const Color(0xFFF5F5F5);
        fg = const Color(0xFF424242);
        phaseLabel = 'Awaiting payment';
        break;
    }

    final pm = _c.paymentMethod?.trim() ?? '';
    final pmLine = pm.isEmpty ? null : 'Recorded method: $pm';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: fg.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.savings_outlined, color: fg, size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Simulated escrow',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: fg,
                    fontSize: 15,
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: fg.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  phaseLabel,
                  style: TextStyle(
                    color: fg,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          if (pmLine != null) ...[
            const SizedBox(height: 8),
            Text(
              pmLine,
              style: TextStyle(
                color: fg.withValues(alpha: 0.85),
                fontSize: 12,
              ),
            ),
          ],
          const SizedBox(height: 8),
          _simEscrowAmountRow(
            'Commission total',
            _formatEscrowMoney(sim, sim.commissionTotal),
            fg,
          ),
          if (sim.heldInEscrow > 0)
            _simEscrowAmountRow(
              'Held in app escrow',
              _formatEscrowMoney(sim, sim.heldInEscrow),
              fg,
            ),
          if (sim.releasedToArtist > 0)
            _simEscrowAmountRow(
              'Paid out to artist (simulated)',
              _formatEscrowMoney(sim, sim.releasedToArtist),
              fg,
            ),
          if (sim.refundedToPatron > 0)
            _simEscrowAmountRow(
              'Returned to patron (simulated)',
              _formatEscrowMoney(sim, sim.refundedToPatron),
              fg,
            ),
          if (sim.releaseGoal.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              sim.releaseGoal,
              style: TextStyle(
                color: fg.withValues(alpha: 0.9),
                fontSize: 12,
                height: 1.35,
              ),
            ),
          ],
          if (sim.refundNote.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              sim.refundNote,
              style: TextStyle(
                color: fg.withValues(alpha: 0.85),
                fontSize: 12,
                height: 1.35,
              ),
            ),
          ],
          if (sim.disclaimer.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              sim.disclaimer,
              style: TextStyle(
                color: fg.withValues(alpha: 0.65),
                fontSize: 11,
                height: 1.35,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _simEscrowAmountRow(String label, String value, Color fg) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: fg.withValues(alpha: 0.88),
                fontSize: 13,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: fg,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEscrowStatusBanner() {
    final e = _c.escrowStatus;
    if (e == EscrowStatus.none) return const SizedBox.shrink();
    final pm = _c.paymentMethod?.trim() ?? '';
    final pmSuffix = pm.isEmpty ? '' : ' · $pm';

    late Color bg;
    late Color fg;
    late String title;
    late String subtitle;

    switch (e) {
      case EscrowStatus.funded:
        bg = const Color(0xFFE8F5E9);
        fg = const Color(0xFF1B5E20);
        title = 'Payment in escrow$pmSuffix';
        subtitle =
            'Funds are held until the commission is completed or rejected with a refund.';
        break;
      case EscrowStatus.released:
        bg = const Color(0xFFE3F2FD);
        fg = const Color(0xFF0D47A1);
        title = 'Escrow released$pmSuffix';
        subtitle =
            'Payout to the artist is recorded in the app. Connect a payment provider for real transfers.';
        break;
      case EscrowStatus.refunded:
        bg = const Color(0xFFFFF3E0);
        fg = const Color(0xFFE65100);
        title = 'Escrow refunded';
        subtitle = 'Held funds were returned to the patron.';
        break;
      default:
        return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: fg.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.account_balance_wallet_outlined, color: fg, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: fg,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: fg.withValues(alpha: 0.9),
                    height: 1.3,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommissionerHeader() {
    return Row(
      children: [
        Text(
          'Commission',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: BcColors.brandRed,
              ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: _openCommissionWorkView,
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.remove_red_eye,
              size: 18,
              color: Color(0xFF666666),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCommissionerActionSection() {
    final status = _c.status;
    String actionText;
    Color actionColor;
    String? buttonText;
    VoidCallback? onPressed;
    var showPatronReleaseAfterReview = false;

    switch (status) {
      case ProjectStatus.pending:
        actionText = 'Waiting for artist to accept your commission request.';
        actionColor = const Color(0xFFFFA000);
        break;
      case ProjectStatus.accepted:
        if (_c.escrowStatus == EscrowStatus.none) {
          actionText =
              'The artist accepted your request. Complete payment to fund escrow so they can start.';
          actionColor = const Color(0xFF1976D2);
          buttonText = 'Complete payment';
          onPressed = _openPatronPayment;
        } else {
          actionText =
              'Your commission has been accepted! The artist will start working soon.';
          actionColor = const Color(0xFF1976D2);
          buttonText = 'View Work';
          onPressed = _openCommissionWorkView;
        }
        break;
      case ProjectStatus.inProgress:
        actionText =
            'Review the submitted artwork. Accepting completes the commission and releases escrow to the artist.';
        actionColor = const Color(0xFFFFA000);
        buttonText = 'View artwork';
        onPressed = _openCommissionWorkView;
        showPatronReleaseAfterReview =
            _c.submissionImages.isNotEmpty || _c.submissionRound > 0;
        break;
      case ProjectStatus.completed:
        actionText = 'Your commission has been completed! Check out the final artwork.';
        actionColor = const Color(0xFF2E7D32);
        buttonText = 'View Work';
        onPressed = _openCommissionWorkView;
        break;
      case ProjectStatus.rejected:
        actionText = 'Unfortunately, your commission request was rejected.';
        actionColor = BcColors.brandRed;
        break;
    }

    return Container(
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
            'Commission Status',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF1A1A1E),
                ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: actionColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: actionColor.withValues(alpha: 0.3)),
            ),
            child: Text(
              actionText,
              style: TextStyle(color: actionColor, fontWeight: FontWeight.w500),
            ),
          ),
          if (buttonText != null) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onPressed,
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
                child: Text(
                  buttonText,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
          if (showPatronReleaseAfterReview) ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _patronCompleting ? null : _patronCompleteAndReleaseEscrow,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7D32),
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey.shade300,
                  disabledForegroundColor: Colors.grey.shade600,
                  elevation: 0,
                  surfaceTintColor: Colors.transparent,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                child: _patronCompleting
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
                          fontSize: 14,
                          height: 1.25,
                        ),
                      ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildArtworkUploader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: BcColors.cardBorder),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Artwork Submission',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF1A1A1E),
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'PNG, JPG, GIF up to 10MB',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: const Color(0xFF8C8C90),
                    ),
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: _pickSubmissionImage,
                child: Container(
                  height: 120,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: BcColors.cardBorder),
                  ),
                  child: Text(
                    'Click to upload',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: const Color(0xFF8C8C90),
                        ),
                  ),
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
          style: t.bodySmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: const Color(0xFF8C8C90),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: t.bodyMedium?.copyWith(
            color: colored ? BcColors.brandRed : const Color(0xFF1A1A1E),
            fontWeight: colored ? FontWeight.w800 : FontWeight.w500,
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
        itemCount: _c.referenceImages.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final imagePath = _c.referenceImages[index];
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
              fontWeight: bold ? FontWeight.w800 : FontWeight.w500,
              color: colored ? BcColors.brandRed : const Color(0xFF1A1A1E),
            ),
          ),
        ],
      ),
    );
  }
}

String _paymentMethodDisplayLabel(String code) {
  switch (code.toLowerCase()) {
    case 'gcash':
      return 'GCash';
    case 'paymaya':
      return 'PayMaya';
    case 'paypal':
      return 'PayPal';
    case 'stripe':
      return 'Stripe';
    default:
      return code;
  }
}
