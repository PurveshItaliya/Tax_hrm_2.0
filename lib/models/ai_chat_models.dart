import 'dart:convert';
import 'package:tax_hrm/utils/basicdata.dart';

/// Represents the payload sent to the AI webhook endpoint.
class AiChatRequest {
  final String message;
  final String companyName;
  final int companyId;
  final String custId;
  final String currentUserName;

  const AiChatRequest({
    required this.message,
    required this.companyName,
    required this.companyId,
    required this.custId,
    required this.currentUserName,
  });

  Map<String, dynamic> toJson() {
    return {
      'message': message,
      'companyName': companyName,
      'companyId': companyId,
      'custId': custId,
      'currentUserName': currentUserName,
    };
  }

  String toJsonString() => jsonEncode(toJson());
}

/// Represents an employee's attendance/leave summary returned by the admin chat assistant.
class AiEmployeeSummaryItem {
  final String name;
  final String? image;
  final String summary;

  const AiEmployeeSummaryItem({
    required this.name,
    this.image,
    required this.summary,
  });

  factory AiEmployeeSummaryItem.fromJson(dynamic jsonInput) {
    if (jsonInput is Map) {
      return AiEmployeeSummaryItem(
        name: jsonInput['name']?.toString() ?? '',
        image: jsonInput['image']?.toString(),
        summary: jsonInput['summary']?.toString() ?? '',
      );
    }
    return AiEmployeeSummaryItem(
      name: '',
      summary: jsonInput?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'image': image,
    'summary': summary,
  };

  /// Parses present count from summary string (e.g. "26 present, 1 absent...")
  String? get presentCount {
    final match = RegExp(r'(\d+)\s+present', caseSensitive: false).firstMatch(summary);
    return match?.group(1);
  }

  /// Parses absent count from summary string
  String? get absentCount {
    final match = RegExp(r'(\d+)\s+absent', caseSensitive: false).firstMatch(summary);
    return match?.group(1);
  }

  /// Parses paid holiday info
  String? get holidayInfo {
    final match = RegExp(r'Paid holiday:\s*([^;]+)', caseSensitive: false).firstMatch(summary);
    return match?.group(1)?.trim();
  }

  /// Parses paid leave info
  /// Safely resolves full image URL from relative path, filename, or absolute URL.
  String? get resolvedImageUrl {
    if (image == null) return null;
    var raw = image!.trim();
    if (raw.isEmpty || raw.toLowerCase() == 'null' || raw.toLowerCase() == 'undefined') {
      return null;
    }
    if (raw.startsWith('http://') || raw.startsWith('https://')) {
      final uri = Uri.tryParse(raw);
      if (uri != null && uri.hasScheme && (uri.host.isNotEmpty || uri.hasAuthority)) {
        return raw;
      }
      return null;
    }

    // Strip leading slashes
    raw = raw.replaceFirst(RegExp(r'^/+'), '');
    if (raw.isEmpty) return null;

    final base = apibaseurl.endsWith('/') ? apibaseurl : '$apibaseurl/';
    if (raw.startsWith('UploadFiles/') || raw.startsWith('HRM/Uploads/')) {
      return '$base$raw';
    }
    return '${base}UploadFiles/Emp/$raw';
  }

  String? get paidLeaveInfo {
    final match = RegExp(r'Paid leave:\s*([^;.]+)', caseSensitive: false).firstMatch(summary);
    return match?.group(1)?.trim();
  }
}

/// Represents token usage metrics returned by the LLM
class AiTokenUsage {
  final int inputTokens;
  final int outputTokens;
  final int totalTokens;

  const AiTokenUsage({
    this.inputTokens = 0,
    this.outputTokens = 0,
    this.totalTokens = 0,
  });

  factory AiTokenUsage.fromJson(dynamic jsonInput) {
    if (jsonInput is Map) {
      return AiTokenUsage(
        inputTokens: (jsonInput['inputTokens'] as num?)?.toInt() ?? 0,
        outputTokens: (jsonInput['outputTokens'] as num?)?.toInt() ?? 0,
        totalTokens: (jsonInput['totalTokens'] as num?)?.toInt() ?? 0,
      );
    }
    return const AiTokenUsage();
  }

