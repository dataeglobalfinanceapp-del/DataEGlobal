part of '../payroll_screen.dart';

class _PayrollTokens {
  const _PayrollTokens._();

  static const Color screenBackground = Color(0xFFF5F6F7);
  static const Color surface = Colors.white;
  static const Color primary = Color(0xFF0F766E);
  static const Color tabSelected = Color(0xFF0B7CFF);
  static const Color textStrong = Color(0xFF111827);
  static const Color textMuted = Color(0xFF4B5563);
  static const Color border = Color(0xFFD8DEE8);
  static const Color divider = Color(0xFFE5E7EB);
  static const Color selectedRow = Color(0xFFEAF4FF);
  static const Color warning = Color(0xFFB45309);
  static const Color warningBackground = Color(0xFFFFFBEB);
  static const Color error = Color(0xFFDC2626);

  static const double cardRadius = 8;
  static const double controlRadius = 6;

  static const EdgeInsets pagePadding = EdgeInsets.fromLTRB(16, 12, 16, 24);

  static const List<BoxShadow> panelShadow = <BoxShadow>[
    BoxShadow(color: Color(0x14000000), blurRadius: 18, offset: Offset(0, 6)),
  ];

  static BoxDecoration get panelDecoration => BoxDecoration(
    color: surface,
    borderRadius: BorderRadius.circular(cardRadius),
    boxShadow: panelShadow,
  );

  static InputDecoration get inputDecoration => InputDecoration(
    filled: true,
    fillColor: surface,
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 15),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(controlRadius),
      borderSide: const BorderSide(color: border),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(controlRadius),
      borderSide: const BorderSide(color: primary, width: 1.4),
    ),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(controlRadius),
      borderSide: const BorderSide(color: border),
    ),
  );

  static InputDecoration get searchDecoration => InputDecoration(
    hintText: 'Search employees...',
    hintStyle: inputHint,
    prefixIcon: const Icon(Icons.search, color: textMuted),
    filled: true,
    fillColor: surface,
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(controlRadius),
      borderSide: const BorderSide(color: border),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(controlRadius),
      borderSide: const BorderSide(color: tabSelected, width: 1.4),
    ),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(controlRadius),
      borderSide: const BorderSide(color: border),
    ),
  );

  static OutlineInputBorder get cellBorder => OutlineInputBorder(
    borderRadius: BorderRadius.circular(controlRadius),
    borderSide: const BorderSide(color: border),
  );

  static OutlineInputBorder get focusedCellBorder => OutlineInputBorder(
    borderRadius: BorderRadius.circular(controlRadius),
    borderSide: const BorderSide(color: primary, width: 1.5),
  );

  static const TextStyle appBarTitle = TextStyle(
    color: Colors.black87,
    fontSize: 17,
    fontWeight: FontWeight.w500,
  );
  static const TextStyle sectionTitle = TextStyle(
    color: Colors.black,
    fontSize: 22,
    fontWeight: FontWeight.w800,
  );
  static const TextStyle employeesTitle = TextStyle(
    color: textStrong,
    fontSize: 28,
    fontWeight: FontWeight.w800,
  );
  static const TextStyle cardTitle = TextStyle(
    color: textStrong,
    fontSize: 22,
    fontWeight: FontWeight.w800,
  );
  static const TextStyle dialogTitle = TextStyle(
    color: textStrong,
    fontSize: 24,
    fontWeight: FontWeight.w800,
  );
  static const TextStyle dialogFieldLabel = TextStyle(
    color: textStrong,
    fontSize: 14,
    fontWeight: FontWeight.w800,
  );
  static const TextStyle dialogOptionalLabel = TextStyle(
    color: textMuted,
    fontSize: 13,
    fontWeight: FontWeight.w500,
  );
  static const TextStyle listHeader = TextStyle(
    color: textMuted,
    fontSize: 12,
    fontWeight: FontWeight.w900,
  );
  static const TextStyle fieldLabel = TextStyle(
    color: Color(0xFF4B5563),
    fontSize: 13,
    fontWeight: FontWeight.w900,
  );
  static const TextStyle cardFieldLabel = TextStyle(
    color: Color(0xFF4B5563),
    fontSize: 12,
    fontWeight: FontWeight.w900,
  );
  static const TextStyle balanceValue = TextStyle(
    color: Colors.black,
    fontSize: 28,
    fontWeight: FontWeight.w900,
  );
  static const TextStyle inputText = TextStyle(
    color: textStrong,
    fontSize: 17,
    fontWeight: FontWeight.w500,
  );
  static const TextStyle inputHint = TextStyle(
    color: Color(0xFF9CA3AF),
    fontSize: 16,
    fontWeight: FontWeight.w400,
  );
  static const TextStyle helperText = TextStyle(
    color: textMuted,
    fontSize: 12,
    fontWeight: FontWeight.w600,
  );
  static const TextStyle cautionText = TextStyle(
    color: warning,
    fontSize: 12,
    fontWeight: FontWeight.w700,
    height: 1.3,
  );
  static const TextStyle employeeListName = TextStyle(
    color: textStrong,
    fontSize: 16,
    fontWeight: FontWeight.w700,
  );
  static const TextStyle detailLabel = TextStyle(
    color: textMuted,
    fontSize: 14,
    fontWeight: FontWeight.w600,
  );
  static const TextStyle detailValue = TextStyle(
    color: textStrong,
    fontSize: 15,
    fontWeight: FontWeight.w800,
    height: 1.35,
  );
  static const TextStyle inlineLabel = TextStyle(
    color: textMuted,
    fontSize: 12,
    fontWeight: FontWeight.w900,
  );
  static const TextStyle cardMiniLabel = TextStyle(
    color: textMuted,
    fontSize: 14,
    fontWeight: FontWeight.w900,
  );
  static const TextStyle employeeName = TextStyle(
    color: Colors.black,
    fontSize: 18,
    fontWeight: FontWeight.w800,
    height: 1.25,
  );
  static const TextStyle rowTotal = TextStyle(
    color: Colors.black,
    fontSize: 22,
    fontWeight: FontWeight.w900,
  );
  static const TextStyle footerTotal = TextStyle(
    color: Colors.black,
    fontSize: 18,
    fontWeight: FontWeight.w900,
  );
}
