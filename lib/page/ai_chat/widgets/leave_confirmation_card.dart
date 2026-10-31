import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:tax_hrm/api/leavesapi.dart';
import 'package:tax_hrm/controllers/ai_chat_controller.dart';
import 'package:tax_hrm/models/ai_chat_models.dart';
import 'package:tax_hrm/models/fixeddat.dart';
import 'package:tax_hrm/models/leaveM/getleavemaster.dart';
import 'package:tax_hrm/page/leave/admin_leave_page.dart';
import 'package:tax_hrm/page/leave/leavepage.dart';
import 'package:tax_hrm/utils/colorsfile.dart';
import 'package:tax_hrm/utils/navigation.dart';
import 'package:tax_hrm/utils/titlesfile.dart';
import 'package:tax_hrm/widigets/toastmessage.dart';

/// Interactive card widget embedded in AI chat message for leave requests.
///
/// Behavior:
/// - If leaveType is ALREADY provided, does NOT ask or show options (clean summary)
/// - If leaveType is NOT provided, fetches company leave types from API and shows options
/// - Reason is REQUIRED (no static placeholder allowed); provides interactive reason input
/// - When submitted successfully:
///   * Hides the "Submit Leave" and "Edit" buttons
///   * Shows "View Leave" button that redirects directly to LeaveViewPage / AdminLeavePage
class LeaveConfirmationCard extends StatefulWidget {
  final AiChatActionResponse action;
  final Future<bool> Function(String? leaveType, String? reason) onConfirm;
  final VoidCallback onEdit;
  final Function(String fieldName, String value)? onQuickSelect;
  final List<String>? availableLeaveTypes;

  const LeaveConfirmationCard({
    super.key,
    required this.action,
    required this.onConfirm,
    required this.onEdit,
    this.onQuickSelect,
    this.availableLeaveTypes,
  });

  @override
  State<LeaveConfirmationCard> createState() => _LeaveConfirmationCardState();
}

class _LeaveConfirmationCardState extends State<LeaveConfirmationCard> {
  String? selectedLeaveType;
  late TextEditingController reasonController;
  bool isSubmitting = false;
  bool isSubmitted = false;
  bool showOptions = false;
  List<String> dynamicLeaveTypes = [];
  bool isLoadingTypes = false;

  @override
  void initState() {
    super.initState();
    final initialType = (widget.action.leaveType != null &&
            widget.action.leaveType!.trim().isNotEmpty)
        ? widget.action.leaveType!.trim()
        : null;

    selectedLeaveType = initialType;
    reasonController = TextEditingController(text: widget.action.reason ?? '');
    isSubmitted = widget.action.isSubmitted;

    final bool hasInitialLeaveType = initialType != null &&
        !widget.action.missingFields.any((f) =>
            f.toLowerCase().contains('leave') ||
            f.toLowerCase().contains('type'));

    // If leave type is ALREADY provided, do NOT ask for leave type.
    // If leave type is NOT provided, show options box and fetch all company types from API.
    if (!hasInitialLeaveType && !isSubmitted) {
      showOptions = true;
      _loadLeaveTypesFromApi();
    }
  }

  @override
  void dispose() {
    reasonController.dispose();
    super.dispose();
  }

