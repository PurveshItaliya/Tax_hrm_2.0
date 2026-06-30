// To parse this JSON data, do
//
//     final emailVerification = emailVerificationFromJson(jsonString);

import 'dart:convert';

EmailVerification emailVerificationFromJson(String str) =>
    EmailVerification.fromJson(json.decode(str));

String emailVerificationToJson(EmailVerification data) =>
    json.encode(data.toJson());

class EmailVerification {
  bool success;
  int status;
  String message;
  String verify;

  EmailVerification({
    required this.success,
    required this.status,
    required this.message,
    required this.verify,
  });

  factory EmailVerification.fromJson(Map<String, dynamic> json) =>
      EmailVerification(
        success: json["success"] ?? true,
        status: json["status"] ?? 0,
        message: json["message"] ?? "",
        verify: json["verify"] ?? "",
      );

  Map<String, dynamic> toJson() => {
    "success": success,
    "status": status,
    "message": message,
    "verify": verify,
  };
}
