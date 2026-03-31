import 'package:flutter/material.dart';

import '../../models/app_models.dart';
import '../../services/api_client.dart';
import '../../widgets/common/bc_app_bar.dart';
import '../../widgets/home/feed_post_card.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _HomeData {
  final List<Project> projects;

  _HomeData({required this.projects});
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _apiClient = ApiClient();
  late Future<_HomeData> _homeFuture;

  @override
  void initState() {
    super.initState();
    _homeFuture = _loadHome();
  }

  Future<_HomeData> _loadHome() async {
    final results = await Future.wait([
      _apiClient.fetchDashboardProjects(),
    ]);
    final projects = (results[0]).map(Project.fromJson).toList();
    return _HomeData(projects: projects);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const BcAppBar(),
      body: FutureBuilder<_HomeData>(
        future: _homeFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            final error = snapshot.error;
            final message = error is ApiException ? error.message : error.toString();
            // Helps when testing on emulator: socket/DNS errors will show up here.
            // ignore: avoid_print
            print('Home feed error: $message');
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Failed to load home feed.'),
                  const SizedBox(height: 8),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: () {
                      setState(() {
                        _homeFuture = _loadHome();
                      });
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final data = snapshot.data ?? _HomeData(projects: const []);
          final posts = data.projects;

          return CustomScrollView(
            slivers: [
              const SliverToBoxAdapter(
                child: Divider(height: 1, color: Color(0xFFD8D8DE)),
              ),
              SliverList.separated(
                itemCount: posts.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final p = posts[index];
                  final tags = <String>[
                    if (p.status == ProjectStatus.inquiry) 'Inquiry',
                    if (p.status == ProjectStatus.inProgress) 'In Progress',
                    if (p.status == ProjectStatus.completed) 'Completed',
                    if (p.milestones.isNotEmpty) 'Milestones',
                    'Commission',
                  ];

                  return FeedPostCard(
                    author: p.clientName.isEmpty ? 'Brush&Coin' : p.clientName,
                    subtitle: 'March 14',
                    title: p.title.isEmpty
                        ? 'Lorem Ipsum Lorem Ipsum Lorem Ipsum'
                        : p.title,
                    tags: tags,
                  );
                },
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 16)),
            ],
          );
        },
      ),
    );
  }
}
