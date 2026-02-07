import 'package:flutter/material.dart';
import 'package:pidayapp/services/database_helper.dart';

class BugReportDialog extends StatefulWidget {
  final String screenName;
  final String? studentName;

  const BugReportDialog({
    super.key,
    required this.screenName,
    this.studentName,
  });

  static void show(BuildContext context,
      {required String screenName, String? studentName}) {
    showDialog(
      context: context,
      builder: (context) => BugReportDialog(
        screenName: screenName,
        studentName: studentName,
      ),
    );
  }

  @override
  State<BugReportDialog> createState() => _BugReportDialogState();
}

class _BugReportDialogState extends State<BugReportDialog> {
  final TextEditingController _controller = TextEditingController();
  bool _isSending = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _sendReport() async {
    final message = _controller.text.trim();
    if (message.isEmpty) return;

    setState(() => _isSending = true);

    try {
      await DatabaseHelper.instance.saveBugReport(
        studentName: widget.studentName ?? "Unknown",
        screenName: widget.screenName,
        message: message,
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Bug report saved! Mr Afsar will see it in the Teacher Panel.'),
            backgroundColor: Color(0xFF8E2157),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save report. Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.bug_report, color: Color(0xFF8E2157)),
          SizedBox(width: 8),
          Text('Report an Issue'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('What went wrong? Please describe the error:'),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: 'e.g. The image is not loading...',
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    const BorderSide(color: Color(0xFF8E2157), width: 2),
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isSending ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isSending ? null : _sendReport,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF8E2157),
            foregroundColor: Colors.white,
          ),
          child: _isSending
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white))
              : const Text('Send Report'),
        ),
      ],
    );
  }
}
