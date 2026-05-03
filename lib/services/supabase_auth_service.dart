import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseAuthService {
  final SupabaseClient _client = Supabase.instance.client;

  // Web Client ID từ Google Cloud Console
  static const _webClientId =
      '93955508034-qlhk2essllejnvu3djjikb7pa80b2t66.apps.googleusercontent.com';

  User? get currentUser => _client.auth.currentUser;

  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) {
    return _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  Future<AuthResponse> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    final response = await _client.auth.signUp(
      email: email,
      password: password,
      data: {'name': name},
    );
    return response;
  }

  /// Đăng nhập bằng Google (native picker trên mobile, OAuth redirect trên web)
  Future<AuthResponse?> signInWithGoogle() async {
    if (kIsWeb) {
      // ── Web: dùng OAuth redirect ──────────────────────────────────────
      await _client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: Uri.base.origin,
        queryParams: {
          'prompt': 'select_account', // Bắt buộc Google hiện bảng chọn lại tài khoản
        },
      );
      return null; // web tự redirect, không có response ngay
    }

    // ── Mobile: native Google Account Picker ─────────────────────────
    final googleSignIn = GoogleSignIn(serverClientId: _webClientId);

    // Đăng xuất session Google cũ để luôn hiện account picker
    try {
      final isSignedIn = await googleSignIn.isSignedIn();
      if (!isSignedIn) {
        await googleSignIn.signInSilently();
      }
      await googleSignIn.disconnect();
    } catch (_) {}

    try {
      await googleSignIn.signOut();
    } catch (_) {}

    final googleUser = await googleSignIn.signIn();
    if (googleUser == null) {
      throw Exception('Đăng nhập bị huỷ');
    }

    final googleAuth = await googleUser.authentication;
    final idToken = googleAuth.idToken;

    if (idToken == null) {
      throw Exception('Không lấy được ID Token từ Google');
    }

    return _client.auth.signInWithIdToken(
      provider: OAuthProvider.google,
      idToken: idToken,
      accessToken: googleAuth.accessToken,
    );
  }

  // ✅ CHỈ logout, KHÔNG xử lý player ở đây
  Future<void> signOut() async {
    // Đăng xuất khỏi Google nếu đã đăng nhập bằng Google
    try {
      final googleSignIn = GoogleSignIn(serverClientId: _webClientId);
      final isSignedIn = await googleSignIn.isSignedIn();
      if (!isSignedIn) {
        await googleSignIn.signInSilently();
      }
      await googleSignIn.disconnect();
    } catch (_) {}

    try {
      final googleSignIn = GoogleSignIn(serverClientId: _webClientId);
      await googleSignIn.signOut();
    } catch (_) {}

    await _client.auth.signOut();
  }

  Future<void> resetPasswordForEmail(String email) async {
    final redirectTo =
        kIsWeb ? 'http://localhost:3000' : 'com.datmusicapp://reset-password';

    await _client.auth.resetPasswordForEmail(
      email,
      redirectTo: redirectTo,
    );
  }

  Future<void> updatePassword(String newPassword) {
    return _client.auth.updateUser(
      UserAttributes(password: newPassword),
    );
  }

  String mapError(Object error) {
    final message = error.toString().toLowerCase();

    if (message.contains('invalid login credentials')) {
      return 'Email hoặc mật khẩu không đúng';
    }
    if (message.contains('user already registered') ||
        message.contains('email address already exists')) {
      return 'Email này đã được sử dụng';
    }
    if (message.contains('network')) {
      return 'Lỗi kết nối mạng';
    }
    if (message.contains('cancelled') || message.contains('cancel') ||
        message.contains('huỷ')) {
      return 'Đã huỷ đăng nhập';
    }
    if (message.contains('id token')) {
      return 'Đăng nhập Google thất bại, vui lòng thử lại';
    }

    return 'Đã xảy ra lỗi: $error';
  }
}