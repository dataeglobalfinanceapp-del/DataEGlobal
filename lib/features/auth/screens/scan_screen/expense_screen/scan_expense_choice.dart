import 'package:flutter/material.dart';

import 'scan_expense_auto_screen.dart';
import 'scan_expense_manual_screen.dart';

class ScanExpenseScreen extends StatelessWidget {
  const ScanExpenseScreen({super.key});

  Future<void> _openEntry(BuildContext context, Widget screen) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => screen),
    );
    if (!context.mounted) return;
    if (result != null) Navigator.pop(context, result);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Expense',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 17,
            fontWeight: FontWeight.w500,
          ),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _ChoiceCard(
              icon: Icons.edit_outlined,
              title: 'Enter Manually',
              subtitle: 'Type expense details yourself',
              color: const Color(0xFFEFF6FF),
              onTap: () => _openEntry(context, const ScanExpenseManualScreen()),
            ),
            const SizedBox(height: 12),
            _ChoiceCard(
              icon: Icons.document_scanner_outlined,
              title: 'Extract Automatically',
              subtitle: 'Scan a check with the camera',
              color: const Color(0xFFFEF3C7),
              onTap: () => _openEntry(context, const ScanExpenseAutoScreen()),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChoiceCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _ChoiceCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: const Color(0xFF1E40AF), size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Color(0xFF6B7280)),
          ],
        ),
      ),
    );
  }
}
