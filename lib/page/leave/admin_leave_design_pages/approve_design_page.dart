import 'package:flutter/material.dart';
import 'package:tax_hrm/utils/titlesfile.dart';
import 'package:tax_hrm/utils/colorsfile.dart';

class LeaveApproveCard extends StatelessWidget {
  final String name;
  final String reason;
  final String date;
  final String status;
  final Color leaveTypeColor;
  final String duration;
  final String leaveType;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const LeaveApproveCard({
    super.key,
    required this.name,
    required this.reason,
    required this.date,
    this.status = "Approved",
    required this.onEdit,
    required this.onDelete,
    required this.leaveTypeColor,
    required this.duration,
    required this.leaveType,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(
        color: ColorConst.white, // Explicit white background
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
        border: Border.all(color: ColorConst.textBorder),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// 1. HEADER: Name & Duration Badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    name,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: ColorConst.black, // Hardcoded dark slate
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),

              ],
            ),
            const SizedBox(height: 8),

            /// 2. METADATA: Date & Leave Type
            Row(
              children: [
                Icon(Icons.calendar_month_outlined, size: 16, color: ColorConst.textgrey),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    date,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: ColorConst.textgrey,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 12),
                _buildBadge(
                  leaveType,
                  leaveTypeColor.withOpacity(0.1),
                  leaveTypeColor,
                ),
              ],
            ),
            const SizedBox(height: 16),

            /// 3. REASON BLOCK: Highlighted for readability
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: ColorConst.greyOpicityColor,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: ColorConst.textBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    reasonForLeaveString,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: ColorConst.textgrey,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    reason,
                    style: TextStyle(
                      fontSize: 13,
                      color: ColorConst.black,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            Divider(color: ColorConst.textBorder, height: 1),
            const SizedBox(height: 12),

            /// 4. FOOTER: Status Indicator & Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildStatusIndicator(status),
                Row(
                  children: [
                    _iconBtn(Icons.edit_outlined, const Color(0xFF3182CE), onEdit),
                    const SizedBox(width: 8),
                    _iconBtn(Icons.delete_outline, const Color(0xFFE53E3E), onDelete),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Helper: Reusable Badge for Leave Type and Duration
  Widget _buildBadge(String text, Color bgColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }

  /// Helper: Status Indicator with glowing dot
  Widget _buildStatusIndicator(String statusText) {
    // Dynamically adjust color if status is pending, otherwise default to green
    final bool isPending = statusText.toLowerCase() == 'pending';
    final Color primaryColor = isPending ? Colors.orange : Colors.green;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: primaryColor,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: primaryColor.withOpacity(0.4),
                blurRadius: 4,
                spreadRadius: 1,
              )
            ],
          ),
        ),
        const SizedBox(width: 8),
        Text(
          statusText,
          style: TextStyle(
            color: isPending ? Colors.orange.shade800 : Colors.green.shade800,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ],
    );
  }

  /// Helper: Action Buttons with InkWell ripple effect
  Widget _iconBtn(IconData icon, Color color, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        splashColor: color.withOpacity(0.2),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 20, color: color),
        ),
      ),
    );
  }
}