  Future<void> _loadLeaveTypesFromApi() async {
    // 1. Check if provided directly via widget parameter
    if (widget.availableLeaveTypes != null &&
        widget.availableLeaveTypes!.isNotEmpty) {
      if (mounted) {
        setState(() {
          dynamicLeaveTypes = widget.availableLeaveTypes!;
        });
      }
      return;
    }

    // 2. Check if already available in GetX AiChatController cache
    if (Get.isRegistered<AiChatController>()) {
      final ctrl = Get.find<AiChatController>();
      if (ctrl.companyLeaveTypes.isNotEmpty) {
        if (mounted) {
          setState(() {
            dynamicLeaveTypes = ctrl.companyLeaveTypes.toList();
          });
        }
        return;
      }
    }

    // 3. Otherwise fetch from API
    if (mounted) setState(() => isLoadingTypes = true);
    try {
      final result = await LeaveMasterApiService().getLeaveMlist();
      if (result is List<GetLeaveMaster>) {
        final names = result
            .map((e) => (e.leaveTypeFName ?? '').trim())
            .where((n) => n.isNotEmpty)
            .toList();
        if (mounted) {
          setState(() {
            dynamicLeaveTypes = names;
          });
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          dynamicLeaveTypes = [
            'Casual Leave',
            'Sick Leave',
            'Paid Leave',
            'Privilege Leave',
          ];
        });
      }
    } finally {
      if (mounted) setState(() => isLoadingTypes = false);
    }
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.trim().isEmpty) return '-';
    try {
      final dt = DateTime.parse(dateStr.trim());
      return DateFormat('dd MMM yyyy').format(dt);
    } catch (_) {
      return dateStr;
    }
  }

  void _navigateToLeaveScreen(BuildContext context) {
    final bool isAdmin = curentUser is Map && curentUser['Role'] == 'Admin';
    nextScreen(
      context,
      isAdmin
          ? const AdminLeavePage(isShowBack: true)
          : const LeaveViewPage(isShowBack: true),
    );
  }

  @override
  Widget build(BuildContext context) {
    final effectiveLeaveType =
        selectedLeaveType ?? widget.action.leaveType;
    final hasLeaveType =
        effectiveLeaveType != null && effectiveLeaveType.trim().isNotEmpty;

    final currentReason = reasonController.text.trim();
    final hasReason = currentReason.isNotEmpty;

    final hasInitialLeaveType = widget.action.leaveType != null &&
        widget.action.leaveType!.trim().isNotEmpty &&
        !widget.action.missingFields.any((f) =>
            f.toLowerCase().contains('leave') ||
            f.toLowerCase().contains('type'));

    final isReadyToSubmit = hasLeaveType && hasReason;
    final isDark = ColorConst.isDark;

    return Container(
      margin: const EdgeInsets.only(top: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF242426) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSubmitted
              ? const Color(0xFF16A34A)
              : (isReadyToSubmit
                  ? const Color(0xFF22C55E)
                  : const Color(0xFFF59E0B)),
          width: 1.3,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.25 : 0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header Banner ─────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isSubmitted
                  ? const Color(0xFFDCFCE7)
                  : (isReadyToSubmit
                      ? const Color(0xFFDCFCE7)
                      : const Color(0xFFFEF3C7)),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(15)),
            ),
            child: Row(
              children: [
                Icon(
                  isSubmitted
                      ? Icons.check_circle_rounded
                      : (isReadyToSubmit
                          ? Icons.check_circle_rounded
                          : Icons.warning_amber_rounded),
                  size: 18,
                  color: (isSubmitted || isReadyToSubmit)
                      ? const Color(0xFF15803D)
                      : const Color(0xFFB45309),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isSubmitted
                        ? 'Leave Submitted Successfully'
                        : (isReadyToSubmit
                            ? 'Leave Request Ready for Submission'
                            : (!hasLeaveType && !hasReason
                                ? 'Details Required: Leave Type & Reason'
                                : (!hasLeaveType
                                    ? 'Details Required: Leave Type'
                                    : 'Details Required: Reason'))),
                    style: TextStyle(
                      fontFamily: fontInterSemiBoldString,
                      fontSize: 13,
                      color: (isSubmitted || isReadyToSubmit)
                          ? const Color(0xFF15803D)
                          : const Color(0xFFB45309),
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: ColorConst.themeColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    widget.action.isHalfDay
                        ? '${widget.action.leaveDuration ?? 0.5} Day'
                        : '${widget.action.leaveDuration ?? 1.0} Day',
                    style: TextStyle(
                      fontFamily: fontInterBoldString,
                      fontSize: 11,
                      color: ColorConst.themeColor,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Leave Details Grid ────────────────────────────
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Optional Employee Info Row (Admin Leave)
                if (widget.action.employeeName != null &&
                    widget.action.employeeName!.trim().isNotEmpty) ...[
                  Row(
                    children: [
                      Expanded(
                        child: _buildInfoItem(
                          icon: Icons.person_rounded,
                          label: 'Employee',
                          value: widget.action.employeeName!.trim(),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],

                // Dates & Day Type Row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _buildInfoItem(
                        icon: Icons.calendar_today_rounded,
                        label: 'Dates',
                        value: (widget.action.startDate ==
                                    widget.action.endDate ||
                                widget.action.endDate == null ||
                                widget.action.endDate!.isEmpty)
                            ? _formatDate(widget.action.startDate)
                            : '${_formatDate(widget.action.startDate)} → ${_formatDate(widget.action.endDate)}',
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildInfoItem(
                        icon: Icons.timelapse_rounded,
                        label: 'Period',
                        value: widget.action.dayType ??
                            (widget.action.isHalfDay
                                ? 'Second Half'
                                : 'Full Day'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Leave Type Row (with optional Change toggle if already provided)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _buildInfoItem(
                        icon: Icons.category_rounded,
                        label: 'Leave Type',
                        value: hasLeaveType
                            ? effectiveLeaveType
                            : 'Not specified (Select below or tap Edit)',
                        isWarning: !hasLeaveType,
                      ),
                    ),
                    if (hasInitialLeaveType && !isSubmitted)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              showOptions = !showOptions;
                              if (showOptions && dynamicLeaveTypes.isEmpty) {
                                _loadLeaveTypesFromApi();
                              }
                            });
                          },
                          borderRadius: BorderRadius.circular(4),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  showOptions
                                      ? Icons.expand_less_rounded
                                      : Icons.swap_horiz_rounded,
                                  size: 13,
                                  color: ColorConst.themeColor,
                                ),
                                const SizedBox(width: 2),
                                Text(
                                  showOptions ? 'Hide' : 'Change',
                                  style: TextStyle(
                                    fontFamily: fontInterMediumString,
                                    fontSize: 11,
                                    color: ColorConst.themeColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),

                // ── Dynamic Leave Type Options from API ─────────
                // Only rendered if leave type was NOT provided, OR user explicitly tapped 'Change'
                if (showOptions && !isSubmitted) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF332A15)
                          : const Color(0xFFFFFBEB),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: const Color(0xFFFDE68A),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.touch_app_rounded,
                              size: 14,
                              color: Color(0xFFD97706),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                hasLeaveType
                                    ? 'Selected Leave Type: $effectiveLeaveType'
                                    : 'Select Leave Type to apply directly:',
                                style: TextStyle(
                                  fontFamily: fontInterMediumString,
                                  fontSize: 11.5,
                                  color: const Color(0xFFD97706),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        if (isLoadingTypes)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 8),
                            child: Center(
                              child: SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Color(0xFFD97706),
                                  ),
                                ),
                              ),
                            ),
                          )
                        else if (dynamicLeaveTypes.isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Text(
                              'No leave types found from company master. Please tap Edit.',
                              style: TextStyle(
                                fontFamily: fontInterRegularString,
                                fontSize: 11,
                                color: ColorConst.textgrey,
                              ),
                            ),
                          )
                        else
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: dynamicLeaveTypes.map((type) {
                              final isSelected =
                                  effectiveLeaveType?.toLowerCase() ==
                                      type.toLowerCase();

                              return InkWell(
                                onTap: () {
                                  setState(() {
                                    selectedLeaveType = type;
                                  });
                                },
                                borderRadius: BorderRadius.circular(16),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? ColorConst.themeColor
                                        : ColorConst.themeColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: isSelected
                                          ? ColorConst.themeColor
                                          : ColorConst.themeColor.withOpacity(0.3),
                                      width: 1,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        isSelected
                                            ? Icons.check_rounded
                                            : Icons.add_rounded,
                                        size: 13,
                                        color: isSelected
                                            ? Colors.white
                                            : ColorConst.themeColor,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        type,
                                        style: TextStyle(
                                          fontFamily: fontInterMediumString,
                                          fontSize: 11,
                                          color: isSelected
                                              ? Colors.white
                                              : ColorConst.themeColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 12),

                // ── Reason Section (Required, never static) ─────
                if (isSubmitted) ...[
                  // Read-only reason after submission
                  _buildInfoItem(
                    icon: Icons.short_text_rounded,
                    label: 'Reason',
                    value: currentReason.isNotEmpty
                        ? currentReason
                        : 'No reason specified',
                  ),
                ] else ...[
                  // Interactive reason input field before submission
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.short_text_rounded,
                            size: 15,
                            color: hasReason
                                ? ColorConst.textgrey
                                : const Color(0xFFDC2626),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            hasReason ? 'Reason' : 'Reason (Required) *',
                            style: TextStyle(
                              fontFamily: hasReason
                                  ? fontInterRegularString
                                  : fontInterSemiBoldString,
                              fontSize: 11,
                              color: hasReason
                                  ? ColorConst.textgrey
                                  : const Color(0xFFDC2626),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Container(
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF1E1E20)
                              : const Color(0xFFF9FAFB),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: hasReason
                                ? (isDark
                                    ? const Color(0xFF374151)
                                    : const Color(0xFFE5E7EB))
                                : const Color(0xFFF87171),
                            width: hasReason ? 1 : 1.2,
                          ),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        child: TextField(
                          controller: reasonController,
                          maxLines: 2,
                          minLines: 1,
                          onChanged: (text) {
                            setState(() {});
                          },
                          style: TextStyle(
                            fontFamily: fontInterMediumString,
                            fontSize: 12.5,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                          decoration: InputDecoration(
                            hintText:
                                'Enter reason for leave (e.g., Personal work)...',
                            hintStyle: TextStyle(
                              fontFamily: fontInterRegularString,
                              fontSize: 12,
                              color: ColorConst.textgrey,
                            ),
                            isDense: true,
                            border: InputBorder.none,
                            contentPadding:
                                const EdgeInsets.symmetric(vertical: 4),
                          ),
                        ),
                      ),
                      if (!hasReason)
                        Padding(
                          padding: const EdgeInsets.only(top: 4, left: 2),
                          child: Text(
                            '• Reason is required to submit leave.',
                            style: TextStyle(
                              fontFamily: fontInterRegularString,
                              fontSize: 10.5,
                              color: const Color(0xFFDC2626),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],

                const SizedBox(height: 14),

                // ── Action Buttons ─────────────────────────────────
                // If submitted: HIDE submit and edit buttons, show "View Leave"
                if (isSubmitted) ...[
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _navigateToLeaveScreen(context),
                      icon: const Icon(
                        Icons.visibility_rounded,
                        size: 17,
                        color: Colors.white,
                      ),
                      label: Text(
                        'View Leave',
                        style: TextStyle(
                          fontFamily: fontInterBoldString,
                          fontSize: 13,
                          color: Colors.white,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ColorConst.themeColor,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 11),
                      ),
                    ),
                  ),
                ] else ...[
                  // Not submitted: Show [Edit] and [Submit Leave]
                  Row(
                    children: [
                      // Edit Button (Navigates to ApplyLeavePage)
                      Expanded(
                        flex: 1,
                        child: OutlinedButton.icon(
                          onPressed: isSubmitting ? null : widget.onEdit,
                          icon: const Icon(
                            Icons.edit_note_rounded,
                            size: 17,
                          ),
                          label: Text(
                            'Edit',
                            style: TextStyle(
                              fontFamily: fontInterSemiBoldString,
                              fontSize: 12.5,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: ColorConst.themeColor,
                            side: BorderSide(
                              color: ColorConst.themeColor,
                              width: 1.2,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),

                      // Submit Button (Direct Leave API Call)
                      Expanded(
                        flex: 1,
                        child: ElevatedButton.icon(
                          onPressed: isSubmitting
                              ? null
                              : () async {
                                  if (!hasReason) {
                                    showtoastmessage(
                                      'Please enter reason for your leave',
                                    );
                                    return;
                                  }
                                  if (!hasLeaveType) {
                                    showtoastmessage(
                                      'Please select a Leave Type first',
                                    );
                                    return;
                                  }

                                  setState(() => isSubmitting = true);
                                  try {
                                    final success = await widget.onConfirm(
                                      selectedLeaveType,
                                      currentReason,
                                    );
                                    if (success == true && mounted) {
                                      setState(() {
                                        isSubmitted = true;
                                      });
                                    }
                                  } finally {
                                    if (mounted) {
                                      setState(() => isSubmitting = false);
                                    }
                                  }
                                },
                          icon: isSubmitting
                              ? const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white),
                                  ),
                                )
                              : const Icon(
                                  Icons.send_rounded,
                                  size: 16,
                                  color: Colors.white,
                                ),
                          label: Text(
                            isSubmitting ? 'Submitting...' : 'Submit Leave',
                            style: TextStyle(
                              fontFamily: fontInterBoldString,
                              fontSize: 12.5,
                              color: Colors.white,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isReadyToSubmit
                                ? const Color(0xFF16A34A)
                                : ColorConst.themeColor.withOpacity(0.4),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String label,
    required String value,
    bool isWarning = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 15,
          color: isWarning ? const Color(0xFFDC2626) : ColorConst.textgrey,
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontFamily: fontInterRegularString,
                  fontSize: 11,
                  color: ColorConst.textgrey,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontFamily: isWarning
                      ? fontInterMediumString
                      : fontInterSemiBoldString,
                  fontSize: 12.5,
                  color: isWarning
                      ? const Color(0xFFDC2626)
                      : (ColorConst.isDark ? Colors.white : Colors.black87),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