  Map<String, dynamic> toJson() => {
    'inputTokens': inputTokens,
    'outputTokens': outputTokens,
    'totalTokens': totalTokens,
  };
}

/// Represents the structured response returned by the AI webhook.
///
/// Can represent different action types, such as `CONFIRM_LEAVE_REQUEST`,
/// employee attendance summaries, standard conversational text, or future HRM workflows.
class AiChatActionResponse {
  final bool success;
  final String? action;
  final String? intent;
  final String? route;
  final bool requiresConfirmation;
  final bool readyToSubmit;
  final String? leaveType;
  final String? startDate;
  final String? endDate;
  final double? leaveDuration;
  final String? dayType;
  final String? reason;
  final List<String> missingFields;
  final String message;
  final Map<String, dynamic> rawJson;
  final bool isSubmitted;
  final String? employeeName;
  final int? empId;
  final List<AiEmployeeSummaryItem> employees;
  final String? totalSummary;
  final AiTokenUsage? tokenUsage;

  const AiChatActionResponse({
    this.success = true,
    this.action,
    this.intent,
    this.route,
    this.requiresConfirmation = false,
    this.readyToSubmit = false,
    this.leaveType,
    this.startDate,
    this.endDate,
    this.leaveDuration,
    this.dayType,
    this.reason,
    this.missingFields = const [],
    this.message = '',
    this.rawJson = const {},
    this.isSubmitted = false,
    this.employeeName,
    this.empId,
    this.employees = const [],
    this.totalSummary,
    this.tokenUsage,
  });

  AiChatActionResponse copyWith({
    bool? success,
    String? action,
    String? intent,
    String? route,
    bool? requiresConfirmation,
    bool? readyToSubmit,
    String? leaveType,
    String? startDate,
    String? endDate,
    double? leaveDuration,
    String? dayType,
    String? reason,
    List<String>? missingFields,
    String? message,
    Map<String, dynamic>? rawJson,
    bool? isSubmitted,
    String? employeeName,
    int? empId,
    List<AiEmployeeSummaryItem>? employees,
    String? totalSummary,
    AiTokenUsage? tokenUsage,
  }) {
    return AiChatActionResponse(
      success: success ?? this.success,
      action: action ?? this.action,
      intent: intent ?? this.intent,
      route: route ?? this.route,
      requiresConfirmation: requiresConfirmation ?? this.requiresConfirmation,
      readyToSubmit: readyToSubmit ?? this.readyToSubmit,
      leaveType: leaveType ?? this.leaveType,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      leaveDuration: leaveDuration ?? this.leaveDuration,
      dayType: dayType ?? this.dayType,
      reason: reason ?? this.reason,
      missingFields: missingFields ?? this.missingFields,
      message: message ?? this.message,
      rawJson: rawJson ?? this.rawJson,
      isSubmitted: isSubmitted ?? this.isSubmitted,
      employeeName: employeeName ?? this.employeeName,
      empId: empId ?? this.empId,
      employees: employees ?? this.employees,
      totalSummary: totalSummary ?? this.totalSummary,
      tokenUsage: tokenUsage ?? this.tokenUsage,
    );
  }

  /// True if this response is a Leave Confirmation / Leave Request action card.
  bool get isLeaveConfirmation {
    final act = (action ?? '').toUpperCase();
    return act == 'CONFIRM_LEAVE_REQUEST' ||
        act.contains('LEAVE') ||
        requiresConfirmation;
  }

