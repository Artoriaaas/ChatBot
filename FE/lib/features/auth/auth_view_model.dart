import 'package:flutter/foundation.dart';
import 'package:paper_chat/models/user_profile.dart';
import 'package:paper_chat/services/auth_service.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthViewModel extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final GoogleSignIn _googleSignIn = GoogleSignIn();

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

  Future<bool> loginWithEmail(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    // Simulate network delay for authenticating
    await Future.delayed(const Duration(milliseconds: 600));

    if (email.trim().isEmpty || !email.contains('@')) {
      _errorMessage = 'Email không hợp lệ. Vui lòng kiểm tra lại.';
      _isLoading = false;
      notifyListeners();
      return false;
    }

    if (password.length < 6) {
      _errorMessage = 'Mật khẩu phải có ít nhất 6 ký tự.';
      _isLoading = false;
      notifyListeners();
      return false;
    }

    try {
      final token = await _authService.login(email.trim(), password);
      
      if (token != null) {
        // Here we could decode JWT to get user info, but for now we just create a UserProfile
        final nameFromEmail = email.split('@').first;
        final formattedName = nameFromEmail[0].toUpperCase() + nameFromEmail.substring(1);
        
        _currentUser = UserProfile(
          id: 'usr_${DateTime.now().millisecondsSinceEpoch}',
          name: formattedName,
          email: email.trim(),
          avatarUrl: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150',
          isGoogleAuth: false,
        );
        _isLoggedIn = true;
      }
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }

    _isLoading = false;
    notifyListeners();
    return true;
  }

  Future<bool> registerWithEmail({
    required String name,
    required String email,
    required String password,
    required String confirmPassword,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 700));

    if (name.trim().isEmpty) {
      _errorMessage = 'Vui lòng nhập họ và tên của bạn.';
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
      _errorMessage = 'Mật khẩu phải có từ 6 ký tự trở lên.';
      _isLoading = false;
      notifyListeners();
      return false;
    }

    if (password != confirmPassword) {
      _errorMessage = 'Mật khẩu xác nhận không trùng khớp.';
      _isLoading = false;
      notifyListeners();
      return false;
    }

    try {
      await _authService.register(name.trim(), email.trim(), password);
      
      // Auto login after register
      return await loginWithEmail(email.trim(), password);
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> loginWithGoogle() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      
      final token = await _authService.loginWithGoogle(
        googleUser.email,
        googleUser.displayName ?? googleUser.email.split('@').first,
        googleUser.id,
        googleAuth.idToken,
      );

      if (token != null) {
        _currentUser = UserProfile(
          id: googleUser.id,
          name: googleUser.displayName ?? googleUser.email.split('@').first,
          email: googleUser.email,
          avatarUrl: googleUser.photoUrl ?? 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150',
          isGoogleAuth: true,
        );
        _isLoggedIn = true;
      }
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }

    _isLoading = false;
    notifyListeners();
    return true;
  }

  Future<bool> sendPasswordResetOtp(String email) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 600));

    final trimmed = email.trim();
    if (trimmed.isEmpty || !trimmed.contains('@') || !trimmed.contains('.')) {
      _errorMessage = 'Email không hợp lệ. Vui lòng kiểm tra lại.';
      _isLoading = false;
      notifyListeners();
      return false;
    }

    _isLoading = false;
    notifyListeners();
    return true;
  }

  Future<bool> verifyOtpAndResetPassword({
    required String email,
    required String otp,
    required String newPassword,
    required String confirmPassword,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 700));

    final trimmedOtp = otp.trim();
    if (trimmedOtp.isEmpty || trimmedOtp != '123456') {
      _errorMessage = 'Mã xác thực không chính xác (Mã thử nghiệm: 123456).';
      _isLoading = false;
      notifyListeners();
      return false;
    }

    if (newPassword.length < 6) {
      _errorMessage = 'Mật khẩu mới phải có ít nhất 6 ký tự.';
      _isLoading = false;
      notifyListeners();
      return false;
    }

    if (newPassword != confirmPassword) {
      _errorMessage = 'Mật khẩu xác nhận không trùng khớp.';
      _isLoading = false;
      notifyListeners();
      return false;
    }

    _isLoading = false;
    notifyListeners();
    return true;
  }

  void logout() {
    _authService.logout();
    _googleSignIn.signOut();
    _isLoggedIn = false;
    _currentUser = null;
    _errorMessage = null;
    notifyListeners();
  }
}

