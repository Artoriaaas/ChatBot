import 'package:flutter/material.dart';
import 'package:paper_chat/app/theme/app_colors.dart';
import 'package:paper_chat/app/theme/app_typography.dart';
import 'package:paper_chat/features/auth/auth_view_model.dart';
import 'package:paper_chat/features/settings/settings_view_model.dart';

class AuthScreen extends StatefulWidget {
  final AuthViewModel authVM;
  final SettingsViewModel settingsVM;

  const AuthScreen({
    super.key,
    required this.authVM,
    required this.settingsVM,
  });

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  int _activeTab = 0; // 0 = Login, 1 = Register
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _rememberMe = true;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _switchTab(int tabIndex) {
    setState(() {
      _activeTab = tabIndex;
      widget.authVM.clearError();
    });
  }

  Future<void> _submitForm() async {
    if (_activeTab == 0) {
      final success = await widget.authVM.loginWithEmail(
        _emailController.text,
        _passwordController.text,
      );
      if (success && !widget.authVM.isLoggedIn && mounted) {
        _showOtpDialog(_emailController.text, true);
      }
    } else {
      final success = await widget.authVM.registerWithEmail(
        name: _nameController.text,
        email: _emailController.text,
        password: _passwordController.text,
        confirmPassword: _confirmPasswordController.text,
      );
      if (success && mounted) {
        _showOtpDialog(_emailController.text, false);
      }
    }
  }