  /// True if this response contains employee attendance summaries.
  /// Extracts date range from totalSummary if present (e.g. "(1 Oct 2026 to 31 Oct 2026)")
  String? get dateRange {
    if (totalSummary == null) return null;
    final match = RegExp(r'\(([^)]*\d{4}[^)]*)\)').firstMatch(totalSummary!);
    if (match != null) {
      return match.group(1)?.trim();
    }
    final dateMatch = RegExp(r'(\d{1,2}\s+[A-Za-z]+\s+\d{4}\s+to\s+\d{1,2}\s+[A-Za-z]+\s+\d{4})').firstMatch(totalSummary!);
    if (dateMatch != null) {
      return dateMatch.group(1)?.trim();
    }
    return null;
  }

  bool get hasEmployeeSummaries =>
      employees.isNotEmpty || (totalSummary != null && totalSummary!.trim().isNotEmpty);

  /// Display text for chat bubble: message > totalSummary > default
  String get displayMessage {
    if (message.trim().isNotEmpty) return message;
    if (totalSummary != null && totalSummary!.trim().isNotEmpty) return totalSummary!;
    if (employees.isNotEmpty) return 'Attendance summary for ${employees.length} employee(s):';
    if (success) return 'Request processed successfully.';
    return 'Sorry, I encountered an issue processing your request.';
  }

  /// True if there are required fields missing from the leave prompt.
  bool get hasMissingFields => missingFields.isNotEmpty;

  /// True if the duration represents a half day.
  bool get isHalfDay =>
      (leaveDuration != null && leaveDuration! > 0 && leaveDuration! < 1.0) ||
      (dayType != null &&
          (dayType!.toLowerCase().contains('half') ||
              dayType!.toLowerCase().contains('1st') ||
              dayType!.toLowerCase().contains('2nd')));

  /// Converts this AI leave confirmation response into a Map compatible with ApplyLeavePage.
  Map<String, dynamic> toLeaveDataMap() {
    return {
      'cguid': null,
      'empLeaveId': 0,
      'empId': empId ?? 0,
      'employeeName': employeeName ?? '',
      'fromDate': startDate ?? '',
      'toDate': endDate ?? (startDate ?? ''),
      'dayType': dayType ?? (isHalfDay ? 'Second Half' : 'Full Day'),
      'leaveDuration': leaveDuration ?? (isHalfDay ? 0.5 : 1.0),
      'leaveTypeFName': leaveType ?? '',
      'leaveType': leaveType ?? '',
      'remarks': reason ?? '',
      'reason': reason ?? '',
    };
  }

