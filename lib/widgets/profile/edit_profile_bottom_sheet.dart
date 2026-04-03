import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../services/api_client.dart';
import '../../state/app_profile_scope.dart';
import 'profile_avatar.dart';

const int _kMaxImageBytes = 750000;

// Match [CreatePostScreen] label + field styling.
const Color _labelAccent = Color(0xFFFF4A4A);
const Color _labelMuted = Color(0xFF8C8C90);
const Color _fieldFill = Color(0xFFF6F6F6);
const Color _uploadStroke = Color(0xFFE5E5E5);

Map<String, String> _defaultSocial() => {
      'facebook': '',
      'instagram': '',
      'twitter': '',
      'website': '',
    };

/// Edit profile in a tall bottom sheet — chrome and fields match [CreatePostScreen] (sheet mode).
Future<bool> showEditProfileBottomSheet(
  BuildContext context, {
  required String initialUsername,
  required String initialFirstName,
  required String initialLastName,
  String? initialAvatarUrl,
  Map<String, String>? initialSocialLinks,
  bool initialTipsEnabled = false,
  String? initialTipsUrl,
}) async {
  final r = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) {
      final height = MediaQuery.sizeOf(sheetContext).height * 0.92;
      return Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(sheetContext).bottom,
        ),
        child: SizedBox(
          height: height,
          child: _EditProfileSheet(
            initialUsername: initialUsername,
            initialFirstName: initialFirstName,
            initialLastName: initialLastName,
            initialAvatarUrl: initialAvatarUrl,
            initialSocialLinks: initialSocialLinks ?? _defaultSocial(),
            initialTipsEnabled: initialTipsEnabled,
            initialTipsUrl: initialTipsUrl ?? '',
          ),
        ),
      );
    },
  );
  return r ?? false;
}

class _EditProfileSheet extends StatefulWidget {
  final String initialUsername;
  final String initialFirstName;
  final String initialLastName;
  final String? initialAvatarUrl;
  final Map<String, String> initialSocialLinks;
  final bool initialTipsEnabled;
  final String initialTipsUrl;

  const _EditProfileSheet({
    required this.initialUsername,
    required this.initialFirstName,
    required this.initialLastName,
    required this.initialAvatarUrl,
    required this.initialSocialLinks,
    required this.initialTipsEnabled,
    required this.initialTipsUrl,
  });

