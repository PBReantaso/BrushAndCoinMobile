import 'package:flutter/material.dart';

import '../../state/app_profile_scope.dart';
import '../../widgets/common/bc_app_bar.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _showGallery = true;

  @override
  Widget build(BuildContext context) {
    final profileState = AppProfileScope.of(context);
    final p = profileState.profile;
    final displayName = [
      p.firstName.trim(),
      p.lastName.trim(),
    ].where((s) => s.isNotEmpty).join(' ');
    final headerName = displayName.isEmpty ? 'Name' : displayName;

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
          GridView.builder(
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
              final colors = _showGallery
                  ? const [
                      [Color(0xFF2A4B79), Color(0xFF8CA6DB)],
                      [Color(0xFF0E7490), Color(0xFF5BB3F2)],
                      [Color(0xFFE5A96D), Color(0xFFCC7B4A)],
                      [Color(0xFFE88999), Color(0xFFF4B5C0)],
                    ]
                  : const [
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
