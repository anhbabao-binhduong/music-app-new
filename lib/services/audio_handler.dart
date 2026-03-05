import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';

/// Bridges just_audio with audio_service for background playback
/// and media notification controls (lock screen, notification bar).
class MyAudioHandler extends BaseAudioHandler with QueueHandler, SeekHandler {
  final AudioPlayer _player = AudioPlayer();

  MyAudioHandler() {
    _init();
  }

  void _init() {
    // Forward playback state to audio_service
    _player.playbackEventStream.map(_transformEvent).pipe(playbackState);

    // Forward current media item
    _player.currentIndexStream.listen((index) {
      if (index != null && queue.value.isNotEmpty) {
        mediaItem.add(queue.value[index]);
      }
    });
  }

  // ─── Playback Controls ───────────────────────────────────

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> stop() async {
    await _player.stop();
    return super.stop();
  }

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> skipToNext() => _player.seekToNext();

  @override
  Future<void> skipToPrevious() => _player.seekToPrevious();

  @override
  Future<void> setRepeatMode(AudioServiceRepeatMode repeatMode) async {
    final loopMode = switch (repeatMode) {
      AudioServiceRepeatMode.none => LoopMode.off,
      AudioServiceRepeatMode.one  => LoopMode.one,
      _                           => LoopMode.all,
    };
    await _player.setLoopMode(loopMode);
  }

  @override
  Future<void> setShuffleMode(AudioServiceShuffleMode shuffleMode) async {
    final enabled = shuffleMode == AudioServiceShuffleMode.all;
    await _player.setShuffleModeEnabled(enabled);
  }

  // ─── Queue Management ────────────────────────────────────

  @override
Future<void> addQueueItems(List<MediaItem> mediaItems) async {
  final audioSources = mediaItems.map(_mediaItemToAudioSource).toList();

  await _player.setAudioSources(
    audioSources,
    initialIndex: 0,
  );

  queue.add(mediaItems);
}

  @override
  Future<void> skipToQueueItem(int index) async {
    await _player.seek(Duration.zero, index: index);
    play();
  }

  // ─── Helpers ─────────────────────────────────────────────

  AudioSource _mediaItemToAudioSource(MediaItem item) {
  if (item.id.startsWith('assets/')) {
    return AudioSource.asset(item.id, tag: item);
  }
  return AudioSource.uri(Uri.parse(item.id), tag: item);
}

  PlaybackState _transformEvent(PlaybackEvent event) {
    final playing = _player.playing;
    return PlaybackState(
      controls: [
        MediaControl.skipToPrevious,
        playing ? MediaControl.pause : MediaControl.play,
        MediaControl.stop,
        MediaControl.skipToNext,
      ],
      systemActions: const {
        MediaAction.seek,
        MediaAction.seekForward,
        MediaAction.seekBackward,
      },
      androidCompactActionIndices: const [0, 1, 3],
      processingState: switch (_player.processingState) {
        ProcessingState.idle        => AudioProcessingState.idle,
        ProcessingState.loading     => AudioProcessingState.loading,
        ProcessingState.buffering   => AudioProcessingState.buffering,
        ProcessingState.ready       => AudioProcessingState.ready,
        ProcessingState.completed   => AudioProcessingState.completed,
      },
      playing: playing,
      updatePosition: _player.position,
      bufferedPosition: _player.bufferedPosition,
      speed: _player.speed,
      queueIndex: event.currentIndex,
    );
  }

  /// Expose raw player stream for UI progress bar
  Stream<Duration> get positionStream => _player.positionStream;
  Stream<Duration?> get durationStream => _player.durationStream;

  AudioPlayer get player => _player;
}