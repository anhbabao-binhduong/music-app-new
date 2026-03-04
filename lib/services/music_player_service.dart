import 'package:audio_service/audio_service.dart';
import 'package:audio_session/audio_session.dart';
import '../services/audio_handler.dart';

/// Singleton service that initializes and exposes the audio engine.
/// Use [get_it] to inject this wherever needed.
class MusicPlayerService {
  // Initialized once via [init()] — called from main.dart
  late final MyAudioHandler _audioHandler;

  MyAudioHandler get handler => _audioHandler;

  // ─── Initialization ──────────────────────────────────────

  /// Must be called before runApp(), inside an async main().
  Future<void> init() async {
    // 1. Configure audio session (focus, interruption behavior)
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.music());

    // 2. Register background audio handler with audio_service
    _audioHandler = await AudioService.init(
      builder: () => MyAudioHandler(),
      config: const AudioServiceConfig(
        androidNotificationChannelId: 'com.yourapp.music.channel.audio',
        androidNotificationChannelName: 'Music Playback',
        androidNotificationOngoing: true,
        androidStopForegroundOnPause: true,
        notificationColor: Color(0xFF1DB954), // Spotify-green accent ví dụ
      ),
    );
  }

  // ─── Convenience API (delegates to handler) ──────────────

  Future<void> playSong(MediaItem item) async {
    await _audioHandler.addQueueItems([item]);
    await _audioHandler.play();
  }

  Future<void> playPlaylist(List<MediaItem> items, {int startIndex = 0}) async {
    await _audioHandler.addQueueItems(items);
    await _audioHandler.skipToQueueItem(startIndex);
  }

  Future<void> play()         => _audioHandler.play();
  Future<void> pause()        => _audioHandler.pause();
  Future<void> stop()         => _audioHandler.stop();
  Future<void> next()         => _audioHandler.skipToNext();
  Future<void> previous()     => _audioHandler.skipToPrevious();
  Future<void> seek(Duration pos) => _audioHandler.seek(pos);

  Stream<PlaybackState> get playbackStateStream =>
      _audioHandler.playbackState;

  Stream<MediaItem?> get currentSongStream =>
      _audioHandler.mediaItem;

  Stream<Duration> get positionStream =>
      _audioHandler.positionStream;

  Stream<Duration?> get durationStream =>
      _audioHandler.durationStream;
}