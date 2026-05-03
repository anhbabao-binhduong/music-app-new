import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:music_app/pages/auth/auth_shared.dart';
import 'package:music_app/presentation/bloc/forgot_password/forgot_password_cubit.dart';
import 'package:music_app/presentation/bloc/forgot_password/forgot_password_state.dart';

class ForgotPasswordCheckEmailPage extends StatefulWidget {
  final String email;

  const ForgotPasswordCheckEmailPage({super.key, required this.email});

  @override
  State<ForgotPasswordCheckEmailPage> createState() =>
      _ForgotPasswordCheckEmailPageState();
}

class _ForgotPasswordCheckEmailPageState extends State<ForgotPasswordCheckEmailPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _bgController;

  Timer? _cooldownTimer;
  int _remainingSeconds = 60;

  bool get _canResend => _remainingSeconds <= 0;

  @override
  void initState() {
    super.initState();
    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();

    _startCooldown();
  }

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    _bgController.dispose();
    super.dispose();
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

  String _maskEmail(String email) {
    final trimmed = email.trim();
    final atIndex = trimmed.indexOf('@');
    if (atIndex <= 1) return trimmed;

    final local = trimmed.substring(0, atIndex);
    final domain = trimmed.substring(atIndex + 1);

    final keep = local.length >= 3 ? 2 : 1;
    final masked = '${local.substring(0, keep)}***';

    return '$masked@$domain';
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ForgotPasswordCubit, ForgotPasswordState>(
      listener: (context, state) {
        if (state is ForgotPasswordError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: kAuthError,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              margin: const EdgeInsets.all(16),
            ),
          );
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
                      constraints:
                          BoxConstraints(minHeight: constraints.maxHeight),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(maxWidth: maxWidth),
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: horizontalPadding,
                              vertical: verticalPadding,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _buildHeader(isWide),
                                SizedBox(height: isWide ? 52 : 44),
                                Container(
                                  padding: const EdgeInsets.all(18),
                                  decoration: BoxDecoration(
                                    color: kAuthCard,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color:
                                          Colors.white.withValues(alpha: 0.08),
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Email đã gửi tới',
                                        style: TextStyle(
                                          color: kAuthSubText,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          letterSpacing: 0.2,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        _maskEmail(widget.email),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: -0.2,
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      const Text(
                                        'Hãy mở email và bấm vào liên kết để đặt lại mật khẩu.',
                                        style: TextStyle(
                                          color: kAuthSubText,
                                          fontSize: 14,
                                          height: 1.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 20),
                                TextButton(
                                  onPressed: _canResend
                                      ? () async {
                                          _startCooldown();
                                          await context
                                              .read<ForgotPasswordCubit>()
                                              .resendResetEmail(widget.email);
                                        }
                                      : null,
                                  child: Text(
                                    _canResend
                                        ? 'Gửi lại'
                                        : 'Gửi lại sau $_remainingSeconds giây',
                                    style: const TextStyle(
                                      color: kAuthAccent,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(),
                                  child: const Text(
                                    'Quay lại',
                                    style: TextStyle(
                                      color: kAuthSubText,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ],
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
            Icons.mark_email_read_rounded,
            color: Colors.white,
            size: isWide ? 48 : 42,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Kiểm tra email',
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
          'Chúng tôi đã gửi một liên kết đặt lại mật khẩu. Hãy kiểm tra hộp thư đến và cả mục Spam.',
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