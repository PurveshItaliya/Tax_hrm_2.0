import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:tax_hrm/models/ai_chat_models.dart';
import 'package:tax_hrm/page/ai_chat/widgets/leave_confirmation_card.dart';
import 'package:tax_hrm/utils/colorsfile.dart';
import 'package:tax_hrm/utils/titlesfile.dart';

/// Renders a single chat bubble in the AI Chat screen.
///
/// Supports user messages (right-aligned, brand gradient) and AI messages
/// (left-aligned, soft card with bot avatar and optional embedded action cards).
class AiChatBubble extends StatelessWidget {
  final AiChatMessage message;
  final Future<bool> Function(String? leaveType, String? reason) onConfirm;
  final VoidCallback onEdit;
  final Function(String fieldName, String value)? onQuickSelect;
  final List<String>? availableLeaveTypes;

  const AiChatBubble({
    super.key,
    required this.message,
    required this.onConfirm,
    required this.onEdit,
    this.onQuickSelect,
    this.availableLeaveTypes,
  });

  @override
  Widget build(BuildContext context) {
    if (message.isUser) {
      return _buildUserBubble(context);
    } else {
      return _buildAiBubble(context);
    }
  }

  /// User message bubble (right-aligned)
  Widget _buildUserBubble(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final maxBubbleWidth = (size.width * 0.78).clamp(240.0, 520.0);

    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12, left: 40),
        constraints: BoxConstraints(maxWidth: maxBubbleWidth),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [ColorConst.themeColor, ColorConst.darkGreenColor],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(4),
            bottomLeft: Radius.circular(16),
            bottomRight: Radius.circular(16),
          ),
          boxShadow: [
            BoxShadow(
              color: ColorConst.themeColor.withOpacity(0.25),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              message.text,
              style: TextStyle(
                fontFamily: fontInterRegularString,
                fontSize: 14,
                color: Colors.white,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  DateFormat('hh:mm a').format(message.timestamp),
                  style: TextStyle(
                    fontFamily: fontInterRegularString,
                    fontSize: 10,
                    color: Colors.white.withOpacity(0.75),
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(
                  Icons.done_all_rounded,
                  size: 13,
                  color: Colors.white70,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// AI message bubble (left-aligned)
  Widget _buildAiBubble(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final maxBubbleWidth = (size.width * 0.88).clamp(280.0, 620.0);
    final isDark = ColorConst.isDark;

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14, right: 24),
        constraints: BoxConstraints(maxWidth: maxBubbleWidth),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // AI Bot Avatar
            Container(
              width: 32,
              height: 32,
              margin: const EdgeInsets.only(top: 2, right: 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    ColorConst.themeColor,
                    const Color(0xFF6366F1),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: ColorConst.themeColor.withOpacity(0.3),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.auto_awesome,
                size: 16,
                color: Colors.white,
              ),
            ),

            // Message Bubble & Action Card
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E1E20) : Colors.white,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(4),
                        topRight: Radius.circular(16),
                        bottomLeft: Radius.circular(16),
                        bottomRight: Radius.circular(16),
                      ),
                      border: Border.all(
                        color: isDark
                            ? const Color(0xFF2C2C2E)
                            : const Color(0xFFE5E7EB),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          message.text,
                          style: TextStyle(
                            fontFamily: fontInterRegularString,
                            fontSize: 13.5,
                            color: isDark ? Colors.white : const Color(0xFF1F2937),
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          DateFormat('hh:mm a').format(message.timestamp),
                          style: TextStyle(
                            fontFamily: fontInterRegularString,
                            fontSize: 10,
                            color: ColorConst.textgrey,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Embedded Leave Confirmation Action Card
                  if (message.actionResponse != null &&
                      message.actionResponse!.isLeaveConfirmation) ...[
                    LeaveConfirmationCard(
                      action: message.actionResponse!,
                      onConfirm: onConfirm,
                      onEdit: onEdit,
                      onQuickSelect: onQuickSelect,
                      availableLeaveTypes: availableLeaveTypes,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
