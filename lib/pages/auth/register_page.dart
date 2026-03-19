import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:music_app/pages/auth/auth_shared.dart';
import 'package:music_app/pages/home/home_page.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage>
    with SingleTickerProviderStateMixin {
  final _formKey     = GlobalKey<FormState>();
  final _nameCtrl    = TextEditingController();
  final _emailCtrl   = TextEditingController();
  final _passCtrl    = TextEditingController();
  final _confirmCtrl = TextEditingController();

  bool _obscurePass    = true;
  bool _obscureConfirm = true;
  bool _isLoading      = false;
  bool _agreedToTerms  = false;

  late final AnimationController _bgCtrl;

  @override
  void initState() {
    super.initState();
    _bgCtrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 8))..repeat();
  }

  @override
  void dispose() {
    _bgCtrl.dispose();
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  String? _validateName(String? v) {
    if (v == null || v.trim().isEmpty) return 'Vui lòng nhập tên của bạn';
    if (v.trim().length < 2) return 'Tên phải có ít nhất 2 ký tự';
    return null;
  }

  String? _validateEmail(String? v) {
    if (v == null || v.trim().isEmpty) return 'Vui lòng nhập email';
    final re = RegExp(r'^[\w\.\-]+@[\w\-]+\.[a-zA-Z]{2,}$');
    if (!re.hasMatch(v.trim())) return 'Email không hợp lệ';
    return null;
  }

  String? _validatePass(String? v) {
    if (v == null || v.isEmpty) return 'Vui lòng nhập mật khẩu';
    if (v.length < 7) return 'Mật khẩu phải có ít nhất 7 ký tự';
    if (!RegExp(r'[A-Z]').hasMatch(v)) return 'Phải có ít nhất 1 chữ hoa (A-Z)';
    if (!RegExp(r'[!@#\$%^&*(),.?":{}|<>_\-+=\[\]\\\/]').hasMatch(v))
      return 'Phải có ít nhất 1 ký tự đặc biệt (!@#\$...)';
    return null;
  }

  String? _validateConfirm(String? v) {
    if (v == null || v.isEmpty) return 'Vui lòng xác nhận mật khẩu';
    if (v != _passCtrl.text) return 'Mật khẩu không khớp';
    return null;
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

  void _showComingSoon(String provider) {
    final suffix = kIsWeb ? ' trên bản web này' : '';
    _showSnack('$provider chưa được tích hợp$suffix', isError: true);
  }

  String _friendlyError(String code) {
    switch (code) {
      case 'email-already-in-use':    return 'Email này đã được sử dụng';
      case 'invalid-email':           return 'Email không hợp lệ';
      case 'weak-password':           return 'Mật khẩu quá yếu';
      case 'network-request-failed':  return 'Lỗi kết nối mạng';
      case 'too-many-requests':       return 'Quá nhiều yêu cầu. Thử lại sau';
      default:                        return 'Đăng ký thất bại ($code)';
    }
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    if (!_agreedToTerms) {
      _showSnack('Vui lòng đồng ý với Điều khoản dịch vụ', isError: true);
      return;
    }
    setState(() => _isLoading = true);
    try {
      final credential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
        email: _emailCtrl.text.trim(),
        password: _passCtrl.text,
      );
      final user = credential.user!;
      await user.updateDisplayName(_nameCtrl.text.trim());
      try {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'uid':       user.uid,
          'name':      _nameCtrl.text.trim(),
          'email':     _emailCtrl.text.trim(),
          'createdAt': FieldValue.serverTimestamp(),
          'avatarUrl': '',
        });
      } catch (_) {}

      if (!mounted) return;
      _showSnack('Tạo tài khoản thành công! 🎉');
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kAuthBg,
      body: Stack(
        children: [
          AuthAnimatedBackground(controller: _bgCtrl),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Center(
                  child: ConstrainedBox(
                    // ← giới hạn max width 460px trên web/tablet
                    constraints: const BoxConstraints(maxWidth: 460),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 28, vertical: 40),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _buildHeader(context),
                            const SizedBox(height: 36),
                            _buildForm(),
                            const SizedBox(height: 20),
                            _buildTermsRow(),
                            const SizedBox(height: 28),
                            _buildRegisterButton(),
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
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Column(
      children: [
        Row(children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
              ),
              child: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: Colors.white, size: 16),
            ),
          ),
        ]),
        const SizedBox(height: 28),
        Container(
          width: 80, height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [Color(0xFF4A148C), Color(0xFF0D47A1)],
              begin: Alignment.topLeft, end: Alignment.bottomRight,
            ),
            boxShadow: [BoxShadow(
              color: const Color(0xFF4A148C).withValues(alpha: 0.5),
              blurRadius: 28, spreadRadius: 2,
            )],
          ),
          child: const Icon(Icons.headphones_rounded, color: Colors.white, size: 38),
        ),
        const SizedBox(height: 20),
        const Text('Tạo tài khoản mới',
            style: TextStyle(color: Colors.white, fontSize: 26,
                fontWeight: FontWeight.w800, letterSpacing: -0.5)),
        const SizedBox(height: 8),
        const Text('Tham gia để trải nghiệm âm nhạc không giới hạn',
            textAlign: TextAlign.center,
            style: TextStyle(color: kAuthSubText, fontSize: 13.5, height: 1.5)),
      ],
    );
  }

  Widget _buildForm() {
    return Column(children: [
      AuthTextField(controller: _nameCtrl, hintText: 'Họ và tên',
          prefixIcon: Icons.person_outline_rounded, validator: _validateName),
      const SizedBox(height: 14),
      AuthTextField(controller: _emailCtrl, hintText: 'Địa chỉ Email',
          prefixIcon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress, validator: _validateEmail),
      const SizedBox(height: 14),
      AuthTextField(
        controller: _passCtrl, hintText: 'Mật khẩu',
        prefixIcon: Icons.lock_outline_rounded,
        obscureText: _obscurePass, validator: _validatePass,
        suffixIcon: GestureDetector(
          onTap: () => setState(() => _obscurePass = !_obscurePass),
          child: Icon(_obscurePass
              ? Icons.visibility_off_outlined : Icons.visibility_outlined,
              color: kAuthSubText, size: 20),
        ),
      ),
      const SizedBox(height: 14),
      AuthTextField(
        controller: _confirmCtrl, hintText: 'Xác nhận mật khẩu',
        prefixIcon: Icons.lock_person_outlined,
        obscureText: _obscureConfirm, validator: _validateConfirm,
        suffixIcon: GestureDetector(
          onTap: () => setState(() => _obscureConfirm = !_obscureConfirm),
          child: Icon(_obscureConfirm
              ? Icons.visibility_off_outlined : Icons.visibility_outlined,
              color: kAuthSubText, size: 20),
        ),
      ),
    ]);
  }

  Widget _buildTermsRow() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () => setState(() => _agreedToTerms = !_agreedToTerms),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 22, height: 22,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              gradient: _agreedToTerms
                  ? const LinearGradient(
                      colors: [Color(0xFF7B1FA2), Color(0xFF1565C0)],
                      begin: Alignment.topLeft, end: Alignment.bottomRight)
                  : null,
              border: !_agreedToTerms
                  ? Border.all(color: Colors.white.withValues(alpha: 0.25), width: 1.5)
                  : null,
            ),
            child: _agreedToTerms
                ? const Icon(Icons.check_rounded, color: Colors.white, size: 14)
                : null,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: RichText(
            text: const TextSpan(
              style: TextStyle(color: kAuthSubText, fontSize: 13, height: 1.5),
              children: [
                TextSpan(text: 'Tôi đồng ý với '),
                TextSpan(text: 'Điều khoản dịch vụ',
                    style: TextStyle(color: kAuthAccent, fontWeight: FontWeight.w600)),
                TextSpan(text: ' và '),
                TextSpan(text: 'Chính sách bảo mật',
                    style: TextStyle(color: kAuthAccent, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRegisterButton() => AuthGradientButton(
      label: 'Tạo tài khoản', isLoading: _isLoading, onTap: _submit);

  Widget _buildDivider() {
    return Row(children: [
      Expanded(child: Divider(color: Colors.white.withValues(alpha: 0.12), thickness: 1)),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Text('hoặc đăng ký với',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.35), fontSize: 12)),
      ),
      Expanded(child: Divider(color: Colors.white.withValues(alpha: 0.12), thickness: 1)),
    ]);
  }

  Widget _buildSocialButtons() {
    return Row(children: [
      Expanded(child: AuthSocialButton(label: 'Google',
          icon: Icons.g_mobiledata_rounded,
          iconColor: const Color(0xFFEA4335),
          onTap: () => _showComingSoon('Đăng ký Google'))),
      const SizedBox(width: 14),
      Expanded(child: AuthSocialButton(label: 'Facebook',
          icon: Icons.facebook_rounded,
          iconColor: const Color(0xFF1877F2),
          onTap: () => _showComingSoon('Đăng ký Facebook'))),
    ]);
  }

  Widget _buildFooter(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text('Đã có tài khoản? ',
            style: TextStyle(color: kAuthSubText, fontSize: 14)),
        GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: const Text('Đăng nhập',
              style: TextStyle(color: kAuthAccent, fontSize: 14,
                  fontWeight: FontWeight.w700)),
        ),
      ],
    );
  }
}