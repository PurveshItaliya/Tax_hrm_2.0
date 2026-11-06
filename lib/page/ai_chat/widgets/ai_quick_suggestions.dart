import 'package:flutter/material.dart';
import 'package:tax_hrm/utils/colorsfile.dart';
import 'package:tax_hrm/utils/titlesfile.dart';

/// Quick suggestion chips shown above the input bar to help users initiate actions fast.
///
/// Supports:
/// - Admin Mode: Filter chips by employee name + hints with diverse user names
/// - Employee Mode: Standard personal action hints
/// - Rich visual aesthetics, dark mode support, and smooth bouncing physics
class AiQuickSuggestions extends StatelessWidget {
  final Function(String query) onSelect;
  final List<String> suggestions;
  final bool isAdmin;
  final List<String> employeeNames;
  final String selectedEmployee;
  final Function(String employeeName)? onSelectEmployee;

  const AiQuickSuggestions({
    super.key,
    required this.onSelect,
    this.suggestions = const [],
    this.isAdmin = false,
    this.employeeNames = const [],
    this.selectedEmployee = '',
    this.onSelectEmployee,
  });

  static const List<String> defaultSuggestions = [
    'add today second half leave',
    'Apply casual leave for tomorrow',
    'Sick leave for 2 days',
    'First half leave on Friday',
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = ColorConst.isDark;
    final displaySuggestions =
        suggestions.isNotEmpty ? suggestions : defaultSuggestions;

    final showEmployeeFilter = isAdmin && employeeNames.isNotEmpty;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Admin Employee Filter Bar (Level 1 fast selector) ──
          if (showEmployeeFilter) ...[
            SizedBox(
              height: 28,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: employeeNames.length + 1,
                separatorBuilder: (context, index) => const SizedBox(width: 6),
                itemBuilder: (context, index) {
                  if (index == 0) {
                    final isAllSelected = selectedEmployee.isEmpty;
                    return _buildEmployeeChip(
                      label: 'All Employees',
                      isSelected: isAllSelected,
                      icon: Icons.groups_rounded,
                      isDark: isDark,
                      onTap: () => onSelectEmployee?.call(''),
                    );
                  }

                  final empName = employeeNames[index - 1];
                  final isSelected = selectedEmployee.toLowerCase() ==
                      empName.toLowerCase();

                  return _buildEmployeeChip(
                    label: empName,
                    isSelected: isSelected,
                    icon: Icons.person_rounded,
                    isDark: isDark,
                    onTap: () => onSelectEmployee?.call(empName),
                  );
                },
              ),
            ),
            const SizedBox(height: 6),
          ],

          // ── Quick Suggestions Chips Row ─────────────────────────
          SizedBox(
            height: 38,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: displaySuggestions.length,
              separatorBuilder: (context, index) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final item = displaySuggestions[index];
                return InkWell(
                  onTap: () => onSelect(item),
                  borderRadius: BorderRadius.circular(19),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E1E20) : Colors.white,
                      borderRadius: BorderRadius.circular(19),
                      border: Border.all(
                        color: isDark
                            ? const Color(0xFF2C2C2E)
                            : const Color(0xFFE5E7EB),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color:
                              Colors.black.withOpacity(isDark ? 0.25 : 0.03),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            color: ColorConst.themeColor.withOpacity(0.12),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Icon(
                              isAdmin
                                  ? Icons.alternate_email_rounded
                                  : Icons.auto_awesome,
                              size: 11,
                              color: ColorConst.themeColor,
                            ),
                          ),
                        ),
                        const SizedBox(width: 7),
                        RichText(
                          text: TextSpan(
                            children: _buildHintSpans(item, isDark),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Builds individual employee filter pill chip
  Widget _buildEmployeeChip({
    required String label,
    required bool isSelected,
    required IconData icon,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  colors: [ColorConst.themeColor, ColorConst.darkGreenColor],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isSelected
              ? null
              : (isDark ? const Color(0xFF252528) : const Color(0xFFF3F4F6)),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? Colors.transparent
                : (isDark
                    ? const Color(0xFF3A3A3C)
                    : const Color(0xFFE5E7EB)),
            width: 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: ColorConst.themeColor.withOpacity(0.3),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? Icons.check_circle_rounded : icon,
              size: 12,
              color: isSelected
                  ? Colors.white
                  : (isDark ? Colors.white70 : const Color(0xFF4B5563)),
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontFamily:
                    isSelected ? fontInterSemiBoldString : fontInterMediumString,
                fontSize: 11,
                color: isSelected
                    ? Colors.white
                    : (isDark ? Colors.white70 : const Color(0xFF374151)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds styled text spans, highlighting employee names in admin hints
  List<InlineSpan> _buildHintSpans(String text, bool isDark) {
    if (!isAdmin || employeeNames.isEmpty) {
      return [
        TextSpan(
          text: text,
          style: TextStyle(
            fontFamily: fontInterMediumString,
            fontSize: 12,
            color: isDark ? Colors.white70 : const Color(0xFF374151),
          ),
        ),
      ];
    }

    // Match employee name inside the hint text
    for (final name in employeeNames) {
      final idx = text.toLowerCase().indexOf(name.toLowerCase());
      if (idx != -1) {
        final before = text.substring(0, idx);
        final matched = text.substring(idx, idx + name.length);
        final after = text.substring(idx + name.length);
        return [
          if (before.isNotEmpty)
            TextSpan(
              text: before,
              style: TextStyle(
                fontFamily: fontInterMediumString,
                fontSize: 12,
                color: isDark ? Colors.white70 : const Color(0xFF374151),
              ),
            ),
          TextSpan(
            text: matched,
            style: TextStyle(
              fontFamily: fontInterSemiBoldString,
              fontSize: 12.2,
              color: ColorConst.themeColor,
            ),
          ),
          if (after.isNotEmpty)
            TextSpan(
              text: after,
              style: TextStyle(
                fontFamily: fontInterMediumString,
                fontSize: 12,
                color: isDark ? Colors.white70 : const Color(0xFF374151),
              ),
            ),
        ];
      }
    }

    return [
      TextSpan(
        text: text,
        style: TextStyle(
          fontFamily: fontInterMediumString,
          fontSize: 12,
          color: isDark ? Colors.white70 : const Color(0xFF374151),
        ),
      ),
    ];
  }
}
