import 'dart:convert';
import 'package:http/http.dart' as http;

class AuthService {
  final String baseUrl = 'https://yourdomain.com/api/auth';

  Future<bool> sendOtp(String phone) async {
    final res = await http.post(
      Uri.parse('$baseUrl/send-otp'),
      body: jsonEncode({'phoneNumber': phone}),
      headers: {'Content-Type': 'application/json'},
    );
    return res.statusCode == 200;
  }

  Future<String?> verifyOtp(String phone, String otp) async {
    final res = await http.post(
      Uri.parse('$baseUrl/verify-otp'),
      body: jsonEncode({'phoneNumber': phone, 'otp': otp}),
      headers: {'Content-Type': 'application/json'},
    );
    if (res.statusCode == 200) {
      final body = jsonDecode(res.body);
      return body['token'];
    }
    return null;
  }
}
