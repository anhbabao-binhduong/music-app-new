import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:math';

class EmailJsService {
  static const String _serviceId = 'service_01rpvom';
  static const String _templateId = 'template_cbzppi9';
  static const String _publicKey = 'vrHwbjVZZG4vImBYs';

  Future<void> sendOtp({
    required String toEmail,
    required String otp,
  }) async {
    final url = Uri.parse('https://api.emailjs.com/api/v1.0/email/send');
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'service_id': _serviceId,
        'template_id': _templateId,
        'user_id': _publicKey,
        'template_params': {
          'passcode': otp,
          'to_email': toEmail,
        },
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to send OTP: ${response.body}');
    }
  }

  static String generateOtp() {
    return List.generate(4, (_) => (Random().nextInt(10)).toString()).join();
  }
}