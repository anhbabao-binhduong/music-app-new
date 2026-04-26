import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:music_app/core/constants/colors.dart';
import 'package:music_app/presentation/bloc/admin/admin_cubit.dart';
import 'package:music_app/pages/home/home_page.dart';
import 'package:music_app/pages/admin/admin_stack.dart';

/// Màn hình điều phối đầu tiên sau khi mở app.
/// - Chưa đăng nhập → [HomePage] (guest mode)
/// - Đã đăng nhập + role user → [HomePage]
/// - Đã đăng nhập + role admin/moderator → [AdminStack]
class RootPage extends StatefulWidget {
  const RootPage({super.key});

  @override
  State<RootPage> createState() => _RootPageState();
}

class _RootPageState extends State<RootPage> {
  _RootState _state = _RootState.checking;
  String _role = 'user';

  @override
  void initState() {
    super.initState();
    _resolveRole();
  }

  Future<void> _resolveRole() async {
    try {
      // If the session is stale/broken (e.g. PKCE verifier missing),
      // refreshSession will throw AuthException — catch and fall back to guest.
      final session = Supabase.instance.client.auth.currentSession;
      if (session == null) {
        // No session at all → guest / user stack
        if (!mounted) return;
        setState(() => _state = _RootState.user);
        return;
      }

      final role = await context.read<AdminCubit>().loadCurrentRole();
      if (!mounted) return;
      setState(() {
        _role = role;
        _state = (role == 'admin' || role == 'moderator')
            ? _RootState.admin
            : _RootState.user;
      });
    } on AuthException catch (e) {
      // PKCE "code verifier not found" or any auth exception → treat as guest
      debugPrint('[RootPage] AuthException: ${e.message} — falling back to guest');
      if (!mounted) return;
      try {
        await Supabase.instance.client.auth.signOut();
      } catch (_) {}
      if (!mounted) return;
      setState(() => _state = _RootState.user);
    } catch (_) {
      if (!mounted) return;
      setState(() => _state = _RootState.user);
    }
  }

  @override
  Widget build(BuildContext context) {
    return switch (_state) {
      _RootState.checking => const _SplashScreen(),
      _RootState.admin => AdminStack(userRole: _role),
      _RootState.user => const HomePage(),
    };
  }
}

enum _RootState { checking, user, admin }

// ── Splash giữ chỗ trong lúc check role ───────────────────────────────────
class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 36,
              backgroundColor: colorScheme.surfaceContainerHighest,
              child: const Icon(
                Icons.music_note_rounded,
                color: kAccent,
                size: 36,
              ),
            ),
            const SizedBox(height: 24),
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                color: kAccent,
                strokeWidth: 2.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
