import 'package:flutter/material.dart';

import '../../services/api_client.dart';
import '../../theme/app_colors.dart';
import '../../theme/content_spacing.dart';

/// Report queue — only for accounts with `user.isAdmin` on the API.
class AdminReportsScreen extends StatefulWidget {
  const AdminReportsScreen({super.key});

  @override
  State<AdminReportsScreen> createState() => _AdminReportsScreenState();
}

class _AdminReportsScreenState extends State<AdminReportsScreen> {
  final _api = ApiClient();

  String _filter = 'pending';
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

  Future<void> _submitResolution(int reportId, String status) async {
    final noteController = TextEditingController();
    final submit = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(status == 'dismissed' ? 'Dismiss report' : 'Mark resolved'),
        content: TextField(
          controller: noteController,
          decoration: const InputDecoration(
            labelText: 'Internal note (optional)',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Submit'),
          ),
        ],
      ),
    );
    final noteText = noteController.text.trim();
    noteController.dispose();
    if (submit != true || !mounted) return;

    try {
      await _api.resolveAdminReport(
        reportId: reportId,
        status: status,
        resolutionNote: noteText.isEmpty ? null : noteText,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Report updated.')),
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
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'pending', label: Text('Pending')),
                    ButtonSegment(value: 'all', label: Text('All')),
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
            ),
            Expanded(child: _buildList()),
          ],
        ),
      ),
    );
  }

  Widget _buildList() {
    if (_loading && _reports.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              FilledButton(onPressed: _load, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }
    if (_reports.isEmpty) {
      return const Center(
        child: Text('No reports in this filter.'),
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
        final kind = '${r['targetKind'] ?? ''}';
        final targetId = _readInt(r['targetId']);
        final reporter = '${r['reporterLabel'] ?? r['reporterId'] ?? ''}';
        final reason = (r['reason'] as String?)?.trim() ?? '';
        final status = '${r['status'] ?? ''}';
        final created = '${r['createdAt'] ?? ''}';

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE6E6EA)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '#$id · $kind #$targetId',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  'From: $reporter',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: const Color(0xFF6C6C74),
                      ),
                ),
                Text(
                  created,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: const Color(0xFF9B9B9F),
                        fontSize: 12,
                      ),
                ),
                if (reason.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(reason, style: Theme.of(context).textTheme.bodyMedium),
                ],
                const SizedBox(height: 6),
                Text(
                  'Status: $status',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: const Color(0xFF3A3A3F),
                      ),
                ),
                if (status == 'pending') ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      OutlinedButton(
                        onPressed: () => _submitResolution(id, 'dismissed'),
                        child: const Text('Dismiss'),
                      ),
                      const SizedBox(width: 8),
                      FilledButton(
                        onPressed: () => _submitResolution(id, 'resolved'),
                        child: const Text('Resolve'),
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