  void _showOtpDialog(String email, bool isLogin) {
    final colors = AppColorsExtension.of(context);
    final strings = widget.settingsVM.strings;
    final otpController = TextEditingController();
    bool isSubmitting = false;
    String? localError;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: colors.surface,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
              contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
              actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
              title: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: colors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Icon(Icons.verified_outlined, color: colors.primary, size: 20),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      isLogin ? 'Xác thực đăng nhập' : 'Xác thực đăng ký',
                      style: AppTypography.heading3.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colors.textPrimary,
                        fontSize: 17,
                      ),
                    ),
                  ),
                ],
              ),
              content: SizedBox(
                width: 380,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: colors.primary.withValues(alpha: 0.07),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: colors.primary.withValues(alpha: 0.2)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.email_outlined, size: 16, color: colors.primary),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Mã OTP 6 chữ số đã được gửi đến:\n$email',
                              style: TextStyle(
                                color: colors.textPrimary,
                                fontSize: 12,
                                height: 1.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Nhập mã OTP',
                      style: AppTypography.caption.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: otpController,
                      keyboardType: TextInputType.number,
                      autofocus: true,
                      maxLength: 6,
                      style: TextStyle(
                        color: colors.textPrimary,
                        letterSpacing: 6,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                      textAlign: TextAlign.center,
                      decoration: InputDecoration(
                        hintText: '------',
                        hintStyle: TextStyle(
                          color: colors.textSecondary.withValues(alpha: 0.3),
                          letterSpacing: 6,
                          fontSize: 20,
                        ),
                        counterText: '',
                        errorText: localError,
                        filled: true,
                        fillColor: colors.appBackground,
                        contentPadding: const EdgeInsets.symmetric(vertical: 14),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: colors.divider),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: colors.primary, width: 2),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: colors.error),
                        ),
                      ),
                      onChanged: (_) => setDialogState(() => localError = null),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSubmitting ? null : () => Navigator.pop(dialogContext),
                  child: Text(strings.cancel, style: TextStyle(color: colors.textSecondary)),
                ),
                ElevatedButton(
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          final otp = otpController.text.trim();
                          if (otp.length < 6) {
                            setDialogState(() => localError = 'Vui lòng nhập đủ 6 chữ số');
                            return;
                          }
                          setDialogState(() => isSubmitting = true);

                          bool success = false;
                          if (isLogin) {
                            // Đăng nhập: verify OTP → nhận JWT → isLoggedIn = true
                            success = await widget.authVM.verifyLoginOtp(email, otp);
                          } else {
                            // Đăng ký: verify OTP đăng ký → tạo user → gửi OTP đăng nhập
                            success = await widget.authVM.verifyRegisterOtp(
                              email,
                              otp,
                              _passwordController.text,
                            );
                          }

                          if (!dialogContext.mounted) return;

                          if (isLogin && success) {
                            // Đăng nhập OK → đóng dialog, vào app
                            Navigator.pop(dialogContext);
                          } else if (!isLogin && success) {
                            // Đăng ký OK → đóng dialog này, hiện OTP đăng nhập
                            Navigator.pop(dialogContext);
                            if (mounted) {
                              _showOtpDialog(email, true);
                            }
                          } else {
                            setDialogState(() {
                              isSubmitting = false;
                              localError = widget.authVM.errorMessage ??
                                  'OTP không hợp lệ hoặc đã hết hạn';
                            });
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.primary,
                    foregroundColor: colors.onPrimary,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: isSubmitting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Xác nhận', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showForgotPasswordDialog() {
    final strings = widget.settingsVM.strings;
    final emailController = TextEditingController(text: _emailController.text.trim());
    final otpController = TextEditingController(text: '123456');
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    int currentStep = 1;
    String? localError;
    bool isSubmitting = false;
    bool obscureNewPassword = true;
    bool obscureConfirmPassword = true;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final colors = AppColorsExtension.of(context);

            return AlertDialog(
              backgroundColor: colors.surface,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
              contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
              actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
              title: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: colors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Icon(
                        currentStep == 1 ? Icons.lock_reset_rounded : Icons.verified_user_rounded,
                        color: colors.primary,
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      currentStep == 1 ? strings.resetPasswordTitle : strings.resetPasswordButton,
                      style: AppTypography.heading3.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colors.textPrimary,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ],
              ),
              content: SizedBox(
                width: 420,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (currentStep == 1) ...[
                      Text(
                        strings.resetPasswordStep1Subtitle,
                        style: AppTypography.caption.copyWith(
                          color: colors.textSecondary,
                          fontSize: 13,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        strings.emailLabel,
                        style: AppTypography.caption.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: emailController,
                        keyboardType: TextInputType.emailAddress,
                        autofocus: true,
                        style: AppTypography.body.copyWith(color: colors.textPrimary),
                        decoration: InputDecoration(
                          hintText: strings.emailHint,
                          hintStyle: AppTypography.caption.copyWith(color: colors.textSecondary.withValues(alpha: 0.6)),
                          prefixIcon: Icon(Icons.email_outlined, size: 18, color: colors.textSecondary),
                          errorText: localError,
                          filled: true,
                          fillColor: colors.appBackground,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: colors.divider)),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: colors.divider)),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: colors.primary)),
                        ),
                        onChanged: (_) {
                          if (localError != null) {
                            setDialogState(() => localError = null);
                          }
                        },
                      ),
                    ] else ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: colors.primary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: colors.primary.withValues(alpha: 0.2)),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline, size: 18, color: colors.primary),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '${strings.resetPasswordStep2Subtitle}\n(Email: ${emailController.text.trim()})',
                                style: TextStyle(fontSize: 12, color: colors.textPrimary),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),

                      // OTP Code field
                      Text(
                        strings.otpCodeLabel,
                        style: AppTypography.caption.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: otpController,
                        keyboardType: TextInputType.number,
                        style: AppTypography.body.copyWith(
                          color: colors.textPrimary,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2.0,
                        ),
                        decoration: InputDecoration(
                          hintText: strings.otpCodeHint,
                          hintStyle: AppTypography.caption.copyWith(
                            color: colors.textSecondary.withValues(alpha: 0.6),
                            letterSpacing: 0,
                          ),
                          prefixIcon: Icon(Icons.pin_outlined, size: 18, color: colors.textSecondary),
                          suffixIcon: TextButton(
                            onPressed: () async {
                              await widget.authVM.sendPasswordResetOtp(emailController.text.trim());
                              setDialogState(() {
                                otpController.text = '123456';
                              });
                            },
                            child: Text(
                              strings.resendCode,
                              style: TextStyle(fontSize: 11, color: colors.primary, fontWeight: FontWeight.bold),
                            ),
                          ),
                          filled: true,
                          fillColor: colors.appBackground,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: colors.divider)),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: colors.divider)),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: colors.primary)),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // New password field
                      Text(
                        strings.newPasswordLabel,
                        style: AppTypography.caption.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: newPasswordController,
                        obscureText: obscureNewPassword,
                        style: AppTypography.body.copyWith(color: colors.textPrimary),
                        decoration: InputDecoration(
                          hintText: strings.newPasswordHint,
                          hintStyle: AppTypography.caption.copyWith(color: colors.textSecondary.withValues(alpha: 0.6)),
                          prefixIcon: Icon(Icons.lock_outline, size: 18, color: colors.textSecondary),
                          suffixIcon: IconButton(
                            icon: Icon(
                              obscureNewPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                              size: 18,
                              color: colors.textSecondary,
                            ),
                            onPressed: () => setDialogState(() => obscureNewPassword = !obscureNewPassword),
                          ),
                          filled: true,
                          fillColor: colors.appBackground,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: colors.divider)),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: colors.divider)),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: colors.primary)),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Confirm new password field
                      Text(
                        strings.confirmNewPasswordLabel,
                        style: AppTypography.caption.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: confirmPasswordController,
                        obscureText: obscureConfirmPassword,
                        style: AppTypography.body.copyWith(color: colors.textPrimary),
                        decoration: InputDecoration(
                          hintText: strings.confirmNewPasswordHint,
                          hintStyle: AppTypography.caption.copyWith(color: colors.textSecondary.withValues(alpha: 0.6)),
                          prefixIcon: Icon(Icons.lock_reset, size: 18, color: colors.textSecondary),
                          suffixIcon: IconButton(
                            icon: Icon(
                              obscureConfirmPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                              size: 18,
                              color: colors.textSecondary,
                            ),
                            onPressed: () => setDialogState(() => obscureConfirmPassword = !obscureConfirmPassword),
                          ),
                          filled: true,
                          fillColor: colors.appBackground,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: colors.divider)),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: colors.divider)),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: colors.primary)),
                        ),
                      ),

                      if (localError != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          localError!,
                          style: TextStyle(fontSize: 12, color: colors.error, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ],
                  ],
                ),
              ),
              actions: [
                if (currentStep == 1) ...[
                  TextButton(
                    onPressed: isSubmitting ? null : () => Navigator.pop(dialogContext),
                    child: Text(strings.cancel, style: TextStyle(color: colors.textSecondary)),
                  ),
                  ElevatedButton(
                    onPressed: isSubmitting
                        ? null
                        : () async {
                            final email = emailController.text.trim();
                            if (email.isEmpty || !email.contains('@') || !email.contains('.')) {
                              setDialogState(() {
                                localError = strings.enterValidEmail;
                              });
                              return;
                            }

                            setDialogState(() => isSubmitting = true);
                            final success = await widget.authVM.sendPasswordResetOtp(email);
                            if (!dialogContext.mounted) return;

                            if (success) {
                              setDialogState(() {
                                isSubmitting = false;
                                currentStep = 2;
                                localError = null;
                              });
                            } else {
                              setDialogState(() {
                                isSubmitting = false;
                                localError = widget.authVM.errorMessage ?? strings.enterValidEmail;
                              });
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colors.primary,
                      foregroundColor: colors.onPrimary,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: isSubmitting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : Text(strings.sendOtpCode, style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ] else ...[
                  TextButton(
                    onPressed: isSubmitting
                        ? null
                        : () {
                            setDialogState(() {
                              currentStep = 1;
                              localError = null;
                            });
                          },
                    child: Text(strings.back, style: TextStyle(color: colors.textSecondary)),
                  ),
                  ElevatedButton(
                    onPressed: isSubmitting
                        ? null
                        : () async {
                            final otp = otpController.text.trim();
                            final newPass = newPasswordController.text;
                            final confirmPass = confirmPasswordController.text;

                            if (otp.isEmpty) {
                              setDialogState(() => localError = strings.enterValidOtp);
                              return;
                            }

                            setDialogState(() => isSubmitting = true);
                            final success = await widget.authVM.verifyOtpAndResetPassword(
                              email: emailController.text.trim(),
                              otp: otp,
                              newPassword: newPass,
                              confirmPassword: confirmPass,
                            );
                            if (!dialogContext.mounted) return;

                            if (success) {
                              Navigator.pop(dialogContext);

                              // Auto populate into login screen for convenience
                              _emailController.text = emailController.text.trim();
                              _passwordController.text = newPass;

                              if (mounted) {
                                ScaffoldMessenger.of(this.context).showSnackBar(
                                  SnackBar(
                                    content: Row(
                                      children: [
                                        const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(strings.resetPasswordSuccess),
                                        ),
                                      ],
                                    ),
                                    backgroundColor: Colors.green.shade700,
                                    duration: const Duration(seconds: 4),
                                  ),
                                );
                              }
                            } else {
                              setDialogState(() {
                                isSubmitting = false;
                                localError = widget.authVM.errorMessage ?? strings.enterValidOtp;
                              });
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colors.primary,
                      foregroundColor: colors.onPrimary,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: isSubmitting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : Text(strings.resetPasswordButton, style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColorsExtension.of(context);
    final strings = widget.settingsVM.strings;
    final isWide = MediaQuery.of(context).size.width >= 850;

    return Scaffold(
      backgroundColor: colors.appBackground,
      body: ListenableBuilder(
        listenable: widget.authVM,
        builder: (context, _) {
          return Row(
            children: [
              // Left Panel: Branding & App Highlights (Visible on Desktop / Wide screens)
              if (isWide)
                Expanded(
                  flex: 5,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          colors.surface,
                          colors.primary.withValues(alpha: 0.08),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      border: Border(right: BorderSide(color: colors.divider)),
                    ),
                    padding: const EdgeInsets.all(48),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // App Logo & Title
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: colors.primary,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: colors.primary.withValues(alpha: 0.3),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.auto_awesome,
                                size: 22,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Text(
                              strings.appTitle,
                              style: AppTypography.heading2.copyWith(
                                fontWeight: FontWeight.bold,
                                color: colors.textPrimary,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: colors.primary.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'AI Research',
                                style: AppTypography.caption.copyWith(
                                  color: colors.primary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),

                        // Headline Banner
                        Text(
                          strings.isVi
                              ? 'Đọc báo khoa học &\nnghiên cứu chuyên sâu cùng AI'
                              : 'Accelerate Your Research\nwith AI-Powered Intelligence',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                            color: colors.textPrimary,
                            height: 1.25,
                            letterSpacing: -0.8,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          strings.authSubtitle,
                          style: AppTypography.body.copyWith(
                            color: colors.textSecondary,
                            fontSize: 15,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 36),

                        // Feature Cards List
                        _FeatureHighlightTile(
                          icon: Icons.folder_special_rounded,
                          title: strings.isVi ? 'Quản lý Dự án Đa Tài liệu' : 'Multi-Document Project Workspace',
                          subtitle: strings.isVi ? 'Tương tác AI đồng thời trên hàng chục bài báo cùng lúc' : 'Chat with AI across multiple PDF documents simultaneously',
                        ),
                        const SizedBox(height: 14),
                        _FeatureHighlightTile(
                          icon: Icons.find_in_page_rounded,
                          title: strings.isVi ? 'Đối chiếu Trích dẫn Chính xác' : 'Precise Citation Cross-Referencing',
                          subtitle: strings.isVi ? 'Truy vết chính xác từng câu trả lời đến trang PDF gốc' : 'Trace every answer back to exact PDF pages and excerpts',
                        ),
                        const SizedBox(height: 14),
                        _FeatureHighlightTile(
                          icon: Icons.edit_note_rounded,
                          title: strings.isVi ? 'Ghi chú Thông minh Thu gọn' : 'Minimizable Smart Note Drafting',
                          subtitle: strings.isVi ? 'Vừa xem AI trả lời vừa tự gõ ghi chú không bị gián đoạn' : 'Take custom notes side-by-side without modal interruptions',
                        ),
                        const Spacer(),

                        // Footer watermark
                        Text(
                          strings.isVi ? '© 2026 Paperdesk AI Inc. Đã đăng ký bản quyền.' : '© 2026 Paperdesk AI Inc. All rights reserved.',
                          style: TextStyle(fontSize: 11, color: colors.textSecondary.withValues(alpha: 0.6)),
                        ),
                      ],
                    ),
                  ),
                ),

              // Right Panel: Auth Form Container (Login & Register)
              Expanded(
                flex: 4,
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 32),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 420),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // App icon branding for narrow mode
                          if (!isWide) ...[
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.auto_awesome, color: colors.primary, size: 28),
                                const SizedBox(width: 8),
                                Text(
                                  strings.appTitle,
                                  style: AppTypography.heading3.copyWith(fontWeight: FontWeight.bold, color: colors.textPrimary),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                          ],

                          // Auth Mode Header & Subtitle
                          Text(
                            _activeTab == 0 ? strings.signInTitle : strings.signUpTitle,
                            style: AppTypography.heading2.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colors.textPrimary,
                              fontSize: 24,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            strings.authSubtitle,
                            style: AppTypography.caption.copyWith(
                              color: colors.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Tab Switcher [Đăng nhập | Đăng ký]
                          Container(
                            height: 44,
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: colors.surface,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: colors.divider),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: InkWell(
                                    onTap: () => _switchTab(0),
                                    borderRadius: BorderRadius.circular(8),
                                    child: Container(
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        color: _activeTab == 0 ? colors.primary : Colors.transparent,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        strings.loginTab,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                          color: _activeTab == 0 ? colors.onPrimary : colors.textSecondary,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: InkWell(
                                    onTap: () => _switchTab(1),
                                    borderRadius: BorderRadius.circular(8),
                                    child: Container(
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        color: _activeTab == 1 ? colors.primary : Colors.transparent,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        strings.registerTab,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                          color: _activeTab == 1 ? colors.onPrimary : colors.textSecondary,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Error Message Banner if any
                          if (widget.authVM.errorMessage != null) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                color: colors.error.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: colors.error.withValues(alpha: 0.3)),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.error_outline, size: 18, color: colors.error),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      widget.authVM.errorMessage!,
                                      style: TextStyle(fontSize: 12, color: colors.error, fontWeight: FontWeight.w500),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],

                          // Form Field 1: Full Name (Only in Register tab)
                          if (_activeTab == 1) ...[
                            Text(
                              strings.fullNameLabel,
                              style: AppTypography.caption.copyWith(fontWeight: FontWeight.bold, color: colors.textPrimary),
                            ),
                            const SizedBox(height: 6),
                            TextField(
                              controller: _nameController,
                              style: AppTypography.body.copyWith(color: colors.textPrimary),
                              decoration: InputDecoration(
                                hintText: strings.fullNameHint,
                                hintStyle: AppTypography.caption.copyWith(color: colors.textSecondary.withValues(alpha: 0.6)),
                                prefixIcon: Icon(Icons.person_outline, size: 18, color: colors.textSecondary),
                                filled: true,
                                fillColor: colors.surface,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: colors.divider)),
                                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: colors.divider)),
                                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: colors.primary)),
                              ),
                            ),
                            const SizedBox(height: 14),
                          ],

                          // Form Field 2: Email Address
                          Text(
                            strings.emailLabel,
                            style: AppTypography.caption.copyWith(fontWeight: FontWeight.bold, color: colors.textPrimary),
                          ),
                          const SizedBox(height: 6),
                          TextField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            style: AppTypography.body.copyWith(color: colors.textPrimary),
                            decoration: InputDecoration(
                              hintText: strings.emailHint,
                              hintStyle: AppTypography.caption.copyWith(color: colors.textSecondary.withValues(alpha: 0.6)),
                              prefixIcon: Icon(Icons.email_outlined, size: 18, color: colors.textSecondary),
                              filled: true,
                              fillColor: colors.surface,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: colors.divider)),
                              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: colors.divider)),
                              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: colors.primary)),
                            ),
                          ),
                          const SizedBox(height: 14),

                          // Form Field 3: Password
                          Text(
                            strings.passwordLabel,
                            style: AppTypography.caption.copyWith(fontWeight: FontWeight.bold, color: colors.textPrimary),
                          ),
                          const SizedBox(height: 6),
                          TextField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            style: AppTypography.body.copyWith(color: colors.textPrimary),
                            decoration: InputDecoration(
                              hintText: strings.passwordHint,
                              hintStyle: AppTypography.caption.copyWith(color: colors.textSecondary.withValues(alpha: 0.6)),
                              prefixIcon: Icon(Icons.lock_outline, size: 18, color: colors.textSecondary),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                  size: 18,
                                  color: colors.textSecondary,
                                ),
                                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                              ),
                              filled: true,
                              fillColor: colors.surface,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: colors.divider)),
                              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: colors.divider)),
                              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: colors.primary)),
                            ),
                          ),
                          const SizedBox(height: 14),

                          // Form Field 4: Confirm Password (Only in Register tab)
                          if (_activeTab == 1) ...[
                            Text(
                              strings.confirmPasswordLabel,
                              style: AppTypography.caption.copyWith(fontWeight: FontWeight.bold, color: colors.textPrimary),
                            ),
                            const SizedBox(height: 6),
                            TextField(
                              controller: _confirmPasswordController,
                              obscureText: _obscureConfirmPassword,
                              style: AppTypography.body.copyWith(color: colors.textPrimary),
                              decoration: InputDecoration(
                                hintText: strings.confirmPasswordHint,
                                hintStyle: AppTypography.caption.copyWith(color: colors.textSecondary.withValues(alpha: 0.6)),
                                prefixIcon: Icon(Icons.lock_reset, size: 18, color: colors.textSecondary),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscureConfirmPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                    size: 18,
                                    color: colors.textSecondary,
                                  ),
                                  onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                                ),
                                filled: true,
                                fillColor: colors.surface,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: colors.divider)),
                                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: colors.divider)),
                                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: colors.primary)),
                              ),
                            ),
                            const SizedBox(height: 14),
                          ],

                          // Remember Me / Forgot Password (In Login mode)
                          if (_activeTab == 0)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: Checkbox(
                                        value: _rememberMe,
                                        onChanged: (val) => setState(() => _rememberMe = val ?? true),
                                        activeColor: colors.primary,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(strings.rememberMe, style: TextStyle(fontSize: 12, color: colors.textSecondary)),
                                  ],
                                ),
                                TextButton(
                                  onPressed: _showForgotPasswordDialog,
                                  child: Text(strings.forgotPassword, style: TextStyle(fontSize: 12, color: colors.primary, fontWeight: FontWeight.bold)),
                                ),
                              ],
                            ),
                          const SizedBox(height: 20),

                          // Primary Action Button (Sign In / Register)
                          ElevatedButton(
                            onPressed: widget.authVM.isLoading ? null : _submitForm,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: colors.primary,
                              foregroundColor: colors.onPrimary,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              elevation: 2,
                            ),
                            child: widget.authVM.isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                  )
                                : Text(
                                    _activeTab == 0 ? strings.signInButton : strings.signUpButton,
                                    style: AppTypography.subtitle.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: colors.onPrimary,
                                      fontSize: 15,
                                    ),
                                  ),
                          ),
                          const SizedBox(height: 24),

                          // Switch Tab Prompt Link at Bottom
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                _activeTab == 0 ? strings.dontHaveAccount : strings.alreadyHaveAccount,
                                style: TextStyle(fontSize: 13, color: colors.textSecondary),
                              ),
                              TextButton(
                                onPressed: () => _switchTab(_activeTab == 0 ? 1 : 0),
                                child: Text(
                                  _activeTab == 0 ? strings.signUpNow : strings.signInNow,
                                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: colors.primary),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _FeatureHighlightTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _FeatureHighlightTile({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColorsExtension.of(context);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.surface.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.divider.withValues(alpha: 0.6)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: colors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: colors.primary, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.caption.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colors.textPrimary,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: AppTypography.caption.copyWith(
                    color: colors.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

