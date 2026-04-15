import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:music_app/data/models/user_song_model.dart';
import 'admin_state.dart';

class AdminCubit extends Cubit<AdminState> {
  final SupabaseClient _db = Supabase.instance.client;

  AdminCubit() : super(const AdminInitial());

  // ── Load current user role ─────────────────────────────────────────────
  Future<String> loadCurrentRole() async {
    final uid = _db.auth.currentUser?.id;
    if (uid == null) return 'user';
    try {
      final res = await _db
          .from('profiles')
          .select('role')
          .eq('id', uid)
          .single();
      return res['role'] as String? ?? 'user';
    } catch (_) {
      return 'user';
    }
  }

  // ── Load all admin data ────────────────────────────────────────────────
  Future<void> loadAll() async {
    emit(const AdminLoading());
    try {
      final currentRole = await loadCurrentRole();

      final statsRaw = await _db.rpc('get_admin_stats');
      final songsRaw = await _db
          .from('user_songs')
          .select('*, profiles(name, email, avatar_url)')
          .order('created_at', ascending: false);
      final usersRaw = await _db.from('profiles').select().order('created_at');
      final commentsRaw = await _db
          .from('comments')
          .select()
          .order('created_at', ascending: false)
          .limit(100);

      emit(AdminLoaded(
        stats: AdminStats.fromJson(statsRaw as Map<String, dynamic>),
        allUserSongs: (songsRaw as List)
            .map((e) => UserSongModel.fromJson(e))
            .toList(),
        users: (usersRaw as List)
            .map((e) => AdminUserItem.fromJson(e))
            .toList(),
        comments: (commentsRaw as List)
            .map((e) => AdminCommentItem.fromJson(e))
            .toList(),
        currentUserRole: currentRole,
      ));
    } catch (e) {
      emit(AdminError('Lỗi tải dữ liệu: $e'));
    }
  }

  // ── Refresh user_songs chỉ ───────────────────────────────────────────────
  Future<void> loadPendingSongs() async {
    if (state is! AdminLoaded) {
      await loadAll();
      return;
    }
    final s = state as AdminLoaded;
    try {
      final raw = await _db
          .from('user_songs')
          .select('*, profiles(name, email, avatar_url)')
          .order('created_at', ascending: false);
      emit(s.copyWith(
        allUserSongs:
            (raw as List).map((e) => UserSongModel.fromJson(e)).toList(),
      ));
    } catch (e) {
      emit(AdminError('Lỗi tải bài: $e'));
    }
  }

