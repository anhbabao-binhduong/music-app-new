import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:music_app/pages/auth/auth_shared.dart';
import 'package:music_app/pages/auth/login_page.dart';
import 'package:music_app/presentation/bloc/forgot_password/forgot_password_cubit.dart';
import 'package:music_app/presentation/bloc/forgot_password/forgot_password_state.dart';

class ResetPasswordPage extends StatefulWidget {
  const ResetPasswordPage({super.key});

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _newPassController = TextEditingController();
  final _confirmPassController = TextEditingController();

  late final AnimationController _bgController;

  bool _obscureNew = true;
  bool _obscureConfirm = true;

  @override
  void initState() {
    super.initState();
    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();
  }

  @override
  void dispose() {
    _bgController.dispose();
    _newPassController.dispose();
    _confirmPassController.dispose();
    super.dispose();
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'Vui lòng nhập mật khẩu mới';
    if (value.length < 8) return 'Mật khẩu phải có ít nhất 8 ký tự';

    final hasUpper = RegExp(r'[A-Z]').hasMatch(value);
    final hasDigit = RegExp(r'\d').hasMatch(value);

    if (!hasUpper || !hasDigit) {
      return 'Mật khẩu phải có chữ hoa và số';
    }
    return null;
  }

  String? _validateConfirm(String? value) {
    if (value == null || value.isEmpty) return 'Vui lòng xác nhận mật khẩu';
    if (value != _newPassController.text) return 'Mật khẩu xác nhận không khớp';
    return null;
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    await context
        .read<ForgotPasswordCubit>()
        .updatePassword(_newPassController.text);
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

  @override
  Widget build(BuildContext context) {
    return BlocListener<ForgotPasswordCubit, ForgotPasswordState>(
      listener: (context, state) {
        if (state is ResetPasswordSuccess) {
          _showSnack('Đổi mật khẩu thành công');
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const LoginPage()),
            (route) => false,
          );
          return;
        }

        if (state is ResetPasswordError) {
          _showSnack(state.message, isError: true);
        }
      },
      child: Scaffold(
        backgroundColor: kAuthBg,
        body: Stack(
          fit: StackFit.expand,
          children: [
            AuthAnimatedBackground(controller: _bgController),
            SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth > 600;
                  final horizontalPadding = isWide
                      ? (constraints.maxWidth * 0.08).clamp(40.0, 80.0)
                      : 28.0;
                  final verticalPadding = isWide ? 60.0 : 40.0;
                  final maxWidth = isWide ? 560.0 : 460.0;

                  return SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minHeight: constraints.maxHeight),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(maxWidth: maxWidth),
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: horizontalPadding,
                              vertical: verticalPadding,
                            ),
                            child: Form(
                              key: _formKey,
                              child: BlocBuilder<ForgotPasswordCubit,
                                  ForgotPasswordState>(
                                builder: (context, state) {
                                  final isLoading = state is ResetPasswordLoading;

                                  return Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      _buildHeader(isWide),
                                      SizedBox(height: isWide ? 56 : 48),
                                      AuthTextField(
                                        controller: _newPassController,
                                        hintText: 'Mật khẩu mới',
                                        prefixIcon: Icons.lock_outline_rounded,
                                        obscureText: _obscureNew,
                                        validator: _validatePassword,
                                        suffixIcon: GestureDetector(
                                          onTap: () => setState(
                                              () => _obscureNew = !_obscureNew),
                                          child: Icon(
                                            _obscureNew
                                                ? Icons.visibility_off_outlined
                                                : Icons.visibility_outlined,
                                            color: kAuthSubText,
                                            size: 20,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      AuthTextField(
                                        controller: _confirmPassController,
                                        hintText: 'Xác nhận mật khẩu',
                                        prefixIcon: Icons.lock_rounded,
                                        obscureText: _obscureConfirm,
                                        validator: _validateConfirm,
                                        suffixIcon: GestureDetector(
                                          onTap: () => setState(() =>
                                              _obscureConfirm = !_obscureConfirm),
                                          child: Icon(
                                            _obscureConfirm
                                                ? Icons.visibility_off_outlined
                                                : Icons.visibility_outlined,
                                            color: kAuthSubText,
                                            size: 20,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 28),
                                      AuthGradientButton(
                                        label: 'Cập nhật mật khẩu',
                                        isLoading: isLoading,
                                        onTap: _submit,
                                      ),
                                      const SizedBox(height: 16),
                                      TextButton(
                                        onPressed: isLoading
                                            ? null
                                            : () => Navigator.of(context).pushAndRemoveUntil(
                                                  MaterialPageRoute(
                                                      builder: (_) =>
                                                          const LoginPage()),
                                                  (route) => false,
                                                ),
                                        child: const Text(
                                          'Quay lại đăng nhập',
                                          style: TextStyle(
                                            color: kAuthAccent,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                    ],
                                  );
                                },
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
            Icons.password_rounded,
            color: Colors.white,
            size: isWide ? 48 : 42,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Đặt lại mật khẩu',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white,
            fontSize: titleSize,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Tạo một mật khẩu mới mạnh để bảo vệ tài khoản của bạn',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: kAuthSubText,
            fontSize: 14,
            height: 1.5,
          ),
        ),
      ],
    );
  }
}