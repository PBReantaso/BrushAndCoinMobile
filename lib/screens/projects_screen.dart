import 'package:flutter/material.dart';

import '../models/app_models.dart';
import '../services/api_client.dart';

class ProjectsScreen extends StatefulWidget {
  const ProjectsScreen({super.key});

  @override
  State<ProjectsScreen> createState() => _ProjectsScreenState();
}

class _ProjectsScreenState extends State<ProjectsScreen> {
  final _apiClient = ApiClient();
  late Future<List<Project>> _projectsFuture;

  @override
  void initState() {
    super.initState();
    _projectsFuture = _loadProjects();
  }

  Future<List<Project>> _loadProjects() async {
    final items = await _apiClient.fetchProjects();
    return items.map(Project.fromJson).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Projects & Contracts'),
      ),
      body: FutureBuilder<List<Project>>(
        future: _projectsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: FilledButton(
                onPressed: () {
                  setState(() {
                    _projectsFuture = _loadProjects();
                  });
                },
                child: const Text('Retry loading projects'),
              ),
            );
          }

          final projects = snapshot.data ?? const <Project>[];
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: projects.length,
            itemBuilder: (context, index) {
              final p = projects[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ExpansionTile(
                  title: Text(p.title),
                  subtitle: Text('Client: ${p.clientName}'),
                  children: [
                    for (final m in p.milestones)
                      ListTile(
                        title: Text(m.title),
                        trailing: Text('₱${m.amount.toStringAsFixed(0)}'),
                        leading: Icon(
                          m.isReleased
                              ? Icons.verified
                              : Icons.lock_clock_outlined,
                        ),
                        onTap: () {},
                      ),
                    TextButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.description_outlined),
                      label: const Text('View Digital Contract'),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        child: const Icon(Icons.add),
      ),
    );
  }
}