  // ── Duyệt bài hát ─────────────────────────────────────────────────────────
  Future<void> approveSong(String songId) async {
    if (state is! AdminLoaded) return;
    try {
      await _db.from('user_songs').update({
        'status': 'approved',
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', songId);

      final s = state as AdminLoaded;
      final updated = s.allUserSongs.map((song) {
        if (song.id != songId) return song;
        // Return a "copy" with status approved (reconstruct via fromJson hack)
        return UserSongModel(
          id: song.id, userId: song.userId, title: song.title,
          artist: song.artist, album: song.album, audioUrl: song.audioUrl,
          artUrl: song.artUrl, durationMs: song.durationMs,
          fileSize: song.fileSize, status: 'approved',
          rejectReason: song.rejectReason, createdAt: song.createdAt,
          uploaderName: song.uploaderName, uploaderEmail: song.uploaderEmail,
          uploaderAvatarUrl: song.uploaderAvatarUrl,
        );
      }).toList();
      emit(s.copyWith(
        allUserSongs: updated,
        stats: AdminStats(
          totalUsers: s.stats.totalUsers,
          totalSongs: s.stats.totalSongs,
          pendingSongs: s.stats.pendingSongs - 1,
          approvedSongs: s.stats.approvedSongs + 1,
          rejectedSongs: s.stats.rejectedSongs,
          totalPlays: s.stats.totalPlays,
          totalComments: s.stats.totalComments,
        ),
      ));
    } catch (e) {
      emit(AdminError('Lỗi duyệt bài: $e'));
    }
  }

  // ── Từ chối bài hát ───────────────────────────────────────────────────────
  Future<void> rejectSong(String songId, String reason) async {
    if (state is! AdminLoaded) return;
    try {
      await _db.from('user_songs').update({
        'status': 'rejected',
        'reject_reason': reason.trim(),
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', songId);

      final s = state as AdminLoaded;
      final updated = s.allUserSongs.map((song) {
        if (song.id != songId) return song;
        return UserSongModel(
          id: song.id, userId: song.userId, title: song.title,
          artist: song.artist, album: song.album, audioUrl: song.audioUrl,
          artUrl: song.artUrl, durationMs: song.durationMs,
          fileSize: song.fileSize, status: 'rejected',
          rejectReason: reason.trim(), createdAt: song.createdAt,
          uploaderName: song.uploaderName, uploaderEmail: song.uploaderEmail,
          uploaderAvatarUrl: song.uploaderAvatarUrl,
        );
      }).toList();
      emit(s.copyWith(
        allUserSongs: updated,
        stats: AdminStats(
          totalUsers: s.stats.totalUsers,
          totalSongs: s.stats.totalSongs,
          pendingSongs: s.stats.pendingSongs - 1,
          approvedSongs: s.stats.approvedSongs,
          rejectedSongs: s.stats.rejectedSongs + 1,
          totalPlays: s.stats.totalPlays,
          totalComments: s.stats.totalComments,
        ),
      ));
    } catch (e) {
      emit(AdminError('Lỗi từ chối bài: $e'));
    }
  }

  // ── Đổi role user (chỉ admin) ─────────────────────────────────────────
  Future<void> changeUserRole(String userId, String newRole) async {
    if (state is! AdminLoaded) return;
    try {
      await _db
          .from('profiles')
          .update({'role': newRole}).eq('id', userId);
      final s = state as AdminLoaded;
      emit(s.copyWith(
        users: s.users.map((u) {
          return u.id == userId ? u.copyWith(role: newRole) : u;
        }).toList(),
      ));
    } catch (e) {
      emit(AdminError('Lỗi đổi role: $e'));
    }
  }

  // ── Ban user (chỉ admin) ───────────────────────────────────────────────
  Future<void> banUser(String userId, String reason) async {
    if (state is! AdminLoaded) return;
    try {
      final now = DateTime.now().toIso8601String();
      await _db.from('profiles').update({
        'is_banned': true,
        'banned_at': now,
        'ban_reason': reason.trim(),
      }).eq('id', userId);

      final s = state as AdminLoaded;
      emit(s.copyWith(
        users: s.users.map((u) {
          return u.id == userId
              ? u.copyWith(isBanned: true, banReason: reason.trim())
              : u;
        }).toList(),
      ));
    } catch (e) {
      emit(AdminError('Lỗi ban user: $e'));
    }
  }

  // ── Unban user (chỉ admin) ────────────────────────────────────────────
  Future<void> unbanUser(String userId) async {
    if (state is! AdminLoaded) return;
    try {
      await _db.from('profiles').update({
        'is_banned': false,
        'banned_at': null,
        'ban_reason': null,
      }).eq('id', userId);

      final s = state as AdminLoaded;
      emit(s.copyWith(
        users: s.users.map((u) {
          return u.id == userId ? u.copyWith(isBanned: false) : u;
        }).toList(),
      ));
    } catch (e) {
      emit(AdminError('Lỗi unban user: $e'));
    }
  }

  // ── Xóa comment ───────────────────────────────────────────────────────
  Future<void> deleteComment(String commentId) async {
    if (state is! AdminLoaded) return;
    try {
      await _db.from('comments').delete().eq('id', commentId);
      final s = state as AdminLoaded;
      emit(s.copyWith(
        comments: s.comments.where((c) => c.id != commentId).toList(),
      ));
    } catch (e) {
      emit(AdminError('Lỗi xóa bình luận: $e'));
    }
  }
}
