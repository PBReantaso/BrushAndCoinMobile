import 'package:flutter/material.dart';

import '../models/app_models.dart';
import '../services/api_client.dart';

class ArtistsScreen extends StatefulWidget {
  const ArtistsScreen({super.key});

  @override
  State<ArtistsScreen> createState() => _ArtistsScreenState();
}

class _ArtistsScreenState extends State<ArtistsScreen> {
  final _apiClient = ApiClient();
  late Future<List<Artist>> _artistsFuture;

  @override
  void initState() {
    super.initState();
    _artistsFuture = _loadArtists();
  }

  Future<List<Artist>> _loadArtists() async {
    final items = await _apiClient.fetchArtists();
    return items.map(Artist.fromJson).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Discover Artists'),
      ),
      body: FutureBuilder<List<Artist>>(
        future: _artistsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: FilledButton(
                onPressed: () {
                  setState(() {
                    _artistsFuture = _loadArtists();
                  });
                },
                child: const Text('Retry loading artists'),
              ),
            );
          }

          final artists = snapshot.data ?? const <Artist>[];
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: artists.length,
            itemBuilder: (context, index) {
              final artist = artists[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    child: Text(artist.name.characters.first),
                  ),
                  title: Text(artist.name),
                  subtitle: Text('${artist.location} • ⭐ ${artist.rating}'),
                  onTap: () {},
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {},
        icon: const Icon(Icons.upload_file),
        label: const Text('Update Portfolio'),
      ),
    );
  }
}
