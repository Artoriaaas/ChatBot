import 'package:flutter/foundation.dart';
import 'package:paper_chat/models/user_profile.dart';

class AuthViewModel extends ChangeNotifier {
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

    // Success login
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

    _currentUser = UserProfile(
      id: 'usr_${DateTime.now().millisecondsSinceEpoch}',
      name: name.trim(),
      email: email.trim(),
      avatarUrl: 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=150',
      isGoogleAuth: false,
    );
    _isLoggedIn = true;
    _isLoading = false;
    notifyListeners();
    return true;
  }

  Future<bool> loginWithGoogle() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 800));

    _currentUser = const UserProfile(
      id: 'usr_google_1',
      name: 'Dr. Alex Nguyen',
      email: 'alex.nguyen@gmail.com',
      avatarUrl: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150',
      isGoogleAuth: true,
    );
    _isLoggedIn = true;
    _isLoading = false;
    notifyListeners();
    return true;
  }

  Future<bool> sendPasswordResetEmail(String email) async {
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

  void logout() {
    _isLoggedIn = false;
    _currentUser = null;
    _errorMessage = null;
    notifyListeners();
  }
}

