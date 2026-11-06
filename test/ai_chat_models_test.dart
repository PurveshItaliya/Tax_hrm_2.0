import 'package:flutter_test/flutter_test.dart';
import 'package:tax_hrm/models/ai_chat_models.dart';

void main() {
  group('AiChatModels & Response Parsing Tests', () {
    test('AiChatRequest serializes properly into expected JSON payload', () {
      const request = AiChatRequest(
        message: 'add today second half leave ',
        companyName: 'TAXFILE INFOSOFT PVT LTD(MDB)',
        companyId: 1092,
        custId: 'TAY967',
        currentUserName: 'Swift',
      );

      final json = request.toJson();
      expect(json['message'], 'add today second half leave ');
      expect(json['companyName'], 'TAXFILE INFOSOFT PVT LTD(MDB)');
      expect(json['companyId'], 1092);
      expect(json['custId'], 'TAY967');
      expect(json.containsKey('currentUserId'), false);
      expect(json['currentUserName'], 'Swift');
    });

    test('AiChatActionResponse correctly parses CONFIRM_LEAVE_REQUEST with missing fields', () {
      final json = {
        "success": true,
        "action": "CONFIRM_LEAVE_REQUEST",
        "requiresConfirmation": true,
        "readyToSubmit": false,
        "leaveType": "",
        "startDate": "2026-10-27",
        "endDate": "2026-10-27",
        "leaveDuration": 0.5,
        "dayType": "Second Half",
        "reason": "",
        "missingFields": ["leave type"],
        "message": "Please confirm or provide: leave type."
      };

      final response = AiChatActionResponse.fromJson(json);

      expect(response.success, true);
      expect(response.action, "CONFIRM_LEAVE_REQUEST");
      expect(response.requiresConfirmation, true);
      expect(response.readyToSubmit, false);
      expect(response.startDate, "2026-10-27");
      expect(response.endDate, "2026-10-27");
      expect(response.leaveDuration, 0.5);
      expect(response.dayType, "Second Half");
      expect(response.isHalfDay, true);
      expect(response.hasMissingFields, true);
      expect(response.missingFields, contains("leave type"));
      expect(response.isLeaveConfirmation, true);

      // Verify toLeaveDataMap for ApplyLeavePage
      final leaveMap = response.toLeaveDataMap();
      expect(leaveMap['fromDate'], "2026-10-27");
      expect(leaveMap['toDate'], "2026-10-27");
      expect(leaveMap['dayType'], "Second Half");
      expect(leaveMap['leaveDuration'], 0.5);
    });

    test('AiChatActionResponse correctly parses completed leave request', () {
      final json = {
        "success": true,
        "action": "CONFIRM_LEAVE_REQUEST",
        "requiresConfirmation": true,
        "readyToSubmit": true,
        "leaveType": "Casual Leave",
        "startDate": "2026-10-27",
        "endDate": "2026-10-27",
        "leaveDuration": 0.5,
        "dayType": "Second Half",
        "reason": "Doctor appointment",
        "missingFields": [],
        "message": "Please confirm your Casual Leave request."
      };

      final response = AiChatActionResponse.fromJson(json);

      expect(response.success, true);
      expect(response.readyToSubmit, true);
      expect(response.hasMissingFields, false);
      expect(response.leaveType, "Casual Leave");
      expect(response.reason, "Doctor appointment");
      expect(response.isLeaveConfirmation, true);
      expect(response.isSubmitted, false);

      final submitted = response.copyWith(isSubmitted: true);
      expect(submitted.isSubmitted, true);
      expect(submitted.leaveType, "Casual Leave");
    });

    test('AiChatActionResponse correctly parses employee attendance summary response', () {
      final json = {
        "employees": [
          {
            "name": "YUG KUNJADIYA",
            "image": null,
            "summary": "26 present, 1 absent; Paid holiday: 0 hours 0 minutes; Paid leave: 0 hours 0 minutes."
          }
        ],
        "totalSummary": "Summary for 1 employee(s) (1 Oct 2026 to 31 Oct 2026): YUG KUNJADIYA: 26 present, 1 absent; Paid holiday: 0 hours 0 minutes; Paid leave: 0 hours 0 minutes.",
        "tokenUsage": {
          "inputTokens": 301,
          "outputTokens": 37,
          "totalTokens": 338
        }
      };

      final response = AiChatActionResponse.fromJson(json);

      expect(response.success, true);
      expect(response.hasEmployeeSummaries, true);
      expect(response.employees.length, 1);
      expect(response.employees.first.name, "YUG KUNJADIYA");
      expect(response.employees.first.presentCount, "26");
      expect(response.employees.first.absentCount, "1");
      expect(response.totalSummary, contains("YUG KUNJADIYA"));
      expect(response.tokenUsage?.totalTokens, 338);
      expect(response.displayMessage, contains("YUG KUNJADIYA"));
    });

    test('AiChatActionResponse correctly parses standard conversational response with response key', () {
      final json = {
        "response": "I'm currently available to assist only with HRM-related queries and tasks. I cannot help with this particular request. Please ask me something related to Attendance, Employee Leave, Payroll, Payslip, or other HRM features."
      };

      final response = AiChatActionResponse.fromJson(json);

      expect(response.success, true);
      expect(response.message, contains("I'm currently available to assist"));
      expect(response.displayMessage, contains("I'm currently available to assist"));
    });

    test('AiChatActionResponse parses stringified JSON containing response key', () {
      const jsonStr = '{"response": "Here is your response"}';
      final response = AiChatActionResponse.fromJson(jsonStr);

      expect(response.success, true);
      expect(response.displayMessage, "Here is your response");
    });

    test('AiEmployeeSummaryItem safely resolves image URLs without host errors', () {
      const itemWithSlash = AiEmployeeSummaryItem(
        name: 'YUG KUNJADIYA',
        image: '/9495657d-8c13-41ca-8936-7f2a624b88b5.jpg',
        summary: '26 present',
      );
      expect(itemWithSlash.resolvedImageUrl, contains('UploadFiles/Emp/9495657d-8c13-41ca-8936-7f2a624b88b5.jpg'));
      expect(itemWithSlash.resolvedImageUrl!.startsWith('http'), true);

      const itemWithoutSlash = AiEmployeeSummaryItem(
        name: 'YUG KUNJADIYA',
        image: '9495657d-8c13-41ca-8936-7f2a624b88b5.jpg',
        summary: '26 present',
      );
      expect(itemWithoutSlash.resolvedImageUrl, contains('UploadFiles/Emp/9495657d-8c13-41ca-8936-7f2a624b88b5.jpg'));

      const itemWithFullUrl = AiEmployeeSummaryItem(
        name: 'YUG KUNJADIYA',
        image: 'https://taxcrmtesting.taxfile.co.in/UploadFiles/Emp/pic.jpg',
        summary: '26 present',
      );
      expect(itemWithFullUrl.resolvedImageUrl, 'https://taxcrmtesting.taxfile.co.in/UploadFiles/Emp/pic.jpg');

      const itemNull = AiEmployeeSummaryItem(
        name: 'YUG KUNJADIYA',
        image: null,
        summary: '26 present',
      );
      expect(itemNull.resolvedImageUrl, null);

      const itemEmpty = AiEmployeeSummaryItem(
        name: 'YUG KUNJADIYA',
        image: '   ',
        summary: '26 present',
      );
      expect(itemEmpty.resolvedImageUrl, null);
    });

    test('AiChatActionResponse correctly extracts dateRange from totalSummary', () {
      final json = {
        "employees": [
          {
            "name": "YUG KUNJADIYA",
            "image": "/9495657d-8c13-41ca-8936-7f2a624b88b5.jpg",
            "summary": "26 present, 1 absent; Paid holiday: 0 hours 0 minutes; Paid leave: 0 hours 0 minutes."
          }
        ],
        "totalSummary": "Summary for 1 employee(s) (1 Oct 2026 to 31 Oct 2026): YUG KUNJADIYA: 26 present, 1 absent; Paid holiday: 0 hours 0 minutes; Paid leave: 0 hours 0 minutes.",
      };

      final response = AiChatActionResponse.fromJson(json);
      expect(response.dateRange, "1 Oct 2026 to 31 Oct 2026");
    });

    test('AiChatActionResponse parses array containing response object', () {
      final listJson = [
        {"response": "Response from list"}
      ];
      final response = AiChatActionResponse.fromJson(listJson);

      expect(response.success, true);
      expect(response.displayMessage, "Response from list");
    });
  });
}
