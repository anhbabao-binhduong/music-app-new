import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:music_app/core/router/app_routes.dart';
import 'package:music_app/pages/auth/auth_shared.dart';
import 'package:music_app/pages/auth/login_page.dart';
import 'package:music_app/presentation/bloc/forgot_password/forgot_password_cubit.dart';
import 'package:music_app/presentation/bloc/forgot_password/forgot_password_state.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  late final AnimationController _bgController;

  Timer? _cooldownTimer;
  int _remainingSeconds = 0;
  String? _emailError;

  bool get _isCooldownActive => _remainingSeconds > 0;

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
    _cooldownTimer?.cancel();
    _bgController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  String? _validateEmail(String? value) {
    if (_emailError != null) return _emailError;
    if (value == null || value.trim().isEmpty) {
      return 'Vui lòng nhập email';
    }
    final regex = RegExp(r'^[\w.\-]+@[\w\-]+\.[a-zA-Z]{2,}$');
    if (!regex.hasMatch(value.trim())) {
      return 'Email không hợp lệ';
    }
    return null;
  }

  void _startCooldown() {
    _cooldownTimer?.cancel();
    setState(() => _remainingSeconds = 60);
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_remainingSeconds <= 1) {
        timer.cancel();
        setState(() => _remainingSeconds = 0);
        return;
      }
      setState(() => _remainingSeconds -= 1);
    });
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    setState(() => _emailError = null);

    if (!_formKey.currentState!.validate() || _isCooldownActive) {
      return;
    }

    await context
        .read<ForgotPasswordCubit>()
        .sendResetEmail(_emailController.text.trim());
  }

  void _handleStateChange(ForgotPasswordState state) {
    if (state is ForgotPasswordLoading ||
        state is ResetPasswordLoading ||
        state is ForgotPasswordInitial) {
      return;
    }

    if (state is ForgotPasswordEmailSent) {
      _startCooldown();
      Navigator.of(context).pushNamed(
        AppRoutes.forgotPasswordCheckEmail,
        arguments: state.email,
      );
      return;
    }

    if (state is ForgotPasswordError) {
      final message = state.message.toLowerCase();
      final isMissingEmail = message.contains('not found') ||
          message.contains('email') && message.contains('không tồn tại') ||
          message.contains('user') && message.contains('not found');

      if (isMissingEmail) {
        setState(() => _emailError = 'Email không tồn tại trong hệ thống');
        _formKey.currentState?.validate();
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(state.message),
          backgroundColor: kAuthError,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ForgotPasswordCubit, ForgotPasswordState>(
      listener: (context, state) => _handleStateChange(state),
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
                                  final isLoading = state is ForgotPasswordLoading;

                                  return Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      _buildHeader(isWide),
                                      SizedBox(height: isWide ? 56 : 48),
                                      AuthTextField(
                                        controller: _emailController,
                                        hintText: 'Nhập email đã đăng ký',
                                        prefixIcon: Icons.mail_outline_rounded,
                                        keyboardType:
                                            TextInputType.emailAddress,
                                        validator: _validateEmail,
                                      ),
                                      const SizedBox(height: 12),
                                      AnimatedOpacity(
                                        duration:
                                            const Duration(milliseconds: 200),
                                        opacity: _isCooldownActive ? 1 : 0,
                                        child: Text(
                                          _isCooldownActive
                                              ? 'Bạn có thể gửi lại sau $_remainingSeconds giây'
                                              : '',
                                          style: const TextStyle(
                                            color: kAuthSubText,
                                            fontSize: 12,
                                            height: 1.4,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 28),
                                      AuthGradientButton(
                                        label: _isCooldownActive
                                            ? 'Gửi lại sau $_remainingSeconds giây'
                                            : 'Gửi email khôi phục',
                                        isLoading: isLoading,
                                        onTap: _submit,
                                      ),
                                      const SizedBox(height: 20),
                                      TextButton(
                                        onPressed: isLoading
                                            ? null
                                            : () {
                                                Navigator.of(context).pushReplacement(
                                                  MaterialPageRoute(
                                                    builder: (_) =>
                                                        const LoginPage(),
                                                  ),
                                                );
                                              },
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
            Icons.lock_reset_rounded,
            color: Colors.white,
            size: isWide ? 48 : 42,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Khôi phục mật khẩu',
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
          'Nhập email của bạn để nhận liên kết đặt lại mật khẩu an toàn',
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