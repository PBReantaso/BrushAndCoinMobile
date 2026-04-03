import 'package:flutter/material.dart';
import 'package:timezone/timezone.dart' as tz;

import '../../models/app_models.dart';
import '../../services/api_client.dart';
import '../../state/inbox_badge_scope.dart';
import '../communication/communication_screen.dart';
import '../communication/messages/chat_screen.dart';
import '../home/calendar_map_screen.dart';
import '../home/dashboard_screen.dart';

class AppNotificationItem {
  final int id;
  final String type;
  final String title;
  final String body;
  final Map<String, dynamic> payload;
  final DateTime? readAt;
  final DateTime createdAt;

  AppNotificationItem({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.payload,
    required this.readAt,
    required this.createdAt,
  });

  bool get isUnread => readAt == null;

  factory AppNotificationItem.fromJson(Map<String, dynamic> json) {
    final ph = tz.getLocation('Asia/Manila');
    DateTime? parseRead(dynamic v) {
      if (v == null) return null;
      if (v is String && v.isNotEmpty) {
        return tz.TZDateTime.from(DateTime.parse(v), ph);
      }
      return null;
    }

    DateTime parseCreated(dynamic v) {
      if (v is String && v.isNotEmpty) {
        return tz.TZDateTime.from(DateTime.parse(v), ph);
      }
      return DateTime.now();
    }

    final rawPayload = json['payload'];
    final payload = rawPayload is Map
        ? rawPayload.map((k, v) => MapEntry('$k', v))
        : <String, dynamic>{};

    return AppNotificationItem(
      id: json['id'] is int ? json['id'] as int : int.tryParse('${json['id']}') ?? 0,
      type: '${json['type'] ?? ''}',
      title: '${json['title'] ?? ''}',
      body: '${json['body'] ?? ''}',
      payload: payload,
      readAt: parseRead(json['readAt']),
      createdAt: parseCreated(json['createdAt']),
    );
  }
}

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final _api = ApiClient();
  final _scrollController = ScrollController();
  List<AppNotificationItem> _items = [];
  int? _nextBeforeId;
  bool _loading = true;
  bool _loadingMore = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _load(initial: true);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients || _loadingMore || _nextBeforeId == null) return;
    final pos = _scrollController.position;
    if (pos.pixels > pos.maxScrollExtent - 200) {
      _loadMore();
    }
  }

  Future<void> _load({bool initial = false}) async {
    if (initial) {
      setState(() {
        _loading = true;
        _error = null;
        _items = [];
        _nextBeforeId = null;
      });
    }
    try {
      final page = await _api.fetchNotifications(limit: 30);
      if (!mounted) return;
      setState(() {
        _items = page.notifications.map(AppNotificationItem.fromJson).toList();
        _nextBeforeId = page.nextBeforeId;
        _loading = false;
        _error = null;
      });
      InboxBadgeScope.maybeOf(context)?.refresh();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = '$e';
      });
    }
  }

  Future<void> _loadMore() async {
    final before = _nextBeforeId;
    if (before == null || _loadingMore) return;
    setState(() => _loadingMore = true);
    try {
      final page = await _api.fetchNotifications(limit: 30, beforeId: before);
      if (!mounted) return;
      setState(() {
        final more = page.notifications.map(AppNotificationItem.fromJson).toList();
        _items = [..._items, ...more];
        _nextBeforeId = page.nextBeforeId;
        _loadingMore = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingMore = false);
    }
  }

  Future<void> _onTapItem(AppNotificationItem item) async {
    try {
      await _api.markNotificationRead(item.id);
    } catch (_) {
      // Still allow navigation
    }
    if (!mounted) return;

    setState(() {
      final i = _items.indexWhere((x) => x.id == item.id);
      if (i != -1) {
        _items = [
          ..._items.sublist(0, i),
          AppNotificationItem(
            id: item.id,
            type: item.type,
            title: item.title,
            body: item.body,
            payload: item.payload,
            readAt: DateTime.now(),
            createdAt: item.createdAt,
          ),
          ..._items.sublist(i + 1),
        ];
      }
    });
    InboxBadgeScope.maybeOf(context)?.refresh();

    if (item.type == 'message') {
      final raw = item.payload['conversationId'];
      final cid = raw is int ? raw : int.tryParse('$raw');
      if (cid != null && cid > 0 && mounted) {
        Navigator.of(context).push<void>(
          MaterialPageRoute<void>(
            builder: (_) => ChatScreen(
              conversation: Conversation(id: cid, name: 'Chat'),
            ),
          ),
        );
      }
    } else if (item.type == 'event_new' || item.type == 'event_updated') {
      if (!mounted) return;
      Navigator.of(context).push<void>(
        MaterialPageRoute<void>(builder: (_) => const CalendarMapScreen()),
      );
    } else if (item.type == 'commission_request' || item.type == 'commission_update') {
      if (!mounted) return;
      Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder: (_) => const CommunicationScreen(initialTabIndex: 1),
        ),
      );
    } else if (item.type == 'mention') {
      final raw = item.payload['postId'];
      final hasPost = raw != null && (raw is int ? raw > 0 : int.tryParse('$raw') != null);
      if (hasPost && mounted) {
        Navigator.of(context).push<void>(
          MaterialPageRoute<void>(builder: (_) => const DashboardScreen()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F3F6),
      appBar: AppBar(
        title: const Text('Notifications'),
        surfaceTintColor: Colors.transparent,
      ),
      body: RefreshIndicator(
        onRefresh: () => _load(initial: true),
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(24),
                    children: [
                      Text(_error!, style: Theme.of(context).textTheme.bodyMedium),
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: () => _load(initial: true),
                        child: const Text('Retry'),
                      ),
                    ],
                  )
                : _items.isEmpty
                    ? ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: const [
                          SizedBox(height: 120),
                          Center(child: Text('No notifications yet.')),
                        ],
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: _items.length + (_loadingMore ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index >= _items.length) {
                            return const Padding(
                              padding: EdgeInsets.all(16),
                              child: Center(child: CircularProgressIndicator()),
                            );
                          }
                          final n = _items[index];
                          final local = n.createdAt.toLocal();
                          final time =
                              '${local.month}/${local.day}/${local.year} · '
                              '${local.hour.toString().padLeft(2, '0')}:'
                              '${local.minute.toString().padLeft(2, '0')}';
                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                            elevation: 0,
                            color: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () => _onTapItem(n),
                              child: Padding(
                                padding: const EdgeInsets.all(14),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (n.isUnread)
                                      Container(
                                        width: 8,
                                        height: 8,
                                        margin: const EdgeInsets.only(top: 6, right: 10),
                                        decoration: const BoxDecoration(
                                          color: Color(0xFFFF4A4A),
                                          shape: BoxShape.circle,
                                        ),
                                      )
                                    else
                                      const SizedBox(width: 18),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            n.title,
                                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                                  fontWeight:
                                                      n.isUnread ? FontWeight.w700 : FontWeight.w600,
                                                ),
                                          ),
                                          if (n.body.isNotEmpty) ...[
                                            const SizedBox(height: 4),
                                            Text(
                                              n.body,
                                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                                    color: const Color(0xFF55555C),
                                                  ),
                                            ),
                                          ],
                                          const SizedBox(height: 6),
                                          Text(
                                            time,
                                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                  color: const Color(0xFF8B8B8B),
                                                ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
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
