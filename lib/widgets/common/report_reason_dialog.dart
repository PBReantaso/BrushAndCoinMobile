import 'package:flutter/material.dart';

/// Returns trimmed reason text on submit, or `null` if cancelled.
Future<String?> showReportReasonDialog(
  BuildContext context, {
  required String title,
  String hintText = 'Add details (optional)',
}) async {
  final controller = TextEditingController();
  try {
    final result = await showDialog<String?>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hintText,
            border: const OutlineInputBorder(),
          ),
          maxLines: 4,
          textCapitalization: TextCapitalization.sentences,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(controller.text.trim()),
            child: const Text('Submit'),
          ),
        ],
      ),
    );
    return result;
  } finally {
    controller.dispose();
  }
}
