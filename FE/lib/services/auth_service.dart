import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:paper_chat/services/api_config.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  final http.Client _client;

  AuthService({http.Client? client}) : _client = client ?? http.Client();

  /// Đăng nhập bằng Email và Password
  Future<String?> login(String email, String password) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/Auth/login');
    final response = await _client.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final token = data['token'];
      await saveToken(token);
      return token;
    } else {
      throw Exception('Lỗi đăng nhập: ${response.body}');
    }
  }

  /// Đăng ký tài khoản mới
  Future<void> register(String name, String email, String password) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/Auth/register');
    final response = await _client.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'fullName': name,
        'email': email,
        'password': password,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Lỗi đăng ký: ${response.body}');
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