  @override
  State<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<_EditProfileSheet> {
  final _api = ApiClient();
  final _picker = ImagePicker();
  late final TextEditingController _username;
  late final TextEditingController _firstName;
  late final TextEditingController _lastName;
  late final TextEditingController _facebook;
  late final TextEditingController _instagram;
  late final TextEditingController _twitter;
  late final TextEditingController _website;
  late final TextEditingController _tipsUrl;

  String? _serverAvatarUrl;
  String? _newPhotoDataUrl;
  bool _removedPhoto = false;
  bool _saving = false;
  bool _pickingImage = false;
  late bool _tipsEnabled;

  @override
  void initState() {
    super.initState();
    _username = TextEditingController(text: widget.initialUsername);
    _firstName = TextEditingController(text: widget.initialFirstName);
    _lastName = TextEditingController(text: widget.initialLastName);
    final s = widget.initialSocialLinks;
    _facebook = TextEditingController(text: s['facebook'] ?? '');
    _instagram = TextEditingController(text: s['instagram'] ?? '');
    _twitter = TextEditingController(text: s['twitter'] ?? '');
    _website = TextEditingController(text: s['website'] ?? '');
    _tipsUrl = TextEditingController(text: widget.initialTipsUrl);
    _tipsEnabled = widget.initialTipsEnabled;
    _serverAvatarUrl = widget.initialAvatarUrl;
  }

  @override
  void dispose() {
    _username.dispose();
    _firstName.dispose();
    _lastName.dispose();
    _facebook.dispose();
    _instagram.dispose();
    _twitter.dispose();
    _website.dispose();
    _tipsUrl.dispose();
    super.dispose();
  }

  String? get _previewUrl {
    if (_removedPhoto) return null;
    if (_newPhotoDataUrl != null) return _newPhotoDataUrl;
    return _serverAvatarUrl;
  }

  Future<void> _pickPhoto() async {
    await showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Take photo'),
              onTap: () async {
                Navigator.of(ctx).pop();
                await _pickFromSource(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from gallery'),
              onTap: () async {
                Navigator.of(ctx).pop();
                await _pickFromSource(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickFromSource(ImageSource source) async {
    if (_pickingImage) return;
    setState(() => _pickingImage = true);
    try {
      if (source == ImageSource.camera) {
        final granted = await Permission.camera.request();
        if (!granted.isGranted) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Camera permission is required to take a photo.')),
          );
          return;
        }
      }
      final x = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 88,
      );
      if (x == null) return;
      final bytes = await x.readAsBytes();
      if (bytes.length > _kMaxImageBytes) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Image is too large. Try another photo.')),
        );
        return;
      }
      final b64 = base64Encode(bytes);
      if (!mounted) return;
      setState(() {
        _newPhotoDataUrl = 'data:image/jpeg;base64,$b64';
        _removedPhoto = false;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to pick image: $e')),
      );
    } finally {
      if (mounted) setState(() => _pickingImage = false);
    }
  }

  void _removePhoto() {
    setState(() {
      _newPhotoDataUrl = null;
      _removedPhoto = true;
    });
  }

  Future<void> _save() async {
    if (_saving) return;
    final u = _username.text.trim();
    if (u.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Username is required.')),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      final tip = _tipsUrl.text.trim();
      await _api.updateProfile(
        username: u,
        firstName: _firstName.text.trim(),
        lastName: _lastName.text.trim(),
        avatarUrl: _newPhotoDataUrl,
        clearAvatar: _removedPhoto && _newPhotoDataUrl == null,
        socialLinks: {
          'facebook': _facebook.text.trim(),
          'instagram': _instagram.text.trim(),
          'twitter': _twitter.text.trim(),
          'website': _website.text.trim(),
        },
        tipsEnabled: _tipsEnabled,
        tipsUrl: tip.isNotEmpty ? tip : null,
        clearTipsUrl: tip.isEmpty,
      );
      final me = await _api.fetchMe();
      if (!mounted) return;
      final user = me['user'];
      if (user is Map) {
        final scope = AppProfileScope.of(context);
        final un = user['username'];
        final fn = user['firstName'];
        final ln = user['lastName'];
        final av = user['avatarUrl'];
        scope.applyServerProfile(
          username: un is String ? un : null,
          firstName: fn is String ? fn : null,
          lastName: ln is String ? ln : null,
          avatarUrl: av is String ? av : null,
          clearAvatar: av == null,
        );
      }
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not save profile.')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _labelBlock(String label) {
    return Text(
      label,
      style: const TextStyle(
        fontWeight: FontWeight.w800,
        color: _labelAccent,
      ),
    );
  }

  InputDecoration _filledDecoration(String? hint) {
    return InputDecoration(
      hintText: hint,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      filled: true,
      fillColor: _fieldFill,
    );
  }

  @override
  Widget build(BuildContext context) {
    final titleStyle = Theme.of(context).textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w900,
        );

    final bottomInset = MediaQuery.paddingOf(context).bottom;

    final listView = ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _labelBlock('Profile photo'),
            const SizedBox(height: 6),
            Center(child: _avatarBlock(context)),
          ],
        ),
        if (_previewUrl != null && !_saving) ...[
          const SizedBox(height: 8),
          Center(
            child: TextButton(
              onPressed: _removePhoto,
              child: Text(
                'Remove photo',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: const Color(0xFF2564EB),
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ),
          ),
        ],
        const SizedBox(height: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _labelBlock('Username'),
            const SizedBox(height: 6),
            TextField(
              controller: _username,
              textInputAction: TextInputAction.next,
              decoration: _filledDecoration('Username'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _labelBlock('First name'),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _firstName,
                    textInputAction: TextInputAction.next,
                    textCapitalization: TextCapitalization.words,
                    decoration: _filledDecoration('First name'),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _labelBlock('Last name'),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _lastName,
                    textInputAction: TextInputAction.next,
                    textCapitalization: TextCapitalization.words,
                    decoration: _filledDecoration('Last name'),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _labelBlock('Links'),
        const SizedBox(height: 6),
        Text(
          'Profiles you share publicly (paste full URLs).',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: _labelMuted,
                fontWeight: FontWeight.w500,
              ),
        ),
        const SizedBox(height: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _labelBlock('Facebook'),
            const SizedBox(height: 6),
            TextField(
              controller: _facebook,
              keyboardType: TextInputType.url,
              decoration: _filledDecoration('https://…'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _labelBlock('Instagram'),
            const SizedBox(height: 6),
            TextField(
              controller: _instagram,
              keyboardType: TextInputType.url,
              decoration: _filledDecoration('https://…'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _labelBlock('X (Twitter)'),
            const SizedBox(height: 6),
            TextField(
              controller: _twitter,
              keyboardType: TextInputType.url,
              decoration: _filledDecoration('https://…'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _labelBlock('Website'),
            const SizedBox(height: 6),
            TextField(
              controller: _website,
              keyboardType: TextInputType.url,
              decoration: _filledDecoration('https://…'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _labelBlock('Tips'),
        const SizedBox(height: 6),
        Text(
          'Let supporters send tips (e.g. Ko-fi, PayPal.me, Buy Me a Coffee). '
          'Commission checkout can be added later.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: _labelMuted,
                fontWeight: FontWeight.w500,
              ),
        ),
        const SizedBox(height: 8),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(
            'Show tips link on my profile',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1F1F24),
                ),
          ),
          value: _tipsEnabled,
          activeThumbColor: const Color(0xFFFF4A4A),
          activeTrackColor: const Color(0xFFFF4A4A).withValues(alpha: 0.35),
          onChanged: _saving
              ? null
              : (v) {
                  setState(() => _tipsEnabled = v);
                },
        ),
        const SizedBox(height: 4),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _labelBlock('Tips / support link'),
            const SizedBox(height: 6),
            TextField(
              controller: _tipsUrl,
              keyboardType: TextInputType.url,
              textInputAction: TextInputAction.done,
              decoration: _filledDecoration('https://ko-fi.com/yourname'),
            ),
          ],
        ),
      ],
    );

    final bottomButton = Padding(
      padding: EdgeInsets.fromLTRB(16, 8, 16, 18 + bottomInset),
      child: SizedBox(
        width: double.infinity,
        height: 48,
        child: FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFFFF4A4A),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Save profile'),
        ),
      ),
    );

    final formBody = Column(
      children: [
        Expanded(
          child: SafeArea(
            top: false,
            child: listView,
          ),
        ),
        bottomButton,
      ],
    );

    return Material(
      color: Colors.white,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 8),
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFC7C7C7),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              children: [
                IconButton(
                  onPressed: _saving ? null : () => Navigator.of(context).maybePop(false),
                  icon: const Icon(Icons.close, color: Color(0xFF1F1F24)),
                ),
                Expanded(
                  child: Text(
                    'Edit profile',
                    textAlign: TextAlign.center,
                    style: titleStyle,
                  ),
                ),
                const SizedBox(width: 48),
              ],
            ),
          ),
          Expanded(child: formBody),
        ],
      ),
    );
  }

  Widget _avatarBlock(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: (_saving || _pickingImage) ? null : _pickPhoto,
      child: Container(
        width: 140,
        height: 140,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: _fieldFill,
          border: Border.all(color: _uploadStroke),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (_previewUrl != null)
              ProfileAvatar(imageUrl: _previewUrl, radius: 70)
            else
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.add_a_photo_outlined,
                    color: _labelAccent,
                    size: 36,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Add photo',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: const Color(0xFF7B7B82),
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ],
              ),
            if (_previewUrl != null && !_pickingImage)
              Align(
                alignment: Alignment.bottomRight,
                child: Container(
                  margin: const EdgeInsets.all(8),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    'Change',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
              ),
            if (_pickingImage)
              ColoredBox(
                color: Colors.white.withValues(alpha: 0.65),
                child: const Center(
                  child: SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
