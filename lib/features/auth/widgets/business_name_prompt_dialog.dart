import 'package:flutter/material.dart';

Future<String?> showBusinessNamePromptDialog(BuildContext context) {
  return showDialog<String?>(
    context: context,
    barrierDismissible: false,
    builder: (context) => const BusinessNamePromptDialog(),
  );
}

class BusinessNamePromptDialog extends StatefulWidget {
  const BusinessNamePromptDialog({super.key});

  @override
  State<BusinessNamePromptDialog> createState() =>
      _BusinessNamePromptDialogState();
}

class _BusinessNamePromptDialogState extends State<BusinessNamePromptDialog> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Business name'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Add an optional business name. You can change it later in Account Settings.',
          ),
          const SizedBox(height: 16),
          TextField(
            key: const ValueKey('businessName.onboardingField'),
            controller: _controller,
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.done,
            maxLength: 120,
            decoration: const InputDecoration(
              labelText: 'Business name (optional)',
            ),
            onSubmitted: (_) => Navigator.pop(context, _controller.text),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Skip'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _controller.text),
          child: const Text('Save'),
        ),
      ],
    );
  }
}
