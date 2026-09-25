import 'package:flutter/foundation.dart';
import 'package:paper_chat/models/user_profile.dart';
import 'package:paper_chat/services/auth_service.dart';

class AuthViewModel extends ChangeNotifier {
  final AuthService _authService = AuthService();

  bool _isLoggedIn = false;
  bool _isLoading = false;
  String? _errorMessage;
  UserProfile? _currentUser;

  bool get isLoggedIn => _isLoggedIn;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  UserProfile? get currentUser => _currentUser;

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Xóa token cũ khi khởi động app để bắt buộc đăng nhập lại
  Future<void> clearSession() async {
    await _authService.logout();
    _isLoggedIn = false;
    _currentUser = null;
    notifyListeners();
  }

  // ─────────────────────────────────────────────────────────────
  // ĐĂNG NHẬP: gửi email + password lên backend, nhận JWT trực tiếp (không cần OTP)
  // ─────────────────────────────────────────────────────────────
  Future<bool> loginWithEmail(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final trimmedEmail = email.trim().toLowerCase();
    final trimmedPass = password.trim();

    if (trimmedEmail.isEmpty || !trimmedEmail.contains('@')) {
      _errorMessage = 'Email không hợp lệ.';
      _isLoading = false;
      notifyListeners();
      return false;
    }

    if (trimmedPass.length < 6) {
      _errorMessage = 'Mật khẩu phải có ít nhất 6 ký tự.';
      _isLoading = false;
      notifyListeners();
      return false;
    }

    try {
      final token = await _authService.login(trimmedEmail, trimmedPass);
      if (token != null && token.isNotEmpty) {
        final namePart = trimmedEmail.split('@').first;
        final displayName = namePart[0].toUpperCase() + namePart.substring(1);
        _currentUser = UserProfile(
          id: 'usr_${DateTime.now().millisecondsSinceEpoch}',
          name: displayName,
          email: trimmedEmail,
          avatarUrl:
              'https://ui-avatars.com/api/?name=${Uri.encodeComponent(displayName)}&background=6366f1&color=fff&bold=true',
          isGoogleAuth: false,
        );
        _isLoggedIn = true;
        _isLoading = false;
        notifyListeners();
        return true;
      }
      _errorMessage = 'Không nhận được token xác thực từ máy chủ.';
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // ─────────────────────────────────────────────────────────────
  // ĐĂNG NHẬP – Bước 2: xác thực OTP, nhận JWT token
  // Trả về true = đăng nhập thành công, isLoggedIn = true
  // Trả về false = OTP sai hoặc hết hạn
  // ─────────────────────────────────────────────────────────────
  Future<bool> verifyLoginOtp(String email, String otp) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final normalizedEmail = email.trim().toLowerCase();
      final token = await _authService.verifyLogin(normalizedEmail, otp.trim());
      if (token != null && token.isNotEmpty) {
        final namePart = normalizedEmail.split('@').first;
        final displayName = namePart[0].toUpperCase() + namePart.substring(1);
        _currentUser = UserProfile(
          id: 'usr_${DateTime.now().millisecondsSinceEpoch}',
          name: displayName,
          email: normalizedEmail,
          avatarUrl:
              'https://ui-avatars.com/api/?name=${Uri.encodeComponent(displayName)}&background=6366f1&color=fff&bold=true',
          isGoogleAuth: false,
        );
        _isLoggedIn = true;
        _isLoading = false;
        notifyListeners();
        return true;
      }
      _errorMessage = 'Xác thực thất bại, vui lòng thử lại.';
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // ─────────────────────────────────────────────────────────────
  // ĐĂNG KÝ – Bước 1: gửi thông tin tài khoản lên backend
  // Backend lưu tạm thông tin + gửi OTP qua email
  // Trả về true = OTP đã gửi
  // Trả về false = email đã tồn tại hoặc lỗi
  // ─────────────────────────────────────────────────────────────
  Future<bool> registerWithEmail({
    required String name,
    required String email,
    required String password,
    required String confirmPassword,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    if (name.trim().isEmpty) {
      _errorMessage = 'Vui lòng nhập họ và tên.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
    if (email.trim().isEmpty || !email.contains('@')) {
      _errorMessage = 'Email không hợp lệ.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
    if (password.length < 6) {
      _errorMessage = 'Mật khẩu phải từ 6 ký tự trở lên.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
    if (password != confirmPassword) {
      _errorMessage = 'Mật khẩu xác nhận không khớp.';
      _isLoading = false;
      notifyListeners();
      return false;
    }

    try {
      final otpSent =
          await _authService.register(name.trim(), email.trim().toLowerCase(), password);
      _isLoading = false;
      notifyListeners();
      return otpSent;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // ─────────────────────────────────────────────────────────────
  // ĐĂNG KÝ – Bước 2: xác thực OTP để hoàn tất tạo tài khoản
  // Khi verify OTP thành công → nhận JWT token và đăng nhập trực tiếp
  // ─────────────────────────────────────────────────────────────
  Future<bool> verifyRegisterOtp(
      String email, String otp, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final normalizedEmail = email.trim().toLowerCase();
      final token =
          await _authService.verifyRegister(normalizedEmail, otp.trim());
      if (token != null && token.isNotEmpty) {
        final namePart = normalizedEmail.split('@').first;
        final displayName = namePart[0].toUpperCase() + namePart.substring(1);
        _currentUser = UserProfile(
          id: 'usr_${DateTime.now().millisecondsSinceEpoch}',
          name: displayName,
          email: normalizedEmail,
          avatarUrl:
              'https://ui-avatars.com/api/?name=${Uri.encodeComponent(displayName)}&background=6366f1&color=fff&bold=true',
          isGoogleAuth: false,
        );
        _isLoggedIn = true;
        _isLoading = false;
        notifyListeners();
        return true;
      }
      _errorMessage = 'OTP không hợp lệ hoặc đã hết hạn.';
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // ─────────────────────────────────────────────────────────────
  // ĐĂNG XUẤT
  // ─────────────────────────────────────────────────────────────
  Future<void> logout() async {
    await _authService.logout();
    _isLoggedIn = false;
    _currentUser = null;
    _errorMessage = null;
    notifyListeners();
  }

  // ─────────────────────────────────────────────────────────────
  // QUÊN MẬT KHẨU – Bước 1: gửi OTP reset về email
  // TODO: Cần backend endpoint /Auth/forgot-password
  // ─────────────────────────────────────────────────────────────
  Future<bool> sendPasswordResetOtp(String email) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final trimmed = email.trim();
    if (trimmed.isEmpty || !trimmed.contains('@') || !trimmed.contains('.')) {
      _errorMessage = 'Email không hợp lệ.';
      _isLoading = false;
      notifyListeners();
      return false;
    }

    // TODO: Gọi API khi backend có endpoint này
    await Future.delayed(const Duration(milliseconds: 500));
    _errorMessage = 'Tính năng đang phát triển. Vui lòng liên hệ quản trị viên.';
    _isLoading = false;
    notifyListeners();
    return false;
  }

  // ─────────────────────────────────────────────────────────────
  // QUÊN MẬT KHẨU – Bước 2: xác thực OTP + đặt mật khẩu mới
  // TODO: Cần backend endpoint /Auth/reset-password
  // ─────────────────────────────────────────────────────────────
  Future<bool> verifyOtpAndResetPassword({
    required String email,
    required String otp,
    required String newPassword,
    required String confirmPassword,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    if (newPassword.length < 6) {
      _errorMessage = 'Mật khẩu mới phải có ít nhất 6 ký tự.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
    if (newPassword != confirmPassword) {
      _errorMessage = 'Mật khẩu xác nhận không khớp.';
      _isLoading = false;
      notifyListeners();
      return false;
    }

    // TODO: Gọi API khi backend có endpoint này
    await Future.delayed(const Duration(milliseconds: 500));
    _errorMessage = 'Tính năng đang phát triển. Vui lòng liên hệ quản trị viên.';
    _isLoading = false;
    notifyListeners();
    return false;
  }
}
