import 'package:equatable/equatable.dart';
import 'package:music_app/data/models/user_song_model.dart';

// ── Admin Stats ────────────────────────────────────────────────────────────
class AdminStats extends Equatable {
  final int totalUsers;
  final int totalSongs;
  final int pendingSongs;
  final int approvedSongs;
  final int rejectedSongs;
  final int totalPlays;
  final int totalComments;

  const AdminStats({
    required this.totalUsers,
    required this.totalSongs,
    required this.pendingSongs,
    required this.approvedSongs,
    required this.rejectedSongs,
    required this.totalPlays,
    required this.totalComments,
  });

  factory AdminStats.fromJson(Map<String, dynamic> j) => AdminStats(
        totalUsers: (j['total_users'] as num).toInt(),
        totalSongs: (j['total_songs'] as num).toInt(),
        pendingSongs: (j['pending_songs'] as num).toInt(),
        approvedSongs: (j['approved_songs'] as num).toInt(),
        rejectedSongs: (j['rejected_songs'] as num).toInt(),
        totalPlays: (j['total_plays'] as num).toInt(),
        totalComments: (j['total_comments'] as num).toInt(),
      );

  @override
  List<Object?> get props => [pendingSongs, totalUsers];
}

// ── User item ──────────────────────────────────────────────────────────────
class AdminUserItem extends Equatable {
  final String id;
  final String? name;
  final String? email;
  final String? avatarUrl;
  final String role;
  final bool isBanned;
  final DateTime? bannedAt;
  final String? banReason;
  final DateTime? createdAt;

  const AdminUserItem({
    required this.id,
    this.name,
    this.email,
    this.avatarUrl,
    required this.role,
    this.isBanned = false,
    this.bannedAt,
    this.banReason,
    this.createdAt,
  });

  factory AdminUserItem.fromJson(Map<String, dynamic> j) => AdminUserItem(
        id: j['id'] as String,
        name: j['name'] as String?,
        email: j['email'] as String?,
        avatarUrl: j['avatar_url'] as String?,
        role: j['role'] as String? ?? 'user',
        isBanned: j['is_banned'] as bool? ?? false,
        bannedAt: j['banned_at'] != null
            ? DateTime.tryParse(j['banned_at'] as String)
            : null,
        banReason: j['ban_reason'] as String?,
        createdAt: j['created_at'] != null
            ? DateTime.tryParse(j['created_at'] as String)
            : null,
      );

  AdminUserItem copyWith({String? role, bool? isBanned, String? banReason}) =>
      AdminUserItem(
        id: id,
        name: name,
        email: email,
        avatarUrl: avatarUrl,
        role: role ?? this.role,
        isBanned: isBanned ?? this.isBanned,
        bannedAt: bannedAt,
        banReason: banReason ?? this.banReason,
        createdAt: createdAt,
      );

  @override
  List<Object?> get props => [id, role, isBanned];
}

// ── Comment item ───────────────────────────────────────────────────────────
class AdminCommentItem extends Equatable {
  final String id;
  final String songId;
  final String userId;
  final String displayName;
  final String content;
  final DateTime createdAt;

  const AdminCommentItem({
    required this.id,
    required this.songId,
    required this.userId,
    required this.displayName,
    required this.content,
    required this.createdAt,
  });

  factory AdminCommentItem.fromJson(Map<String, dynamic> j) =>
      AdminCommentItem(
        id: j['id'] as String,
        songId: j['song_id'] as String,
        userId: j['user_id'] as String,
        displayName: j['display_name'] as String? ?? 'Anonymous',
        content: j['content'] as String,
        createdAt: DateTime.parse(j['created_at'] as String),
      );

  @override
  List<Object?> get props => [id];
}

// ── States ─────────────────────────────────────────────────────────────────
abstract class AdminState extends Equatable {
  const AdminState();
  @override
  List<Object?> get props => [];
}

class AdminInitial extends AdminState {
  const AdminInitial();
}

class AdminLoading extends AdminState {
  const AdminLoading();
}

class AdminLoaded extends AdminState {
  final AdminStats stats;
  final List<UserSongModel> allUserSongs;
  final List<AdminUserItem> users;
  final List<AdminCommentItem> comments;
  final String currentUserRole;

  const AdminLoaded({
    required this.stats,
    required this.allUserSongs,
    required this.users,
    required this.comments,
    this.currentUserRole = 'user',
  });

  /// Convenience getters for filtered views
  List<UserSongModel> get pendingSongs =>
      allUserSongs.where((s) => s.isPending).toList();
  List<UserSongModel> get approvedSongs =>
      allUserSongs.where((s) => s.isApproved).toList();
  List<UserSongModel> get rejectedSongs =>
      allUserSongs.where((s) => s.isRejected).toList();

  AdminLoaded copyWith({
    AdminStats? stats,
    List<UserSongModel>? allUserSongs,
    List<AdminUserItem>? users,
    List<AdminCommentItem>? comments,
    String? currentUserRole,
  }) =>
      AdminLoaded(
        stats: stats ?? this.stats,
        allUserSongs: allUserSongs ?? this.allUserSongs,
        users: users ?? this.users,
        comments: comments ?? this.comments,
        currentUserRole: currentUserRole ?? this.currentUserRole,
      );

  bool get isAdmin => currentUserRole == 'admin';
  bool get isModerator => currentUserRole == 'moderator';
  bool get canManageUsers => isAdmin;

  @override
  List<Object?> get props => [stats, allUserSongs.length, users.length, currentUserRole];
}

class AdminError extends AdminState {
  final String message;
  const AdminError(this.message);
  @override
  List<Object?> get props => [message];
}
