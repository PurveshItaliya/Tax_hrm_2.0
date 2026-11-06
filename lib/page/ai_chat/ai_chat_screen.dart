import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tax_hrm/controllers/ai_chat_controller.dart';
import 'package:tax_hrm/page/ai_chat/widgets/ai_chat_bubble.dart';
import 'package:tax_hrm/page/ai_chat/widgets/ai_chat_input.dart';
import 'package:tax_hrm/page/ai_chat/widgets/ai_quick_suggestions.dart';
import 'package:tax_hrm/utils/colorsfile.dart';
import 'package:tax_hrm/utils/titlesfile.dart';

/// Full screen AI Chat Assistant for TAX HRM 2.0.
///
/// Follows Master Architecture & Performance Rules:
/// - Screen -> Controller -> Repository -> Service
/// - Instant navigation (<100ms) and level-1 memory caching
/// - Granular Obx reactivity on chat list and input bar
class AiChatScreen extends StatefulWidget {
  const AiChatScreen({super.key});

  @override
  State<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends State<AiChatScreen> {
  late final AiChatController controller;

  @override
  void initState() {
    super.initState();
    // Register controller if not already present
    if (Get.isRegistered<AiChatController>()) {
      controller = Get.find<AiChatController>();
    } else {
      controller = Get.put(AiChatController());
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final isTablet = size.width > 600;
    final maxContentWidth = isTablet ? 760.0 : double.infinity;
    final isDark = ColorConst.isDark;

    return Scaffold(
      backgroundColor: ColorConst.scaffoldColor,
      appBar: _buildAppBar(context),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxContentWidth),
            child: Column(
              children: [
                // ── 1. Scrollable Message Feed ─────────────────────
                Expanded(
                  child: Obx(() {
                    return ListView.builder(
                      controller: controller.scrollController,
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      itemCount: controller.messages.length +
                          (controller.isLoading.value ? 1 : 0),
                      itemBuilder: (context, index) {
                        // Show typing indicator at the end if loading
                        if (index == controller.messages.length) {
                          return _buildTypingIndicator(isDark);
                        }

                        final message = controller.messages[index];
                        return AiChatBubble(
                          message: message,
                          availableLeaveTypes: controller.companyLeaveTypes,
                          onConfirm: (leaveType, reason) async {
                            if (message.actionResponse != null) {
                              return await controller.handleDirectLeaveSubmit(
                                message.actionResponse!,
                                leaveType,
                                reason,
                              );
                            }
                            return false;
                          },
                          onEdit: () => message.actionResponse != null
                              ? controller.handleEdit(context, message.actionResponse!)
                              : null,
                          onQuickSelect: controller.handleQuickSelect,
                        );
                      },
                    );
                  }),
                ),

                // ── 2. Quick Suggestions Row ───────────────────────
                Obx(() {
                  if (controller.isLoading.value) return const SizedBox.shrink();
                  return AiQuickSuggestions(
                    suggestions: controller.quickHints,
                    isAdmin: controller.isAdmin.value,
                    employeeNames: controller.employeeNames,
                    selectedEmployee: controller.selectedEmployeeFilter.value,
                    onSelectEmployee: controller.selectEmployeeFilter,
                    onSelect: (prompt) => controller.sendMessage(prompt),
                  );
                }),

                // ── 3. Pinned Bottom Input Bar ────────────────────
                Obx(() {
                  final hint = controller.isAdmin.value
                      ? (controller.selectedEmployeeFilter.value.isNotEmpty
                          ? 'Ask AI for ${controller.selectedEmployeeFilter.value} (e.g. Apply leave tomorrow)...'
                          : 'Ask AI for any employee (e.g. Apply leave for Rahul today)...')
                      : 'Ask AI or apply leave (e.g. add today second half leave)...';

                  return AiChatInput(
                    controller: controller.textController,
                    focusNode: controller.focusNode,
                    isLoading: controller.isLoading.value,
                    hintText: hint,
                    onSend: () => controller.sendMessage(),
                  );
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Custom top app bar with AI branding and Clear Conversation action
  PreferredSizeWidget _buildAppBar(BuildContext context) {
    final isDark = ColorConst.isDark;

    return AppBar(
      backgroundColor: isDark ? const Color(0xFF1C1C1E) : Colors.white,
      elevation: 0.5,
      leading: IconButton(
        icon: Icon(
          Icons.arrow_back_ios_new_rounded,
          size: 20,
          color: ColorConst.appbarTextColor,
        ),
        onPressed: () => Navigator.pop(context),
      ),
      titleSpacing: 0,
      title: Row(
        children: [
          // Glowing AI Avatar
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [ColorConst.themeColor, const Color(0xFF6366F1)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: ColorConst.themeColor.withOpacity(0.35),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(
              Icons.auto_awesome,
              size: 18,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'HRM AI Assistant',
                    style: TextStyle(
                      fontFamily: fontInterBoldString,
                      fontSize: 15,
                      color: ColorConst.appbarTextColor,
                    ),
                  ),
                  Obx(() {
                    if (!controller.isAdmin.value) return const SizedBox.shrink();
                    return Container(
                      margin: const EdgeInsets.only(left: 6),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 1.5,
                      ),
                      decoration: BoxDecoration(
                        color: ColorConst.themeColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'ADMIN',
                        style: TextStyle(
                          fontFamily: fontInterBoldString,
                          fontSize: 9.5,
                          color: ColorConst.themeColor,
                          letterSpacing: 0.5,
                        ),
                      ),
                    );
                  }),
                ],
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      color: Color(0xFF22C55E),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    'Online • Instant Help',
                    style: TextStyle(
                      fontFamily: fontInterRegularString,
                      fontSize: 11,
                      color: ColorConst.textgrey,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
      actions: [
        IconButton(
          tooltip: 'Clear Chat',
          icon: Icon(
            Icons.delete_outline_rounded,
            size: 22,
            color: ColorConst.textgrey,
          ),
          onPressed: () {
            _showClearDialog(context);
          },
        ),
      ],
    );
  }

  void _showClearDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Clear Conversation?',
          style: TextStyle(
            fontFamily: fontInterBoldString,
            fontSize: 16,
          ),
        ),
        content: Text(
          'Are you sure you want to clear the active conversation?',
          style: TextStyle(
            fontFamily: fontInterRegularString,
            fontSize: 13,
            color: ColorConst.textgrey,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: TextStyle(
                fontFamily: fontInterMediumString,
                color: ColorConst.textgrey,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              controller.clearChat();
            },
            child: Text(
              'Clear',
              style: TextStyle(
                fontFamily: fontInterSemiBoldString,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Animated typing indicator while AI is processing response
  Widget _buildTypingIndicator(bool isDark) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E20) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFE5E7EB),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [ColorConst.themeColor, const Color(0xFF6366F1)],
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.auto_awesome,
                size: 11,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Thinking...',
              style: TextStyle(
                fontFamily: fontInterMediumString,
                fontSize: 12.5,
                color: ColorConst.themeColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
