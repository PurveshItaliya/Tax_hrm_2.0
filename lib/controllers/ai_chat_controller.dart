import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tax_hrm/models/ai_chat_models.dart';
import 'package:tax_hrm/models/fixeddat.dart';
import 'package:tax_hrm/page/leave/applyleavepage.dart';
import 'package:tax_hrm/repositories/ai_chat_repository.dart';
import 'package:tax_hrm/utils/navigation.dart';
import 'package:tax_hrm/widigets/toastmessage.dart';

/// GetX controller managing UI state, messaging, and action workflows for the AI Assistant.
///
/// Follows Master Controller Rules (Rule 9 & 14):
/// - Manages Rx variables and reactive UI state
/// - Delegates all data flow and caching to AiChatRepository
/// - Disposes all controllers, listeners, and focus nodes in onClose()
class AiChatController extends GetxController {
  final AiChatRepository _repository;

  AiChatController({AiChatRepository? repository})
      : _repository = repository ?? AiChatRepository();

  // ── Observables ───────────────────────────────────────────
  final RxList<AiChatMessage> messages = <AiChatMessage>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool isSubmittingDirectLeave = false.obs;
  final RxBool hasInputText = false.obs;
  final RxList<String> companyLeaveTypes = <String>[].obs;
  final RxBool isLoadingLeaveTypes = false.obs;

  // ── Admin & Hints Observables ─────────────────────────────
  final RxBool isAdmin = false.obs;
  final RxList<String> employeeNames = <String>[].obs;
  final RxString selectedEmployeeFilter = ''.obs;
  final RxList<String> quickHints = <String>[].obs;

  // ── Form & Scroll Controllers ─────────────────────────────
  late final TextEditingController textController;
  late final ScrollController scrollController;
  late final FocusNode focusNode;

  @override
  void onInit() {
    super.onInit();
    textController = TextEditingController();
    scrollController = ScrollController();
    focusNode = FocusNode();

    textController.addListener(_onTextChanged);

    final role = (curentUser is Map && curentUser['Role'] != null)
        ? curentUser['Role'].toString().trim().toLowerCase()
        : (curentUser is Map && curentUser['role'] != null)
            ? curentUser['role'].toString().trim().toLowerCase()
            : '';
    isAdmin.value = role == 'admin' || role == 'sub-admin';

    // Instant UI (Rule 2): Load cached conversation & hints from repository
    loadHints();
    _loadInitialMessages();
    loadCompanyLeaveTypes();
  }

  /// Prepares quick suggestions / hints according to role (Admin vs Employee).
  void loadHints() {
    if (!isAdmin.value) {
      quickHints.assignAll([
        'add today second half leave',
        'Apply casual leave for tomorrow',
        'Sick leave for 2 days',
        'First half leave on Friday',
        'Check my leave balance',
        'My attendance this month',
      ]);
      return;
    }

    // Admin Mode: Instant Level 1 Memory Cache (Rule 2 & 3)
    final inMemoryNames = allManinEmplyeList
        .map((e) => (e.firstName ?? '').trim())
        .where((n) => n.isNotEmpty)
        .toSet()
        .toList();

    if (inMemoryNames.isNotEmpty) {
      employeeNames.assignAll(inMemoryNames);
      _generateAdminHints(inMemoryNames);
    } else {
      // Instant default user names for <100ms display
      final fallbackNames = ['Rahul', 'Priya', 'Amit', 'Sneha', 'Karan'];
      employeeNames.assignAll(fallbackNames);
      _generateAdminHints(fallbackNames);
    }

    // Background silent refresh (Rule 2 & 3)
    _refreshEmployeeNamesInBackground();
  }

  Future<void> _refreshEmployeeNamesInBackground() async {
    try {
      final names = await _repository.getEmployeeNames();
      if (names.isNotEmpty) {
        employeeNames.assignAll(names);
        _generateAdminHints(names);
      }
    } catch (e) {
      debugPrint('[AI_CHAT_CONTROLLER] Error refreshing employee names: $e');
    }
  }

  void _generateAdminHints(List<String> names) {
    if (names.isEmpty) return;

    if (selectedEmployeeFilter.value.isNotEmpty) {
      final name = selectedEmployeeFilter.value;
      quickHints.assignAll([
        'Add today second half leave for $name',
        'Apply casual leave for $name tomorrow',
        'Sick leave for $name for 2 days',
        'First half leave for $name on Friday',
        'Check attendance of $name today',
        'Show leave balance for $name',
        'Is $name present today?',
      ]);
      return;
    }

    // Distribute different user names across diverse hints for admin
    final n = names.length;
    quickHints.assignAll([
      'Add today second half leave for ${names[0]}',
      'Apply casual leave for ${names[1 % n]} tomorrow',
      'Sick leave for ${names[2 % n]} for 2 days',
      'Check attendance of ${names[3 % n]} today',
      'First half leave for ${names[4 % n]} on Friday',
      'Show leave balance for ${names[0]}',
      'Is ${names[1 % n]} present today?',
      if (n > 2) 'Add full day leave for ${names[2 % n]} today',
    ]);
  }

