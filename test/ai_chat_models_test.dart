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
        currentUserId: 1210,
        currentUserName: 'Swift',
      );

      final json = request.toJson();
      expect(json['message'], 'add today second half leave ');
      expect(json['companyName'], 'TAXFILE INFOSOFT PVT LTD(MDB)');
      expect(json['companyId'], 1092);
      expect(json['custId'], 'TAY967');
      expect(json['currentUserId'], 1210);
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
  });
}
