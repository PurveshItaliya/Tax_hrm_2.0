import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:tax_hrm/api/employeapi.dart';
import 'package:tax_hrm/api/eventsapi.dart';
import 'package:tax_hrm/api/leavesapi.dart';
import 'package:tax_hrm/models/ai_chat_models.dart';
import 'package:tax_hrm/models/createcguid.dart';
import 'package:tax_hrm/models/employes/getemployes.dart';
import 'package:tax_hrm/models/fixeddat.dart';
import 'package:tax_hrm/models/leaveM/getleavemaster.dart';
import 'package:tax_hrm/models/leavetype/applyleave.dart';
import 'package:tax_hrm/services/ai_chat_service.dart';
import 'package:tax_hrm/utils/basicdata.dart';

/// Single source of truth for AI chat interactions.
///
/// Follows Master Architecture Rules:
/// - Screen -> Controller -> Repository -> Service
/// - Manages active user and company context dynamically
/// - In-memory session message caching for instant UI reload (Rule 2 & 3)
class AiChatRepository {
  final AiChatService _aiService;

  // In-memory session cache for instant screen opening (Rule 2 & Level 1 Cache)
  static final List<AiChatMessage> _memoryCache = [];

  // Memory Cache for employee lists (Level 1 Cache)
  static List<Employeelists> _cachedEmployees = [];

  AiChatRepository({AiChatService? aiService})
      : _aiService = aiService ?? AiChatService();

  /// Returns cached messages for instant display without waiting for network.
  List<AiChatMessage> getCachedMessages() {
    return List.unmodifiable(_memoryCache);
  }

  /// Saves a message to the session cache.
  void cacheMessage(AiChatMessage message) {
    _memoryCache.add(message);
  }

  /// Clears the session cache.
  void clearCache() {
    _memoryCache.clear();
  }

  /// Fetches company employees with memory cache first (Rule 2 & 3)
  Future<List<Employeelists>> getCompanyEmployees() async {
    if (_cachedEmployees.isNotEmpty) {
      return _cachedEmployees;
    }
    if (allManinEmplyeList.isNotEmpty) {
      _cachedEmployees = List.from(allManinEmplyeList);
      return _cachedEmployees;
    }

    try {
      final list = await Employeeclass().emppppapi();
      if (list is List<Employeelists> && list.isNotEmpty) {
        allManinEmplyeList = list;
        _cachedEmployees = list;
        return list;
      }
    } catch (e) {
      debugPrint('[AI_CHAT_REPO] Error fetching employees: $e');
    }
    return _cachedEmployees;
  }

  /// Returns unique display names of employees for admin hints
  Future<List<String>> getEmployeeNames() async {
    final list = await getCompanyEmployees();
    final names = <String>[];
    for (final emp in list) {
      final first = (emp.firstName ?? '').trim();
      final last = (emp.lastName ?? '').trim();
      final full = '$first $last'.trim();
      final displayName = first.isNotEmpty ? first : full;
      if (displayName.isNotEmpty && !names.contains(displayName)) {
        names.add(displayName);
      }
    }
    return names;
  }

  /// Sends a user message to the AI webhook with active user profile context.
  Future<AiChatActionResponse> sendUserMessage(String messageText) async {
    // Dynamically retrieve logged-in credentials or fallback safely to defaults
    final String companyName = (selectedcurentcompany?.companyName != null &&
            selectedcurentcompany!.companyName!.trim().isNotEmpty)
        ? selectedcurentcompany!.companyName!
        : (curentUser is Map &&
                curentUser['CompanyName'] != null &&
                curentUser['CompanyName'].toString().trim().isNotEmpty)
            ? curentUser['CompanyName'].toString()
            : 'TAXFILE INFOSOFT PVT LTD(MDB)';

    final int companyId = (selectedcurentcompany?.companyId != null &&
            selectedcurentcompany!.companyId! > 0)
        ? selectedcurentcompany!.companyId!
        : (curentUser is Map && curentUser['CompanyId'] != null)
            ? int.tryParse(curentUser['CompanyId'].toString()) ?? 1092
            : 1092;

    final String custId = (selectedcurentcompany?.custId != null &&
            selectedcurentcompany!.custId!.trim().isNotEmpty)
        ? selectedcurentcompany!.custId!
        : (curentUser is Map &&
                curentUser['CustId'] != null &&
                curentUser['CustId'].toString().trim().isNotEmpty)
            ? curentUser['CustId'].toString()
            : (curentUser is Map &&
                    curentUser['custId'] != null &&
                    curentUser['custId'].toString().trim().isNotEmpty)
                ? curentUser['custId'].toString()
                : 'TAY967';

    final int currentUserId = (curentUser is Map && curentUser['Id'] != null)
        ? int.tryParse(curentUser['Id'].toString()) ?? 1210
        : 1210;

    final String currentUserName = (curentUser is Map &&
            curentUser['UserName'] != null &&
            curentUser['UserName'].toString().trim().isNotEmpty)
        ? curentUser['UserName'].toString()
        : (curentUser is Map &&
                curentUser['FirstName'] != null &&
                curentUser['FirstName'].toString().trim().isNotEmpty)
            ? curentUser['FirstName'].toString()
            : 'Swift';

    final request = AiChatRequest(
      message: messageText,
      companyName: companyName,
      companyId: companyId,
      custId: custId,
      currentUserId: currentUserId,
      currentUserName: currentUserName,
    );

    return await _aiService.sendMessage(request);
  }