  void selectEmployeeFilter(String employeeName) {
    if (selectedEmployeeFilter.value == employeeName) {
      selectedEmployeeFilter.value = '';
    } else {
      selectedEmployeeFilter.value = employeeName;
    }
    _generateAdminHints(employeeNames);
  }

  /// Loads company leave types from HRM master list
  Future<void> loadCompanyLeaveTypes() async {
    if (companyLeaveTypes.isNotEmpty) return;
    isLoadingLeaveTypes.value = true;
    try {
      final list = await _repository.getCompanyLeaveTypes();
      final names = list
          .map((e) => (e.leaveTypeFName ?? '').trim())
          .where((n) => n.isNotEmpty)
          .toList();
      if (names.isNotEmpty) {
        companyLeaveTypes.assignAll(names);
      }
    } catch (e) {
      debugPrint('[AI_CHAT_CONTROLLER] Error loading leave types: $e');
    } finally {
      isLoadingLeaveTypes.value = false;
    }
  }

  void _onTextChanged() {
    final hasText = textController.text.trim().isNotEmpty;
    if (hasInputText.value != hasText) {
      hasInputText.value = hasText;
    }
  }

  void _loadInitialMessages() {
    final cached = _repository.getCachedMessages();
    if (cached.isNotEmpty) {
      messages.assignAll(cached);
    } else {
      // Friendly greeting message from AI Assistant
      final userName = (curentUser is Map && curentUser['FirstName'] != null)
          ? curentUser['FirstName'].toString()
          : (curentUser is Map && curentUser['UserName'] != null)
              ? curentUser['UserName'].toString()
              : 'there';

      final sampleName = employeeNames.isNotEmpty ? employeeNames.first : 'Rahul';

      final welcomeText = isAdmin.value
          ? 'Hello $userName! 👋 (Admin Mode)\nI am your TAX HRM AI Assistant. You can apply leaves for employees, check employee attendance, or manage team requests.\n\nTry saying: "Apply casual leave for $sampleName tomorrow"'
          : 'Hello $userName! 👋\nI am your TAX HRM AI Assistant. You can ask me to apply for leaves, check attendance, or inquire about company policies.\n\nTry saying: "add today second half leave"';

      final welcomeMsg = AiChatMessage(
        id: 'welcome_1',
        text: welcomeText,
        isUser: false,
        timestamp: DateTime.now(),
      );
      messages.add(welcomeMsg);
      _repository.cacheMessage(welcomeMsg);
    }
  }

  /// Sends a chat message to the AI webhook and updates the chat feed.
  Future<void> sendMessage([String? customText]) async {
    final textToSend = (customText ?? textController.text).trim();
    if (textToSend.isEmpty || isLoading.value) return;

    if (customText == null) {
      textController.clear();
      hasInputText.value = false;
    }

    // 1. Add User Message
    final userMessage = AiChatMessage(
      id: 'usr_${DateTime.now().millisecondsSinceEpoch}',
      text: textToSend,
      isUser: true,
      timestamp: DateTime.now(),
    );

    messages.add(userMessage);
    _repository.cacheMessage(userMessage);
    _scrollToBottom();

    // Detect target employee name from prompt if admin
    String? detectedEmployee;
    if (isAdmin.value && employeeNames.isNotEmpty) {
      final lowerText = textToSend.toLowerCase();
      for (final name in employeeNames) {
        if (lowerText.contains(name.toLowerCase())) {
          detectedEmployee = name;
          break;
        }
      }
    }

    // 2. Trigger loading & call API via Repository
    isLoading.value = true;
    try {
      final response = await _repository.sendUserMessage(textToSend);

      AiChatActionResponse finalResponse = response;
      if (detectedEmployee != null &&
          (response.employeeName == null || response.employeeName!.isEmpty)) {
        finalResponse = response.copyWith(employeeName: detectedEmployee);
      }

      final botMessage = AiChatMessage(
        id: 'bot_${DateTime.now().millisecondsSinceEpoch}',
        text: finalResponse.message.isNotEmpty
            ? finalResponse.message
            : (finalResponse.success
                ? 'Leave request processed.'
                : 'Sorry, I encountered an issue processing your request.'),
        isUser: false,
        timestamp: DateTime.now(),
        actionResponse: finalResponse.isLeaveConfirmation ? finalResponse : null,
      );

      messages.add(botMessage);
      _repository.cacheMessage(botMessage);
    } catch (e) {
      final errorMessage = AiChatMessage(
        id: 'err_${DateTime.now().millisecondsSinceEpoch}',
        text: 'An error occurred while connecting. Please try again.',
        isUser: false,
        timestamp: DateTime.now(),
        isError: true,
      );
      messages.add(errorMessage);
      _repository.cacheMessage(errorMessage);
    } finally {
      isLoading.value = false;
      _scrollToBottom();
    }
  }

