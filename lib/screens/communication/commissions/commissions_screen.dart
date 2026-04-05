import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../models/app_models.dart';
import '../../../services/api_client.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/content_spacing.dart';
import '../../../widgets/profile/profile_avatar.dart';
import '../../home/create_post_screen.dart';
import 'commission_detail_screen.dart';

enum _CommissionScope { all, received, sent }

class CommissionsScreen extends StatefulWidget {
  const CommissionsScreen({super.key});

  @override
  State<CommissionsScreen> createState() => _CommissionsScreenState();
}

class _CommissionsScreenState extends State<CommissionsScreen> {
  final _apiClient = ApiClient();
  _CommissionScope _scope = _CommissionScope.all;
  String? _currentUsername;
  late Future<List<Project>> _commissionsFuture;

  @override
  void initState() {
    super.initState();
    _loadCurrentUsername();
    _commissionsFuture = _loadCommissions();
  }

  Future<void> _loadCurrentUsername() async {
    try {
      final username = await _apiClient.getCurrentUsername();
      if (mounted) {
        setState(() => _currentUsername = username);
      }
    } catch (e) {
      // Handle error silently for now
    }
  }

  Future<List<Project>> _loadCommissions() async {
    final items = await _apiClient.fetchCommissions();
    return items.map(Project.fromJson).toList();
  }

  Future<void> _reloadCommissions() async {
    final f = _loadCommissions();
    setState(() {
      _commissionsFuture = f;
    });
    await f;
  }

  List<Project> _applyFilter(List<Project> items) {
    if (_currentUsername == null) return [];

    final me = _currentUsername!.trim().toLowerCase();
    return items.where((project) {
      final client = (project.clientName).trim().toLowerCase();
      final isReceived = client != me;
      if (_scope == _CommissionScope.received && !isReceived) return false;
      if (_scope == _CommissionScope.sent && isReceived) return false;
      return true;
    }).toList();
  }

