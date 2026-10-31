import 'dart:convert';

/// Represents the payload sent to the AI webhook endpoint.
class AiChatRequest {
  final String message;
  final String companyName;
  final int companyId;
  final String custId;
  final int currentUserId;
  final String currentUserName;

  const AiChatRequest({
    required this.message,
    required this.companyName,
    required this.companyId,
    required this.custId,
    required this.currentUserId,
    required this.currentUserName,
  });

  Map<String, dynamic> toJson() {
    return {
      'message': message,
      'companyName': companyName,
      'companyId': companyId,
      'custId': custId,
      'currentUserId': currentUserId,
      'currentUserName': currentUserName,
    };
  }

  String toJsonString() => jsonEncode(toJson());
}

/// Represents the structured response returned by the AI webhook.
///
/// Can represent different action types, such as `CONFIRM_LEAVE_REQUEST`,
/// standard conversational text, or future HRM workflows.
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
    );
  }

  /// True if this response is a Leave Confirmation / Leave Request action card.
  bool get isLeaveConfirmation {
    final act = (action ?? '').toUpperCase();
    return act == 'CONFIRM_LEAVE_REQUEST' ||
        act.contains('LEAVE') ||
        requiresConfirmation;
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
        json = jsonDecode(jsonInput) as Map<String, dynamic>;
      } catch (_) {
        return AiChatActionResponse(message: jsonInput);
      }
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

    return AiChatActionResponse(
      success: json['success'] == true,
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
      message: json['message']?.toString() ?? '',
      rawJson: json,
      employeeName: rawEmployee?.toString(),
      empId: parsedEmpId,
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
