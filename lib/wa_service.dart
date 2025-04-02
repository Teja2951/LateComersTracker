import 'dart:convert';
import 'package:http/http.dart' as http;

class WaService {
  final String accessToken = 'EAAORxibdDZC8BOyqAUct5QueQO3qzKrnlxjbKXwrIpTfRLNeORbz8vl03bUSZCt0ZAO64zZCj5nHVX1ygMHbmIxZAz4hF82POR8RRBab4JYsZC0XBjUrZBnmfTwLdLartEBEoKD0M8TEvw6T5FtAftwLvdr39kUkX0psm2BEXS7cFmyGghB24Nv2tCGGEO5tMjK6K19HfGstdZBZBZApZAWeREpwGnTQyY2YjCZAuZAEZD'; // Replace with your actual token
  final String apiUrl = 'https://graph.facebook.com/v21.0/531357373394306/messages';

  Future<void> sendStudentInfo(String phoneNumber, String studentList) async {
    final messageData = {
      'messaging_product': 'whatsapp',
      'to': phoneNumber,
      'type': 'template',
      'template': {
        'name': 'student_info', // Template name
        'language': {'code': 'en'},
        'components': [
          {
            'type': 'body',
            'parameters': [
              {'type': 'text', 'text': studentList}
            ]
          }
        ]
      }
    };

    final headers = {
      'Authorization': 'Bearer $accessToken',
      'Content-Type': 'application/json',
    };

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: headers,
        body: json.encode(messageData),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('Message sent successfully!');
      } else {
        print('Failed to send message: ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      print('Error: $e');
    }
  }
}

