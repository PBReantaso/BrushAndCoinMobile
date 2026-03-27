import 'package:flutter/material.dart';

import '../../models/app_models.dart';
import '../../services/api_client.dart';
import '../../widgets/home/feed_post_card.dart';
import '../../widgets/home/story_bubble.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _HomeData {
  final List<Artist> artists;
  final List<Project> projects;

  _HomeData({required this.artists, required this.projects});
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
      _apiClient.fetchArtists(),
      _apiClient.fetchDashboardProjects(),
    ]);
    final artists = (results[0]).map(Artist.fromJson).toList();
    final projects = (results[1]).map(Project.fromJson).toList();
    return _HomeData(artists: artists, projects: projects);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFEDEDF1),
        elevation: 0,
        titleSpacing: 12,
        title: const Text(
          'B&C',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            letterSpacing: 0.4,
            color: Color(0xFF222222),
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.add_circle, color: Color(0xFFFF4A4A)),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.search, color: Color(0xFF303030)),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.notifications, color: Color(0xFF101010)),
          ),
          const SizedBox(width: 4),
        ],
      ),
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

          final data = snapshot.data ?? _HomeData(artists: const [], projects: const []);
          final stories = data.artists.take(12).toList();
          final posts = data.projects;

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 94,
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
                    scrollDirection: Axis.horizontal,
                    itemCount: stories.length + 1,
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return const StoryBubble(
                          label: 'You',
                          initials: 'You',
                        );
                      }
                      final a = stories[index - 1];
                      final initials = a.name
                          .trim()
                          .split(RegExp(r'\\s+'))
                          .where((p) => p.isNotEmpty)
                          .take(2)
                          .map((p) => p.characters.first.toUpperCase())
                          .join();
                      return StoryBubble(
                        label: a.name,
                        initials: initials.isEmpty ? 'A' : initials,
                        onTap: () {},
                      );
                    },
                  ),
                ),
              ),
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
