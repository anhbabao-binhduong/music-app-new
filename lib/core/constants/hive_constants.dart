/// Centralized Hive box name constants.
/// Never hardcode box names inline — always use these.
class HiveBoxes {
  HiveBoxes._();

  static const String songs     = 'songs_box';
  static const String favorites = 'favorites_box';   // Box<SongModel>
  static const String history   = 'history_box';     // Box<HistoryEntryModel>
  static const String playlists = 'playlists_box';   // Box<PlaylistModel>
  static const String albums    = 'albums_box';      // Box<AlbumModel>
  static const String settings  = 'settings_box';    // Box<dynamic>
}

class HiveSettingsKeys {
  HiveSettingsKeys._();

  static const String themeMode            = 'theme_mode'; // 'dark' | 'light' | 'system'
  static const String lastSongId           = 'last_song_id';
  static const String lastPosition         = 'last_position_ms';
  static const String volumeLevel          = 'volume_level';
  static const String notificationsEnabled = 'notifications_enabled';
  static const String resumePlayback       = 'resume_playback';
  static const String downloadOnWifiOnly   = 'download_on_wifi_only';
  static const String streamQuality        = 'stream_quality';

  // Queue persistence — key theo userId để mỗi tài khoản có queue riêng
  // Dùng: queuePrefix + userId  →  e.g. "queue_abc123"
  static const String queuePrefix        = 'queue_';         // List<Map> JSON
  static const String queueIndexPrefix   = 'queue_index_';   // int: vị trí bài đang phát
}