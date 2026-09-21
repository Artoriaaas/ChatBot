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
      await widget.authVM.loginWithEmail(
        _emailController.text,
        _passwordController.text,
      );
    } else {
      await widget.authVM.registerWithEmail(
        name: _nameController.text,
        email: _emailController.text,
        password: _passwordController.text,
        confirmPassword: _confirmPasswordController.text,
      );
    }
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

                          // Google Auth Button
                          OutlinedButton(
                            onPressed: widget.authVM.isLoading ? null : () => widget.authVM.loginWithGoogle(),
                            style: OutlinedButton.styleFrom(
                              backgroundColor: colors.surface,
                              foregroundColor: colors.textPrimary,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              side: BorderSide(color: colors.divider),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // Google G Icon
                                Container(
                                  width: 20,
                                  height: 20,
                                  alignment: Alignment.center,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.white,
                                  ),
                                  child: const Text(
                                    'G',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blueAccent,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  strings.continueWithGoogle,
                                  style: AppTypography.body.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: colors.textPrimary,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Divider: - HOẶC BẰNG EMAIL -
                          Row(
                            children: [
                              Expanded(child: Divider(color: colors.divider)),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                child: Text(
                                  strings.orWithEmail,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.8,
                                    color: colors.textSecondary.withValues(alpha: 0.7),
                                  ),
                                ),
                              ),
                              Expanded(child: Divider(color: colors.divider)),
                            ],
                          ),
                          const SizedBox(height: 20),

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
                                  onPressed: () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Vui lòng kiểm tra hộp thư email của bạn để đặt lại mật khẩu.')),
                                    );
                                  },
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

