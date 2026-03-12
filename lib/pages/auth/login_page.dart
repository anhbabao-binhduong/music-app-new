import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:music_app/pages/auth/auth_shared.dart';
import 'package:music_app/pages/auth/register_page.dart';
import 'package:music_app/pages/home/home_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with SingleTickerProviderStateMixin {
  final _formKey   = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl  = TextEditingController();

  bool _obscurePass = true;
  bool _isLoading   = false;

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
    final re = RegExp(r'^[\w\.\-]+@[\w\-]+\.[a-zA-Z]{2,}$');
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
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailCtrl.text.trim(),
        password: _passCtrl.text,
      );
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const HomePage()),
        (route) => false,
      );
    } on FirebaseAuthException catch (e) {
      _showSnack(_friendlyError(e.code), isError: true);
    } catch (e) {
      _showSnack('Đã xảy ra lỗi. Vui lòng thử lại.', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? kAuthError : Colors.green.shade600,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      margin: const EdgeInsets.all(16),
    ));
  }

  String _friendlyError(String code) {
    switch (code) {
      case 'user-not-found':         return 'Email này chưa được đăng ký';
      case 'wrong-password':         return 'Mật khẩu không đúng';
      case 'invalid-credential':     return 'Email hoặc mật khẩu không đúng';
      case 'invalid-email':          return 'Email không hợp lệ';
      case 'user-disabled':          return 'Tài khoản này đã bị vô hiệu hóa';
      case 'too-many-requests':      return 'Quá nhiều lần thử. Vui lòng thử lại sau';
      case 'network-request-failed': return 'Lỗi kết nối mạng';
      default:                       return 'Đăng nhập thất bại ($code)';
    }
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
                final hPad   = isWide
                    ? (constraints.maxWidth * 0.08).clamp(40.0, 80.0)
                    : 28.0;
                final vPad   = isWide ? 60.0 : 40.0;
                final maxW   = isWide ? 560.0 : 460.0;

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
    final iconSize  = isWide ? 100.0 : 88.0;
    final titleSize = isWide ? 32.0  : 28.0;

    return Column(
      children: [
        Container(
          width: iconSize, height: iconSize,
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
          child: Icon(Icons.music_note_rounded, color: Colors.white,
              size: isWide ? 48 : 42),
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
          'Đăng nhập để tiếp tục thưởng thức âm nhạc',
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
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerRight,
          child: GestureDetector(
            onTap: () {},
            child: const Text(
              'Quên mật khẩu?',
              style: TextStyle(
                color: kAuthAccent,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
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
          child: AuthSocialButton(
            label: 'Google',
            icon: Icons.g_mobiledata_rounded,
            iconColor: const Color(0xFFEA4335),
            onTap: () {},
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: AuthSocialButton(
            label: 'Facebook',
            icon: Icons.facebook_rounded,
            iconColor: const Color(0xFF1877F2),
            onTap: () {},
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