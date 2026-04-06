import 'package:flutter/material.dart';

import '../../services/api_client.dart';
import '../../theme/app_colors.dart';
import '../../theme/content_spacing.dart';
import '../../widgets/home/post_image_display.dart';
import '../../widgets/profile/profile_avatar.dart';

const double _kDialogRadius = 16;
const double _kFieldRadius = 12;

Map<String, dynamic>? _asStringKeyMap(dynamic v) {
  if (v == null) return null;
  if (v is Map) {
    return Map<String, dynamic>.from(v);
  }
  return null;
}

Future<void> _showReportedPostImageLightbox(
  BuildContext context,
  String imageUrl,
) async {
  final url = imageUrl.trim();
  if (url.isEmpty) return;

  await showGeneralDialog<void>(
    context: context,
    useRootNavigator: true,
    barrierDismissible: true,
    barrierLabel:
        MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: Colors.black.withValues(alpha: 0.88),
    transitionDuration: const Duration(milliseconds: 220),
    pageBuilder: (ctx, animation, secondaryAnimation) {
      final size = MediaQuery.sizeOf(ctx);
      final pad = MediaQuery.paddingOf(ctx);
      final imageHeight = (size.height - pad.vertical - 56).clamp(160.0, size.height);

      return SafeArea(
        child: Material(
          color: Colors.transparent,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: SizedBox(
                    width: size.width - 24,
                    height: imageHeight,
                    child: InteractiveViewer(
                      minScale: 0.85,
                      maxScale: 4,
                      clipBehavior: Clip.none,
                      child: PostImageDisplay(
                        imageUrl: url,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: pad.top + 4,
                right: 8,
                child: IconButton(
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.black45,
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(ctx).pop(),
                ),
              ),
            ],
          ),
        ),
      );
    },
    transitionBuilder: (ctx, animation, secondaryAnimation, child) {
      return FadeTransition(
        opacity: CurvedAnimation(
          parent: animation,
          curve: Curves.easeOut,
        ),
        child: child,
      );
    },
  );
}

InputDecoration _adminDialogFieldDecoration(
  BuildContext context, {
  required String label,
  String? hint,
}) {
  return InputDecoration(
    labelText: label,
    hintText: hint,
    filled: true,
    fillColor: const Color(0xFFF8F8FA),
    labelStyle: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: BcColors.labelMuted,
          fontWeight: FontWeight.w600,
        ),
    floatingLabelStyle: TextStyle(
      color: BcColors.brandRed,
      fontWeight: FontWeight.w600,
      fontSize: (Theme.of(context).textTheme.bodySmall?.fontSize ?? 12) * 0.95,
    ),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(_kFieldRadius),
      borderSide: const BorderSide(color: BcColors.cardBorder),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(_kFieldRadius),
      borderSide: const BorderSide(color: BcColors.cardBorder),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(_kFieldRadius),
      borderSide: const BorderSide(color: BcColors.brandRed, width: 1.5),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
  );
}

/// Report queue — only for accounts with `user.isAdmin` on the API.
class AdminReportsScreen extends StatefulWidget {
  const AdminReportsScreen({super.key});

  @override
  State<AdminReportsScreen> createState() => _AdminReportsScreenState();
}

class _AdminReportsScreenState extends State<AdminReportsScreen> {
  final _api = ApiClient();

