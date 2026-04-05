import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Small icon buttons for Facebook, Instagram, X, website, and optional tips — same data as edit profile.
class ProfileSocialLinksRow extends StatelessWidget {
  final Map<String, String> socialLinks;
  final bool tipsEnabled;
  final String? tipsUrl;

  const ProfileSocialLinksRow({
    super.key,
    required this.socialLinks,
    this.tipsEnabled = false,
    this.tipsUrl,
  });

  static Map<String, String> emptyMap() => {
        'facebook': '',
        'instagram': '',
        'twitter': '',
        'website': '',
      };

  static Map<String, String> parseMap(dynamic v) {
    const keys = ['facebook', 'instagram', 'twitter', 'website'];
    final out = <String, String>{};
    if (v is Map) {
      for (final k in keys) {
        final x = v[k];
        out[k] = x is String ? x.trim() : '';
      }
      return out;
    }
    return emptyMap();
  }

  String? _normalizedUrl(String raw) {
    final t = raw.trim();
    if (t.isEmpty) return null;
    if (t.startsWith('http://') || t.startsWith('https://')) return t;
    return 'https://$t';
  }

  Future<void> _open(BuildContext context, String raw) async {
    final s = _normalizedUrl(raw);
    if (s == null) return;
    final uri = Uri.tryParse(s);
    if (uri == null || !(uri.isScheme('http') || uri.isScheme('https'))) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid link.')),
        );
      }
      return;
    }
    try {
      var ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok) {
        ok = await launchUrl(uri, mode: LaunchMode.platformDefault);
      }
      if (!ok && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open link.')),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open link.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final fb = socialLinks['facebook'] ?? '';
    final ig = socialLinks['instagram'] ?? '';
    final tw = socialLinks['twitter'] ?? '';
    final web = socialLinks['website'] ?? '';
    final tip = tipsEnabled && (tipsUrl?.trim().isNotEmpty ?? false) ? tipsUrl!.trim() : '';

    final entries = <({String url, IconData icon, String label})>[];
    if (fb.isNotEmpty) {
      entries.add((url: fb, icon: Icons.facebook, label: 'Facebook'));
    }
    if (ig.isNotEmpty) {
      entries.add((url: ig, icon: Icons.camera_alt_outlined, label: 'Instagram'));
    }
    if (tw.isNotEmpty) {
      entries.add((url: tw, icon: Icons.chat_bubble_outline, label: 'X'));
    }
    if (web.isNotEmpty) {
      entries.add((url: web, icon: Icons.language, label: 'Website'));
    }
    if (tip.isNotEmpty) {
      entries.add((url: tip, icon: Icons.volunteer_activism_outlined, label: 'Tips'));
    }

    if (entries.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final e in entries)
            Tooltip(
              message: e.label,
              child: Material(
                color: const Color(0xFFF0F0F4),
                borderRadius: BorderRadius.circular(10),
                child: InkWell(
                  onTap: () => _open(context, e.url),
                  borderRadius: BorderRadius.circular(10),
                  child: SizedBox(
                    width: 40,
                    height: 40,
                    child: Icon(
                      e.icon,
                      size: 22,
                      color: const Color(0xFFFF4A4A),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
