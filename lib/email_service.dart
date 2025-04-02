import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class SendEmailService {
  final String sendGridApiKey = dotenv.env['SEND_GRID_APIKEY']!;

  // Function to send email to the mentor
  Future<void> sendEmail(String mentorEmail, String data) async {
    final url = Uri.parse('https://api.sendgrid.com/v3/mail/send');
    
    final headers = {
      'Authorization': 'Bearer $sendGridApiKey',
      'Content-Type': 'application/json',
    };

    final emailData = {
      'personalizations': [
        {
          'to': [
            {'email': mentorEmail}
          ],
        }
      ],
      'from': {'email': 'learnatyour@gmail.com'},  // Sender's email hod_bsh_engg@gmrit.edu.in
      'subject': 'Students late to college today(${DateTime.now().toLocal().toIso8601String().split('T').first})',
      'content': [
        {
          'type': 'text/plain',
          'value': 'Dear Mentor,\n\n The following students were late to the college today \n\n $data \n please take the necessary actions \n\n Best Regards \n HOD-BSH',
        }
      ],
    };

    try {
      final response = await http.post(
        url,
        headers: headers,
        body: json.encode(emailData),
      );

      if (response.statusCode == 202) {
        print('Email sent successfully!');
      } else {
        print('Failed to send email: ${response.statusCode}');
      }
    } catch (e) {
      print('Error: $e');
    }
  }
}
