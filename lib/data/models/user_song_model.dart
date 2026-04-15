import 'package:audio_service/audio_service.dart';

class UserSongModel {
  final String id;
  final String userId;
  final String title;
  final String artist;
  final String? album;
  final String audioUrl;
  final String? artUrl;
  final int durationMs;
  final int? fileSize;
  final String status; // 'pending' | 'approved' | 'rejected'
  final String? rejectReason;
  final DateTime createdAt;
  // Uploader info (joined from profiles)
  final String? uploaderName;
  final String? uploaderEmail;
  final String? uploaderAvatarUrl;

  const UserSongModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.artist,
    this.album,
    required this.audioUrl,
    this.artUrl,
    this.durationMs = 0,
    this.fileSize,
    this.status = 'pending',
    this.rejectReason,
    required this.createdAt,
    this.uploaderName,
    this.uploaderEmail,
    this.uploaderAvatarUrl,
  });

  factory UserSongModel.fromJson(Map<String, dynamic> json) {
    // profiles may be joined as a nested map
    final profile = json['profiles'] as Map<String, dynamic>?;
    return UserSongModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      title: json['title'] as String,
      artist: json['artist'] as String? ?? 'Unknown',
      album: json['album'] as String?,
      audioUrl: json['audio_url'] as String,
      artUrl: json['art_url'] as String?,
      durationMs: json['duration_ms'] as int? ?? 0,
      fileSize: json['file_size'] as int?,
      status: json['status'] as String? ?? 'pending',
      rejectReason: json['reject_reason'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      uploaderName: profile?['name'] as String?,
      uploaderEmail: profile?['email'] as String?,
      uploaderAvatarUrl: profile?['avatar_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'user_id': userId,
    'title': title,
    'artist': artist,
    'album': album,
    'audio_url': audioUrl,
    'art_url': artUrl,
    'duration_ms': durationMs,
    'file_size': fileSize,
    'status': status,
  };

  /// Convert sang MediaItem để phát qua PlayerBloc
  MediaItem toMediaItem() {
    return MediaItem(
      id: audioUrl,
      title: title,
      artist: artist,
      album: album ?? 'Nhạc tải lên',
      artUri: artUrl != null ? Uri.parse(artUrl!) : null,
      duration: Duration(milliseconds: durationMs),
      extras: {
        'url': audioUrl,
        'userSongId': id,
        'isUserUpload': true,
      },
    );
  }

  bool get isPending => status == 'pending';
  bool get isApproved => status == 'approved';
  bool get isRejected => status == 'rejected';
}
