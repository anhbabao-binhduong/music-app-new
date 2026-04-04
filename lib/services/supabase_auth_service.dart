import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseAuthService {
  final SupabaseClient _client = Supabase.instance.client;

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

  // ✅ CHỈ logout, KHÔNG xử lý player ở đây
  Future<void> signOut() async {
    await _client.auth.signOut();
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

    return 'Đã xảy ra lỗi: $error';
  }
}