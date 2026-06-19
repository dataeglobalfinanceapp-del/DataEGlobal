import 'package:flutter/material.dart';

import 'package:biztrack/services/app_clock.dart';

class TestClockOverlay extends StatefulWidget {
  final Widget child;
  final GlobalKey<NavigatorState> navigatorKey;

  const TestClockOverlay({
    super.key,
    required this.child,
    required this.navigatorKey,
  });

  @override
  State<TestClockOverlay> createState() => _TestClockOverlayState();
}

class _TestClockOverlayState extends State<TestClockOverlay> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<DateTime?>(
      valueListenable: AppClock.listenable,
      builder: (context, _, _) {
        final now = AppClock.now;
        return Stack(
          children: [
            widget.child,
            Positioned(
              right: 12,
              bottom: MediaQuery.paddingOf(context).bottom + 12,
              child: _expanded
                  ? _ClockPanel(
                      now: now,
                      navigatorKey: widget.navigatorKey,
                      onCollapse: () => setState(() => _expanded = false),
                    )
                  : _ClockPill(
                      now: now,
                      isOverridden: AppClock.isOverridden,
                      onTap: () => setState(() => _expanded = true),
                    ),
            ),
          ],
        );
      },
    );
  }
}

class _ClockPill extends StatelessWidget {
  final DateTime now;
  final bool isOverridden;
  final VoidCallback onTap;

  const _ClockPill({
    required this.now,
    required this.isOverridden,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: isOverridden
                ? const Color(0xFF111827)
                : const Color(0xEEFFFFFF),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: isOverridden
                  ? const Color(0xFF111827)
                  : const Color(0xFFE5E7EB),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.18),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.schedule,
                size: 16,
                color: isOverridden ? Colors.white : const Color(0xFF111827),
              ),
              const SizedBox(width: 6),
              Text(
                _shortDate(now),
                style: TextStyle(
                  color: isOverridden ? Colors.white : const Color(0xFF111827),
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ClockPanel extends StatelessWidget {
  final DateTime now;
  final GlobalKey<NavigatorState> navigatorKey;
  final VoidCallback onCollapse;

  const _ClockPanel({
    required this.now,
    required this.navigatorKey,
    required this.onCollapse,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        width: 260,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: const Color(0xFFE5E7EB)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.20),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.schedule, size: 18, color: Color(0xFF2563EB)),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Test Clock',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF111827),
                    ),
                  ),
                ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: onCollapse,
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              _fullDate(now),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              AppClock.isOverridden ? 'Using test date' : 'Using current date',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Color(0xFF6B7280),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _StepButton(label: '-1D', onTap: () => AppClock.shiftDays(-1)),
                const SizedBox(width: 6),
                _StepButton(label: '+1D', onTap: () => AppClock.shiftDays(1)),
                const SizedBox(width: 6),
                _StepButton(
                  label: '-1M',
                  onTap: () => AppClock.shiftMonths(-1),
                ),
                const SizedBox(width: 6),
                _StepButton(label: '+1M', onTap: () => AppClock.shiftMonths(1)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickDate,
                    icon: const Icon(Icons.calendar_month, size: 16),
                    label: const Text('Pick'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton(
                    onPressed: AppClock.reset,
                    child: const Text('Reset'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final context = navigatorKey.currentContext;
    if (context == null) return;

    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;
    AppClock.set(AppClock.withDate(picked));
  }
}

class _StepButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _StepButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, 36),
          padding: EdgeInsets.zero,
        ),
        child: Text(label, style: const TextStyle(fontSize: 11)),
      ),
    );
  }
}

String _shortDate(DateTime date) {
  return '${date.month.toString().padLeft(2, '0')}/'
      '${date.day.toString().padLeft(2, '0')}/${date.year}';
}

String _fullDate(DateTime date) {
  return '${date.month.toString().padLeft(2, '0')}/'
      '${date.day.toString().padLeft(2, '0')}/${date.year}';
}