  factory AiChatActionResponse.fromJson(dynamic jsonInput) {
    if (jsonInput == null) return const AiChatActionResponse();

    Map<String, dynamic> json;
    if (jsonInput is String) {
      try {
        final decoded = jsonDecode(jsonInput);
        if (decoded is List && decoded.isNotEmpty && decoded.first is Map) {
          json = Map<String, dynamic>.from(decoded.first);
        } else if (decoded is Map) {
          json = Map<String, dynamic>.from(decoded);
        } else {
          return AiChatActionResponse(message: decoded?.toString() ?? jsonInput);
        }
      } catch (_) {
        return AiChatActionResponse(message: jsonInput);
      }
    } else if (jsonInput is List && jsonInput.isNotEmpty && jsonInput.first is Map) {
      json = Map<String, dynamic>.from(jsonInput.first);
    } else if (jsonInput is Map) {
      json = Map<String, dynamic>.from(jsonInput);
    } else {
      return AiChatActionResponse(message: jsonInput.toString());
    }

    // Parse missingFields safely
    List<String> missing = [];
    if (json['missingFields'] is List) {
      missing = (json['missingFields'] as List)
          .map((e) => e?.toString() ?? '')
          .where((e) => e.trim().isNotEmpty)
          .toList();
    }

    // Parse leaveDuration as double safely
    double? duration;
    final rawDuration = json['leaveDuration'];
    if (rawDuration != null) {
      if (rawDuration is num) {
        duration = rawDuration.toDouble();
      } else {
        duration = double.tryParse(rawDuration.toString());
      }
    }

    final rawEmployee = json['employeeName'] ??
        json['empName'] ??
        json['userName'] ??
        json['employee'] ??
        json['user'] ??
        json['targetUser'] ??
        json['targetEmployee'];

    final rawEmpId = json['empId'] ??
        json['emp_id'] ??
        json['employeeId'] ??
        json['userId'] ??
        json['id'];

    int? parsedEmpId;
    if (rawEmpId != null) {
      if (rawEmpId is num) {
        parsedEmpId = rawEmpId.toInt();
      } else {
        parsedEmpId = int.tryParse(rawEmpId.toString());
      }
    }

    // Parse employees list safely
    List<AiEmployeeSummaryItem> parsedEmployees = [];
    if (json['employees'] is List) {
      parsedEmployees = (json['employees'] as List)
          .map((e) => AiEmployeeSummaryItem.fromJson(e))
          .toList();
    }

    // Parse token usage
    AiTokenUsage? parsedTokenUsage;
    if (json['tokenUsage'] != null) {
      parsedTokenUsage = AiTokenUsage.fromJson(json['tokenUsage']);
    }

    final totalSum = json['totalSummary']?.toString();

    // Determine message text from various standard webhook/LLM response keys:
    // 'response', 'message', 'msg', 'text', 'reply', 'content', 'output', 'answer', 'result'
    final rawMsg = json['response'] ??
        json['message'] ??
        json['msg'] ??
        json['text'] ??
        json['reply'] ??
        json['content'] ??
        json['output'] ??
        json['answer'] ??
        json['result'];

    String msg = '';
    if (rawMsg != null) {
      if (rawMsg is String) {
        msg = rawMsg.trim();
      } else if (rawMsg is Map && rawMsg.containsKey('content')) {
        msg = rawMsg['content']?.toString().trim() ?? '';
      } else if (rawMsg is List) {
        msg = rawMsg.map((e) => e?.toString() ?? '').where((e) => e.isNotEmpty).join('\n').trim();
      } else {
        msg = rawMsg.toString().trim();
      }
    }

    if (msg.isEmpty && totalSum != null && totalSum.isNotEmpty) {
      msg = totalSum;
    }

    // If explicit success boolean is missing, infer success based on having data or a response message
    final bool isSuccess = json.containsKey('success')
        ? (json['success'] == true)
        : (parsedEmployees.isNotEmpty || (totalSum != null && totalSum.isNotEmpty) || msg.isNotEmpty);

    return AiChatActionResponse(
      success: isSuccess,
      action: json['action']?.toString(),
      intent: json['intent']?.toString(),
      route: json['route']?.toString(),
      requiresConfirmation: json['requiresConfirmation'] == true,
      readyToSubmit: json['readyToSubmit'] == true,
      leaveType: json['leaveType']?.toString() ?? '',
      startDate: json['startDate']?.toString(),
      endDate: json['endDate']?.toString(),
      leaveDuration: duration,
      dayType: json['dayType']?.toString(),
      reason: json['reason']?.toString() ?? '',
      missingFields: missing,
      message: msg,
      rawJson: json,
      employeeName: rawEmployee?.toString(),
      empId: parsedEmpId,
      employees: parsedEmployees,
      totalSummary: totalSum,
      tokenUsage: parsedTokenUsage,
    );
  }
}

/// Represents an in-memory chat message displayed in the UI.
class AiChatMessage {
  final String id;
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final AiChatActionResponse? actionResponse;
  final bool isSending;
  final bool isError;

  const AiChatMessage({
    required this.id,
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.actionResponse,
    this.isSending = false,
    this.isError = false,
  });

  AiChatMessage copyWith({
    String? id,
    String? text,
    bool? isUser,
    DateTime? timestamp,
    AiChatActionResponse? actionResponse,
    bool? isSending,
    bool? isError,
  }) {
    return AiChatMessage(
      id: id ?? this.id,
      text: text ?? this.text,
      isUser: isUser ?? this.isUser,
      timestamp: timestamp ?? this.timestamp,
      actionResponse: actionResponse ?? this.actionResponse,
      isSending: isSending ?? this.isSending,
      isError: isError ?? this.isError,
    );
  }
}

