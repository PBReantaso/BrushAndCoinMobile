import 'package:flutter/material.dart';

/// Returns trimmed reason text on submit, or `null` if cancelled.
///
/// The text controller is owned by dialog [State] so it is disposed after the
/// route is removed — disposing it in `finally` after [showDialog] returns
/// triggers `'_dependents.isEmpty'` crashes.
Future<String?> showReportReasonDialog(
  BuildContext context, {
  required String title,
  String hintText = 'Add details (optional)',
}) {
  return showDialog<String?>(
    context: context,
    builder: (ctx) => _ReportReasonDialogWidget(
      title: title,
      hintText: hintText,
    ),
  );
}

class _ReportReasonDialogWidget extends StatefulWidget {
  final String title;
  final String hintText;

  const _ReportReasonDialogWidget({
    required this.title,
    required this.hintText,
  });

  @override
  State<_ReportReasonDialogWidget> createState() =>
      _ReportReasonDialogWidgetState();
}

class _ReportReasonDialogWidgetState extends State<_ReportReasonDialogWidget> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        controller: _controller,
        decoration: InputDecoration(
          hintText: widget.hintText,
          border: const OutlineInputBorder(),
        ),
        maxLines: 4,
        textCapitalization: TextCapitalization.sentences,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () =>
              Navigator.of(context).pop(_controller.text.trim()),
          child: const Text('Submit'),
        ),
      ],
    );
  }
}
