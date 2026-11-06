import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:tax_hrm/models/ai_chat_models.dart';
import 'package:tax_hrm/utils/colorsfile.dart';
import 'package:tax_hrm/utils/titlesfile.dart';

/// Renders structured employee attendance summaries returned by the HRM AI webhook.
///
/// Features:
/// - Safe image loading using [CachedNetworkImage] and [resolvedImageUrl] to prevent URI host crashes
/// - Displays clean metric chips (Present, Absent, Holiday, Leave) without duplicating summary text
/// - Shows date period in the card header when available
/// - Displays timestamp and token usage in a modern footer
class AiEmployeeSummaryCard extends StatelessWidget {
  final AiChatActionResponse action;
  final DateTime? timestamp;

  const AiEmployeeSummaryCard({
    super.key,
    required this.action,
    this.timestamp,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = ColorConst.isDark;
    final employees = action.employees;
    final dateRange = action.dateRange;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 4, bottom: 4),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E20) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFE2E8F0),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Header ───────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: ColorConst.themeColor.withOpacity(isDark ? 0.15 : 0.08),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(15),
                topRight: Radius.circular(15),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: ColorConst.themeColor,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.badge_rounded,
                    size: 14,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Attendance Summary',
                        style: TextStyle(
                          fontFamily: fontInterBoldString,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : ColorConst.settingTextColors,
                        ),
                      ),
                      if (dateRange != null && dateRange.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          dateRange,
                          style: TextStyle(
                            fontFamily: fontInterRegularString,
                            fontSize: 11,
                            color: isDark ? Colors.white60 : ColorConst.textgrey,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (employees.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: ColorConst.themeColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${employees.length} Employee${employees.length > 1 ? 's' : ''}',
                      style: TextStyle(
                        fontFamily: fontInterBoldString,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: ColorConst.themeColor,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // ── Employee List ─────────────────────────────────────────
          if (employees.isNotEmpty) ...[
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              itemCount: employees.length,
              separatorBuilder: (_, _) => Divider(
                color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF1F5F9),
                height: 18,
                thickness: 1,
              ),
              itemBuilder: (context, index) {
                final emp = employees[index];
                return _buildEmployeeItem(context, emp, isDark);
              },
            ),
          ] else if (action.totalSummary != null && action.totalSummary!.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.all(14),
              child: Text(
                action.totalSummary!,
                style: TextStyle(
                  fontFamily: fontInterRegularString,
                  fontSize: 13,
                  color: isDark ? Colors.white70 : const Color(0xFF334155),
                  height: 1.4,
                ),
              ),
            ),
          ],

          // ── Footer (Timestamp & Token Usage) ───────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              color: isDark ? Colors.black26 : const Color(0xFFF8FAFC),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(15),
                bottomRight: Radius.circular(15),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  DateFormat('hh:mm a').format(timestamp ?? DateTime.now()),
                  style: TextStyle(
                    fontFamily: fontInterRegularString,
                    fontSize: 10,
                    color: ColorConst.textgrey,
                  ),
                ),
                if (action.tokenUsage != null && action.tokenUsage!.totalTokens > 0)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.bolt,
                        size: 12,
                        color: ColorConst.textgrey,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        'Tokens: ${action.tokenUsage!.totalTokens}',
                        style: TextStyle(
                          fontFamily: fontInterRegularString,
                          fontSize: 10,
                          color: ColorConst.textgrey,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmployeeItem(
    BuildContext context,
    AiEmployeeSummaryItem emp,
    bool isDark,
  ) {
    final present = emp.presentCount;
    final absent = emp.absentCount;
    final holiday = emp.holidayInfo;
    final leave = emp.paidLeaveInfo;

    final hasChips = present != null ||
        absent != null ||
        (holiday != null && holiday != '0 hours 0 minutes') ||
        (leave != null && leave != '0 hours 0 minutes');

    // Only show raw summary text if chips couldn't be extracted,
    // or if the summary contains remarks beyond standard Present/Absent/Holiday/Leave.
    final isStandardSummary = RegExp(
      r'^\s*\d+\s+present\s*,\s*\d+\s+absent\s*;\s*Paid\s+holiday:\s*[^;]+;\s*Paid\s+leave:\s*[^;.]+\.?\s*$',
      caseSensitive: false,
    ).hasMatch(emp.summary);

    final showRawSummary = !hasChips || (!isStandardSummary && emp.summary.trim().isNotEmpty);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Name & Avatar
        Row(
          children: [
            _buildAvatar(emp),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                emp.name,
                style: TextStyle(
                  fontFamily: fontInterBoldString,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
            ),
          ],
        ),

        // Quick metric chips (Instant visual breakdown)
        if (hasChips) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              if (present != null)
                _buildMetricChip(
                  label: '$present Present',
                  icon: Icons.check_circle_rounded,
                  bgColor: const Color(0xFF10B981).withOpacity(0.12),
                  textColor: const Color(0xFF059669),
                ),
              if (absent != null)
                _buildMetricChip(
                  label: '$absent Absent',
                  icon: Icons.cancel_rounded,
                  bgColor: const Color(0xFFEF4444).withOpacity(0.12),
                  textColor: const Color(0xFFDC2626),
                ),
              if (holiday != null && holiday != '0 hours 0 minutes')
                _buildMetricChip(
                  label: 'Holiday: $holiday',
                  icon: Icons.beach_access_rounded,
                  bgColor: const Color(0xFF3B82F6).withOpacity(0.12),
                  textColor: const Color(0xFF2563EB),
                ),
              if (leave != null && leave != '0 hours 0 minutes')
                _buildMetricChip(
                  label: 'Leave: $leave',
                  icon: Icons.event_busy_rounded,
                  bgColor: const Color(0xFFF59E0B).withOpacity(0.12),
                  textColor: const Color(0xFFD97706),
                ),
            ],
          ),
        ],

        // Show non-standard extra summary text only when needed
        if (showRawSummary) ...[
          const SizedBox(height: 6),
          Text(
            emp.summary,
            style: TextStyle(
              fontFamily: fontInterRegularString,
              fontSize: 12.5,
              color: isDark ? Colors.white70 : const Color(0xFF475569),
              height: 1.35,
            ),
          ),
        ],
      ],
    );
  }

  /// Safe avatar builder: Uses [CachedNetworkImage] with employee initials fallback.
  /// Prevents any host-missing URI ArgumentErrors and ensures graceful network fallback.
  Widget _buildAvatar(AiEmployeeSummaryItem emp) {
    final initials = _getInitials(emp.name);
    final imageUrl = emp.resolvedImageUrl;

    return ClipOval(
      child: Container(
        width: 32,
        height: 32,
        color: ColorConst.themeColor.withOpacity(0.15),
        child: (imageUrl != null && imageUrl.isNotEmpty)
            ? CachedNetworkImage(
                imageUrl: imageUrl,
                width: 32,
                height: 32,
                fit: BoxFit.cover,
                placeholder: (context, url) => Center(
                  child: Text(
                    initials,
                    style: TextStyle(
                      fontFamily: fontInterBoldString,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: ColorConst.themeColor,
                    ),
                  ),
                ),
                errorWidget: (context, url, error) => Center(
                  child: Text(
                    initials,
                    style: TextStyle(
                      fontFamily: fontInterBoldString,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: ColorConst.themeColor,
                    ),
                  ),
                ),
              )
            : Center(
                child: Text(
                  initials,
                  style: TextStyle(
                    fontFamily: fontInterBoldString,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: ColorConst.themeColor,
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildMetricChip({
    required String label,
    required IconData icon,
    required Color bgColor,
    required Color textColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: textColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  String _getInitials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts[0].isEmpty) return 'EM';
    if (parts.length == 1) {
      return parts[0].substring(0, parts[0].length.clamp(1, 2)).toUpperCase();
    }
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }
}
