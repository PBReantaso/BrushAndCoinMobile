import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../services/api_client.dart';

/// Opens create-post as a modal [showModalBottomSheet] (~full height, no sheet animation).
Future<bool?> showCreatePostBottomSheet(BuildContext context) {
  return showModalBottomSheet<bool>(
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
          child: const CreatePostScreen(asBottomSheet: true),
        ),
      );
    },
  );
}

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key, this.asBottomSheet = false});

  /// When true, renders sheet chrome (handle, close) instead of a [Scaffold] + [AppBar].
  final bool asBottomSheet;

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final _apiClient = ApiClient();
  final _picker = ImagePicker();

  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _tagsController = TextEditingController();

  String _category = '';
  bool _submitting = false;
  bool _pickingImage = false;
  File? _imageFile;

  static const _categories = ['Digital Art', 'Portrait', 'Traditional', 'Fan Art', 'Other'];

  // Match [CreateEventScreen] label + field styling.
  static const _labelAccent = Color(0xFFFF4A4A);
  static const _labelMuted = Color(0xFF8C8C90);
  static const _fieldFill = Color(0xFFF6F6F6);
  static const _uploadStroke = Color(0xFFE5E5E5);

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final titleStyle = Theme.of(context).textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w900,
        );

    final bottomInset =
        widget.asBottomSheet ? MediaQuery.paddingOf(context).bottom : 0.0;

    final listView = ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      children: _formScrollChildren(),
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
          onPressed: _submitting ? null : _submit,
          child: _submitting
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Create Artwork'),
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

    if (widget.asBottomSheet) {
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
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: const Icon(Icons.close, color: Color(0xFF1F1F24)),
                  ),
                  Expanded(
                    child: Text(
                      'Create Post',
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

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1F1F24)),
        ),
        title: Text('Create Post', style: titleStyle),
      ),
      body: formBody,
    );
  }

  Widget _labelBlock(String label, Color color) {
    return Text(
      label,
      style: TextStyle(
        fontWeight: FontWeight.w800,
        color: color,
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

  List<Widget> _formScrollChildren() {
    return [
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _labelBlock('Upload Artwork', _labelAccent),
          const SizedBox(height: 6),
          Center(child: _uploadBox()),
        ],
      ),
      const SizedBox(height: 12),
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _labelBlock('Title', _labelAccent),
          const SizedBox(height: 6),
          TextField(
            controller: _titleController,
            decoration: _filledDecoration('Give your artwork a title...'),
          ),
        ],
      ),
      const SizedBox(height: 12),
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _labelBlock('Description', _labelAccent),
          const SizedBox(height: 6),
          TextField(
            controller: _descriptionController,
            minLines: 5,
            maxLines: 6,
            decoration: _filledDecoration('Tell us about your artwork...'),
          ),
        ],
      ),
      const SizedBox(height: 12),
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _labelBlock('Category', _labelAccent),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: _fieldFill,
              borderRadius: BorderRadius.circular(12),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _category.isEmpty ? null : _category,
                hint: Text(
                  'Select a category',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: _labelMuted,
                      ),
                ),
                isExpanded: true,
                items: _categories
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (v) => setState(() => _category = v ?? ''),
              ),
            ),
          ),
        ],
      ),
      const SizedBox(height: 12),
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _labelBlock('Tags', _labelAccent),
          const SizedBox(height: 6),
          TextField(
            controller: _tagsController,
            decoration: _filledDecoration(
              'Enter tags separated by commas (e.g., portrait, digital)',
            ),
          ),
        ],
      ),
      const SizedBox(height: 6),
      Text(
        'Tags help others discover your artwork',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: _labelMuted,
              fontWeight: FontWeight.w500,
            ),
      ),
    ];
  }

  Widget _uploadBox() {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: _pickingImage ? null : _pickImage,
      child: Container(
        width: 220,
        height: 220,
        decoration: BoxDecoration(
          color: _fieldFill,
          border: Border.all(color: _uploadStroke),
          borderRadius: BorderRadius.circular(16),
          image: _imageFile != null
              ? DecorationImage(
                  image: FileImage(_imageFile!),
                  fit: BoxFit.cover,
                )
              : null,
        ),
        child: _imageFile == null
            ? Center(
                child: _pickingImage
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.add_photo_alternate_outlined,
                            color: Color(0xFFFF4A4A),
                            size: 34,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Click to upload',
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                  color: const Color(0xFF7B7B82),
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'PNG, JPG, GIF up to 5MB',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: const Color(0xFF9B9B9F),
                                ),
                          ),
                        ],
                      ),
              )
            : Align(
                alignment: Alignment.bottomRight,
                child: Container(
                  margin: const EdgeInsets.all(8),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
      ),
    );
  }

  Future<void> _pickImage() async {
    if (_pickingImage) return;
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
    setState(() => _pickingImage = true);
    try {
      if (source == ImageSource.camera) {
        final granted = await Permission.camera.request();
        if (!granted.isGranted) return;
      }
      final picked = await _picker.pickImage(source: source, imageQuality: 90);
      if (picked == null) return;
      final file = File(picked.path);
      if (await file.length() > 5 * 1024 * 1024) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Image is larger than 5MB.')),
        );
        return;
      }
      if (!mounted) return;
      setState(() => _imageFile = file);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Unable to pick image: $e')));
    } finally {
      if (mounted) setState(() => _pickingImage = false);
    }
  }

  Future<void> _submit() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Title is required.')));
      return;
    }
    setState(() => _submitting = true);
    try {
      final tags = _tagsController.text
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
      await _apiClient.createPost(
        title: title,
        description: _descriptionController.text.trim(),
        category: _category,
        price: 0,
        isCommissionAvailable: false,
        tags: tags,
        imageUrl: _imageFile?.path,
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }
}