  /// Directly creates the leave in the HRM system using CreateEmpLeave API.
  /// Requires reason; does not allow static fallback.
  Future<bool> handleDirectLeaveSubmit(
    AiChatActionResponse action, [
    String? chosenLeaveType,
    String? chosenReason,
  ]) async {
    final effectiveLeaveType =
        (chosenLeaveType ?? action.leaveType ?? '').trim();

    final effectiveReason =
        (chosenReason ?? action.reason ?? '').trim();

    if (effectiveLeaveType.isEmpty &&
        action.missingFields.any((f) => f.toLowerCase().contains('leave') || f.toLowerCase().contains('type'))) {
      showtoastmessage('Please select a Leave Type first');
      return false;
    }

    if (effectiveReason.isEmpty) {
      showtoastmessage('Please enter reason for your leave');
      return false;
    }

    if (isSubmittingDirectLeave.value) return false;
    isSubmittingDirectLeave.value = true;

    try {
      final result = await _repository.submitDirectLeave(
        action: action,
        selectedLeaveTypeName:
            effectiveLeaveType.isNotEmpty ? effectiveLeaveType : null,
        customReason: effectiveReason,
      );

      if (result.success == true) {
        showtoastmessage('Leave applied successfully');

        // Mark the action response on the original message as submitted
        for (int i = 0; i < messages.length; i++) {
          if (messages[i].actionResponse == action) {
            messages[i] = messages[i].copyWith(
              actionResponse: action.copyWith(
                isSubmitted: true,
                reason: effectiveReason,
                leaveType: effectiveLeaveType.isNotEmpty ? effectiveLeaveType : action.leaveType,
              ),
            );
            break;
          }
        }

        final empDisplayName = (action.employeeName != null &&
                action.employeeName!.trim().isNotEmpty)
            ? action.employeeName!.trim()
            : '';

        final confirmationText =
            '✅ Leave applied successfully!\n'
            '${empDisplayName.isNotEmpty ? "• Employee: $empDisplayName\n" : ""}'
            '• Leave Type: ${effectiveLeaveType.isNotEmpty ? effectiveLeaveType : "Leave"}\n'
            '• Period: ${action.dayType ?? (action.isHalfDay ? "Second Half" : "Full Day")} (${action.leaveDuration ?? (action.isHalfDay ? 0.5 : 1.0)} Day)\n'
            '• Dates: ${action.startDate ?? ""} to ${action.endDate ?? action.startDate ?? ""}\n'
            '• Reason: $effectiveReason\n'
            '• Status: ${(curentUser is Map && curentUser["Role"] == "Admin") ? "Approved" : "Pending Approval"}';

        final botMsg = AiChatMessage(
          id: 'applied_${DateTime.now().millisecondsSinceEpoch}',
          text: confirmationText,
          isUser: false,
          timestamp: DateTime.now(),
        );

        messages.add(botMsg);
        _repository.cacheMessage(botMsg);
        _scrollToBottom();
        return true;
      } else {
        showtoastmessage('Failed to apply leave. Please check eligible leave or tap Edit.');
        return false;
      }
    } catch (e) {
      showtoastmessage('Error applying leave: $e');
      return false;
    } finally {
      isSubmittingDirectLeave.value = false;
    }
  }

  /// Backward-compatible handleConfirm alias
  void handleConfirm(AiChatActionResponse action, [String? chosenLeaveType, String? chosenReason]) {
    handleDirectLeaveSubmit(action, chosenLeaveType, chosenReason);
  }

  /// Handles "Edit" action: Navigates to ApplyLeavePage with all pre-filled fields.
  void handleEdit(BuildContext context, AiChatActionResponse action) {
    final leaveDataMap = action.toLeaveDataMap();

    nextScreen(
      context,
      ApplyLeavePage(
        isEdit: false,
        leaveData: leaveDataMap,
      ),
      onthenValue: (result) {
        if (result == true) {
          // If the user successfully submitted the leave on the form screen
          final confirmNotice = AiChatMessage(
            id: 'edit_saved_${DateTime.now().millisecondsSinceEpoch}',
            text: 'Leave application submitted successfully from the form.',
            isUser: false,
            timestamp: DateTime.now(),
          );
          messages.add(confirmNotice);
          _repository.cacheMessage(confirmNotice);
          _scrollToBottom();
        }
      },
    );
  }

  /// Rapidly supply a missing field (e.g. Leave Type: Casual Leave).
  void handleQuickSelect(String fieldName, String value) {
    sendMessage(value);
  }

  /// Clears active conversation.
  void clearChat() {
    _repository.clearCache();
    messages.clear();
    _loadInitialMessages();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (scrollController.hasClients) {
        scrollController.animateTo(
          scrollController.position.maxScrollExtent + 80,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void onClose() {
    textController.removeListener(_onTextChanged);
    textController.dispose();
    scrollController.dispose();
    focusNode.dispose();
    super.onClose();
  }
}
