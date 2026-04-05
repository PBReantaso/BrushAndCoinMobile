import 'package:flutter/material.dart';

/// Matches [CreatePostScreen] label + field styling.
const Color _kLabelAccent = Color(0xFFFF4A4A);
const Color _kFieldFill = Color(0xFFF6F6F6);

/// Returns updated title and description, or null if dismissed without saving.
Future<({String title, String description})?> showEditPostBottomSheet(
  BuildContext context, {
  required String initialTitle,
  required String initialDescription,
}) {
  return showModalBottomSheet<({String title, String description})>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) {
      final height = MediaQuery.sizeOf(sheetContext).height * 0.88;
      return Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(sheetContext).bottom,
        ),
        child: SizedBox(
          height: height,
          child: _EditPostSheet(
            initialTitle: initialTitle,
            initialDescription: initialDescription,
          ),
        ),
      );
    },
  );
}

class _EditPostSheet extends StatefulWidget {
  final String initialTitle;
  final String initialDescription;

  const _EditPostSheet({
    required this.initialTitle,
    required this.initialDescription,
  });

  @override
  State<_EditPostSheet> createState() => _EditPostSheetState();
}

class _EditPostSheetState extends State<_EditPostSheet> {
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.initialTitle);
    _descriptionController = TextEditingController(text: widget.initialDescription);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _save() {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Title is required.')),
      );
      return;
    }
    Navigator.of(context).pop((
      title: title,
      description: _descriptionController.text.trim(),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final titleStyle = Theme.of(context).textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w900,
        );

    InputDecoration filledDecoration(String? hint) {
      return InputDecoration(
        hintText: hint,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        filled: true,
        fillColor: _kFieldFill,
      );
    }

    Widget label(String text) {
      return Text(
        text,
        style: const TextStyle(
          fontWeight: FontWeight.w800,
          color: _kLabelAccent,
        ),
      );
    }

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
                    'Edit post',
                    textAlign: TextAlign.center,
                    style: titleStyle,
                  ),
                ),
                const SizedBox(width: 48),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              children: [
                label('Title'),
                const SizedBox(height: 6),
                TextField(
                  controller: _titleController,
                  decoration: filledDecoration('Title'),
                  textCapitalization: TextCapitalization.sentences,
                ),
                const SizedBox(height: 12),
                label('Description'),
                const SizedBox(height: 6),
                TextField(
                  controller: _descriptionController,
                  minLines: 5,
                  maxLines: 8,
                  decoration: filledDecoration('Description'),
                  textCapitalization: TextCapitalization.sentences,
                ),
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 18),
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
                  onPressed: _save,
                  child: const Text('Save'),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