  Widget _buildEmptyState() {
    return RefreshIndicator(
      color: const Color(0xFFFF4A4A),
      onRefresh: _reloadCommissions,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'No commissions can be found',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF4A4A4A),
                          ),
                    ),
                    const SizedBox(height: 6),
                    GestureDetector(
                      onTap: () {
                        showCreatePostBottomSheet(context);
                      },
                      child: const Text(
                        'Start sharing your art',
                        style: TextStyle(
                          color: BcColors.brandRed,
                          fontWeight: FontWeight.w700,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  bool _isSeedCommission(Project project) {
    const seedTitles = ['Portrait Commission', 'Event Mural'];
    const seedClients = ['Ana Santos', 'Local Café'];
    return seedTitles.contains(project.title) ||
        seedClients.contains(project.clientName);
  }

  bool _isProjectInProgress(Project project) {
    return project.status == ProjectStatus.inProgress ||
        (project.status == ProjectStatus.accepted && project.milestones.isNotEmpty);
  }

  String _displayStatusLabel(Project project) {
    if (_isProjectInProgress(project)) {
      return 'In progress';
    }

    switch (project.status) {
      case ProjectStatus.pending:
        return 'Pending';
      case ProjectStatus.accepted:
        return 'Accepted';
      case ProjectStatus.completed:
        return 'Completed';
      case ProjectStatus.rejected:
        return 'Failed';
      case ProjectStatus.inProgress:
        return 'In progress';
    }
  }

  Color _displayStatusColor(Project project) {
    if (_isProjectInProgress(project)) {
      return BcColors.brandRed;
    }

    switch (project.status) {
      case ProjectStatus.pending:
        return const Color(0xFFFF4A4A);
      case ProjectStatus.accepted:
        return const Color(0xFF1976D2);
      case ProjectStatus.completed:
        return const Color(0xFF2E7D32);
      case ProjectStatus.rejected:
        return const Color(0xFF444444);
      case ProjectStatus.inProgress:
        return BcColors.brandRed;
    }
  }

  String _commissionPreviewLine(Project project) {
    final m = project.lastMessage;
    if (m != null && m.trim().isNotEmpty) return m.trim();
    return '...';
  }

  String _commissionCardTime(Project project) {
    DateTime? anchor;
    switch (project.status) {
      case ProjectStatus.pending:
        anchor = project.createdAt;
        break;
      case ProjectStatus.accepted:
      case ProjectStatus.inProgress:
        anchor = project.lastMessageAt ?? project.createdAt;
        break;
      case ProjectStatus.completed:
        anchor = project.completedAt ?? project.lastMessageAt ?? project.createdAt;
        break;
      case ProjectStatus.rejected:
        anchor = project.lastMessageAt ?? project.createdAt;
        break;
    }
    if (anchor == null) return '—';
    final local = anchor.toLocal();
    final now = DateTime.now();
    if (local.year == now.year &&
        local.month == now.month &&
        local.day == now.day) {
      return DateFormat.jm().format(local);
    }
    return DateFormat('MM/dd/yyyy').format(local);
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        kScreenHorizontalPadding,
        8,
        kScreenHorizontalPadding,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'Commissions',
                style: t.titleMedium?.copyWith(
                  color: BcColors.brandRed,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              Theme(
                data: Theme.of(context).copyWith(
                  highlightColor: const Color(0xFFFFE4E4),
                  splashColor: const Color(0x26FF4A4A),
                ),
                child: PopupMenuButton<_CommissionScope>(
                  tooltip: 'Filter commissions',
                  initialValue: _scope,
                  onSelected: (mode) => setState(() => _scope = mode),
                  position: PopupMenuPosition.under,
                  offset: const Offset(0, 6),
                  elevation: 10,
                  shadowColor: Colors.black.withValues(alpha: 0.14),
                  surfaceTintColor: Colors.transparent,
                  color: Colors.white,
                  menuPadding: const EdgeInsets.symmetric(vertical: 4),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  constraints: const BoxConstraints(minWidth: 188),
                  popUpAnimationStyle: AnimationStyle.noAnimation,
                  itemBuilder: (menuContext) {
                    final m = Theme.of(menuContext).textTheme;
                    final itemStyle = m.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF222222),
                    );
                    return [
                      PopupMenuItem(
                        value: _CommissionScope.all,
                        height: 40,
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        child: Text('All', style: itemStyle),
                      ),
                      PopupMenuItem(
                        value: _CommissionScope.received,
                        height: 40,
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        child: Text('Received', style: itemStyle),
                      ),
                      PopupMenuItem(
                        value: _CommissionScope.sent,
                        height: 40,
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        child: Text('Sent', style: itemStyle),
                      ),
                    ];
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                    child: Icon(
                      Icons.filter_list,
                      color: Colors.black.withValues(alpha: 0.75),
                      size: 26,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Expanded(
            child: FutureBuilder<List<Project>>(
              future: _commissionsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return _buildEmptyState();
                }

                final commissions = _applyFilter(snapshot.data ?? []);
                final visibleCommissions =
                    commissions.where((p) => !_isSeedCommission(p)).toList();

                if (visibleCommissions.isEmpty) {
                  return _buildEmptyState();
                }

                return RefreshIndicator(
                  color: const Color(0xFFFF4A4A),
                  onRefresh: _reloadCommissions,
                  child: ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: EdgeInsets.zero,
                    itemCount: visibleCommissions.length,
                    itemBuilder: (context, index) {
                      final commission = visibleCommissions[index];
                      final me = _currentUsername!.trim().toLowerCase();
                      final clientLower =
                          commission.clientName.trim().toLowerCase();
                      final isReceived = clientLower != me;
                      final avatarUrl = isReceived
                          ? commission.patronAvatarUrl
                          : commission.artistAvatarUrl;
                      final cardTitleUsername = isReceived
                          ? commission.clientName
                          : (commission.artistUsername != null &&
                                  commission.artistUsername!.isNotEmpty
                              ? '@${commission.artistUsername}'
                              : '...');
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _CommissionCard(
                          avatarUrl: avatarUrl,
                          cardTitleUsername: cardTitleUsername,
                          previewLine: _commissionPreviewLine(commission),
                          commissionNo: commission.id != null
                              ? 'Commission No#${commission.id}'
                              : 'Commission No#',
                          timeLabel: _commissionCardTime(commission),
                          statusLabel: _displayStatusLabel(commission),
                          statusColor: _displayStatusColor(commission),
                          isUnread: commission.hasUnreadMessages,
                          onTap: () async {
                            await Navigator.push<dynamic>(
                              context,
                              MaterialPageRoute(
                                builder: (context) => CommissionDetailScreen(
                                    commission: commission),
                              ),
                            );
                            if (mounted) await _reloadCommissions();
                          },
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _CommissionCard extends StatelessWidget {
  static const _unreadBg = Color(0xFFFFF0F0);
  static const _unreadBar = Color(0xFFFF9A9A);
  static const _readBg = Color(0xFFFFFFFF);
  static const _readBar = Color(0xFFB0B0B6);

  final String? avatarUrl;
  final String cardTitleUsername;
  final String previewLine;
  final String commissionNo;
  final String timeLabel;
  final String statusLabel;
  final Color statusColor;
  final bool isUnread;
  final VoidCallback onTap;

  const _CommissionCard({
    required this.avatarUrl,
    required this.cardTitleUsername,
    required this.previewLine,
    required this.commissionNo,
    required this.timeLabel,
    required this.statusLabel,
    required this.statusColor,
    required this.isUnread,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final bg = isUnread ? _unreadBg : _readBg;
    final bar = isUnread ? _unreadBar : _readBar;

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: ColoredBox(
        color: bg,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(12, 12, 8, 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ProfileAvatar(
                            imageUrl: avatarUrl,
                            radius: 22,
                            placeholderBackgroundColor: const Color(0xFFFF4A4A),
                            placeholderIconColor: Colors.white,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  cardTitleUsername,
                                  style: t.titleSmall?.copyWith(
                                    fontWeight: isUnread ? FontWeight.w700 : FontWeight.w600,
                                    color: const Color(0xFF111111),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  previewLine,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: t.bodySmall?.copyWith(
                                    color: const Color(0xFF4A4A4A),
                                    height: 1.25,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  commissionNo,
                                  style: t.labelSmall?.copyWith(
                                    color: const Color(0xFF9B9B9F),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                timeLabel,
                                style: t.labelSmall?.copyWith(
                                  color: const Color(0xFF9B9B9F),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                statusLabel,
                                style: t.bodySmall?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: statusColor,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  Container(width: 7, color: bar),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
