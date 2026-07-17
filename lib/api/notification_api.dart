import 'dart:convert';
import 'package:http/http.dart' as http;

class NotificationApi {
  // Backend URL that routes topic notification requests to Firebase via the server.
  // Using the same live server as all other API calls in the app.
  static const String baseUrl = 'https://taxcrmtesting.taxfile.co.in/api';

  Future<bool> sendNotification({
    required String title,
    required String message,
    String? imageUrl,
    String? screen,
    String? scheduleTime,
    required List<String> topics,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/send-notification');
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'title': title,
          'message': message,
          if (imageUrl != null && imageUrl.isNotEmpty) 'imageUrl': imageUrl,
          if (screen != null && screen.isNotEmpty) 'screen': screen,
          if (scheduleTime != null && scheduleTime.isNotEmpty) 'scheduleTime': scheduleTime,
          'topics': topics,
        }),
      );
      
      if (response.statusCode == 200) {
        return true;
      } else {
        print('[NotificationApi] Failed to send: ${response.body}');
        return false;
      }
    } catch (e) {
      print('[NotificationApi] Error sending notification: $e');
      return false;
    }
  }
}
