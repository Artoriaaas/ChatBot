import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:paper_chat/services/api_config.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  final http.Client _client;

  AuthService({http.Client? client}) : _client = client ?? http.Client();

  /// Đăng nhập bằng Email và Password, trực tiếp nhận và lưu token
  Future<String?> login(String email, String password) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/Auth/login');
    final response = await _client.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email.trim().toLowerCase(),
        'password': password,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final token = data['token'] as String?;
      if (token != null && token.isNotEmpty) {
        await saveToken(token);
      }
      return token;
    } else {
      String errorMsg = 'Email hoặc mật khẩu không đúng.';
      try {
        final decoded = jsonDecode(response.body);
        if (decoded is Map && decoded['message'] != null) {
          errorMsg = decoded['message'];
        } else if (response.body.isNotEmpty) {
          errorMsg = response.body;
        }
      } catch (_) {
        if (response.body.isNotEmpty) errorMsg = response.body;
      }
      throw Exception(errorMsg);
    }
  }

  /// Xác thực OTP Đăng nhập
  Future<String?> verifyLogin(String email, String otp) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/Auth/verify-login');
    final response = await _client.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email.trim().toLowerCase(),
        'otp': otp.trim(),
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final token = data['token'];
      if (token != null) {
        await saveToken(token);
      }
      return token;
    } else {
      throw Exception('Mã OTP không hợp lệ hoặc đã hết hạn.');
    }
  }

  /// Đăng ký tài khoản mới
  Future<bool> register(String name, String email, String password) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/Auth/register');
    final response = await _client.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'fullName': name.trim(),
        'email': email.trim().toLowerCase(),
        'password': password,
      }),
    );

    if (response.statusCode == 200) {
      return true;
    } else {
      throw Exception('Lỗi đăng ký: ${response.body}');
    }
  }

  /// Xác thực OTP Đăng ký
  Future<String?> verifyRegister(String email, String otp) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/Auth/verify-register');
    final response = await _client.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email.trim().toLowerCase(),
        'otp': otp.trim(),
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final token = data['token'];
      if (token != null) {
        await saveToken(token);
      }
      return token ?? '';
    } else {
      throw Exception('Mã OTP không hợp lệ hoặc đã hết hạn.');
    }
  }

  /// Gửi thông tin Google lên Backend để lấy JWT token
  Future<String?> loginWithGoogle(String email, String name, String googleId, String? idToken) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/Auth/google-client');
    final response = await _client.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'fullName': name,
        'googleId': googleId,
        'idToken': idToken,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final token = data['token'];
      await saveToken(token);
      return token;
    } else if (response.statusCode == 401) {
      final data = jsonDecode(response.body);
      throw Exception(data['message'] ?? 'Tài khoản chưa tồn tại, vui lòng đăng ký.');
    } else {
      throw Exception('Lỗi đăng nhập Google: ${response.body}');
    }
  }

  Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('jwt_token', token);
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('jwt_token');
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('jwt_token');
  }
}
