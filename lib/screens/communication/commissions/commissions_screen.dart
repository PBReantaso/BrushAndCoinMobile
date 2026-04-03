import 'package:flutter/material.dart';

import '../../../models/app_models.dart';
import '../../../services/api_client.dart';
import '../../home/create_post_screen.dart';
import 'commission_detail_screen.dart';

enum _CommissionFilter { all, pending, accepted, inProgress, completed }

class CommissionsScreen extends StatefulWidget {
  const CommissionsScreen({super.key});

  @override
  State<CommissionsScreen> createState() => _CommissionsScreenState();
}

class _CommissionsScreenState extends State<CommissionsScreen> {
  final _apiClient = ApiClient();
  _CommissionFilter _filter = _CommissionFilter.all;
  late Future<List<Project>> _commissionsFuture;

  @override
  void initState() {
    super.initState();
    _commissionsFuture = _loadCommissions();
  }

  Future<List<Project>> _loadCommissions() async {
    final items = await _apiClient.fetchCommissions();
    return items.map(Project.fromJson).toList();
  }

  List<Project> _applyFilter(List<Project> items) {
    if (_filter == _CommissionFilter.all) return items;

    return items.where((project) {
      final status = project.status;
      switch (_filter) {
        case _CommissionFilter.pending:
          return status == ProjectStatus.inquiry;
        case _CommissionFilter.accepted:
        case _CommissionFilter.inProgress:
          return status == ProjectStatus.inProgress;
        case _CommissionFilter.completed:
          return status == ProjectStatus.completed;
        default:
          return true;
      }
    }).toList();
  }

  bool _isSeedCommission(Project project) {
    const seedTitles = ['Portrait Commission', 'Event Mural'];
    const seedClients = ['Ana Santos', 'Local Café'];
    return seedTitles.contains(project.title) ||
        seedClients.contains(project.clientName);
  }

  String _statusLabel(ProjectStatus status) {
    switch (status) {
      case ProjectStatus.inquiry:
        return 'Pending';
      case ProjectStatus.accepted:
        return 'Accepted';
      case ProjectStatus.inProgress:
        return 'In progress';
      case ProjectStatus.completed:
        return 'Completed';
      case ProjectStatus.rejected:
        return 'Rejected';
    }
  }

  Color _statusColor(ProjectStatus status) {
    switch (status) {
      case ProjectStatus.inquiry:
        return const Color(0xFFFF4A4A);
      case ProjectStatus.accepted:
        return const Color(0xFF1976D2);
      case ProjectStatus.inProgress:
        return const Color(0xFFFFA000);
      case ProjectStatus.completed:
        return const Color(0xFF2E7D32);
      case ProjectStatus.rejected:
        return const Color(0xFFB71C1C);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _StatusFilterRow(
            active: _filter,
            onChanged: (v) => setState(() => _filter = v),
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
                  final personalCommissions = snapshot.data ?? [];

                  if (personalCommissions.isNotEmpty) {
                    return Center(
                      child: FilledButton(
                        onPressed: () {
                          setState(() {
                            _commissionsFuture = _loadCommissions();
                          });
                        },
                        child: const Text('Retry loading commissions'),
                      ),
                    );
                  }

                  // No personal commissions available yet, show empty invocation instead.
                  return Center(
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
                  );
                }

                final commissions = _applyFilter(snapshot.data ?? []);
                final visibleCommissions =
                    commissions.where((p) => !_isSeedCommission(p)).toList();

                if (visibleCommissions.isEmpty) {
                  return Center(
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
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    setState(() {
                      _commissionsFuture = _loadCommissions();
                    });
                    await _commissionsFuture;
                  },
                  child: ListView.builder(
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
                            title: commission.title,
                            clientName: commission.clientName,
                            statusLabel: _statusLabel(commission.status),
                            statusColor: _statusColor(commission.status),
                            date: commission.milestones.isNotEmpty
                                ? 'Milestones: ${commission.milestones.length}'
                                : null,
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

class _StatusFilterRow extends StatelessWidget {
  final _CommissionFilter active;
  final ValueChanged<_CommissionFilter> onChanged;

  const _StatusFilterRow({
    required this.active,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    const options = [
      _CommissionFilter.all,
      _CommissionFilter.pending,
      _CommissionFilter.accepted,
      _CommissionFilter.inProgress,
      _CommissionFilter.completed,
    ];

    final labels = <_CommissionFilter, String>{
      _CommissionFilter.all: 'All',
      _CommissionFilter.pending: 'Pending',
      _CommissionFilter.accepted: 'Accepted',
      _CommissionFilter.inProgress: 'In progress',
      _CommissionFilter.completed: 'Completed',
    };

    return SizedBox(
      height: 40,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFEDEDF1),
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.all(6),
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: options.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (context, index) {
            final opt = options[index];
            final selected = opt == active;
            return GestureDetector(
              onTap: () => onChanged(opt),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: selected
                      ? const Color(0xFFFF4A4A)
                      : const Color(0xFFF3F3F6),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Center(
                  child: Text(
                    labels[opt]!,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: selected ? Colors.white : Colors.black87,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _CommissionCard extends StatelessWidget {
  final String title;
  final String clientName;
  final String statusLabel;
  final Color statusColor;
  final String? date;

  const _CommissionCard({
    required this.title,
    required this.clientName,
    required this.statusLabel,
    required this.statusColor,
    this.date,
  });

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
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
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF111111),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Client: $clientName',
                  style: t.bodySmall?.copyWith(
                    color: const Color(0xFF6E6E6E),
                    height: 1.2,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                if (date != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    date!,
                    style: t.labelSmall?.copyWith(color: const Color(0xFF9B9B9F)),
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