  String _filter = 'all';
  bool _loading = false;
  String? _error;
  List<Map<String, dynamic>> _reports = const [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await _api.fetchAdminReports(status: _filter);
      if (!mounted) return;
      setState(() {
        _reports = list;
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _submitResolution(
    int reportId,
    String status, {
    bool isPostReport = false,
  }) async {
    if (status == 'dismissed') {
      final noteOrCancel = await showDialog<String?>(
        context: context,
        builder: (ctx) => const _AdminResolutionNoteDialog(isDismiss: true),
      );
      if (noteOrCancel == null || !mounted) return;
      await _sendResolution(
        reportId: reportId,
        status: status,
        resolutionNote: noteOrCancel.isEmpty ? null : noteOrCancel,
      );
      return;
    }

    final payload = await showDialog<_ResolvePayload?>(
      context: context,
      builder: (ctx) => _AdminResolveDialog(isPostReport: isPostReport),
    );
    if (payload == null || !mounted) return;

    await _sendResolution(
      reportId: reportId,
      status: status,
      resolutionNote: payload.note.isEmpty ? null : payload.note,
      deleteReportedPost: payload.deletePost,
      sendWarning: payload.sendWarning,
      banDays: payload.banDays,
    );
  }

  Future<void> _sendResolution({
    required int reportId,
    required String status,
    String? resolutionNote,
    bool? deleteReportedPost,
    bool? sendWarning,
    int? banDays,
  }) async {
    try {
      final json = await _api.resolveAdminReport(
        reportId: reportId,
        status: status,
        resolutionNote: resolutionNote,
        deleteReportedPost: deleteReportedPost,
        sendWarning: sendWarning,
        banDays: banDays,
      );
      if (!mounted) return;
      final mod = json['moderation'];
      final parts = <String>['Report updated.'];
      if (mod is Map) {
        if (mod['postDeleted'] == true) parts.add('Post removed.');
        if (mod['warningSent'] == true) parts.add('Warning sent.');
        if (mod['bannedUntil'] != null) parts.add('User banned.');
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(parts.join(' '))),
      );
      await _load();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

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
        title: Text('Report queue', style: bcPushedScreenTitleStyle(context)),
        actions: [
          IconButton(
            onPressed: _loading ? null : _load,
            icon: const Icon(Icons.refresh, color: BcColors.ink),
          ),
        ],
        bottom: const BcAppBarBottomLine(),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                kScreenHorizontalPadding,
                12,
                kScreenHorizontalPadding,
                8,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 2, bottom: 10),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.shield_outlined,
                          size: 18,
                          color: BcColors.brandRed,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Moderation',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                color: BcColors.brandRed,
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                      ],
                    ),
                  ),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SegmentedButton<String>(
                      showSelectedIcon: false,
                      style: ButtonStyle(
                        visualDensity: VisualDensity.compact,
                        padding: WidgetStateProperty.all(
                          const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        ),
                        shape: WidgetStateProperty.all(
                          RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        side: WidgetStateProperty.resolveWith((states) {
                          return BorderSide(
                            color: states.contains(WidgetState.selected)
                                ? BcColors.brandRed
                                : BcColors.cardBorder,
                          );
                        }),
                        backgroundColor: WidgetStateProperty.resolveWith((states) {
                          if (states.contains(WidgetState.selected)) {
                            return BcColors.brandRed;
                          }
                          return Colors.white;
                        }),
                        foregroundColor: WidgetStateProperty.resolveWith((states) {
                          if (states.contains(WidgetState.selected)) {
                            return Colors.white;
                          }
                          return BcColors.ink;
                        }),
                      ),
                      segments: const [
                        ButtonSegment(value: 'all', label: Text('All')),
                        ButtonSegment(value: 'pending', label: Text('Pending')),
                        ButtonSegment(value: 'resolved', label: Text('Resolved')),
                        ButtonSegment(value: 'dismissed', label: Text('Dismissed')),
                      ],
                      selected: {_filter},
                      onSelectionChanged: (Set<String> s) {
                        setState(() => _filter = s.first);
                        _load();
                      },
                    ),
                  ),
                ],
              ),
            ),
            Expanded(child: _buildList()),
          ],
        ),
      ),
    );
  }

  Widget _buildList() {
    if (_loading && _reports.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(
          color: BcColors.brandRed,
          strokeWidth: 2.5,
        ),
      );
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: BcColors.body,
                    ),
              ),
              const SizedBox(height: 12),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: BcColors.brandRed,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: _load,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }
    if (_reports.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.inbox_outlined,
                size: 48,
                color: BcColors.labelMuted,
              ),
              const SizedBox(height: 12),
              Text(
                _filter == 'all'
                    ? 'No reports yet'
                    : 'No reports in this filter',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: BcColors.ink,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                _filter == 'all'
                    ? 'When someone uses Report on a post or profile, it will show up here. Try reporting a test post from another account.'
                    : 'Try the “All” tab, or switch filters above.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: BcColors.subtitle,
                      height: 1.4,
                    ),
              ),
            ],
          ),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(
        kScreenHorizontalPadding,
        0,
        kScreenHorizontalPadding,
        24,
      ),
      itemCount: _reports.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final r = _reports[index];
        final id = _readInt(r['id']);
        final kind = '${r['targetKind'] ?? ''}'.trim().toLowerCase();
        final targetId = _readInt(r['targetId']);
        final reporter = '${r['reporterLabel'] ?? r['reporterId'] ?? ''}';
        final reason = (r['reason'] as String?)?.trim() ?? '';
        final status = '${r['status'] ?? ''}';
        final created = '${r['createdAt'] ?? ''}';
        final targetPost = kind == 'post' ? _asStringKeyMap(r['targetPost']) : null;

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: BcColors.cardBorder),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Icon(
                        kind == 'post'
                            ? Icons.article_outlined
                            : Icons.person_outline_rounded,
                        size: 22,
                        color: BcColors.brandRed,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '#$id · $kind #$targetId',
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: BcColors.ink,
                                ),
                          ),
                          const SizedBox(height: 6),
                          _ReportStatusChip(status: status),
                        ],
                      ),
                    ),
                  ],
                ),
                if (kind == 'post') ...[
                  const SizedBox(height: 12),
                  _ReportedPostPreview(
                    targetPost: targetPost,
                    postId: targetId,
                  ),
                ],
                const SizedBox(height: 8),
                Text(
                  'From: $reporter',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: BcColors.subtitle,
                        fontWeight: FontWeight.w500,
                      ),
                ),
                Text(
                  created,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: BcColors.labelMuted,
                        fontSize: 12,
                      ),
                ),
                if (reason.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8F8FA),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: BcColors.cardBorder),
                    ),
                    child: Text(
                      reason,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: BcColors.body,
                            height: 1.35,
                          ),
                    ),
                  ),
                ],
                if (status == 'pending') ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: BcColors.ink,
                            side: const BorderSide(color: BcColors.cardBorder),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          onPressed: () => _submitResolution(id, 'dismissed'),
                          child: const Text('Dismiss'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: BcColors.brandRed,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          onPressed: () => _submitResolution(
                            id,
                            'resolved',
                            isPostReport: kind == 'post',
                          ),
                          child: const Text('Resolve'),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  int _readInt(dynamic v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v) ?? 0;
    return 0;
  }
}

