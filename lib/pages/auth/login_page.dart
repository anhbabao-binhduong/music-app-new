import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:music_app/pages/auth/auth_shared.dart';
import 'package:music_app/pages/auth/register_page.dart';
import 'package:music_app/pages/home/home_page.dart';
import 'package:music_app/services/supabase_auth_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _authService = SupabaseAuthService();

  bool _obscurePass = true;
  bool _isLoading = false;
  bool _isGoogleLoading = false;
  late final AnimationController _bgCtrl;

  @override
  void initState() {
    super.initState();
    _bgCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();
  }

  @override
  void dispose() {
    _bgCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  String? _validateEmail(String? v) {
    if (v == null || v.trim().isEmpty) return 'Vui lòng nhập email';
    final re = RegExp(r'^[\w.\-]+@[\w\-]+\.[a-zA-Z]{2,}$');
    if (!re.hasMatch(v.trim())) return 'Email không hợp lệ';
    return null;
  }

  String? _validatePass(String? v) {
    if (v == null || v.isEmpty) return 'Vui lòng nhập mật khẩu';
    if (v.length < 6) return 'Mật khẩu phải có ít nhất 6 ký tự';
    return null;
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      await _authService.signIn(
        email: _emailCtrl.text.trim(),
        password: _passCtrl.text,
      );
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const HomePage()),
        (route) => false,
      );
    } catch (e) {
      _showSnack(_authService.mapError(e), isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? kAuthError : Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Future<void> _signInWithGoogle() async {
    setState(() => _isGoogleLoading = true);
    try {
      final response = await _authService.signInWithGoogle();
      if (!mounted) return;
      // response == null nghĩa là web đang redirect → không navigate thủ công
      if (response != null) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const HomePage()),
          (route) => false,
        );
      }
    } catch (e) {
      final msg = _authService.mapError(e);
      if (msg != 'Đã huỷ đăng nhập') {
        _showSnack(msg, isError: true);
      }
    } finally {
      if (mounted) setState(() => _isGoogleLoading = false);
    }
  }

  void _showComingSoon(String provider) {
    final suffix = kIsWeb ? ' trên bản web này' : '';
    _showSnack('$provider chưa được tích hợp$suffix', isError: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kAuthBg,
      body: Stack(
        fit: StackFit.expand,
        children: [
          AuthAnimatedBackground(controller: _bgCtrl),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth > 600;
                final hPad = isWide
                    ? (constraints.maxWidth * 0.08).clamp(40.0, 80.0)
                    : 28.0;
                final vPad = isWide ? 60.0 : 40.0;
                final maxW = isWide ? 560.0 : 460.0;

                return SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: constraints.maxHeight),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: maxW),
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: hPad,
                            vertical: vPad,
                          ),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _buildHeader(isWide),
                                SizedBox(height: isWide ? 56 : 48),
                                _buildForm(),
                                const SizedBox(height: 32),
                                _buildLoginButton(),
                                const SizedBox(height: 28),
                                _buildDivider(),
                                const SizedBox(height: 24),
                                _buildSocialButtons(),
                                const SizedBox(height: 36),
                                _buildFooter(context),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(bool isWide) {
    final iconSize = isWide ? 100.0 : 88.0;
    final titleSize = isWide ? 32.0 : 28.0;

    return Column(
      children: [
        Container(
          width: iconSize,
          height: iconSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [Color(0xFF7B1FA2), Color(0xFF1565C0)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF7B1FA2).withValues(alpha: 0.55),
                blurRadius: 32,
                spreadRadius: 4,
              ),
            ],
          ),
          child: Icon(
            Icons.lock_person_rounded,
            color: Colors.white,
            size: isWide ? 48 : 42,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Chào mừng trở lại!',
          style: TextStyle(
            color: Colors.white,
            fontSize: titleSize,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Đăng nhập bằng email và mật khẩu để tiếp tục nghe nhạc',
          textAlign: TextAlign.center,
          style: TextStyle(color: kAuthSubText, fontSize: 14, height: 1.5),
        ),
      ],
    );
  }

  Widget _buildForm() {
    return Column(
      children: [
        AuthTextField(
          controller: _emailCtrl,
          hintText: 'Địa chỉ Email',
          prefixIcon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
          validator: _validateEmail,
        ),
        const SizedBox(height: 16),
        AuthTextField(
          controller: _passCtrl,
          hintText: 'Mật khẩu',
          prefixIcon: Icons.lock_outline_rounded,
          obscureText: _obscurePass,
          validator: _validatePass,
          suffixIcon: GestureDetector(
            onTap: () => setState(() => _obscurePass = !_obscurePass),
            child: Icon(
              _obscurePass
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
              color: kAuthSubText,
              size: 20,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoginButton() => AuthGradientButton(
        label: 'Đăng nhập',
        isLoading: _isLoading,
        onTap: _submit,
      );

  Widget _buildDivider() {
    return Row(
      children: [
        Expanded(
          child: Divider(
            color: Colors.white.withValues(alpha: 0.12),
            thickness: 1,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'hoặc tiếp tục với',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.35),
              fontSize: 12,
            ),
          ),
        ),
        Expanded(
          child: Divider(
            color: Colors.white.withValues(alpha: 0.12),
            thickness: 1,
          ),
        ),
      ],
    );
  }

  Widget _buildSocialButtons() {
    return Row(
      children: [
        Expanded(
          child: _isGoogleLoading
              ? Container(
                  height: 52,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: Colors.white.withValues(alpha: 0.1)),
                  ),
                  child: const Center(
                    child: SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation(Color(0xFFEA4335)),
                      ),
                    ),
                  ),
                )
              : AuthSocialButton(
                  label: 'Google',
                  icon: Icons.g_mobiledata_rounded,
                  iconColor: const Color(0xFFEA4335),
                  onTap: _signInWithGoogle,
                ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: AuthSocialButton(
            label: 'Facebook',
            icon: Icons.facebook_rounded,
            iconColor: const Color(0xFF1877F2),
            onTap: () => _showComingSoon('Đăng nhập Facebook'),
          ),
        ),
      ],
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          'Chưa có tài khoản? ',
          style: TextStyle(color: kAuthSubText, fontSize: 14),
        ),
        GestureDetector(
          onTap: () => Navigator.of(context).push(
            PageRouteBuilder(
              pageBuilder: (_, anim, __) => const RegisterPage(),
              transitionsBuilder: (_, anim, __, child) => SlideTransition(
                position: Tween(
                  begin: const Offset(1, 0),
                  end: Offset.zero,
                ).animate(
                  CurvedAnimation(parent: anim, curve: Curves.easeOutCubic),
                ),
                child: child,
              ),
            ),
          ),
          child: const Text(
            'Đăng ký ngay',
            style: TextStyle(
              color: kAuthAccent,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}
