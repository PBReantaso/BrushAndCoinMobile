import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../models/app_models.dart';
import '../../../services/api_client.dart';
import '../../home/create_post_screen.dart';
import 'commission_detail_screen.dart';

enum _CommissionDirection { received, sent }
enum _CommissionStatus { all, pending, accepted, inProgress, completed, rejected }

class CommissionsScreen extends StatefulWidget {
  const CommissionsScreen({super.key});

  @override
  State<CommissionsScreen> createState() => _CommissionsScreenState();
}

class _CommissionsScreenState extends State<CommissionsScreen> {
  final _apiClient = ApiClient();
  _CommissionDirection _direction = _CommissionDirection.received;
  _CommissionStatus _status = _CommissionStatus.all;
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

    return items.where((project) {
      // Direction filter
      final isReceived = project.clientName != _currentUsername;
      if (_direction == _CommissionDirection.received && !isReceived) return false;
      if (_direction == _CommissionDirection.sent && isReceived) return false;

      // Status filter
      if (_status != _CommissionStatus.all) {
        final status = project.status;
        switch (_status) {
          case _CommissionStatus.pending:
            if (status != ProjectStatus.pending) return false;
            break;
          case _CommissionStatus.accepted:
              if (status != ProjectStatus.accepted || project.milestones.isNotEmpty) return false;
              break;
            case _CommissionStatus.inProgress:
              if (!_isProjectInProgress(project)) return false;
          default:
            break;
        }
      }

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
                          color: Color(0xFFD32F2F),
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
      return const Color(0xFFD32F2F);
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
        return const Color(0xFFD32F2F);
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: _CommissionActionDropdown(
                  active: _direction,
                  onChanged: (v) => setState(() => _direction = v),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _CommissionStatusDropdown(
                  active: _status,
                  onChanged: (v) => setState(() => _status = v),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
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
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: GestureDetector(
                          onTap: () async {
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => CommissionDetailScreen(
                                    commission: commission),
                              ),
                            );
                            if (result == true && mounted) {
                              setState(() {
                                _commissionsFuture = _loadCommissions();
                              });
                            }
                          },
                          child: _CommissionCard(
                            cardTitleUsername: _direction == _CommissionDirection.sent
                                ? (commission.artistUsername != null &&
                                        commission.artistUsername!.isNotEmpty
                                    ? '@${commission.artistUsername}'
                                    : '...')
                                : commission.clientName,
                            previewLine: _commissionPreviewLine(commission),
                            commissionNo: commission.id != null
                                ? 'Commission No#${commission.id}'
                                : 'Commission No#',
                            timeLabel: _commissionCardTime(commission),
                            statusLabel: _displayStatusLabel(commission),
                            statusColor: _displayStatusColor(commission),
                            isUnread: commission.hasUnreadMessages,
                          ),
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

class _CommissionActionDropdown extends StatelessWidget {
  final _CommissionDirection active;
  final ValueChanged<_CommissionDirection> onChanged;

  const _CommissionActionDropdown({
    required this.active,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final labels = <_CommissionDirection, String>{
      _CommissionDirection.received: 'Received',
      _CommissionDirection.sent: 'Sent',
    };

    return InputDecorator(
      decoration: InputDecoration(
        labelText: 'Commission action',
        filled: true,
        fillColor: const Color(0xFFEDEDF1),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<_CommissionDirection>(
          isExpanded: true,
          value: active,
          icon: const Icon(Icons.keyboard_arrow_down),
          items: _CommissionDirection.values.map((direction) {
            return DropdownMenuItem(
              value: direction,
              child: Text(labels[direction]!),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) onChanged(value);
          },
        ),
      ),
    );
  }
}

class _CommissionStatusDropdown extends StatelessWidget {
  final _CommissionStatus active;
  final ValueChanged<_CommissionStatus> onChanged;

  const _CommissionStatusDropdown({
    required this.active,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final labels = <_CommissionStatus, String>{
      _CommissionStatus.all: 'All',
      _CommissionStatus.pending: 'Pending',
      _CommissionStatus.accepted: 'Accepted',
      _CommissionStatus.inProgress: 'In progress',
      _CommissionStatus.completed: 'Completed',
      _CommissionStatus.rejected: 'Failed',
    };

    return InputDecorator(
      decoration: InputDecoration(
        labelText: 'Status',
        filled: true,
        fillColor: const Color(0xFFEDEDF1),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<_CommissionStatus>(
          isExpanded: true,
          value: active,
          icon: const Icon(Icons.keyboard_arrow_down),
          items: _CommissionStatus.values.map((status) {
            return DropdownMenuItem(
              value: status,
              child: Text(labels[status]!),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) onChanged(value);
          },
        ),
      ),
    );
  }
}

class _CommissionCard extends StatelessWidget {
  static const _unreadBg = Color(0xFFFFEBEB);
  static const _unreadBar = Color(0xFFFF9A9A);
  static const _readBg = Color(0xFFF5F5F6);
  static const _readBar = Color(0xFFB0B0B6);

  final String cardTitleUsername;
  final String previewLine;
  final String commissionNo;
  final String timeLabel;
  final String statusLabel;
  final Color statusColor;
  final bool isUnread;

  const _CommissionCard({
    required this.cardTitleUsername,
    required this.previewLine,
    required this.commissionNo,
    required this.timeLabel,
    required this.statusLabel,
    required this.statusColor,
    required this.isUnread,
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
                      CircleAvatar(
                        radius: 22,
                        backgroundColor: Colors.black12,
                        child: const Icon(Icons.person, color: Color(0xFF111111), size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              cardTitleUsername,
                              style: t.titleSmall?.copyWith(
                                fontWeight: FontWeight.w800,
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
    );
  }
}
