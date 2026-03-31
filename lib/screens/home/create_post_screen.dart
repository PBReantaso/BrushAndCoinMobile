import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../services/api_client.dart';

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final _apiClient = ApiClient();
  final _picker = ImagePicker();

  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController(text: '0.00');
  final _tagsController = TextEditingController();

  String _category = '';
  bool _commission = false;
  bool _submitting = false;
  bool _pickingImage = false;
  File? _imageFile;

  static const _categories = ['Digital Art', 'Portrait', 'Traditional', 'Fan Art', 'Other'];

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F3F6),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF3F3F6),
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back),
        ),
        title: const Text(
          'Create Post',
          style: TextStyle(
            decoration: TextDecoration.underline,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 18),
        children: [
          const Text('Upload Artwork', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w500)),
          const SizedBox(height: 10),
          _uploadBox(),
          const SizedBox(height: 16),
          _label('Title'),
          _field(
            child: TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                border: InputBorder.none,
                hintText: 'Give your artwork a title...',
              ),
            ),
          ),
          const SizedBox(height: 12),
          _label('Description'),
          _field(
            child: TextField(
              controller: _descriptionController,
              minLines: 5,
              maxLines: 6,
              decoration: const InputDecoration(
                border: InputBorder.none,
                hintText: 'Tell us about your artwork...',
              ),
            ),
          ),
          const SizedBox(height: 12),
          _label('Category'),
          _field(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _category.isEmpty ? null : _category,
                hint: const Text('Select a category'),
                isExpanded: true,
                items: _categories
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (v) => setState(() => _category = v ?? ''),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _label('Price'),
                    _field(
                      child: TextField(
                        controller: _priceController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(border: InputBorder.none),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _label('Commission'),
                    _field(
                      child: Row(
                        children: [
                          Checkbox(
                            value: _commission,
                            onChanged: (v) => setState(() => _commission = v ?? false),
                          ),
                          const Expanded(
                            child: Text(
                              'This artwork is available for commissions',
                              style: TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _label('Tags'),
          _field(
            child: TextField(
              controller: _tagsController,
              decoration: const InputDecoration(
                border: InputBorder.none,
                hintText: 'Enter tags separated by commas (e.g., portrait, digital)',
              ),
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Tags help others discover your artwork',
            style: TextStyle(fontSize: 12, color: Colors.black54),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              const Spacer(),
              OutlinedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              const SizedBox(width: 10),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: const Color(0xFFFF4A4A)),
                onPressed: _submitting ? null : _submit,
                child: _submitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Create Artwork'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(text, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
      );

  Widget _field({required Widget child}) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFF8F8FA),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFF2D2D2D)),
        ),
        child: child,
      );

  Widget _uploadBox() {
    return InkWell(
      onTap: _pickImage,
      child: Container(
        height: 140,
        decoration: BoxDecoration(
          color: const Color(0xFFF8F8FA),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFF8393AA), style: BorderStyle.solid),
          image: _imageFile != null
              ? DecorationImage(image: FileImage(_imageFile!), fit: BoxFit.cover)
              : null,
        ),
        child: _imageFile != null
            ? const SizedBox.shrink()
            : Center(
                child: _pickingImage
                    ? const CircularProgressIndicator()
                    : const Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.upload, color: Color(0xFF3F4F68)),
                          SizedBox(height: 8),
                          Text('Click to upload', style: TextStyle(fontWeight: FontWeight.w700)),
                          Text('PNG, JPG, GIF up to 5MB', style: TextStyle(color: Color(0xFF768397))),
                        ],
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
      final price = double.tryParse(_priceController.text.trim()) ?? 0;
      await _apiClient.createPost(
        title: title,
        description: _descriptionController.text.trim(),
        category: _category,
        price: price,
        isCommissionAvailable: _commission,
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