  List<GetLeaveMaster>? _cachedLeaveTypes;

  /// Fetches company leave types from HRM master list (with memory cache)
  Future<List<GetLeaveMaster>> getCompanyLeaveTypes() async {
    if (_cachedLeaveTypes != null && _cachedLeaveTypes!.isNotEmpty) {
      return _cachedLeaveTypes!;
    }
    try {
      final list = await LeaveMasterApiService().getLeaveMlist();
      if (list is List<GetLeaveMaster>) {
        _cachedLeaveTypes = list;
        return list;
      }
    } catch (e) {
      debugPrint('[AI_CHAT_REPO] Error fetching leave types: $e');
    }
    return _cachedLeaveTypes ?? [];
  }

  /// Directly submits a leave request to the HRM CreateEmpLeave API.
  Future<LeaveApply> submitDirectLeave({
    required AiChatActionResponse action,
    String? selectedLeaveTypeName,
    String? customReason,
  }) async {
    final startTime = DateTime.now();

    // 1. Fetch Company Leave Types from master list (cached)
    final leaveTypeList = await getCompanyLeaveTypes();

    // 2. Resolve Leave Type
    GetLeaveMaster? matchedType;
    final candidateName =
        (selectedLeaveTypeName ?? action.leaveType ?? '').trim();
    if (candidateName.isNotEmpty && leaveTypeList.isNotEmpty) {
      final query = candidateName.toLowerCase();
      try {
        matchedType = leaveTypeList.firstWhere(
          (t) =>
              (t.leaveTypeFName ?? '').toLowerCase() == query ||
              (t.leaveTypeFName ?? '').toLowerCase().contains(query),
        );
      } catch (_) {}
    }
    // Fallback if not matched by name
    if (matchedType == null && leaveTypeList.isNotEmpty) {
      matchedType = leaveTypeList.first;
    }

    int empId = (curentUser is Map && curentUser['Id'] != null)
        ? int.tryParse(curentUser['Id'].toString()) ?? 0
        : 0;

    final bool isAdmin = curentUser is Map &&
        (curentUser['Role']?.toString().toLowerCase() == 'admin' ||
         curentUser['Role']?.toString().toLowerCase() == 'sub-admin' ||
         curentUser['role']?.toString().toLowerCase() == 'admin' ||
         curentUser['role']?.toString().toLowerCase() == 'sub-admin');

    // If Admin is submitting leave for a specific employee, resolve their EmpId
    if (isAdmin && (action.employeeName != null || action.empId != null)) {
      if (action.empId != null && action.empId! > 0) {
        empId = action.empId!;
      } else if (action.employeeName != null && action.employeeName!.trim().isNotEmpty) {
        final targetName = action.employeeName!.trim().toLowerCase();
        final employees = await getCompanyEmployees();
        for (final e in employees) {
          final first = (e.firstName ?? '').trim().toLowerCase();
          final last = (e.lastName ?? '').trim().toLowerCase();
          final full = '$first $last'.trim();
          if (first == targetName || full == targetName || full.contains(targetName)) {
            if (e.id != null && e.id! > 0) {
              empId = e.id!;
              break;
            }
          }
        }
      }
    }

    final double duration =
        action.leaveDuration ?? (action.isHalfDay ? 0.5 : 1.0);
    final String startDate =
        (action.startDate != null && action.startDate!.trim().isNotEmpty)
            ? action.startDate!.trim()
            : DateFormat('yyyy-MM-dd').format(DateTime.now());
    final String endDate =
        (action.endDate != null && action.endDate!.trim().isNotEmpty)
            ? action.endDate!.trim()
            : startDate;
    final String dayType =
        action.dayType ?? (action.isHalfDay ? 'Second Half' : 'Full Day');

    // Reason is REQUIRED. Never pass static placeholder text.
    final String reason =
        (customReason != null && customReason.trim().isNotEmpty)
            ? customReason.trim()
            : (action.reason != null && action.reason!.trim().isNotEmpty)
                ? action.reason!.trim()
                : '';

    if (reason.isEmpty) {
      throw Exception('Reason is required to apply leave. Please provide a reason.');
    }

    final String leaveStatus = isAdmin ? 'A' : 'P';
    final String guid = generateCustomUuid();

    // 3. Print Leave Create Request Payload
    final bodyPayload = {
      "Flag": "A",
      "EmpLeave": {
        "EmpId": empId,
        "CompanyId":
            '${selectedcurentcompany?.companyId ?? curentUser?['CompanyId'] ?? 0}',
        "LeaveTypeId": matchedType?.leaveTypeId ?? 0,
        "LeaveTypeCguid": matchedType?.cguid ?? '',
        "LeaveDuration": duration,
        "LeaveDays": duration,
        "FromDate": startDate,
        "ToDate": endDate,
        "LeaveYear": DateTime.now().year,
        "Remarks": reason,
        "Cguid": guid,
        "ApproveStatus": leaveStatus,
        "DayType": dayType,
      },
    };

    AiChatService.printFullBlock(
      '🚀 [DIRECT LEAVE CREATE API REQUEST] POST ${apibaseurl}api/HRM/CreateEmpLeave',
      'PAYLOAD:\n${AiChatService.formatJson(bodyPayload)}',
    );

    // 4. Call Leave API
    final LeaveApply result = await LeaveMasterApiService().applyLeave(
      setEmployeId: empId,
      leaveTypeCguids: matchedType?.cguid ?? '',
      fromdate: startDate,
      leaveTypeid: matchedType?.leaveTypeId ?? 0,
      leaveYears: DateTime.now().year,
      leavedec: duration,
      remarks: reason,
      sendCguid: guid,
      todate: endDate,
      leaveStatusSet: leaveStatus,
      dayType: dayType,
    );

    final durationMs = DateTime.now().difference(startTime).inMilliseconds;

    // 5. Print Leave Create Response
    AiChatService.printFullBlock(
      '📥 [DIRECT LEAVE CREATE API RESPONSE] Status: ${result.success == true ? "SUCCESS (200)" : "FAILED"} | Duration: ${durationMs}ms',
      'FULL RESPONSE BODY:\n${AiChatService.formatJson(result.toJson())}',
    );

    // 6. Push Notification if success
    if (result.success == true) {
      try {
        final bool isAdmin = curentUser is Map && curentUser['Role'] == 'Admin';
        final String custIdBase = (curentUser is Map)
            ? curentUser['CustId']?.toString() ??
                curentUser['custid']?.toString() ??
                ''
            : '';
        final String companyId =
            selectedcurentcompany?.companyId?.toString() ?? '';

        final String fName = (action.employeeName != null && action.employeeName!.trim().isNotEmpty)
            ? action.employeeName!.trim()
            : (curentUser?['FirstName']?.toString() ?? '');
        final String lName = (action.employeeName != null && action.employeeName!.trim().isNotEmpty)
            ? ''
            : (curentUser?['LastName']?.toString() ?? '');
        final String userName = '$fName $lName'.trim().toUpperCase();

        final String targetTopic = isAdmin
            ? '${custIdBase}_${companyId}_$empId'
            : 'ALL_ADMIN_${custIdBase}_$companyId';

        final String fullCompanyName =
            selectedcurentcompany?.companyName?.toString() ?? 'COMPANY';
        final String titleName =
            isAdmin ? 'USER $userName' : fullCompanyName.trim().split(' ').first;

        await EventsApiClass().sendPushNotification(
          title: '$userName Leave Applied',
          description:
              '$userName leave request ($dayType) from $startDate to $endDate has been submitted.',
          topicOverride: targetTopic,
          custIdOverride: targetTopic,
          topicTitleOverride: titleName,
        );
      } catch (_) {}
    }

    return result;
  }
}