class _ReportedPostPreview extends StatelessWidget {
  const _ReportedPostPreview({
    required this.targetPost,
    required this.postId,
  });

  final Map<String, dynamic>? targetPost;
  final int postId;

  String _str(Map<String, dynamic>? m, String key) {
    if (m == null) return '';
    final v = m[key];
    if (v == null) return '';
    return '$v'.trim();
  }

  int _count(Map<String, dynamic>? m, String key) {
    if (m == null) return 0;
    final v = m[key];
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v) ?? 0;
    return 0;
  }

  int? _userId(Map<String, dynamic>? m) {
    if (m == null) return null;
    final v = m['userId'];
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v);
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final p = targetPost;
    if (p == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF8F8),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: BcColors.cardBorder),
        ),
        child: Row(
          children: [
            const Icon(Icons.article_outlined, color: BcColors.labelMuted, size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'This post is no longer available (it may have been deleted). '
                'Reported post id: #$postId.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: BcColors.subtitle,
                      height: 1.35,
                    ),
              ),
            ),
          ],
        ),
      );
    }

    final title = _str(p, 'title');
    final description = _str(p, 'description');
    final author = _str(p, 'authorName');
    final category = _str(p, 'category');
    final imageUrl = _str(p, 'imageUrl');
    final avatarUrl = _str(p, 'authorAvatarUrl');
    final uid = _userId(p);
    final likes = _count(p, 'likeCount');
    final comments = _count(p, 'commentCount');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Reported post',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: BcColors.brandRed,
                fontWeight: FontWeight.w800,
              ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFFF8F8FA),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: BcColors.cardBorder),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: imageUrl.isEmpty
                      ? null
                      : () => _showReportedPostImageLightbox(context, imageUrl),
                  child: SizedBox(
                    width: 78,
                    height: 78,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        PostImageDisplay(
                          imageUrl: imageUrl.isEmpty ? null : imageUrl,
                          fit: BoxFit.cover,
                        ),
                        if (imageUrl.isNotEmpty)
                          Positioned(
                            right: 4,
                            bottom: 4,
                            child: Icon(
                              Icons.zoom_in_rounded,
                              size: 18,
                              color: Colors.white.withValues(alpha: 0.95),
                              shadows: const [
                                Shadow(
                                  color: Colors.black54,
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        ProfileAvatar(
                          imageUrl: avatarUrl.isEmpty ? null : avatarUrl,
                          radius: 13,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            author.isEmpty ? 'Author' : author,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: BcColors.ink,
                                ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    if (category.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        category,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: BcColors.brandRed,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ],
                    if (title.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: BcColors.ink,
                            ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    if (description.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: BcColors.body,
                              height: 1.35,
                            ),
                        maxLines: 4,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 6),
                    Text(
                      '$likes likes · $comments comments'
                      '${uid != null ? ' · author id $uid' : ''}',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: BcColors.labelMuted,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ReportStatusChip extends StatelessWidget {
  const _ReportStatusChip({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    late Color bg;
    late Color fg;
    late String label;
    switch (status) {
      case 'pending':
        bg = const Color(0xFFFFF4E5);
        fg = const Color(0xFFB06000);
        label = 'Pending';
        break;
      case 'resolved':
        bg = const Color(0xFFE8F5E9);
        fg = const Color(0xFF2E7D32);
        label = 'Resolved';
        break;
      case 'dismissed':
        bg = const Color(0xFFF0F0F3);
        fg = BcColors.subtitle;
        label = 'Dismissed';
        break;
      default:
        bg = const Color(0xFFF0F0F3);
        fg = BcColors.ink;
        label = status;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: fg,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
      ),
    );
  }
}

class _ResolvePayload {
  const _ResolvePayload({
    required this.note,
    required this.deletePost,
    required this.sendWarning,
    this.banDays,
  });

  final String note;
  final bool deletePost;
  final bool sendWarning;
  final int? banDays;
}

class _AdminResolveDialog extends StatefulWidget {
  final bool isPostReport;

  const _AdminResolveDialog({required this.isPostReport});

  @override
  State<_AdminResolveDialog> createState() => _AdminResolveDialogState();
}

class _AdminResolveDialogState extends State<_AdminResolveDialog> {
  late final TextEditingController _noteController;
  late final TextEditingController _banDaysController;
  bool _deletePost = false;
  bool _sendWarning = false;

  @override
  void initState() {
    super.initState();
    _noteController = TextEditingController();
    _banDaysController = TextEditingController();
  }

  @override
  void dispose() {
    _noteController.dispose();
    _banDaysController.dispose();
    super.dispose();
  }

  void _submit() {
    final rawBan = _banDaysController.text.trim();
    int? banDays;
    if (rawBan.isNotEmpty) {
      banDays = int.tryParse(rawBan);
      if (banDays == null || banDays < 1 || banDays > 3650) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ban days must be a number from 1 to 3650, or leave empty.'),
          ),
        );
        return;
      }
    }

    Navigator.of(context).pop(
      _ResolvePayload(
        note: _noteController.text.trim(),
        deletePost: widget.isPostReport && _deletePost,
        sendWarning: _sendWarning,
        banDays: banDays,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final subtitleStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
          color: BcColors.subtitle,
          height: 1.35,
        );
    final checkboxShell = Theme.of(context).copyWith(
      checkboxTheme: CheckboxThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return BcColors.brandRed;
          }
          return Colors.transparent;
        }),
        checkColor: WidgetStateProperty.all(Colors.white),
        side: const BorderSide(color: BcColors.cardBorder, width: 1.5),
      ),
    );

    return AlertDialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 6,
      shadowColor: Colors.black26,
      insetPadding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(_kDialogRadius),
      ),
      title: Text(
        'Resolve report',
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: BcColors.brandRed,
            ),
      ),
      content: SingleChildScrollView(
        child: Theme(
          data: checkboxShell,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _noteController,
                decoration: _adminDialogFieldDecoration(
                  context,
                  label: 'Internal note (optional)',
                ),
                maxLines: 3,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: BcColors.body,
                    ),
              ),
              if (widget.isPostReport) ...[
                const SizedBox(height: 10),
                CheckboxListTile(
                  value: _deletePost,
                  onChanged: (v) => setState(() => _deletePost = v ?? false),
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                  title: Text(
                    'Delete the reported post',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: BcColors.body,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  subtitle: Text(
                    'Removes the post from the feed permanently.',
                    style: subtitleStyle,
                  ),
                ),
              ],
              CheckboxListTile(
                value: _sendWarning,
                onChanged: (v) => setState(() => _sendWarning = v ?? false),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
                visualDensity: VisualDensity.compact,
                title: Text(
                  'Send a warning to the reported user',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: BcColors.body,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                subtitle: Text(
                  'They receive an in-app notification.',
                  style: subtitleStyle,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _banDaysController,
                decoration: _adminDialogFieldDecoration(
                  context,
                  label: 'Ban (days, optional)',
                  hint: 'Leave empty for no ban',
                ),
                keyboardType: TextInputType.number,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: BcColors.body,
                    ),
              ),
            ],
          ),
        ),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      actionsAlignment: MainAxisAlignment.end,
      actions: [
        TextButton(
          style: TextButton.styleFrom(foregroundColor: BcColors.ink),
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: BcColors.brandRed,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
          onPressed: _submit,
          child: const Text('Submit'),
        ),
      ],
    );
  }
}

class _AdminResolutionNoteDialog extends StatefulWidget {
  final bool isDismiss;

  const _AdminResolutionNoteDialog({required this.isDismiss});

  @override
  State<_AdminResolutionNoteDialog> createState() =>
      _AdminResolutionNoteDialogState();
}

class _AdminResolutionNoteDialogState extends State<_AdminResolutionNoteDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 6,
      shadowColor: Colors.black26,
      insetPadding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(_kDialogRadius),
      ),
      title: Text(
        widget.isDismiss ? 'Dismiss report' : 'Mark resolved',
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: BcColors.brandRed,
            ),
      ),
      content: TextField(
        controller: _controller,
        decoration: _adminDialogFieldDecoration(
          context,
          label: 'Internal note (optional)',
        ),
        maxLines: 3,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: BcColors.body,
            ),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      actionsAlignment: MainAxisAlignment.end,
      actions: [
        TextButton(
          style: TextButton.styleFrom(foregroundColor: BcColors.ink),
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: BcColors.brandRed,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
          onPressed: () =>
              Navigator.of(context).pop(_controller.text.trim()),
          child: const Text('Submit'),
        ),
      ],
    );
  }
}
