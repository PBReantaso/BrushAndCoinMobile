import 'dart:io';

import 'package:flutter/material.dart';

import '../../services/api_client.dart';
import '../../state/app_profile_scope.dart';
import '../../widgets/common/bc_app_bar.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _showGallery = true;
  final _apiClient = ApiClient();
  late Future<List<_ProfilePost>> _postsFuture;

  @override
  void initState() {
    super.initState();
    _postsFuture = _loadMyPosts();
  }

  Future<List<_ProfilePost>> _loadMyPosts() async {
    final raw = await _apiClient.fetchMyPosts();
    return raw.map(_ProfilePost.fromJson).toList();
  }

  @override
  Widget build(BuildContext context) {
    final profileState = AppProfileScope.of(context);
    final p = profileState.profile;
    final username = p.username.trim();
    final fullName = [
      p.firstName.trim(),
      p.lastName.trim(),
    ].where((s) => s.isNotEmpty).join(' ');
    final headerName = (username.isNotEmpty ? username : fullName).isEmpty
        ? 'Name'
        : (username.isNotEmpty ? username : fullName);

    final genderRaw = p.gender.name; // enum -> 'male' | 'female' | ...
    final genderLabel = switch (genderRaw) {
      'male' => 'Male',
      'female' => 'Female',
      'other' => 'Other',
      'preferNotToSay' => 'Prefer not to say',
      _ => '',
    };

    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F4),
      appBar: const BcAppBar(),
      body: ListView(
        padding: const EdgeInsets.only(top: 8),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Container(
                        width: 185,
                        height: 185,
                        decoration: const BoxDecoration(
                          color: Color(0xFFDCDCDD),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        headerName,
                        style: const TextStyle(fontSize: 14),
                      ),
                      if (genderLabel.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          genderLabel,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.black.withValues(alpha: 0.55),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 142,
                  child: Column(
                    children: [
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: const [
                          Icon(Icons.attach_money, color: Color(0xFFFF4A4A), size: 20),
                          SizedBox(width: 8),
                          Icon(Icons.person_add_alt_1, color: Colors.black, size: 20),
                        ],
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        height: 42,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            elevation: 0,
                            backgroundColor: const Color(0xFFFF3D3D),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () {},
                          child: const Text(
                            'Commission',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.fromLTRB(8, 8, 8, 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE1E1E4),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: const [
                            Text(
                              'Other Socials',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                            SizedBox(height: 6),
                            Divider(height: 1, color: Color(0xFFA6A6A8)),
                            SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                _SocialCircle(
                                  bg: Color(0xFF1877F2),
                                  text: 'f',
                                ),
                                _SocialCircle(
                                  bg: Colors.white,
                                  text: 'X',
                                  fg: Colors.black,
                                ),
                                _SocialCircle(
                                  bg: Color(0xFF1E88E5),
                                  text: 'p',
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          const Center(
            child: Text(
              'Bio',
              style: TextStyle(fontSize: 14, color: Color(0xFF2C2C2C)),
            ),
          ),
          const SizedBox(height: 14),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 0),
            color: const Color(0xFFECECEE),
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _showGallery = true),
                    child: Text(
                      'Gallery',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color:
                            _showGallery ? const Color(0xFFFF3D3D) : Colors.black87,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                Container(width: 1, height: 24, color: const Color(0xFF9D9D9F)),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _showGallery = false),
                    child: Text(
                      'Merchendise',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color:
                            !_showGallery ? const Color(0xFFFF3D3D) : Colors.black87,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          _showGallery
              ? FutureBuilder<List<_ProfilePost>>(
                  future: _postsFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Padding(
                        padding: EdgeInsets.all(24),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }
                    if (snapshot.hasError) {
                      return Padding(
                        padding: const EdgeInsets.all(24),
                        child: Center(
                          child: Text('Failed to load gallery.'),
                        ),
                      );
                    }
                    final posts = snapshot.data ?? const <_ProfilePost>[];
                    if (posts.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.all(24),
                        child: Center(child: Text('No posts yet. Create your first post.')),
                      );
                    }
                    return GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: posts.length,
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 2,
                        crossAxisSpacing: 2,
                        childAspectRatio: 1,
                      ),
                      itemBuilder: (context, index) {
                        final post = posts[index];
                        return _GalleryTile(post: post);
                      },
                    );
                  },
                )
              : GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: 4,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 2,
                    crossAxisSpacing: 2,
                    childAspectRatio: 1,
                  ),
                  itemBuilder: (context, index) {
                    const colors = [
                      [Color(0xFF6F4E37), Color(0xFFD4A373)],
                      [Color(0xFF2F3E46), Color(0xFF84A98C)],
                      [Color(0xFF4A4E69), Color(0xFF9A8C98)],
                      [Color(0xFF5F0F40), Color(0xFF9A031E)],
                    ];
                    final palette = colors[index % colors.length];
                    return Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: palette,
                        ),
                      ),
                      child: const Center(
                        child: Icon(Icons.image, color: Colors.white70),
                      ),
                    );
                  },
                ),
        ],
      ),
    );
  }
}

class _ProfilePost {
  final String? imageUrl;

  const _ProfilePost({required this.imageUrl});

  factory _ProfilePost.fromJson(Map<String, dynamic> json) {
    return _ProfilePost(imageUrl: json['imageUrl'] as String?);
  }
}

class _GalleryTile extends StatelessWidget {
  final _ProfilePost post;

  const _GalleryTile({required this.post});

  @override
  Widget build(BuildContext context) {
    final path = post.imageUrl?.trim() ?? '';
    if (path.isNotEmpty) {
      final imageProvider = path.startsWith('http://') || path.startsWith('https://')
          ? NetworkImage(path) as ImageProvider
          : FileImage(File(path));
      return Image(image: imageProvider, fit: BoxFit.cover, errorBuilder: (_, __, ___) {
        return _fallback();
      });
    }
    return _fallback();
  }

  Widget _fallback() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2A4B79), Color(0xFF8CA6DB)],
        ),
      ),
      child: const Center(child: Icon(Icons.image, color: Colors.white70)),
    );
  }
}

class _SocialCircle extends StatelessWidget {
  final Color bg;
  final String text;
  final Color fg;

  const _SocialCircle({
    required this.bg,
    required this.text,
    this.fg = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: bg,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        text,
        style: TextStyle(
          color: fg,
          fontWeight: FontWeight.w800,
          fontSize: 20,
        ),
      ),
    );
  }
}
