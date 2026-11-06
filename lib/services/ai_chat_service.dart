import 'dart:convert';
import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:tax_hrm/models/ai_chat_models.dart';

/// Dedicated service for communicating with the HRM AI Chat Webhook.
///
/// Follows Master Performance Rules:
/// - Screen -> Controller -> Repository -> Service
/// - Comprehensive API logging (Rule 18)
/// - Full debug payload & response printing
/// - Safe timeouts and ngrok browser warning bypass
class AiChatService {
  static const String endpoint =
      'https://dropkick-flirt-dramatic.ngrok-free.dev/webhook/tax-hrm-admin-chat';

  final http.Client _client;

  AiChatService({http.Client? client}) : _client = client ?? http.Client();

  /// Pretty formats JSON or fallback to raw string
  static String formatJson(dynamic input) {
    try {
      const encoder = JsonEncoder.withIndent('  ');
      if (input is String) {
        return encoder.convert(jsonDecode(input));
      }
      return encoder.convert(input);
    } catch (_) {
      return input.toString();
    }
  }

  /// Prints long text completely without truncation across log buffers
  static void printFullBlock(String title, String content) {
    debugPrint('═══════════════════════════════════════════════════════════════');
    debugPrint(title);
    debugPrint('───────────────────────────────────────────────────────────────');
    const int chunkSize = 800;
    for (int i = 0; i < content.length; i += chunkSize) {
      final end =
          (i + chunkSize < content.length) ? i + chunkSize : content.length;
      debugPrint(content.substring(i, end));
    }
    debugPrint('═══════════════════════════════════════════════════════════════');
  }

  /// Sends a user chat message payload to the AI webhook and returns a structured response.
  Future<AiChatActionResponse> sendMessage(AiChatRequest request) async {
    const screenName = 'AiChatScreen';
    const apiName = 'tax-hrm-admin-chat';
    final startTime = DateTime.now();

    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'ngrok-skip-browser-warning': 'true',
    };

    final payloadMap = request.toJson();
    final payloadJson = request.toJsonString();
    final formattedPayload = formatJson(payloadMap);

    // ── Print Request Details ──────────────────────────────
    printFullBlock(
      '🚀 [AI CHAT API REQUEST] POST $endpoint',
      'HEADERS:\n${formatJson(headers)}\n\nFULL PAYLOAD:\n$formattedPayload',
    );

    try {
      final url = Uri.parse(endpoint);

      final response = await _client
          .post(
            url,
            headers: headers,
            body: payloadJson,
          )
          .timeout(const Duration(seconds: 45));

      final endTime = DateTime.now();
      final duration = endTime.difference(startTime).inMilliseconds;
      final responseBody = utf8.decode(response.bodyBytes);
      final responseSize = responseBody.length;
      final formattedResponse = formatJson(responseBody);

      // ── Print Full Response ────────────────────────────────
      printFullBlock(
        '📥 [AI CHAT API RESPONSE] Status: ${response.statusCode} | Duration: ${duration}ms | Size: ${responseSize}B',
        'FULL RESPONSE BODY:\n$formattedResponse',
      );

      // Rule 18 Logging
      developer.log(
        '[$screenName] API: $apiName | Duration: ${duration}ms | Status: ${response.statusCode} | Source: API | Size: ${responseSize}B',
        name: 'AiChatService',
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final dynamic decoded = jsonDecode(responseBody);
        return AiChatActionResponse.fromJson(decoded);
      } else {
        return AiChatActionResponse(
          success: false,
          message:
              'Server returned error ${response.statusCode}: ${response.reasonPhrase ?? "Request failed"}',
        );
      }
    } catch (e, stackTrace) {
      final endTime = DateTime.now();
      final duration = endTime.difference(startTime).inMilliseconds;

      // ── Print Error Details ────────────────────────────────
      printFullBlock(
        '❌ [AI CHAT API ERROR] Duration: ${duration}ms',
        'ERROR: $e\n\nSTACK TRACE:\n$stackTrace',
      );

      developer.log(
        '[$screenName] API: $apiName | Duration: ${duration}ms | Status: Error ($e) | Source: API | Size: 0B',
        name: 'AiChatService',
      );

      return AiChatActionResponse(
        success: false,
        message:
            'Unable to connect to AI assistant. Please check your internet connection.',
      );
    }
  }

  void dispose() {
    _client.close();
  }
}
