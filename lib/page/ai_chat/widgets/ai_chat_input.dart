import 'package:flutter/material.dart';
import 'package:tax_hrm/utils/colorsfile.dart';
import 'package:tax_hrm/utils/titlesfile.dart';

/// Pinned bottom input widget with expanding text field and animated send button.
class AiChatInput extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isLoading;
  final VoidCallback onSend;
  final String? hintText;

  const AiChatInput({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.isLoading,
    required this.onSend,
    this.hintText,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = ColorConst.isDark;
    final bottomPadding = MediaQuery.paddingOf(context).bottom;

    return Container(
      padding: EdgeInsets.only(
        left: 14,
        right: 14,
        top: 10,
        bottom: bottomPadding > 0 ? bottomPadding + 6 : 12,
      ),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFE5E7EB),
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.25 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Text Input Field Container
          Expanded(
            child: Container(
              constraints: const BoxConstraints(maxHeight: 120),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF2C2C2E)
                    : const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: isDark
                      ? const Color(0xFF3A3A3C)
                      : const Color(0xFFE5E7EB),
                  width: 1,
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
              child: TextField(
                controller: controller,
                focusNode: focusNode,
                maxLines: null,
                keyboardType: TextInputType.multiline,
                textCapitalization: TextCapitalization.sentences,
                style: TextStyle(
                  fontFamily: fontInterRegularString,
                  fontSize: 14,
                  color: isDark ? Colors.white : const Color(0xFF1F2937),
                ),
                decoration: InputDecoration(
                  hintText: hintText ??
                      'Ask AI or apply leave (e.g. add today second half leave)...',
                  hintStyle: TextStyle(
                    fontFamily: fontInterRegularString,
                    fontSize: 13,
                    color: ColorConst.textgrey,
                  ),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                ),
                onSubmitted: (_) {
                  if (!isLoading) onSend();
                },
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Send / Loading Button
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: 44,
            width: 44,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isLoading
                    ? [Colors.grey.shade400, Colors.grey.shade500]
                    : [ColorConst.themeColor, ColorConst.darkGreenColor],
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
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: isLoading ? null : onSend,
                borderRadius: BorderRadius.circular(22),
                child: Center(
                  child: isLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Icon(
                          Icons.arrow_upward_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
