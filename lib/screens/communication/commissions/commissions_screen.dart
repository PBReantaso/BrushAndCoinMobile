import 'package:flutter/material.dart';

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
            if (status != ProjectStatus.inquiry) return false;
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
      case ProjectStatus.inquiry:
        return 'Pending';
      case ProjectStatus.accepted:
        return 'Accepted';
      case ProjectStatus.completed:
        return 'Completed';
      case ProjectStatus.rejected:
        return 'Rejected';
      case ProjectStatus.inProgress:
        return 'In progress';
    }
  }

  Color _displayStatusColor(Project project) {
    if (_isProjectInProgress(project)) {
      return const Color(0xFFD32F2F);
    }

    switch (project.status) {
      case ProjectStatus.inquiry:
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

  Color _commissionCardBackground(Project project) {
    if (_isProjectInProgress(project)) {
      return const Color(0xFFFFEBEA);
    }

    switch (project.status) {
      case ProjectStatus.inquiry:
        return Colors.white;
      case ProjectStatus.accepted:
        return const Color(0xFFF4F8FF);
      case ProjectStatus.completed:
        return Colors.white;
      case ProjectStatus.rejected:
        return const Color(0xFFF5F5F5);
      case ProjectStatus.inProgress:
        return const Color(0xFFFFEBEA);
    }
  }

  String _commissionSubtitle(Project project) {
    if (project.lastMessage != null && project.lastMessage!.isNotEmpty) {
      return project.lastMessage!;
    }
    if (project.description.isNotEmpty) {
      return project.description;
    }
    if (project.title.isNotEmpty) {
      return project.title;
    }
    return 'Commission No.';
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
                            title: commission.clientName,
                            subtitle: _commissionSubtitle(commission),
                            statusLabel: _displayStatusLabel(commission),
                            statusColor: _displayStatusColor(commission),
                            backgroundColor: _commissionCardBackground(commission),
                            isUnread: commission.hasUnreadMessages,
                            date: commission.deadline ??
                                (commission.id != null
                                    ? 'Commission No. ${commission.id}'
                                    : 'Commission No.'),
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
      _CommissionStatus.rejected: 'Rejected',
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
  final String title;
  final String subtitle;
  final String statusLabel;
  final Color statusColor;
  final Color backgroundColor;
  final bool isUnread;
  final String? date;

  const _CommissionCard({
    required this.title,
    required this.subtitle,
    required this.statusLabel,
    required this.statusColor,
    required this.backgroundColor,
    this.isUnread = false,
    this.date,
  });

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: Colors.black12,
            child: const Icon(Icons.brush, color: Color(0xFF111111), size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: t.titleSmall?.copyWith(
                    fontWeight: isUnread ? FontWeight.w900 : FontWeight.w800,
                    color: const Color(0xFF111111),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: t.bodySmall?.copyWith(
                    color: const Color(0xFF4A4A4A),
                    height: 1.25,
                    fontWeight: isUnread ? FontWeight.w700 : FontWeight.w400,
                  ),
                ),
                if (date != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    date!,
                    style: t.labelSmall?.copyWith(
                      color: const Color(0xFF9B9B9F),
                      fontWeight: isUnread ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                statusLabel,
                style: t.bodySmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: statusColor,
                ),
              ),
            ],
          ),
          const SizedBox(width: 10),
          Container(
            width: 6,
            height: 76,
            decoration: BoxDecoration(
              color: statusColor,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
        ],
      ),
    );
  }
}
